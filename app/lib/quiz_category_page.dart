import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:l2l_shared/tenancy/concept_text.dart';
import 'package:l2l_shared/tenancy/concept_media.dart';
import 'package:video_player/video_player.dart';
import 'services/cache_service.dart';
import 'services/prefetch_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'quiz_video_page.dart';
import 'l10n/dynamic_l10n.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
// Removed FontAwesome import, switching to asset icons.
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'tenancy/tenant_scope.dart';

class QuizCategoryPage extends StatefulWidget {
  final bool useMainCategoriesOnly;
  final String category;
  final bool reviewedMode;
  final bool isReviewPass;
  final bool speedMode;
  final int questionCount;
  final int timeLimit;
  const QuizCategoryPage({
    super.key,
    required this.category,
    this.reviewedMode = false,
    this.isReviewPass = false,
    this.speedMode = false,
    this.questionCount = 10,
    this.timeLimit = 10,
    this.useMainCategoriesOnly = true,
  });

  @override
  State<QuizCategoryPage> createState() => _QuizCategoryPageState();
}

class _QuizCategoryPageState extends State<QuizCategoryPage> {
  // Removed local cache manager in favor of CacheService
  int _currentQuestion = 1;
  int _score = 0;
  int _totalQuestions = 0;

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
  // --- review-queue fields ---
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _reviewQueue = [];
  bool _isReviewPass = false;
  bool _isDisposed = false;
  bool _isTransitioning = false;



  @override
  void initState() {
    super.initState();
    loadQuizQuestion();
  }

  // Store quiz documents for category quiz
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _quizDocuments = [];
  // All docs for the selected main category (used for in-category distractors)
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _categoryDocs = [];

  Future<void> loadQuizQuestion() async {
    // Prevent loading if disposed or already loading
    if (_isDisposed || !mounted) return;
    
    setState(() {
      loading = true;
      answered = false;
      selectedIndex = null;
    });

    // If first question, fetch and shuffle docs, else use already fetched docs
    if (!_isReviewPass && (_currentQuestion == 1 || _quizDocuments.isEmpty)) {
      final tenantId = context.read<TenantScope>().tenantId;
      Query<Map<String, dynamic>> q = TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
          .where('category_main', isEqualTo: widget.category);

      // Note: useMainCategoriesOnly signifie qu'on ignore totalement category_sub;
      // ici, on ne rajoute pas de where sur category_sub.
      // Correct questions are drawn from the selected main category only; distractors come from the global pool.

      final catSnapshot = await q.get();

      debugPrint('Category (main): ${widget.category}');
      debugPrint('Total documents in main category: ${catSnapshot.docs.length}');

      final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(catSnapshot.docs)
        ..shuffle();

      if (docs.isEmpty) {
        setState(() {
          questionText = S.of(context)!.noResults; // reuse a close key for now
          videoUrl = '';
          options = [];
          correctAnswer = '';
          loading = false;
        });
        return;
      }

      _categoryDocs = docs; // keep the entire category for in-category distractors
      _totalQuestions = docs.length < widget.questionCount ? docs.length : widget.questionCount;
      _quizDocuments = docs.take(_totalQuestions).toList();
    }

    // Prepare current question
    final correctDoc = _quizDocuments[_currentQuestion - 1];
    // Safety: if we ran out of docs, finish gracefully
    if (_currentQuestion - 1 >= _quizDocuments.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StatefulBuilder(
              builder: (context, setState) {
                final int percentage = ((_score / (_totalQuestions == 0 ? 1 : _totalQuestions)) * 100).toInt();
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
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    iconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(lottieAsset, width: 200, height: 200, repeat: true),
                        const SizedBox(height: 10),
                        Text(message, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 10),
                        Text(
                          '${((percentage).toString())} %',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => QuizCategoryPage(
                                  category: widget.category,
                                  reviewedMode: widget.reviewedMode,
                                  isReviewPass: _isReviewPass,
                                  speedMode: widget.speedMode,
                                  questionCount: widget.questionCount,
                                  timeLimit: widget.timeLimit,
                                  useMainCategoriesOnly: widget.useMainCategoriesOnly,
                                ),
                              ),
                            );
                          },
                          child: Text(S.of(context)!.tryAgain),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Image.asset('assets/icons/whatsapp.png', width: 32, height: 32),
                                onPressed: () {
                                  final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                                  debugPrint('📤 Share tapped: WhatsApp');
                                  unawaited(ShareUtils.shareOnWhatsApp(context, shareText));
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Image.asset('assets/icons/imo.png', width: 32, height: 32),
                                onPressed: () {
                                  final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                                  debugPrint('📤 Share tapped: Imo');
                                  unawaited(ShareUtils.shareOnImo(context, shareText));
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Image.asset('assets/icons/messenger.png', width: 32, height: 32),
                                onPressed: () {
                                  final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                                  debugPrint('📤 Share tapped: Messenger');
                                  unawaited(ShareUtils.shareOnMessenger(context, shareText));
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Image.asset('assets/icons/instagram.png', width: 32, height: 32),
                                onPressed: () {
                                  final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                                  debugPrint('📤 Share tapped: Instagram');
                                  unawaited(ShareUtils.shareOnInstagram(context, shareText));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      });
      return;
    }
    // Pick incorrect options from the SAME CATEGORY (not the whole dictionary)
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pool = _categoryDocs.isNotEmpty
        ? List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(_categoryDocs)
        : List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(_quizDocuments);
    pool.removeWhere((doc) => doc.id == correctDoc.id);
    pool.shuffle();
    final incorrectDocs = pool.take(3).toList();
    final langCode = context.read<TenantScope>().contentLocale;
    final correctWord = ConceptText.labelFor(correctDoc.data(), lang: langCode, fallbackLang: 'en');
    final variants = (correctDoc.data()['variants'] as List<dynamic>?) ?? [];
    final correctVideo = variants.isNotEmpty
        ? ConceptMedia.video480FromVariant(Map<String, dynamic>.from(variants[0] as Map))
        : '';
    // Fetch incorrect options similarly
    final allOptions = [
      correctWord,
      ...incorrectDocs.map((e) => ConceptText.labelFor(e.data(), lang: langCode, fallbackLang: 'en'))
    ]..shuffle();
    videoUrl = correctVideo;
    correctAnswer = correctWord;
    options = List<String>.from(allOptions);

    // Set localized question text
    // Use legacy key via S; we haven't added ARB for quiz yet, reusing a close key is not ideal but safe
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
      
      // Use cache service for better performance
      final cachedFile = await CacheService.instance.getFromCacheOnly(videoUrl);
      if (cachedFile != null) {
        _controller = VideoPlayerController.file(cachedFile);
      } else {
        final file = await CacheService.instance.getSingleFileRespectingSettings(videoUrl);
        _controller = file != null
            ? VideoPlayerController.file(file)
            : VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      await _controller.initialize();
      _controller.setLooping(true);
      await _controller.seekTo(Duration.zero);
      if (!mounted || _isDisposed) return;
      _controller.play();
    }
    debugPrint('✅ UI ready for Q$_currentQuestion – showing video');

    // Pre-cache upcoming videos (after current)
    final prefs = await SharedPreferences.getInstance();
    final shouldPrecache = prefs.getBool('precacheEnabled') ?? true;
    final wifiOnly = prefs.getBool('wifiOnly') ?? false;
    final connectivity = await Connectivity().checkConnectivity();
    if (shouldPrecache && (!wifiOnly || connectivity == ConnectivityResult.wifi)) {
      final start = _currentQuestion; // next question index
      debugPrint('🚀 Background precache started (${_quizDocuments.length - start} items)');
      for (int i = start; i < _quizDocuments.length; i++) {
        if (!mounted || _isDisposed) break;
        final v = (_quizDocuments[i].data()['variants'] as List<dynamic>?) ?? [];
        if (v.isEmpty) continue;
        final url = ConceptMedia.video480FromVariant(Map<String, dynamic>.from(v[0] as Map));
        if (url.isEmpty) continue;
        unawaited(
          PrefetchQueue.instance.enqueue(
            url,
            isCancelled: () => !mounted || _isDisposed,
          ),
        );
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
      final variants = (nextDoc.data()['variants'] as List<dynamic>?) ?? [];
      if (variants.isEmpty) return;
      final nextUrl = ConceptMedia.video480FromVariant(Map<String, dynamic>.from(variants[0] as Map));
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

  Future<void> _preloadQuizVideos(List<String> videoUrls, {String? excludeUrl}) async {
    for (final url in videoUrls) {
      if (url == excludeUrl) continue;
      unawaited(
        PrefetchQueue.instance.enqueue(
          url,
          isCancelled: () => _isDisposed,
        ),
      );
    }
  }

  void checkAnswer() {
    if (selectedIndex != null) {
      setState(() {
        answered = true;
        isCorrect = options[selectedIndex!] == correctAnswer;
        // Only count points in the initial pass
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
    
    // Put UI into a safe loading state immediately
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
    
    final int maxInitial = _totalQuestions;
    final int maxReview = _quizDocuments.length;
    // Advance through initial or review pass
    if ((!_isReviewPass && _currentQuestion < maxInitial) ||
        (_isReviewPass && _currentQuestion < maxReview)) {
      if (mounted) {
        setState(() => _currentQuestion++);
      }
      // Reset flag before loading next question
      _isTransitioning = false;
      loadQuizQuestion();
    }
    // Switch to review pass if needed
    else if (!_isReviewPass && widget.reviewedMode && _reviewQueue.isNotEmpty) {
      if (mounted) {
        setState(() {
          _quizDocuments = List.from(_reviewQueue)..shuffle();
          _reviewQueue.clear();
          _currentQuestion = 1;
          _isReviewPass = true;
        });
      }
      // Reset flag before loading next question
      _isTransitioning = false;
      loadQuizQuestion();
    }
    // Finish quiz
    else {
      _isTransitioning = false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StatefulBuilder(
            builder: (context, setState) {
              final int percentage = ((_score / _totalQuestions) * 100).toInt();
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
                        fontWeight: FontWeight.normal,
                    ),
                  ),
                  iconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(lottieAsset, width: 200, height: 200, repeat: true),
                      const SizedBox(height: 10),
                      Text(message, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 10),
                      Text(
                        '${((percentage).toString())} %',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => QuizCategoryPage(
                                    category: widget.category,
                                    reviewedMode: widget.reviewedMode,
                                    isReviewPass: _isReviewPass,
                                    speedMode: widget.speedMode,
                                    questionCount: widget.questionCount,
                                    timeLimit: widget.timeLimit,
                                    useMainCategoriesOnly: widget.useMainCategoriesOnly,
                                  ),
                                ),
                              );
                            },
                             child: Text(S.of(context)!.tryAgain),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) {
                                  setState(() {
                                    _score = 0;
                                    _currentQuestion = 1;
                                  });
                                  loadQuizQuestion();
                                }
                              });
                            },
                             child: Text(S.of(context)!.backToCategories),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Image.asset('assets/icons/whatsapp.png', width: 32, height: 32),
                            onPressed: () {
                              final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                              debugPrint('📤 Share tapped: WhatsApp');
                              unawaited(ShareUtils.shareOnWhatsApp(context, shareText));
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Image.asset('assets/icons/imo.png', width: 32, height: 32),
                            onPressed: () {
                              final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                              debugPrint('📤 Share tapped: Imo');
                              unawaited(ShareUtils.shareOnImo(context, shareText));
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Image.asset('assets/icons/messenger.png', width: 32, height: 32),
                            onPressed: () {
                              final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                              debugPrint('📤 Share tapped: Messenger');
                              unawaited(ShareUtils.shareOnMessenger(context, shareText));
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Image.asset('assets/icons/instagram.png', width: 32, height: 32),
                            onPressed: () {
                              final String shareText = 'I scored ${percentage}% in the sign language quiz! 🤟 Can you beat me? Download Love to Learn Sign and learn Bangla Sign Language: https://yourapp.link';
                              debugPrint('📤 Share tapped: Instagram');
                              unawaited(ShareUtils.shareOnInstagram(context, shareText));
                            },
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      if (_controller.value.isInitialized) {
        _controller.dispose();
      }
    } catch (_) {}
    try {
      _nextController?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (videoUrl.isEmpty || options.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            S.of(context)!.quizTitleDynamic(widget.category),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: Center(
          child: Text(
            questionText.isNotEmpty
                ? questionText
                : S.of(context)!.notEnoughWords,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final showNextButton = answered == true && isCorrect == false;
    return QuizVideoPage(
      title: S.of(context)!.quizTitleDynamic(translateCategory(context, widget.category)),
      currentQuestion: _currentQuestion,
      maxQuestions: _totalQuestions,
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
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      reviewedMode: widget.reviewedMode,
      isReviewPass: _isReviewPass,
      speedMode: widget.speedMode,
      timeLimit: widget.timeLimit,
      showNextButton: showNextButton,
      onTimeExpired: () {
        if (answered) return; // ignore if already answered
        setState(() {
          answered = true;
          isCorrect = false;
          // Queue for review if enabled
          if (widget.reviewedMode) {
            _reviewQueue.add(_quizDocuments[_currentQuestion - 1]);
          }
        });
        // Advance to next question after a short pause
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          nextQuestion();
        });
      },
    );
  }
}

class ShareUtils {
  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // e.g., PlatformException(ACTIVITY_NOT_FOUND, …)
      return false;
    }
  }

  static Future<void> _fallbackShare(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  static Future<void> shareOnWhatsApp(BuildContext context, String text) async {
    // Try deep link first, then web intent, then share sheet.
    final deep = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    final web  = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await _tryLaunch(deep)) return;
    if (await _tryLaunch(web)) return;
    await _fallbackShare(text);
  }

  static Future<void> shareOnImo(BuildContext context, String text) async {
    final deep = Uri.parse('imo://msg/text/${Uri.encodeComponent(text)}');
    if (await _tryLaunch(deep)) return;
    await _fallbackShare(text);
  }

  static Future<void> shareOnMessenger(BuildContext context, String text) async {
    final deep = Uri.parse('fb-messenger://share?text=${Uri.encodeComponent(text)}');
    if (await _tryLaunch(deep)) return;
    await _fallbackShare(text);
  }

  static Future<void> shareOnInstagram(BuildContext context, String text) async {
    // Instagram doesn't support text-only share via deep links; open app if present, else share sheet.
    final app = Uri.parse('instagram://app');
    if (await _tryLaunch(app)) return;
    await _fallbackShare(text);
  }
}