import 'package:flutter/material.dart';
import 'package:love_to_learn_sign/l10n/dynamic_l10n.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:line_icons/line_icons.dart';
// removed stale import to arb app_localizations
import 'dart:io' show File;
import '../services/cache_service.dart';
import '../services/share_utils.dart';
import 'package:provider/provider.dart';
import 'package:love_to_learn_sign/tenancy/tenant_scope.dart';
import 'package:love_to_learn_sign/locale_provider.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String wordId;
  final bool showShareButton;
  final String? english;
  final String? bengali;
  // Carousel support
  final List<VideoPlayerController>? controllers;
  // Alternative carousel support: provide URLs and let fullscreen lazy-load controllers.
  final List<String>? variantUrls;
  final int? currentIndex;
  final Function(int)? onPageChanged;
  final int? totalVariants;
  // Category support
  final String? categoryMain;
  final String? categorySub;
  const FullscreenVideoPlayer({
    super.key,
    required this.controller,
    required this.wordId,
    this.showShareButton = true,
    this.english,
    this.bengali,
    this.controllers,
    this.variantUrls,
    this.currentIndex,
    this.onPageChanged,
    this.totalVariants,
    this.categoryMain,
    this.categorySub,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> with WidgetsBindingObserver {
  late VideoPlayerController _currentController;
  late int _currentIndex;
  // Controllers created by fullscreen (lazy URL mode). Parent-owned controllers are not disposed here.
  final Map<int, VideoPlayerController> _ownedControllers = {};
  int? _externalIndex;
  
  String _capitalizeFirstLetter(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    return s.length == 1 ? first : '$first${s.substring(1)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentController = widget.controller;
    _currentIndex = widget.currentIndex ?? 0;
    _externalIndex = _currentIndex; // passed-in controller belongs to parent
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  void _switchToController(int index) async {
    if (widget.controllers != null && 
        index >= 0 && 
        index < widget.controllers!.length &&
        widget.onPageChanged != null) {
      // Pause and reset previous controller
      if (_currentController.value.isInitialized) {
        await _currentController.pause();
        await _currentController.seekTo(Duration.zero);
      }
      
      setState(() {
        _currentIndex = index;
        _currentController = widget.controllers![index];
      });
      widget.onPageChanged!(index);
      
      // Auto-play the new video from the beginning
      if (_currentController.value.isInitialized) {
        await _currentController.seekTo(Duration.zero);
        await _currentController.play();
      }
      return;
    }

    // Lazy-load carousel mode (variantUrls provided).
    if (widget.variantUrls != null &&
        index >= 0 &&
        index < widget.variantUrls!.length &&
        widget.onPageChanged != null) {
      // Pause and reset previous controller
      if (_currentController.value.isInitialized) {
        try {
          await _currentController.pause();
          await _currentController.seekTo(Duration.zero);
        } catch (_) {}
      }

      setState(() {
        _currentIndex = index;
      });
      widget.onPageChanged!(index);

      final url = widget.variantUrls![index].trim();
      if (url.isEmpty) return;

      // Reuse if we already created it in fullscreen.
      final existing = _ownedControllers[index];
      if (existing != null) {
        setState(() => _currentController = existing);
        if (_currentController.value.isInitialized) {
          await _currentController.seekTo(Duration.zero);
          await _currentController.play();
        }
        _evictFarOwnedControllers(keepIndex: index);
        _prefetchAdjacentFiles(index);
        return;
      }

      File? file;
      try {
        file = await CacheService.instance.getFromCacheOnly(url);
        file ??= await CacheService.instance.getSingleFileRespectingSettings(url);
      } catch (_) {
        file = null;
      }
      if (!mounted) return;

      final ctrl = file != null
          ? VideoPlayerController.file(file)
          : VideoPlayerController.networkUrl(Uri.parse(url));
      try {
        await ctrl.initialize();
      } catch (_) {
        try {
          ctrl.dispose();
        } catch (_) {}
        return;
      }
      ctrl.setLooping(true);

      if (!mounted) {
        try {
          ctrl.dispose();
        } catch (_) {}
        return;
      }

      _ownedControllers[index] = ctrl;
      setState(() => _currentController = ctrl);
      await _currentController.seekTo(Duration.zero);
      await _currentController.play();

      _evictFarOwnedControllers(keepIndex: index);
      _prefetchAdjacentFiles(index);
      return;
    }
  }

  void _prefetchAdjacentFiles(int index) {
    if (widget.variantUrls == null) return;
    final urls = widget.variantUrls!;
    for (final i in <int>[index - 1, index + 1]) {
      if (i < 0 || i >= urls.length) continue;
      final u = urls[i].trim();
      if (u.isEmpty) continue;
      CacheService.instance.getSingleFileRespectingSettings(u);
    }
  }

  void _evictFarOwnedControllers({required int keepIndex}) {
    final keys = _ownedControllers.keys.toList();
    for (final k in keys) {
      if ((k - keepIndex).abs() <= 1) continue;
      // Never dispose the parent-owned controller.
      if (_externalIndex != null && k == _externalIndex) continue;
      final c = _ownedControllers.remove(k);
      try {
        c?.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose only controllers created by fullscreen (lazy URL mode).
    for (final entry in _ownedControllers.entries) {
      if (_externalIndex != null && entry.key == _externalIndex) continue;
      try {
        entry.value.dispose();
      } catch (_) {}
    }
    _ownedControllers.clear();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause video when app goes to background
      if (_currentController.value.isInitialized && _currentController.value.isPlaying) {
        _currentController.pause();
      }
      // Also pause all controllers if in carousel mode
      if (widget.controllers != null) {
        for (var controller in widget.controllers!) {
          if (controller.value.isInitialized && controller.value.isPlaying) {
            controller.pause();
          }
        }
      }
      if (widget.variantUrls != null) {
        for (final c in _ownedControllers.values) {
          if (c.value.isInitialized && c.value.isPlaying) {
            c.pause();
          }
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume video when app comes to foreground
      if (_currentController.value.isInitialized && !_currentController.value.isPlaying) {
        _currentController.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _currentController;
    final screenSize = MediaQuery.of(context).size;
    final totalCarousel =
        widget.controllers?.length ?? widget.variantUrls?.length ?? 0;
    final hasCarousel = totalCarousel > 1 && widget.onPageChanged != null;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: controller.value.isInitialized
                  ? Builder(
                      builder: (context) {
                        // Force portrait ratio like in VideoViewerPage
                        // Use ratio ~0.82 (between 4:5 and 5:6) for portrait display
                        final portraitRatio = 0.825; // Same as VideoViewerPage (330/400)
                        
                        final availableWidth = screenWidth - 20; // 10px padding
                        final calculatedHeight = availableWidth / portraitRatio;
                        
                        // If calculated height exceeds screen, limit by height
                        double finalWidth, finalHeight;
                        if (calculatedHeight > screenHeight) {
                          finalHeight = screenHeight;
                          finalWidth = finalHeight * portraitRatio;
                        } else {
                          finalWidth = availableWidth;
                          finalHeight = calculatedHeight;
                        }
                        
                        return Container(
                          width: finalWidth,
                          height: finalHeight,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: VideoPlayer(controller),
                          ),
                        );
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            // Words display (English and Bengali) with locale‑based order
            if (widget.english != null || widget.bengali != null)
              Positioned(
                top: 20,
                left: 20,
                right: 80, // Leave space for close button
                child: Builder(
                  builder: (context) {
                    final localeCode = Localizations.localeOf(context).languageCode;
                    final rawEn = widget.english ?? '';
                    final rawBn = widget.bengali ?? '';
                    final enCap = _capitalizeFirstLetter(rawEn);
                    final hasEn = enCap.isNotEmpty;
                    final hasBn = rawBn.isNotEmpty;

                    String? topText;
                    String? bottomText;

                    if (hasEn && hasBn) {
                      if (localeCode == 'bn') {
                        topText = rawBn;
                        bottomText = enCap;
                      } else {
                        topText = enCap;
                        bottomText = rawBn;
                      }
                    } else if (hasEn) {
                      topText = enCap;
                    } else if (hasBn) {
                      topText = rawBn;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topText != null && topText.isNotEmpty && bottomText != null && bottomText.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                topText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                bottomText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else if (topText != null && topText.isNotEmpty)
                          Text(
                            topText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        // Category badge
                        if (widget.categoryMain != null && widget.categoryMain!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildCategoryBadge(context),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ),
            // Navigation buttons for carousel
            if (hasCarousel) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                      ),
                      onPressed: () => _switchToController(_currentIndex - 1),
                    ),
                  ),
                ),
              if (_currentIndex < totalCarousel - 1)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                      ),
                      onPressed: () => _switchToController(_currentIndex + 1),
                    ),
                  ),
                ),
            ],
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 36),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ),
            // Pagination dots for carousel
            if (hasCarousel && widget.totalVariants != null && widget.totalVariants! > 1)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.totalVariants!, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    );
                  }),
                ),
              ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      final speeds = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
                      double current = controller.value.playbackSpeed;
                      int idx = speeds.indexOf(current);
                      int nextIdx = (idx + 1) % speeds.length;
                      controller.setPlaybackSpeed(speeds[nextIdx]);
                      setState(() {});
                    },
                    icon: Icon(IconlyLight.timeCircle),
                    label: Text('${controller.value.playbackSpeed.toStringAsFixed(1)}x'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        controller.value.isPlaying
                            ? controller.pause()
                            : controller.play();
                      });
                    },
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
                  const SizedBox(width: 20),
                  if (widget.showShareButton)
                    Builder(
                      builder: (buttonContext) => ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () async {
                        try {
                          final scope = context.read<TenantScope>();
                          final uiLocale = context.read<LocaleProvider>().locale.languageCode;
                          // Share a deep link to this word; falls back to the system share sheet
                          await ShareService.shareVideo(
                            widget.wordId,
                            english: widget.english,
                            bengali: widget.bengali,
                            tenantId: scope.tenantId,
                            signLangId: scope.signLangId,
                            uiLocale: uiLocale,
                            context: buttonContext,
                          );
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.of(context)!.shareFailed)),
                          );
                        }
                      },
                      icon: const Icon(Icons.ios_share),
                      label: Text(S.of(context)!.share),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final categoryText = translateCategory(context, widget.categoryMain ?? '');
    final subcategoryText = widget.categorySub != null && widget.categorySub!.isNotEmpty
        ? translateCategory(context, widget.categorySub!)
        : null;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                categoryText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              if (subcategoryText != null) ...[
                Text(
                  ' • ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                  ),
                ),
                Text(
                  subcategoryText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}