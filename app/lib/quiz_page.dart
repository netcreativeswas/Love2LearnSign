import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/cache_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'quiz_video_page.dart';
import 'services/share_utils.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class QuizPage extends StatefulWidget {
  final List<DocumentSnapshot>? cachedDocuments;
  final bool reviewedMode;
  final bool speedMode;
  final int questionCount;
  final int timeLimit;
  final bool useMainCategoriesOnly;
  final String?
      category; // null for random, specific category for category mode
  final bool isReviewPass;

  const QuizPage({
    super.key,
    this.cachedDocuments,
    this.reviewedMode = true,
    this.speedMode = false,
    this.questionCount = 10,
    this.timeLimit = 10,
    this.useMainCategoriesOnly = true,
    this.category, // null = random mode, specific category = category mode
    this.isReviewPass = false,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestion = 1;
  int _score = 0;
  int _totalQuestions = 0;

  // Loading state for improved UX
  bool isLoading = false;

  // Store the initial documents for replay/try again
  List<DocumentSnapshot> _initialDocuments = [];

  // Global distractor pool for random mode (fetched once per session)
  List<DocumentSnapshot> _allDocsForDistractors = [];

  late VideoPlayerController _controller;
  VideoPlayerController? _nextController;
  String? _nextVideoUrl;
  double _currentSpeed = 1.0;
  final List<double> _speeds = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

  String questionText = "";
  String videoUrl = '';
  List<String> options = [];
  String correctAnswer = '';
  int? selectedIndex;
  bool answered = false;
  bool isCorrect = false;
  bool loading = true;

  // Review queue for incorrect answers
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _reviewQueue = [];
  bool _isReviewPass = false;
  bool _isDisposed = false;
  bool _isTransitioning = false;
  
  // Audio players for sounds
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _pageTurnPlayer = AudioPlayer();
  final AudioPlayer _levelUpPlayer = AudioPlayer();

  // Quiz documents for the session
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _quizDocuments = [];

  // All docs for the selected main category (used for in-category distractors in category mode)
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _categoryDocs = [];

  @override
  void initState() {
    super.initState();
    if (widget.cachedDocuments != null) {
      _quizDocuments = widget.cachedDocuments!
          .cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadQuizQuestion();
    });
    // Warm up distractor pool only for random mode
    if (widget.category == null) {
      unawaited(_warmupDistractorPool());
    }
    // Précharger les sons pour éviter le retard
    _preloadSounds();
  }

  Future<void> _preloadSounds() async {
    try {
      // Configurer pour latence minimale et volume à 1.0
      await _successPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _successPlayer.setVolume(1.0);
      await _errorPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _errorPlayer.setVolume(1.0);
      await _pageTurnPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _pageTurnPlayer.setVolume(1.0);
      await _levelUpPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _levelUpPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Error preloading sounds: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    questionText = S.of(context)!.questionPrompt;
  }

  /// Check if we're in random mode
  bool get _isRandomMode => widget.category == null;

  /// Fetch a "random slice" of documents from Firestore using a random docId cursor.
  /// We order by documentId, start at a random string cursor, take [desired] * 3 docs,
  /// and if not enough, wrap-around from the beginning.
  Future<List<DocumentSnapshot>> _getServerRandomSlice(int desired) async {
    final int want = desired.clamp(1, 50);
    // random base36-ish cursor to stratify across IDs
    String _randomCursor() {
      final rand = Random();
      const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
      return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    }

    final String cursor = _randomCursor();
    final col =
        FirebaseFirestore.instance.collection('bangla_dictionary_eng_bnsl');

    final first = await col
        .orderBy(FieldPath.documentId)
        .startAt([cursor])
        .limit(want * 3)
        .get();

    List<DocumentSnapshot> combined = List.of(first.docs);

    if (combined.length < want * 2) {
      final wrap = await col
          .orderBy(FieldPath.documentId)
          .limit((want * 3) - combined.length)
          .get();
      combined.addAll(wrap.docs);
    }

    combined.shuffle();
    return combined;
  }

  /// Warm up a large pool of documents to use as distractors (answers) so the options feel more random.
  /// This runs once in the background and does not block gameplay.
  Future<void> _warmupDistractorPool() async {
    try {
      if (_allDocsForDistractors.isNotEmpty) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('bangla_dictionary_eng_bnsl')
          .limit(500)
          .get();
      final docs = snapshot.docs.where((d) {
        final url = _extractVideoUrl(d);
        return url.isNotEmpty;
      }).toList();
      docs.shuffle();
      _allDocsForDistractors = docs;
    } catch (e, st) {
      debugPrint('⚠️ Distractor warmup failed: $e\n$st');
    }
  }

  // --- Option building helpers (ensure at least 2 options even in review pass) ---
  String _getWord(DocumentSnapshot d, bool isBn) {
    try {
      return isBn
          ? (d.get('bengali') as String? ?? '')
          : (d.get('english') as String? ?? '');
    } catch (_) {
      return '';
    }
  }

  /// Builds a shuffled list of options containing the correct answer and up to 3 incorrect ones.
  /// Guarantees at least 2 options by sampling from both the current session list and the
  /// initial session list when needed (e.g., single-item review pass).
  List<String> _buildOptions(DocumentSnapshot correctDoc, bool isBn) {
    // Different strategies based on mode
    if (_isRandomMode) {
      // Random mode: Use global distractor pool for more variety
      final Set<DocumentSnapshot> basePool = {
        ..._quizDocuments,
        ..._initialDocuments,
        ..._allDocsForDistractors,
      }..remove(correctDoc);

      // Map to words and filter empties
      final List<String> distractors = basePool
          .map((d) => _getWord(d, isBn).trim())
          .where((w) => w.isNotEmpty)
          .toSet() // unique
          .toList();

      distractors.shuffle();

      // Take up to 3 distractors
      final List<String> picked = distractors.take(3).toList();

      // Compose options with the correct answer and dedupe
      final List<String> options = <String>{
        _getWord(correctDoc, isBn).trim(),
        ...picked,
      }.where((w) => w.isNotEmpty).toList();

      // Ensure at least 2 options (edge case: only one valid word available)
      if (options.length < 2) {
        // Try to find any additional word different from the correct answer
        final String correct = _getWord(correctDoc, isBn).trim();
        final String? extra = distractors.firstWhere(
          (w) => w != correct,
          orElse: () => '',
        );
        if (extra != null && extra.isNotEmpty) {
          options.add(extra);
        }
      }

      options.shuffle();
      return options;
    } else {
      // Category mode: Use same-category documents for distractors
      List<QueryDocumentSnapshot<Map<String, dynamic>>> pool =
          _categoryDocs.isNotEmpty
              ? List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  _categoryDocs)
              : List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  _quizDocuments);
      pool.removeWhere((doc) => doc.id == correctDoc.id);
      pool.shuffle();

      final incorrectDocs = pool.take(3).toList();

          // Determine which field to use based on current locale
    final bool isBn = Localizations.localeOf(context).languageCode == 'bn';
    final data = correctDoc.data() as Map<String, dynamic>;
    // Fetch correct word in appropriate language
      final correctWord =
          isBn ? (data['bengali'] as String) : (data['english'] as String);
    final variants = (data['variants'] as List<dynamic>?) ?? [];
      final correctVideo =
          variants.isNotEmpty ? (variants[0]['videoUrl'] as String) : '';
      // Fetch incorrect options similarly
      final allOptions = [
        correctWord,
        ...incorrectDocs.map((e) => isBn
            ? (e.data()['bengali'] as String)
            : (e.data()['english'] as String))
      ]..shuffle();

      videoUrl = correctVideo;
      correctAnswer = correctWord;
      return List<String>.from(allOptions);
    }
  }

  // --- End helpers ---

  // --- Helpers for robust video handling ---
  String _extractVideoUrl(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? const {};
      final variants = (data['variants'] as List<dynamic>?) ?? const [];
      if (variants.isEmpty) return '';
      final first = variants.first;
      if (first is Map<String, dynamic>) {
        return (first['videoUrl'] as String? ?? '').trim();
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> _isReachable(String url) async {
    if (url.isEmpty) return false;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);
      final req = await client.headUrl(Uri.parse(url));
      final res = await req.close();
      await res.drain();
      client.close();
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
  // --- End helpers ---

  Future<void> loadQuizQuestion() async {
    // Prevent loading if disposed or already loading
    if (_isDisposed || !mounted) return;
    
    setState(() {
      loading = true;
      answered = false;
      selectedIndex = null;
    });

    // 1) Build the session list up front (and filter out broken/empty videos)
    if (_quizDocuments.isEmpty) {
      if (_isRandomMode) {
        // Random mode: Fetch a server-randomized slice for better variety across runs.
        final serverSlice = await _getServerRandomSlice(widget.questionCount);
        final filtered = serverSlice.where((d) {
          final url = _extractVideoUrl(d);
          return url.isNotEmpty;
        }).toList();

        if (filtered.isEmpty) {
          setState(() {
            questionText = S.of(context)!.notEnoughWords;
            loading = false;
            options = const [];
            correctAnswer = '';
            videoUrl = '';
          });
          return;
        }

        final take = widget.questionCount.clamp(1, filtered.length);
        _initialDocuments = filtered.take(take).toList();
        _quizDocuments = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            _initialDocuments.map(
                (doc) => doc as QueryDocumentSnapshot<Map<String, dynamic>>));

        // Start warming up the distractor pool without blocking UI
        unawaited(_warmupDistractorPool());
      } else {
        // Category mode: Fetch documents for the specific category
        Query<Map<String, dynamic>> q = FirebaseFirestore.instance
            .collection('bangla_dictionary_eng_bnsl')
            .where('category_main', isEqualTo: widget.category);

        final catSnapshot = await q.get();

        debugPrint('Category (main): ${widget.category}');
        debugPrint(
            'Total documents in main category: ${catSnapshot.docs.length}');

        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            catSnapshot.docs)
          ..shuffle();

        if (docs.isEmpty) {
          setState(() {
            questionText = S.of(context)!.noResults;
            videoUrl = '';
            options = [];
            correctAnswer = '';
            loading = false;
          });
          return;
        }

        _categoryDocs =
            docs; // keep the entire category for in-category distractors
        _totalQuestions = docs.length < widget.questionCount
            ? docs.length
            : widget.questionCount;
        _quizDocuments = docs.take(_totalQuestions).toList();
      }
    } else {
      // If we start with cached docs, keep only items with a non-empty URL
      final filtered = _quizDocuments.where((d) {
        final url = _extractVideoUrl(d);
        return url.isNotEmpty;
      }).toList();
      _quizDocuments = filtered;
      if (_initialDocuments.isEmpty) {
        _initialDocuments = List<DocumentSnapshot>.from(_quizDocuments);
      }
      if (_quizDocuments.isEmpty) {
        setState(() {
          questionText = S.of(context)!.notEnoughWords;
          loading = false;
        });
        return;
      }
      // Set total questions for category mode
      if (!_isRandomMode && _totalQuestions == 0) {
        _totalQuestions = _quizDocuments.length;
      }
    }

    if (_currentQuestion - 1 >= _quizDocuments.length) {
      _handleEndOfRound();
      return;
    }

    // 2) Prepare current question
    final correctDoc = _quizDocuments[_currentQuestion - 1];
    final url = _extractVideoUrl(correctDoc);
    if (url.isEmpty) {
      // Skip bad item
      debugPrint('⚠️ Empty/bad videoUrl, skipping.');
      setState(() => loading = false);
      nextQuestion();
      return;
    }

    // Locale-aware answer/options (guarantee at least two choices even in single-item review pass)
    final bool isBn = Localizations.localeOf(context).languageCode == 'bn';
    final String correctWord = _getWord(correctDoc, isBn);

    final List<String> built = _buildOptions(correctDoc, isBn);
    if (built.length < 2) {
      // As an extreme fallback, skip only if we truly cannot build 2 options (should be very rare)
      debugPrint('⚠️ Not enough options after fallback; skipping question.');
      nextQuestion();
      return;
    }

    videoUrl = url;
    correctAnswer = correctWord;
    options = built;

    // Set localized question text
    questionText = S.of(context)!.questionPrompt;

    // Prevent initializing video player if URL or options are missing
    if (videoUrl.isEmpty || options.isEmpty) {
      setState(() {
        loading = false;
      });
      return;
    }

    // Try to reuse pre-initialized next controller if URL matches
    bool controllerReused = false;
    if (_nextController != null && _nextVideoUrl == videoUrl && !_isDisposed) {
      try {
        _controller = _nextController!;
        _nextController = null;
        _nextVideoUrl = null;
        // Ensure baseline state
        if (!_isDisposed && mounted) {
          _controller.setLooping(true);
          await _controller.seekTo(Duration.zero);
          await _controller.play(); // Start playback automatically
          controllerReused = true;
        }
      } catch (e) {
        debugPrint('⚠️ Error reusing next controller: $e');
        // Fall through to normal initialization
        try {
          await _controller.dispose();
        } catch (_) {}
        _nextController = null;
        _nextVideoUrl = null;
      }
    }
    
    // Normal initialization if pre-init failed or not available
    if (!controllerReused) {
      // Dispose any remaining next controller
      try {
        await _nextController?.dispose();
      } catch (_) {}
      _nextController = null;
      _nextVideoUrl = null;
      
      // Stronger caching: obey Wi‑Fi-only and fetch via cache manager when allowed
      final cachedFile = await CacheService.instance.getFromCacheOnly(videoUrl);
      if (cachedFile != null) {
        _controller = VideoPlayerController.file(cachedFile);
      } else {
        final file = await CacheService.instance
            .getSingleFileRespectingSettings(videoUrl);
        _controller = file != null
            ? VideoPlayerController.file(file)
            : VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      await _controller.initialize();
      _controller.setLooping(true);
      await _controller.seekTo(Duration.zero);
    }
    if (!mounted || _isDisposed) return;
    _controller.play();
    debugPrint('✅ UI ready for Q$_currentQuestion – showing video');

    // Pre-cache upcoming videos (after current)
    final prefs = await SharedPreferences.getInstance();
    final shouldPrecache = prefs.getBool('precacheEnabled') ?? true;
    final wifiOnly = prefs.getBool('wifiOnly') ?? false;
    final connectivity = await Connectivity().checkConnectivity();
    if (shouldPrecache &&
        (!wifiOnly || connectivity == ConnectivityResult.wifi)) {
      final start = _currentQuestion; // next question index
      debugPrint(
          '🚀 Background precache started (${_quizDocuments.length - start} items)');
      int yielded = 0;
      for (int i = start; i < _quizDocuments.length; i++) {
        if (!mounted || _isDisposed) break;
        final v =
            (_quizDocuments[i].data()['variants'] as List<dynamic>?) ?? [];
        if (v.isEmpty) continue;
        final url = v[0]['videoUrl'] as String?;
        if (url == null || url.isEmpty) continue;
        try {
          final fileInfo = await CacheService.instance.getFromCacheOnly(url);
          if (fileInfo == null) {
            debugPrint('⬇️ Caching: $url');
            await CacheService.instance.getSingleFileRespectingSettings(url);
            debugPrint('✅ Cached: $url');
          } else {
            debugPrint('✅ Already cached: $url');
          }
        } catch (e) {
          debugPrint('⚠️ Precache failed for $url – $e');
        }
        yielded++;
        if (yielded % 2 == 0) {
          // Yield to UI every couple of files so the spinner/buttons stay responsive
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    }

    setState(() {
      loading = false;
    });

    // Pre-initialize the next controller in the background for seamless transition
    unawaited(_preinitNextController());
  }

  Future<void> _preinitNextController() async {
    try {
      final nextIndex = _currentQuestion; // next question index
      if (nextIndex >= _quizDocuments.length) return;
      final nextDoc = _quizDocuments[nextIndex];
      final nextUrl = _extractVideoUrl(nextDoc);
      if (nextUrl.isEmpty) return;

      // Skip if already prepared for same URL
      if (_nextController != null && _nextVideoUrl == nextUrl) return;

      // Dispose any previous pre-initialized controller
      try {
        await _nextController?.dispose();
      } catch (_) {}
      _nextController = null;
      _nextVideoUrl = null;

      final cachedFile = await CacheService.instance.getFromCacheOnly(nextUrl);
      final file = cachedFile ??
          await CacheService.instance.getSingleFileRespectingSettings(nextUrl);
      final ctrl = file != null
          ? VideoPlayerController.file(file)
          : VideoPlayerController.networkUrl(Uri.parse(nextUrl));
      await ctrl.initialize();
      ctrl.setLooping(true);
      await ctrl.seekTo(Duration.zero);
      if (_isDisposed) {
        try {
          await ctrl.dispose();
        } catch (_) {}
        return;
      }
      _nextController = ctrl;
      _nextVideoUrl = nextUrl;
    } catch (_) {
      // best-effort only
    }
  }

  void _handleEndOfRound() {
    // If we just finished the initial pass and review mode is enabled,
    // replay only the questions that were answered incorrectly.
    if (!_isReviewPass && widget.reviewedMode && _reviewQueue.isNotEmpty) {
      setState(() {
        _quizDocuments = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            _reviewQueue);
        _reviewQueue.clear();
        _currentQuestion = 1;
        _isReviewPass = true;
        // prepare UI state for next load
        loading = true;
        answered = false;
        selectedIndex = null;
      });
      loadQuizQuestion();
    } else {
      // Otherwise, finish the quiz and navigate to results
      // Jouer le son level-up si bon score (>= 70%)
      final maxQuestions = _initialDocuments.isNotEmpty
          ? _initialDocuments.length
          : (_totalQuestions > 0 ? _totalQuestions : widget.questionCount);
      final percentage = maxQuestions > 0 ? (_score / maxQuestions) * 100 : 0;
      if (percentage >= 70) {
        _levelUpPlayer.play(AssetSource('sounds/level-up.mp3'));
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizResultScreen(
              score: _score,
              maxQuestions: maxQuestions,
              quizDocuments: _initialDocuments.isNotEmpty
                  ? _initialDocuments
                  : _quizDocuments,
              reviewedMode: widget.reviewedMode,
              speedMode: widget.speedMode,
              timeLimit: widget.timeLimit,
              isRandomMode: _isRandomMode,
              category: widget.category,
            ),
          ),
        );
      });
    }
  }

  void checkAnswer() {
    if (selectedIndex != null) {
      final bool correct = options[selectedIndex!] == correctAnswer;
      
      // Jouer le son IMMÉDIATEMENT (avant setState pour éviter le retard)
      if (correct) {
        _successPlayer.play(AssetSource('sounds/goodresult.mp3'));
      } else {
        _errorPlayer.play(AssetSource('sounds/windows-error-sound.mp3'));
      }
      
      setState(() {
        answered = true;
        isCorrect = correct;
        // Only count points in the initial pass
        if (isCorrect && !_isReviewPass) {
          _score++;
        }
        // In reviewed mode, queue incorrect questions
        if (widget.reviewedMode && !isCorrect) {
          _reviewQueue.add(_quizDocuments[_currentQuestion - 1]);
        }
      });

      // UX: when user presses Submit, replay the current video automatically
      // (so they immediately see the sign again along with the result).
      unawaited(() async {
        if (!mounted || _isDisposed) return;
        try {
          if (_controller.value.isInitialized) {
            await _controller.seekTo(Duration.zero);
            await _controller.play();
          }
        } catch (_) {
          // best-effort only
        }
      }());

      // Automatically go to next question if correct after a short delay
      if (isCorrect) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && answered && isCorrect && !_isTransitioning) {
            nextQuestion();
          }
        });
      }
    }
  }

  void nextQuestion() {
    // Prevent multiple simultaneous transitions
    if (_isTransitioning || _isDisposed || !mounted) return;
    _isTransitioning = true;
    
    // Jouer le son de transition entre questions
    _pageTurnPlayer.play(AssetSource('sounds/page-turn.mp3'));
    
    // Put UI into a safe loading state immediately to avoid building with a disposed controller
    if (mounted) {
      setState(() {
        loading = true;
        answered = false;
        selectedIndex = null;
      });
    }

    // Dispose current controller safely
    try {
      if (_controller.value.isInitialized) {
        _controller.pause();
      }
      _controller.dispose();
    } catch (_) {
      // Controller might already be disposed
    }

    // Determine if we are in initial or review pass and if more questions remain
    final int maxInitial =
        _isRandomMode ? widget.questionCount : _totalQuestions;
    final int maxReview = _quizDocuments.length;

    if ((!_isReviewPass && _currentQuestion < maxInitial) ||
        (_isReviewPass && _currentQuestion < maxReview)) {
      if (mounted) {
        setState(() => _currentQuestion++);
      }
      // Reset flag before loading next question
      _isTransitioning = false;
      loadQuizQuestion();
    } else {
      _isTransitioning = false;
      _handleEndOfRound();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _successPlayer.dispose();
    _errorPlayer.dispose();
    _pageTurnPlayer.dispose();
    _levelUpPlayer.dispose();
    try {
      _controller.dispose();
    } catch (_) {}
    try {
      _nextController?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show specific copy for the very first load vs subsequent loads
    if (isLoading || loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                (_currentQuestion <= 1 && options.isEmpty)
                    ? S.of(context)!.loadingQuizPleaseWait
                    : S.of(context)!.loadingNextQuestion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final int displayMaxQuestions = _isReviewPass
        ? max(1, _quizDocuments.length)
        : (_isRandomMode ? widget.questionCount : _totalQuestions);

    return QuizVideoPage(
      title: _isRandomMode
          ? S.of(context)!.randomWordsQuiz
          : S
              .of(context)!
              .quizTitleDynamic(translateCategory(context, widget.category!)),
      currentQuestion: _currentQuestion,
      maxQuestions: displayMaxQuestions,
      score: _score,
      questionText: questionText,
      controller: _controller,
      currentSpeed: _currentSpeed,
      speeds: _speeds,
      options: options,
      correctAnswer: correctAnswer,
      selectedIndex: selectedIndex,
      answered: answered,
      isCorrect: isCorrect,
      checkAnswer: checkAnswer,
      nextQuestion: nextQuestion,
      selectAnswer: (index) => setState(() => selectedIndex = index),
      changeSpeed: () {
        setState(() {
          final currentIndex = _speeds.indexOf(_currentSpeed);
          final nextIndex = (currentIndex + 1) % _speeds.length;
          _currentSpeed = _speeds[nextIndex];
          _controller.setPlaybackSpeed(_currentSpeed);
        });
      },
      togglePlayPause: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      reviewedMode: widget.reviewedMode,
      isReviewPass: _isReviewPass,
      speedMode: widget.speedMode,
      timeLimit: widget.timeLimit,
      onTimeExpired: () {
        // Treat as a wrong answer and advance. Also queue for review if applicable.
        if (!mounted) return;
        if (answered) return; // already handled
        setState(() {
          answered = true;
          isCorrect = false;
          // Do not change score here; only increment happens on correct in initial pass
        });
        // If we're in the initial pass and reviewed mode is enabled, queue the question
        if (widget.reviewedMode && !_isReviewPass) {
          try {
            _reviewQueue.add(_quizDocuments[_currentQuestion - 1]);
          } catch (_) {
            // safe-guard
          }
        }
        // Do not auto-advance; UI will show feedback and a Next button
      },
      // Only show Next button if answered and not correct
      showNextButton: answered == true && isCorrect == false,
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int maxQuestions;
  final List<DocumentSnapshot> quizDocuments;
  final bool reviewedMode;
  final bool speedMode;
  final int timeLimit;
  final bool isRandomMode;
  final String? category;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.maxQuestions,
    required this.quizDocuments,
    required this.reviewedMode,
    required this.speedMode,
    required this.timeLimit,
    required this.isRandomMode,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final double passRatio = score / maxQuestions;
    final bool passed = passRatio >= 0.75;
    final int percentage = ((score / maxQuestions) * 100).toInt();
    String lottieAsset;
    String message;
    if (percentage <= 20) {
      lottieAsset = 'assets/1749221648708-smiley Level 1.json';
      message = S.of(context)!.quizMessageLevel1;
    } else if (percentage <= 40) {
      lottieAsset = 'assets/1749223022410-smiley Level 2.json';
      message = S.of(context)!.quizMessageLevel2;
    } else if (percentage <= 60) {
      lottieAsset = 'assets/1749221436432-smiley Level 3.json';
      message = S.of(context)!.quizMessageLevel3;
    } else if (percentage <= 80) {
      lottieAsset = 'assets/1749222529915-smiley Level 4.json';
      message = S.of(context)!.quizMessageLevel4;
    } else {
      lottieAsset = 'assets/1748970298316-smiley Level 5.json';
      message = S.of(context)!.quizMessageLevel5;
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(
            S.of(context)!.quizCompleted,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.normal),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              lottieAsset,
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${((score / maxQuestions) * 100).toStringAsFixed(0)} %',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => QuizPage(
                          cachedDocuments:
                              List<DocumentSnapshot>.from(quizDocuments),
                          // Use the original selection count to replay full quiz from the beginning
                          questionCount: maxQuestions,
                          reviewedMode: reviewedMode,
                          speedMode: speedMode,
                          timeLimit: timeLimit,
                          category: category,
                          isReviewPass: false,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    S.of(context)!.tryAgain,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/main',
                      (route) => false,
                      arguments: {'initialIndex': 2, 'openQuizOptions': true},
                    );
                  },
                  child: Text(
                    S.of(context)!.backToGamePage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/icons/whatsapp.png',
                        width: 32, height: 32),
                    onPressed: () {
                      final shareText =
                          S.of(context)!.shareText(score, maxQuestions);
                      debugPrint('📤 Share tapped: WhatsApp');
                      unawaited(shareOnWhatsApp(shareText));
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.share,
                        size: 30, color: Theme.of(context).colorScheme.primary),
                    onPressed: () {
                      final shareText =
                          S.of(context)!.shareText(score, maxQuestions);
                      debugPrint('📤 Share tapped: universal share');
                      SharePlus.instance
                          .share(ShareParams(text: shareText));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
