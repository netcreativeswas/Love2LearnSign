
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l2l_shared/tenancy/concept_media.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:love_to_learn_sign/home_page.dart';
import 'package:love_to_learn_sign/l10n/app_localizations.dart';

String _redactUrlForLogs(String url) {
  final raw = url.trim();
  if (raw.isEmpty) return raw;
  try {
    final uri = Uri.parse(raw);
    // Remove query params + fragments to avoid leaking tokens.
    return uri.replace(query: '', fragment: '').toString();
  } catch (_) {
    return raw;
  }
}

void _dlog(String message) {
  if (kDebugMode) debugPrint(message);
}

class OnboardingVideoScreen extends StatefulWidget {
  const OnboardingVideoScreen({super.key});

  @override
  State<OnboardingVideoScreen> createState() => _OnboardingVideoScreenState();
}

class _OnboardingVideoScreenState extends State<OnboardingVideoScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;
  final ScrollController _textScrollController = ScrollController();
  late final bool _preferBengaliIntro;

  // Guards & UX timing
  bool _navigated = false;                  // prevent double navigation
  bool _videoHasStarted = false;            // avoid mis-detecting "end" before start
  late final DateTime _enteredAt;
  static const Duration _minShow = Duration(seconds: 4); // minimal visible time

  @override
  void initState() {
    super.initState();
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    _preferBengaliIntro = deviceLocale.languageCode.toLowerCase() == 'bn';
    _enteredAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _init();
  }

  Future<void> _init() async {
    try {
      // 1) Read Firestore doc meta/intro
      _dlog('🔍 Onboarding: Reading Firestore meta/intro document...');
      final doc = await FirebaseFirestore.instance
          .collection('meta')
          .doc('intro')
          .get();
      final data = doc.data() ?? {};
      final enabled = (data['enabled'] as bool?) ?? true;
      String url = ConceptMedia.video480FromConcept(Map<String, dynamic>.from(data));
      
      _dlog('🔍 Onboarding: Document data: $data');
      _dlog('🔍 Onboarding: enabled: $enabled, url: ${_redactUrlForLogs(url)}');
      _dlog('🔍 Onboarding: Document exists: ${doc.exists}');
      _dlog('🔍 Onboarding: Document ID: ${doc.id}');
      _dlog('🔍 Onboarding: Collection path: ${doc.reference.path}');

      if (!enabled || url.isEmpty) {
        // Nothing to show -> show placeholder instead of going home
        _dlog('🔍 Onboarding: Video disabled or URL empty, showing placeholder');
        _failed = true;
        setState(() {
          _loading = false;
        });
        // Don't go home immediately - let user see the placeholder
        return;
      }

      // 2) Skip Firebase Storage conversion for local assets
      if (url.startsWith('assets/')) {
        _dlog('🔍 Onboarding: Using local asset, skipping Firebase Storage conversion');
      } else if (!url.startsWith('http')) {
        // Only convert to download URL for Firebase Storage paths (not assets)
        try {
          _dlog('🔍 Onboarding: Converting Firebase Storage path to download URL...');
          url = await FirebaseStorage.instance.ref(url).getDownloadURL();
          _dlog('🔍 Onboarding: Got download URL: ${_redactUrlForLogs(url)}');
        } catch (e) {
          _dlog('🔍 Onboarding: Error getting download URL: $e');
          _failed = true;
          setState(() {
            _loading = false;
          });
          return _goHomeAfterMinHold(markSeen: true);
        }
      }

      // 3) Initialize VideoPlayer for local asset
      try {
        _dlog('🔍 Onboarding: Initializing video player with URL: ${_redactUrlForLogs(url)}');
        
        // Check if it's a local asset path
        if (url.startsWith('assets/')) {
          _dlog('🔍 Onboarding: Using VideoPlayerController.asset for local file');
          _controller = VideoPlayerController.asset(url);
        } else {
          _dlog('🔍 Onboarding: Using VideoPlayerController.network for remote URL');
          _controller = VideoPlayerController.networkUrl(Uri.parse(url));
        }
        
        _dlog('🔍 Onboarding: Video controller created, initializing...');
        
        // Wait for initialization with timeout
        await _controller!.initialize().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Video initialization timeout');
          },
        );
        
        _dlog('🔍 Onboarding: Video initialized successfully, setting up playback...');
        
        _controller!.setLooping(false);

        // Mark as ready
        setState(() {
          _loading = false;
        });

        // Listen to playback state
        _controller!.addListener(() {
          if (!mounted) return;
          final v = _controller!.value;

          // Mark that playback actually started
          if (v.isInitialized && v.position > Duration.zero) {
            _videoHasStarted = true;
          }

          // Detect end only after it really started
          if (_videoHasStarted &&
              v.isInitialized &&
              !v.isPlaying &&
              v.position >= v.duration - const Duration(milliseconds: 200)) {
            _goHomeAfterMinHold(markSeen: true);
          }
        });

        // Start playback
        _dlog('🔍 Onboarding: Starting video playback...');
        await _controller!.play();
        _dlog('🔍 Onboarding: Video playback started successfully');
        
      } catch (e) {
        _dlog('🔍 Onboarding: Error initializing video: $e');
        _failed = true;
        setState(() {
          _loading = false;
        });
        return _goHomeAfterMinHold(markSeen: true);
      }
    } catch (e) {
      // No network / rules / missing file -> still hold a minimum and continue
      _failed = true;
      setState(() {
        _loading = false;
      });
      return _goHomeAfterMinHold(markSeen: true);
    }
  }

  /// Ensures we keep the splash at least [_minShow] before navigating.
  Future<void> _goHomeAfterMinHold({required bool markSeen}) async {
    if (!mounted || _navigated) return;
    final elapsed = DateTime.now().difference(_enteredAt);
    final remaining = _minShow - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    await _goHome(markSeen: markSeen);
  }

  Future<void> _goHome({required bool markSeen}) async {
    if (!mounted || _navigated) return;
    _navigated = true;

    if (markSeen) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenIntro', true);
    }

    // Restore system UI & orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.paused) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_navigated) _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final introLocale = _preferBengaliIntro ? const Locale('bn') : const Locale('en');
    final introText = lookupAppLocalizations(introLocale).onboardingIntroText;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const _HeaderLogos(),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
        children: [
                    Expanded(
                      flex: 6,
                      child: _VideoStage(
                        controller: _controller,
                        loading: _loading,
                        failed: _failed,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      flex: 4,
                      child: _IntroTextCard(
                        text: introText,
                        controller: _textScrollController,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _goHomeAfterMinHold(markSeen: true),
                        child: const Text('Skip'),
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
}

class _VideoStage extends StatelessWidget {
  const _VideoStage({
    required this.controller,
    required this.loading,
    required this.failed,
  });

  final VideoPlayerController? controller;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    if (!loading && controller != null && controller!.value.isInitialized) {
      return Container(
                    decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
                      ),
                    ),
                  ),
      );
    }

    if (failed) {
      return _VideoMessage(
        icon: Icons.videocam_off,
        title: 'Intro Video Not Available',
        subtitle: 'No video file found in assets or Firestore document empty',
      );
    }

    return const _VideoMessage(
      icon: Icons.play_circle_outline,
      title: 'Loading intro video...',
      subtitle: 'Please wait a moment',
      showLoader: true,
    );
  }
}

class _VideoMessage extends StatelessWidget {
  const _VideoMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showLoader = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
                    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
                  ),
                ],
              ),
      child: Center(
              child: Column(
          mainAxisSize: MainAxisSize.min,
                children: [
            if (showLoader) const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: CircularProgressIndicator(),
            ),
            Icon(icon, size: 64, color: Colors.black54),
            const SizedBox(height: 12),
                  Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _IntroTextCard extends StatelessWidget {
  const _IntroTextCard({required this.text, required this.controller});

  final String text;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Scrollbar(
        controller: controller,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.only(right: 12),
                    child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
          ),
    );
  }
}

class _HeaderLogos extends StatelessWidget {
  const _HeaderLogos();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              'assets/icons/l2l-video-horizontal_black.png',
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Image.asset(
                'assets/icons/Net-creative-logo-orange-square-350px.png',
          width: 56,
          fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
        ],
    );
  }
}