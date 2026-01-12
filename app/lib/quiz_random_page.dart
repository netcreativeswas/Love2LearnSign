import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:l2l_shared/tenancy/concept_text.dart';
import 'package:l2l_shared/tenancy/concept_media.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'tenancy/tenant_scope.dart';
import 'services/cache_service.dart';
import 'services/prefetch_queue.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'quiz_video_page.dart';
import 'services/share_utils.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

class QuizRandomPage extends StatefulWidget {
  final List<DocumentSnapshot>? cachedDocuments;
  final bool reviewedMode;
  final bool speedMode;
  final int questionCount;
  final int timeLimit;
  final bool useMainCategoriesOnly;
  const QuizRandomPage({
    super.key,
    this.cachedDocuments,
    this.reviewedMode = true,
    this.speedMode = false,
    this.questionCount = 10,
    this.timeLimit = 10,
    this.useMainCategoriesOnly = true,
  });

  @override
  State<QuizRandomPage> createState() => _QuizRandomPageState();
}

class _QuizRandomPageState extends State<QuizRandomPage> {
  int _currentQuestion = 1;
  int _score = 0;
  // Add isLoading for improved UX and background caching
  bool isLoading = false;

  // Store the initial documents for replay/try again
  List<DocumentSnapshot> _initialDocuments = [];

  // Global distractor pool (fetched once per session)
  List<DocumentSnapshot> _allDocsForDistractors = [];

  // Replaced by CacheService

  late VideoPlayerController _controller;
  VideoPlayerController? _nextController;
  String? _nextVideoUrl;
  double _currentSpeed = 1.0;
  final List<double> _speeds = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

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
    final tenantId = context.read<TenantScope>().tenantId;
    final col = TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId);

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
      final tenantId = context.read<TenantScope>().tenantId;
      final snapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
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
  String _getWord(DocumentSnapshot d, String langCode) {
    try {
      final data = d.data() as Map<String, dynamic>? ?? const <String, dynamic>{};
      return ConceptText.labelFor(data, lang: langCode, fallbackLang: 'en');
    } catch (_) {
      return '';
    }
  }

  /// Builds a shuffled list of options containing the correct answer and up to 3 incorrect ones.
  /// Guarantees at least 2 options by sampling from both the current session list and the
  /// initial session list when needed (e.g., single-item review pass).
  List<String> _buildOptions(DocumentSnapshot correctDoc, String langCode) {
    // Primary pool = current quiz docs, initial docs, and global distractor pool minus the correct one
    final Set<DocumentSnapshot> basePool = {
      ..._quizDocuments,
      ..._initialDocuments,
      ..._allDocsForDistractors,
    }..remove(correctDoc);

    // Map to words and filter empties
    final List<String> distractors = basePool
        .map((d) => _getWord(d, langCode).trim())
        .where((w) => w.isNotEmpty)
        .toSet() // unique
        .toList();

    distractors.shuffle();

    // Take up to 3 distractors
    final List<String> picked = distractors.take(3).toList();

    // Compose options with the correct answer and dedupe
    final List<String> options = <String>{
      _getWord(correctDoc, langCode).trim(),
      ...picked,
    }.where((w) => w.isNotEmpty).toList();

    // Ensure at least 2 options (edge case: only one valid word available)
    if (options.length < 2) {
      // Try to find any additional word different from the correct answer
      final String correct = _getWord(correctDoc, langCode).trim();
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
  }
  // --- End helpers ---

  // --- Helpers for robust video handling ---
  String _extractVideoUrl(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? const {};
      return ConceptMedia.video480FromConcept(data);
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

  // --- Background pre-caching control ---
  bool _precachingStarted = false;
  bool _isDisposed = false;
  bool _isTransitioning = false;

  Future<void> _startBackgroundPrecaching() async {
    if (_precachingStarted) return;
    _precachingStarted = true;
    debugPrint(
        '🚀 Background precache started (${_quizDocuments.length} items)');

    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldPrecache = prefs.getBool('precacheEnabled') ?? true;
      final wifiOnly = prefs.getBool('wifiOnly') ?? false;
      final connectivity = await Connectivity().checkConnectivity();
      if (!shouldPrecache ||
          (wifiOnly && connectivity != ConnectivityResult.wifi)) {
        return;
      }

      // Snapshot the session list so UI mutations don't affect this loop
      final docsToCache = List<DocumentSnapshot>.from(_quizDocuments);

      for (final doc in docsToCache) {
        if (_isDisposed) break;
        try {
          final url = _extractVideoUrl(doc);
          if (url.isEmpty) continue;
          unawaited(
            PrefetchQueue.instance.enqueue(
              url,
              isCancelled: () => _isDisposed,
            ),
          );
        } catch (e, st) {
          // Never block the UI; best-effort only
          debugPrint('⚠️ Precache failed: $e\n$st');
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ Precache setup failed: $e\n$st');
    }
  }
  // --- End background pre-caching ---

  void _handleEndOfRound() {
    // If we just finished the initial pass and review mode is enabled,
    // replay only the questions that were answered incorrectly.
    if (!_isReviewPass && widget.reviewedMode && _reviewQueue.isNotEmpty) {
      setState(() {
        _quizDocuments = List<DocumentSnapshot>.from(_reviewQueue);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizResultScreen(
              score: _score,
              maxQuestions: _initialDocuments.isNotEmpty
                  ? _initialDocuments.length
                  : widget.questionCount,
              quizDocuments: _initialDocuments.isNotEmpty
                  ? _initialDocuments
                  : _quizDocuments,
              reviewedMode: widget.reviewedMode,
              speedMode: widget.speedMode,
              timeLimit: widget.timeLimit,
            ),
          ),
        );
      });
    }
  }

  late String questionText;
  String videoUrl = '';
  List<String> options = [];
  String correctAnswer = '';
  int? selectedIndex;
  bool answered = false;
  bool isCorrect = false;
  bool loading = true;
  final List<DocumentSnapshot> _reviewQueue = [];
  bool _isReviewPass = false;

  // Store nextDocs for caching
  List<DocumentSnapshot> nextDocs = [];

  // Store quiz documents for the session
  List<DocumentSnapshot> _quizDocuments = [];

  @override
  void initState() {
    super.initState();
    if (widget.cachedDocuments != null) {
      _quizDocuments = widget.cachedDocuments!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadQuizQuestion();
    });
    unawaited(_warmupDistractorPool());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    questionText = S.of(context)!.questionPrompt;
  }

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
      // Fetch a server-randomized slice for better variety across runs.
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

      // Prefer to avoid very recent repeats across sessions without biasing randomness
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList('recentRandomWordIds') ?? <String>[];
      final recentSet = recent.toSet();

      // Prioritize candidates not in recent, then the rest
      final List<DocumentSnapshot> prioritized = [
        ...filtered.where((d) => !recentSet.contains(d.id)),
        ...filtered.where((d) => recentSet.contains(d.id)),
      ];

      // Pick only reachable videos with a short timeout to avoid stalls
      final int take = widget.questionCount.clamp(1, prioritized.length);
      final List<DocumentSnapshot> selected = [];
      for (final d in prioritized) {
        if (selected.length >= take) break;
        final url = _extractVideoUrl(d);
        if (url.isEmpty) continue;
        bool ok = false;
        try {
          ok = await _isReachable(url)
              .timeout(const Duration(seconds: 2), onTimeout: () => false);
        } catch (_) {
          ok = false;
        }
        if (ok) selected.add(d);
      }

      // Fallback: if not enough reachable, top-up from the remaining pool to preserve session size
      if (selected.length < take) {
        for (final d in prioritized) {
          if (selected.length >= take) break;
          if (!selected.contains(d)) selected.add(d);
        }
      }

      _initialDocuments = selected.take(take).toList();
      _quizDocuments = List<DocumentSnapshot>.from(_initialDocuments);

      // Persist recent ids (ring buffer of last 50)
      final List<String> updatedRecent = [
        ..._initialDocuments.map((d) => d.id),
        ...recent,
      ];
      final deduped = <String>{};
      final List<String> finalRecent = [];
      for (final id in updatedRecent) {
        if (deduped.add(id)) finalRecent.add(id);
        if (finalRecent.length >= 50) break;
      }
      await prefs.setStringList('recentRandomWordIds', finalRecent);

      // Warm the first few items in the background (non-blocking)
      final int warmCount =
          _initialDocuments.length < 4 ? _initialDocuments.length : 4;
      unawaited(() async {
        for (int i = 0; i < warmCount; i++) {
          final v =
              (_initialDocuments[i].get('variants') as List<dynamic>?) ?? [];
          if (v.isEmpty) continue;
          final u = v.first is Map ? ConceptMedia.video480FromVariant(Map<String, dynamic>.from(v.first as Map)) : '';
          if (u.isEmpty) continue;
          try {
            await CacheService.instance.getSingleFileRespectingSettings(u);
          } catch (_) {
            // best-effort
          }
        }
      }());

      // Start warming up the distractor pool without blocking UI
      unawaited(_warmupDistractorPool());
    } else {
      // If we start with cached docs, keep only items with a non-empty URL; skip network reachability checks.
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
    final String langCode = context.read<TenantScope>().contentLocale;
    final String correctWord = _getWord(correctDoc, langCode);

    final List<String> built = _buildOptions(correctDoc, langCode);
    if (built.length < 2) {
      // As an extreme fallback, skip only if we truly cannot build 2 options (should be very rare)
      debugPrint('⚠️ Not enough options after fallback; skipping question.');
      nextQuestion();
      return;
    }

    videoUrl = url;
    correctAnswer = correctWord;
    options = built;

    // 3) Initialize the player robustly
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
          _controller.play(); // Start playback automatically
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
        final file =
            await CacheService.instance.getSingleFileRespectingSettings(videoUrl);
        _controller = file != null
            ? VideoPlayerController.file(file)
            : VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      try {
        // Guard against hanging initializes on bad/unreachable URLs
        await _controller.initialize().timeout(const Duration(seconds: 6));
        _controller.setLooping(true);
        await _controller.seekTo(Duration.zero);
        _controller.play();
      } on TimeoutException catch (_) {
        debugPrint('⏱️ Video init timed out, skipping this question');
        try {
          await _controller.dispose();
        } catch (_) {}
        nextQuestion();
        return;
      } catch (e, st) {
        debugPrint('🎥 Video init failed, skipping this question: $e\n$st');
        try {
          await _controller.dispose();
        } catch (_) {}
        nextQuestion();
        return;
      }
    }
    debugPrint('✅ UI ready for Q$_currentQuestion – showing video');

    // Make UI ready immediately
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
    // Fire-and-forget pre-caching so it never blocks question changes
    unawaited(_startBackgroundPrecaching());
    // Also pre-initialize next controller for seamless transition
    unawaited(_preinitNextController());
  }

  Future<void> _preinitNextController() async {
    try {
      final nextIndex = _currentQuestion; // next question index
      if (nextIndex >= _quizDocuments.length) return;
      final nextDoc = _quizDocuments[nextIndex];
      final nextUrl = _extractVideoUrl(nextDoc);
      if (nextUrl.isEmpty) return;

      if (_nextController != null && _nextVideoUrl == nextUrl) return;

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
      // Avoid hanging pre-inits on bad URLs
      await ctrl.initialize().timeout(const Duration(seconds: 6));
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

  void onTimeExpired() {
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
  }

  void checkAnswer() {
    if (selectedIndex != null) {
      setState(() {
        answered = true;
        isCorrect = options[selectedIndex!] == correctAnswer;
        // Only count score in the initial pass
        if (isCorrect && !_isReviewPass) {
          _score++;
        }
        // In reviewed mode, queue incorrect questions
        if (widget.reviewedMode && !isCorrect) {
          _reviewQueue.add(_quizDocuments[_currentQuestion - 1]);
        }
      });

      // UX: when user presses Submit, replay the current video automatically.
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

      // If correct, auto-advance after a short delay
      if (isCorrect) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted && !_isTransitioning) {
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
    final int maxInitial = widget.questionCount;
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

    final int displayMaxQuestions =
        _isReviewPass ? max(1, _quizDocuments.length) : widget.questionCount;

    return QuizVideoPage(
      title: S.of(context)!.randomWordsQuiz,
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
      onTimeExpired: onTimeExpired,
      // Only show Next button if answered and not correct
      showNextButton: answered == true && isCorrect == false,
    );
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int total = 0;
    if (await dir.exists()) {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }
    return total;
  }
}

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int maxQuestions;
  final List<DocumentSnapshot> quizDocuments;
  final bool reviewedMode;
  final bool speedMode;
  final int timeLimit;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.maxQuestions,
    required this.quizDocuments,
    required this.reviewedMode,
    required this.speedMode,
    required this.timeLimit,
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
                        builder: (_) => QuizRandomPage(
                          cachedDocuments:
                              List<DocumentSnapshot>.from(quizDocuments),
                          // Use the original selection count to replay full quiz from the beginning
                          questionCount: maxQuestions,
                          reviewedMode: reviewedMode,
                          speedMode: speedMode,
                          timeLimit: timeLimit,
                          // keep default settings; do not force review-only behavior
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
                      SharePlus.instance.share(ShareParams(text: shareText));
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
