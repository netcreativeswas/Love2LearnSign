import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:provider/provider.dart';
import 'tenancy/tenant_scope.dart';
import 'package:video_player/video_player.dart';
import 'l10n/dynamic_l10n.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:love_to_learn_sign/widgets/video_controls.dart';
import 'services/cache_service.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:line_icons/line_icons.dart';
import 'services/spaced_repetition_service.dart';
import 'theme.dart';
import 'widgets/fullscreen_video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:l2l_shared/tenancy/concept_text.dart';
import 'package:l2l_shared/tenancy/concept_media.dart';
import 'services/flashcard_notification_service.dart';

// For flip animation, we use pi from dart:math above.

class FlashcardPage extends StatefulWidget {
  final int numCards;
  final String contentChoice;   // 'random' ou nom de catégorie
  final bool startingPoint;     // false = word first, true = sign first
  final List<String>? reviewWordIds; // optional: explicit list of word IDs to review (preserve order)

  const FlashcardPage({
    super.key,
    required this.numCards,
    required this.contentChoice,
    required this.startingPoint,
    this.reviewWordIds,
  });

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> with WidgetsBindingObserver {
  // Nouveaux états pour les boutons
  Map<int, String> _wordStatuses = {}; // 'mastered' ou 'review'
  Map<int, int> _wordFrequencies = {}; // fréquence de révision en jours

  void _enterFullscreen() async {
    if (!mounted || _videoController == null || _cards.isEmpty || _currentIndex >= _cards.length) return;
    
    final controller = _videoController!;
    final doc = _cards[_currentIndex];
    final data = doc.data() as Map<String, dynamic>;
    
    final scope = context.read<TenantScope>();
    final localLang = scope.contentLocale;

    // Use multi-language schema with legacy fallbacks.
    final english = ConceptText.labelFor(data, lang: 'en', fallbackLang: 'en');
    final localWord = ConceptText.labelFor(data, lang: localLang, fallbackLang: 'en');
    
    // Get wordId
    final wordId = doc.id;
    
    // Apply current speed to controller before going fullscreen
    controller.setPlaybackSpeed(_currentSpeed);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          controller: controller,
          wordId: wordId,
          english: english,
          bengali: localWord,
          showShareButton: false, // Hide share button in flashcard fullscreen
        ),
      ),
    );

    // Update speed if it was changed in fullscreen
    if (mounted) {
      setState(() {
        _currentSpeed = controller.value.playbackSpeed;
      });
    }
  }
  List<DocumentSnapshot> _allWords = [];
  List<DocumentSnapshot> _cards = [];
  int _currentIndex = 0;
  bool _showFront = true;
  VideoPlayerController? _videoController;
  final AudioPlayer _flipSoundPlayer = AudioPlayer();
  final AudioPlayer _successSoundPlayer = AudioPlayer();
  final AudioPlayer _clickSoundPlayer = AudioPlayer();
  // Cache controllers for preloading videos
  final Map<int, VideoPlayerController> _videoControllers = {};
  // Track the expected source URL per index to avoid mismatches
  final Map<int, String> _controllerUrlByIndex = {};
  // In-memory LRU for initialized controllers - reduced to prevent memory issues
  static const int _cacheCap = 4; // Reduced from 12 to prevent NO_MEMORY errors
  final List<int> _lruOrder = [];
  
  // Flags for state management
  bool _isDisposed = false;
  bool _isTransitioning = false;
  bool _isFlipping = false;

  void _touchLRU(int index) {
    _lruOrder.remove(index);
    _lruOrder.add(index);
  }

  void _evictIfNeeded() {
    while (_lruOrder.length > _cacheCap) {
      final victim = _lruOrder.removeAt(0);
      final controller = _videoControllers.remove(victim);
      try { controller?.dispose(); } catch (_) {}
    }
  }

  void _cachePut(int index, VideoPlayerController c, {required String sourceUrl}) {
    _videoControllers[index] = c;
    _controllerUrlByIndex[index] = sourceUrl;
    _touchLRU(index);
    _evictIfNeeded();
  }

  /// Prefer reading from disk cache first; otherwise stream from network.
  /// Always applies a timeout to initialization to avoid hangs.
  Future<VideoPlayerController> _makeControllerFromUrl(String url) async {
    // Try cache-only first (fast path, no network)
    try {
      final file = await CacheService.instance.getFromCacheOnly(url);
      if (file != null) {
        final c = VideoPlayerController.file(file);
        await c.initialize().timeout(const Duration(seconds: 6));
        c.setLooping(true);
        return c;
      }
    } catch (e) {
      debugPrint('Flashcards: cache-only fetch failed: $e');
    }

    // Fallback to progressive network stream
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    await c.initialize().timeout(const Duration(seconds: 6));
    c.setLooping(true);
    return c;
  }
  double _currentSpeed = 1.0;

  bool _slideForward = true;

  Future<void> _preloadCurrentVideoControllerIfNeeded(int index) async {
    if (_isDisposed || !mounted) return;
    if (index < 0 || index >= _cards.length) return;

    final data = _cards[index].data() as Map<String, dynamic>;
    String url = '';
    if (data.containsKey('variants')) {
      final variants = data['variants'] as List<dynamic>;
      if (variants.isNotEmpty) {
        final firstVariant = variants[0] as Map<String, dynamic>;
        url = ConceptMedia.video480FromVariant(firstVariant);
      }
    }
    if (url.isEmpty) return;

    // If we already have a matching cached controller, nothing to do.
    if (_videoControllers.containsKey(index) && _controllerUrlByIndex[index] == url) {
      final existing = _videoControllers[index];
      if (existing != null && existing.value.isInitialized) {
        return;
      }
    }

    try {
      // Build/init controller and cache it. Do NOT auto-play here.
      final controller = await _makeControllerFromUrl(url);
      await controller.seekTo(Duration.zero);

      if (_isDisposed || !mounted) {
        try { controller.dispose(); } catch (_) {}
        return;
      }
      if (index >= _cards.length) {
        try { controller.dispose(); } catch (_) {}
        return;
      }

      _cachePut(index, controller, sourceUrl: url);

      // If this is the current card and we don't have a controller yet (word-first mode),
      // point _videoController at it so flipping shows the correct video immediately.
      if (index == _currentIndex && !widget.startingPoint) {
        _videoController = controller;
      }
    } catch (e) {
      debugPrint('Flashcards: preload current video failed for index $index: $e');
    }
  }

  // Nouvelles méthodes pour gérer les statuts des mots
  void _markWordAsMastered() {
    // Prevent multiple calls or if already transitioning
    if (_isTransitioning || _isDisposed || !mounted) return;
    
    // Jouer le son de succès
    _successSoundPlayer.play(AssetSource('sounds/success-chime.mp3'));
    
    if (mounted && !_isDisposed) {
      setState(() {
        _wordStatuses[_currentIndex] = 'mastered';
        _wordFrequencies.remove(_currentIndex);
      });
    }

    // Sauvegarder dans le service de répétition espacée
    final wordId = _cards[_currentIndex].id;
    SpacedRepetitionService().markWordAsMastered(wordId);
    // Recompute reminders (only if something is due today; service checks prefs).
    FlashcardNotificationService().scheduleAllReviewNotifications();

    // Avance automatiquement vers la prochaine carte
    _nextCard();
  }

  void _markWordForReview(int frequency) {
    // Prevent multiple calls or if already transitioning
    if (_isTransitioning || _isDisposed || !mounted) return;
    
    if (mounted && !_isDisposed) {
      setState(() {
        _wordStatuses[_currentIndex] = 'review';
        _wordFrequencies[_currentIndex] = frequency;
      });
    }

    // Sauvegarder dans le service de répétition espacée
    final wordId = _cards[_currentIndex].id.toString();
    final frequencyString = _getFrequencyString(frequency);
    SpacedRepetitionService().addWordToReview(wordId, frequencyString);
    // Recompute reminders (only if something is due today; service checks prefs).
    FlashcardNotificationService().scheduleAllReviewNotifications();

    // Avance automatiquement vers la prochaine carte
    _nextCard();
  }

  String _getFrequencyString(int days) {
    return S.of(context)!.flashcardDays(days);
  }

  void _showReviewOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context)!.flashcardChooseReviewFrequency,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: [
                  _buildFrequencyButton(1, S.of(context)!.flashcardDays(1)),
                  _buildFrequencyButton(3, S.of(context)!.flashcardDays(3)),
                  _buildFrequencyButton(7, S.of(context)!.flashcardDays(7)),
                  _buildFrequencyButton(14, S.of(context)!.flashcardDays(14)),
                  _buildFrequencyButton(30, S.of(context)!.flashcardDays(30)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrequencyButton(int frequency, String label) {
    final currentFrequency = _wordFrequencies[_currentIndex];
    final isSelected = currentFrequency == frequency;

    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        _markWordForReview(frequency);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.orange
            : Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }

  void _showSessionEndDialog() {
    final masteredCount = _wordStatuses.values.where((status) => status == 'mastered').length;
    final reviewCount = _wordStatuses.values.where((status) => status == 'review').length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text(S.of(context)!.flashcardCongratsTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context)!.flashcardSessionCompleted(widget.numCards),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildStatRow(S.of(context)!.flashcardStatsMastered, masteredCount, Colors.green),
              SizedBox(height: 10),
              _buildStatRow(S.of(context)!.flashcardStatsToReview, reviewCount, Colors.orange),
              SizedBox(height: 20),
              if (reviewCount > 0) ...[
                Text(S.of(context)!.flashcardStatsByFrequency, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ..._buildFrequencyStats(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Retour à la page précédente
              },
              child: Text(S.of(context)!.flashcardFinish),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        SizedBox(width: 8),
        Text(label),
        Spacer(),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFrequencyStats() {
    final frequencyMap = <int, int>{};
    _wordStatuses.forEach((index, status) {
      if (status == 'review') {
        final frequency = _wordFrequencies[index] ?? 3;
        frequencyMap[frequency] = (frequencyMap[frequency] ?? 0) + 1;
      }
    });

    return frequencyMap.entries.map((entry) {
      return Padding(
        padding: EdgeInsets.only(left: 20, bottom: 5),
        child: Text('• ${S.of(context)!.flashcardDays(entry.key)}: ${entry.value}'),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    // Précharger les sons pour éviter le retard
    _preloadSounds();
    _loadWords().then((_) async {
      await _prepareCards();
      if (!mounted) return;
      // Only auto-initialize when starting with video side
      if (_cards.isNotEmpty && widget.startingPoint) {
        await _initializeVideo(0);
      } else if (_cards.isNotEmpty && !widget.startingPoint) {
        // Word-first: preload current card's video so flip plays instantly.
        unawaited(_preloadCurrentVideoControllerIfNeeded(0));
      }
    });
  }

  Future<void> _preloadSounds() async {
    try {
      // Configurer pour latence minimale et volume à 1.0
      await _flipSoundPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _flipSoundPlayer.setVolume(1.0);
      await _successSoundPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _successSoundPlayer.setVolume(1.0);
      await _clickSoundPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _clickSoundPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Error preloading sounds: $e');
    }
  }

  Future<void> _initializeVideo(int index) async {
    // Safety check: ensure index is valid and not disposed
    if (_isDisposed || !mounted || index < 0 || index >= _cards.length) {
      debugPrint('Flashcard: invalid index $index, cards length: ${_cards.length}');
      _videoController?.pause();
      _videoController = null;
      if (!mounted) return;
      setState(() {
        _currentSpeed = 1.0;
      });
      return;
    }
    
    // Determine expected URL for this index
    final data = _cards[index].data() as Map<String, dynamic>;
    String url = '';
    if (data.containsKey('variants')) {
      final variants = data['variants'] as List<dynamic>;
      if (variants.isNotEmpty) {
        final firstVariant = variants[0] as Map<String, dynamic>;
        url = ConceptMedia.video480FromVariant(firstVariant);
      }
    }

    // Reuse if already cached and URL matches; otherwise rebuild
    if (_videoControllers.containsKey(index)) {
      if (_controllerUrlByIndex[index] == url && url.isNotEmpty) {
        final cachedController = _videoControllers[index];
        if (cachedController != null && cachedController.value.isInitialized) {
          // Pause previous controller if different
          if (_videoController != null && _videoController != cachedController) {
            _videoController!.pause();
          }
          _videoController = cachedController;
          _touchLRU(index);
          // Toujours remettre au début et forcer la lecture
          _videoController!.setLooping(true);
          await _videoController!.seekTo(Duration.zero);
          await _videoController!.play();
          if (!mounted) return;
          setState(() {
            _currentSpeed = _videoController?.value.playbackSpeed ?? 1.0;
          });
          debugPrint('Flashcard: reused cached controller for index $index');
          return;
        } else {
          // Controller exists but not initialized - remove it and rebuild
          debugPrint('Flashcard: cached controller for index $index not initialized, rebuilding');
          try { _videoControllers[index]?.dispose(); } catch (_) {}
          _videoControllers.remove(index);
          _controllerUrlByIndex.remove(index);
        }
      } else {
        // URL mismatch: dispose stale controller and rebuild
        debugPrint('Flashcard: URL mismatch for index $index, rebuilding');
        try { _videoControllers[index]?.dispose(); } catch (_) {}
        _videoControllers.remove(index);
        _controllerUrlByIndex.remove(index);
      }
    }
    debugPrint('Flashcard: initializing video for index $index with URL: $url');

    if (url.isNotEmpty) {
      try {
        // Pause previous controller before creating new one
        if (_videoController != null) {
          _videoController!.pause();
        }
        
      final controller = await _makeControllerFromUrl(url);
        
        // Double-check that we're still on the same index (user might have navigated away)
        if (!mounted || index != _currentIndex) {
          debugPrint('Flashcard: index changed during initialization, disposing controller');
          controller.dispose();
          return;
        }
        
      _videoController = controller;
      _cachePut(index, controller, sourceUrl: url);
      // Forcer la lecture depuis le début
      await _videoController!.seekTo(Duration.zero);
      await _videoController!.play();
      if (!mounted) return;
      setState(() {
        _currentSpeed = _videoController!.value.playbackSpeed;
      });
      debugPrint('Flashcard: successfully initialized video for index $index');
      } catch (e) {
        debugPrint('Flashcard: error initializing video for index $index: $e');
        // Clear controller on error to avoid showing wrong video
        _videoController?.pause();
        _videoController = null;
        // Remove failed controller from cache if it exists
        if (_videoControllers.containsKey(index)) {
          try {
            _videoControllers[index]?.dispose();
          } catch (_) {}
          _videoControllers.remove(index);
          _controllerUrlByIndex.remove(index);
          _lruOrder.remove(index);
        }
        if (!mounted) return;
        setState(() {
          _currentSpeed = 1.0;
        });
      }
    } else {
      // No video URL for this card - clear the controller to avoid showing wrong video
      debugPrint('Flashcard: no video URL for index $index, clearing controller');
      _videoController?.pause();
      _videoController = null;
      if (!mounted) return;
      setState(() {
        _currentSpeed = 1.0;
      });
    }

    // Warm upcoming cards
    _preloadNextVideos();
  }

  Future<void> _loadWords() async {
    try {
      if (widget.contentChoice == 'review_existing') {
        debugPrint('Flashcards: loading words for review');

        // If caller passed explicit IDs (from Review Sessions), fetch exactly those and preserve order.
        final explicitIds = widget.reviewWordIds;
        if (explicitIds != null && explicitIds.isNotEmpty) {
          // Firestore whereIn is limited to 10 per query; split in chunks of 10
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
          for (int i = 0; i < explicitIds.length; i += 10) {
            final chunk = explicitIds.sublist(i, (i + 10 > explicitIds.length) ? explicitIds.length : i + 10);
            final tenantId = context.read<TenantScope>().tenantId;
            final snap = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            docs.addAll(snap.docs);
          }
          // Preserve the order provided by explicitIds
          docs.sort((a, b) => explicitIds.indexOf(a.id).compareTo(explicitIds.indexOf(b.id)));
          _allWords = docs;
          debugPrint('Flashcards: loaded ${_allWords.length} words from explicit reviewWordIds');
          return;
        }

        // Fallback: load from SpacedRepetitionService (previous behavior)
        final wordsToReview = await SpacedRepetitionService().getAllWordsToReview();
        final wordsToReviewList = wordsToReview.where((word) {
          final status = (word.status ?? '').toString().toLowerCase().trim();
          // Accept common variants to avoid locale coupling
          return status == 'review' ||
              status == S.of(context)!.flashcardToReview.toLowerCase() ||
              status == 'à revoir';
        }).toList();
        if (wordsToReviewList.isEmpty) {
          debugPrint('Flashcards: no words to review found');
          _allWords = [];
          return;
        }
        final wordIds = wordsToReviewList.map((word) => word.wordId).toList();
        final tenantId = context.read<TenantScope>().tenantId;
        final snapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
            .where(FieldPath.documentId, whereIn: wordIds)
            .get();
        // Keep stable order (as they came from the service)
        final docs = snapshot.docs;
        docs.sort((a, b) => wordIds.indexOf(a.id).compareTo(wordIds.indexOf(b.id)));
        _allWords = docs;
        debugPrint('Flashcards: loaded ${_allWords.length} words for review from SpacedRepetitionService');
        return;
      } else {
        // Cas normal : charger depuis Firestore selon la catégorie
        final tenantId = context.read<TenantScope>().tenantId;
        Query<Map<String, dynamic>> q = TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId);

        if (widget.contentChoice != 'random') {
          // Specific main category: include all docs whose category_main matches,
          // regardless of subcategory.
          q = q.where('category_main', isEqualTo: widget.contentChoice);
        }

        final snapshot = await q.get();
        _allWords = snapshot.docs;

        debugPrint('Flashcards: fetched ${_allWords.length} docs '
            'for choice="${widget.contentChoice}".');
      }
    } catch (e, st) {
      debugPrint('Flashcards: error while loading words: $e\n$st');
      _allWords = [];
    }
  }

  Future<void> _prepareCards() async {
    // Preserve explicit order if reviewWordIds was provided; otherwise shuffle
    if (!(widget.reviewWordIds != null && widget.reviewWordIds!.isNotEmpty)) {
      _allWords.shuffle();
    }
    final takeCount = widget.numCards.clamp(0, _allWords.length);
    _cards = _allWords.take(takeCount).toList();
    setState(() {}); // trigger build
    // Video initialization removed from here.
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _videoControllers.values) {
      try { controller.dispose(); } catch (_) {}
    }
    _videoControllers.clear();
    _videoController = null;
    _flipSoundPlayer.dispose();
    _successSoundPlayer.dispose();
    _clickSoundPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause la vidéo actuelle quand l'app va en background
      if (_videoController != null && _videoController!.value.isInitialized && _videoController!.value.isPlaying) {
        _videoController!.pause();
      }
      // Pause aussi toutes les vidéos en cache
      for (final controller in _videoControllers.values) {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          controller.pause();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Reprend la vidéo actuelle quand l'app revient au premier plan
      if (_videoController != null && _videoController!.value.isInitialized && !_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    }
  }

  void _flipCard() async {
    // Prevent multiple simultaneous flips
    if (_isFlipping || _isDisposed || !mounted) return;
    _isFlipping = true;
    
    // Jouer le son de retournement
    _flipSoundPlayer.play(AssetSource('sounds/card-flip.mp3'));
    
    // Determine if the next side to show is the video side
    final showVideo = _showFront
      ? !widget.startingPoint   // front=word when startingPoint=false; so flip to video
      : widget.startingPoint;    // front=video when startingPoint=true; so flip to video on back

    if (mounted) {
      setState(() => _showFront = !_showFront);
    }
    
    if (showVideo && !_isDisposed) {
      // Initialize the video for the current card and wait for it
      await _initializeVideo(_currentIndex);
      if (!mounted || _isDisposed) {
        _isFlipping = false;
        return;
      }

      // Post-frame to avoid timing with the flip animation / switcher.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _isDisposed) return;
        try {
          if (_videoController != null && _videoController!.value.isInitialized) {
            await _videoController!.seekTo(Duration.zero);
            await _videoController!.play();
          }
        } catch (_) {
          // best-effort only
        }
      });

      // Force setState to refresh UI after video is ready
      if (mounted && !_isDisposed) setState(() {});
    }
    
    _isFlipping = false;
  }

  void _preloadNextVideos() {
    // Don't preload if disposed
    if (_isDisposed || !mounted) return;
    
    // Limit warmup to the next 2 items to avoid memory issues (reduced from 3)
    final int start = _currentIndex + 1;
    final int endExclusive = (_cards.length < start + 2) ? _cards.length : start + 2;
    for (var i = start; i < endExclusive; i++) {
      if (_videoControllers.containsKey(i) || _isDisposed) continue;

      final data = _cards[i].data() as Map<String, dynamic>;
      String url = '';
      if (data.containsKey('variants')) {
        final variants = data['variants'] as List<dynamic>;
        if (variants.isNotEmpty) {
          final firstVariant = variants[0] as Map<String, dynamic>;
          url = ConceptMedia.video480FromVariant(firstVariant);
        }
      }
      if (url.isEmpty) continue;

      final preloadIndex = i;
      final preloadUrl = url;
      // Fire-and-forget: prefetch file respecting user settings, then init controller with timeout.
      () async {
        try {
          // Check if index is still valid before preloading
          if (preloadIndex >= _cards.length || !mounted || _isDisposed) {
            debugPrint('Flashcards: skipping preload for index $preloadIndex (out of bounds or unmounted)');
            return;
          }
          
          final file = await CacheService.instance.getSingleFileRespectingSettings(preloadUrl);
          if (file == null || _isDisposed) return; // e.g., Wi‑Fi only not met
          
          // Double-check index is still valid after async operation
          if (preloadIndex >= _cards.length || !mounted || _isDisposed) {
            debugPrint('Flashcards: skipping preload for index $preloadIndex (index changed during download)');
            return;
          }
          
          final controller = VideoPlayerController.file(file);
          await controller.initialize().timeout(const Duration(seconds: 6));
          
          // Final check before caching
          if (preloadIndex >= _cards.length || !mounted || _isDisposed) {
            controller.dispose();
            debugPrint('Flashcards: disposing preloaded controller for index $preloadIndex (index changed)');
            return;
          }
          
          controller.setLooping(true);
          _cachePut(preloadIndex, controller, sourceUrl: preloadUrl);
          debugPrint('Flashcards: successfully preloaded video for index $preloadIndex');
        } catch (e) {
          debugPrint('Flashcards: preload failed for index $preloadIndex: $e');
          // Clean up any partial state
          if (_videoControllers.containsKey(preloadIndex)) {
            try {
              _videoControllers[preloadIndex]?.dispose();
            } catch (_) {}
            _videoControllers.remove(preloadIndex);
            _controllerUrlByIndex.remove(preloadIndex);
            _lruOrder.remove(preloadIndex);
          }
        }
      }();
    }
  }

  void _previousCard() {
    // Prevent multiple simultaneous transitions
    if (_isTransitioning || _isDisposed || !mounted || _currentIndex <= 0) return;
    _isTransitioning = true;
    
    _slideForward = false;
    
    // Pause video safely
    try {
      _videoController?.pause();
    } catch (_) {}
    
    _currentIndex--;
    
    // Clean up controllers that are far from current index to free memory
    _cleanupDistantControllers();
    
    _showFront = true;
    
    if (widget.startingPoint) {
      _initializeVideo(_currentIndex).then((_) {
        _isTransitioning = false;
        if (!mounted || _isDisposed) return;
        // Ensure autoplay after transition (Mastered/Review/Prev) in sign-first mode.
        try {
          if (_videoController != null && _videoController!.value.isInitialized) {
            _videoController!.seekTo(Duration.zero);
            _videoController!.play();
          }
        } catch (_) {}
        setState(() {});
      });
    } else {
      // Word-first: clear any stale controller so flip doesn't show previous card's video.
      _videoController = null;
      _isTransitioning = false;
      if (mounted && !_isDisposed) {
        setState(() {});
      }
      // Preload the current card's video in the background for instant flip.
      unawaited(_preloadCurrentVideoControllerIfNeeded(_currentIndex));
    }
  }

  void _nextCard() {
    // Prevent multiple simultaneous transitions
    if (_isTransitioning || _isDisposed || !mounted) return;
    _isTransitioning = true;
    
    _slideForward = true;
    
    // Pause video safely
    try {
      _videoController?.pause();
    } catch (_) {}
    
    _currentIndex++;
    
    // Clean up controllers that are far from current index to free memory
    _cleanupDistantControllers();
    
    if (_currentIndex >= _cards.length) {
      _isTransitioning = false;
      // Session terminée, afficher le dialogue de fin au lieu de naviguer
      if (!_isDisposed && mounted) {
        _showSessionEndDialog();
      }
    } else {
      _showFront = true;
      if (widget.startingPoint) {
        _initializeVideo(_currentIndex).then((_) {
          _isTransitioning = false;
          if (!mounted || _isDisposed) return;
          // Ensure autoplay after transition (Mastered/Review/Next) in sign-first mode.
          try {
            if (_videoController != null && _videoController!.value.isInitialized) {
              _videoController!.seekTo(Duration.zero);
              _videoController!.play();
            }
          } catch (_) {}
          setState(() {});
        });
      } else {
        // Word-first: clear any stale controller so flip doesn't show previous card's video.
        _videoController = null;
        _isTransitioning = false;
        if (mounted && !_isDisposed) {
          setState(() {});
        }
        // Preload the current card's video in the background for instant flip.
        unawaited(_preloadCurrentVideoControllerIfNeeded(_currentIndex));
      }
    }
  }
  
  void _cleanupDistantControllers() {
    // Keep only controllers within 2 indices of current position
    final indicesToKeep = <int>{};
    for (int i = (_currentIndex - 1).clamp(0, _cards.length - 1); 
         i <= (_currentIndex + 2).clamp(0, _cards.length - 1); 
         i++) {
      indicesToKeep.add(i);
    }
    
    // Dispose and remove controllers that are too far away
    final keysToRemove = <int>[];
    for (final key in _videoControllers.keys) {
      if (!indicesToKeep.contains(key)) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      try {
        _videoControllers[key]?.dispose();
      } catch (_) {}
      _videoControllers.remove(key);
      _controllerUrlByIndex.remove(key);
      _lruOrder.remove(key);
      debugPrint('Flashcard: cleaned up controller for distant index $key');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Title & data mapping
    String title = S.of(context)!.flashcardGame;
    if (widget.contentChoice == 'random') {
      title = '${S.of(context)!.flashcardGame} — ${S.of(context)!.randomAllCategories}';
    } else if (widget.contentChoice == 'review_existing') {
      title = '${S.of(context)!.flashcardGame} — ${S.of(context)!.flashcardReviewExisting}';
    } else {
      final String locCat = translateCategory(context, widget.contentChoice);
      title = '${S.of(context)!.flashcardGame} — $locCat';
    }

    String subtitle = '';
    String word = '';
    String videoUrl = '';

    if (_cards.isNotEmpty && _currentIndex < _cards.length) {
      final doc = _cards[_currentIndex];
      final data = doc.data() as Map<String, dynamic>;
      subtitle = '${_currentIndex + 1}/${_cards.length}';

      // Display the tenant local language (with fallback to EN).
      final scope = context.read<TenantScope>();
      final localLang = scope.contentLocale;
      word = ConceptText.labelFor(data, lang: localLang, fallbackLang: 'en');

      if (data.containsKey('variants')) {
        final variants = data['variants'] as List<dynamic>;
        if (variants.isNotEmpty) {
          final firstVariant = variants[0] as Map<String, dynamic>;
          videoUrl = ConceptMedia.video480FromVariant(firstVariant);
        }
      }
    } else if (_cards.isNotEmpty) {
      // Safety during transition when index == length
      subtitle = '${_cards.length}/${_cards.length}';
    }

    final currentStatus = _wordStatuses[_currentIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: _cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    // === Slide only the card area ===
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final offsetBegin = _slideForward ? const Offset(1, 0) : const Offset(-1, 0);
                          final position = animation.drive(
                            Tween<Offset>(begin: offsetBegin, end: Offset.zero)
                                .chain(CurveTween(curve: Curves.ease)),
                          );
                          return SlideTransition(position: position, child: child);
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentIndex),
                          child: GestureDetector(
                            onTap: _flipCard,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                final rotateAnim = animation
                                    .drive(Tween<double>(begin: pi, end: 0)
                                        .chain(CurveTween(curve: Curves.easeInOut)));
                                return AnimatedBuilder(
                                  animation: rotateAnim,
                                  child: child,
                                  builder: (context, child) {
                                    final isUnder = (rotateAnim.value > pi / 2);
                                    return Transform(
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(rotateAnim.value),
                                      alignment: Alignment.center,
                                      child: Opacity(opacity: isUnder ? 0.0 : 1.0, child: child),
                                    );
                                  },
                                );
                              },
                              child: Card(
                                key: ValueKey(_showFront),
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: AspectRatio(
                                  aspectRatio: 4 / 5, // Portrait format matching video
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                                        Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
                                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
                                        Theme.of(context).colorScheme.surface.withOpacity(0.4),
                                        Theme.of(context).colorScheme.surface.withOpacity(0.9),
                                      ],
                                      stops: const [0.0, 0.3, 0.5, 0.6, 0.7, 1.0],
                                    ),
                                  ),
                                    child: Center(
                                    child: _showFront
                                        ? (widget.startingPoint
                                            ? _buildVideoPlayer(videoUrl)
                                              : Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      word,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 40,
                                                            fontFamily: 'Lobster',
                                                          ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    Image.asset(
                                                      'assets/icons/icons-click-here.png',
                                                      width: 50,
                                                      height: 50,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      S.of(context)!.flashcardTapToFlip,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                              ))
                                        : (widget.startingPoint
                                              ? Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      word,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineMedium
                                                          ?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 40,
                                                            fontFamily: 'Lobster',
                                                          ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    Image.asset(
                                                      'assets/icons/icons-click-here.png',
                                                      width: 50,
                                                      height: 50,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      S.of(context)!.flashcardTapToFlip,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                              )
                                            : _buildVideoPlayer(videoUrl)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // === Static buttons (no slide) ===
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _markWordAsMastered,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentStatus == 'mastered'
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: Text(
                                S.of(context)!.flashcardMastered,
                                style: const TextStyle(height: 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          if (subtitle.isNotEmpty)
                            const SizedBox(width: 12)
                          else
                            const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showReviewOptions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentStatus == 'review'
                                    ? Colors.orange
                                    : Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                S.of(context)!.flashcardToReview,
                                style: const TextStyle(height: 1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVideoPlayer(String url) {
    if (url.isEmpty) {
      return Center(
        child: Text(
          S.of(context)!.noVideo,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: 0.6,
              child: Container(
                color: Colors.grey.shade300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.white70,
                      ),
                                                    const SizedBox(height: 20),
                      Image.asset(
                        'assets/icons/icons-click-here.png',
                        width: 70,
                        height: 70,
                      ),
                    ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    // Use available space - fill the card container
    return Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Positioned.fill(
              child: _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
            ),
          ),
        ),
        Positioned(
              left: 0,
              right: 0,
          bottom: 12,
          child: _InlineVideoControls(
            controller: _videoController!,
            isPlaying: _videoController!.value.isPlaying,
            currentSpeed: _currentSpeed,
            onTogglePlayPause: () {
              if (!mounted) return;
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
            onSpeedChanged: (newSpeed) {
              if (!mounted) return;
              _videoController!.setPlaybackSpeed(newSpeed);
              setState(() => _currentSpeed = newSpeed);
            },
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            onPressed: _enterFullscreen,
            icon: Icon(
              Icons.fullscreen,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  size: 30,
            ),
          ),
        ),
      ],
        ),
      ),
    );
  }
}

class _InlineVideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isPlaying;
  final double currentSpeed;
  final VoidCallback onTogglePlayPause;
  final Function(double) onSpeedChanged;

  const _InlineVideoControls({
    required this.controller,
    required this.isPlaying,
    required this.currentSpeed,
    required this.onTogglePlayPause,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          // Speed button - left side
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          onPressed: () {
            // Cycle through speeds: 0.5 -> 0.6 -> ... -> 1.0 -> 0.5
            const speeds = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
            final currentIndex = speeds.indexOf(currentSpeed);
            final nextIndex = (currentIndex + 1) % speeds.length;
            onSpeedChanged(speeds[nextIndex]);
          },
            icon: Icon(IconlyLight.timeCircle),
            label: Text('${currentSpeed.toStringAsFixed(1)}x'),
          ),
          // Play/Pause button - right side
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).colorScheme.primary,
              ),
          onPressed: onTogglePlayPause,
            icon: Icon(
              controller.value.isInitialized
                  ? (controller.value.isPlaying ? LineIcons.pause : IconlyLight.play)
                  : IconlyLight.play,
            ),
            label: Text(
              controller.value.isInitialized && controller.value.isPlaying
                  ? S.of(context)!.pause
                  : S.of(context)!.play,
            ),
            ),
          ],
      ),
    );
  }
}
