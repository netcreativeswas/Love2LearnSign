import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:line_icons/line_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'services/cache_service.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:provider/provider.dart';
import 'services/favorites_repository.dart';
import 'services/history_repository.dart';
import 'services/share_utils.dart';
import 'theme.dart';
import 'widgets/fullscreen_video_player.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'tenancy/tenant_scope.dart';
import 'services/ad_service.dart';
import 'services/session_counter_service.dart';
import 'services/premium_service.dart';
import 'pages/premium_settings_page.dart';


class VideoViewerPage extends StatefulWidget {
  final String wordId;
  final String? videoUrl;
  final bool trackOnInit;

  const VideoViewerPage({
    super.key,
    required this.wordId,
    this.videoUrl,
    this.trackOnInit = true,
  });

  @override
  State<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _accessDenied = false;
  bool _showLearnAlso = true;
  String _english = '';
  String _bengali = '';
  List<dynamic> _variants = [];
  List<VideoPlayerController> _controllers = [];
  late PageController _pageController;
  int _currentIndex = 0;
  double _currentSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
  bool _isNextDirection = true; // Track carousel direction for animation
  
  // Flags for state management
  bool _isDisposed = false;
  bool _isTransitioning = false;
  
  // New fields for related videos and antonyms
  String _categoryMain = '';
  String _categorySub = '';
  List<String> _englishWordAntonyms = [];
  List<String> _bengaliWordAntonyms = [];
  
  // Store the selected random word for "Learn Also" section (to prevent re-shuffling on Play/Pause)
  String? _selectedRelatedWordId;
  Map<String, dynamic>? _selectedRelatedWordData;

  void _cyclePlaybackSpeed(VideoPlayerController controller) {
    if (_isDisposed || !mounted) return;
    
    final currentIndex = _speedOptions.indexOf(_currentSpeed);
    final nextIndex = (currentIndex + 1) % _speedOptions.length;
    final newSpeed = _speedOptions[nextIndex];
    
    try {
      controller.setPlaybackSpeed(newSpeed);
    } catch (_) {}
    
    if (mounted && !_isDisposed) {
      setState(() {
        _currentSpeed = newSpeed;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<HistoryRepository>().add(widget.wordId);
    _pageController = PageController();
    _loadData();
    if (widget.trackOnInit) {
      _trackVideoView();
    }
  }

  /// Track video view and show interstitial ad if needed
  Future<void> _trackVideoView() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Skip ads for paidUser and admin
    if (authProvider.hasRole('paidUser') || authProvider.hasRole('admin')) {
      return;
    }

    try {
      final counter = SessionCounterService();
      final viewCount = await counter.incrementVideoViewCount();
      final shouldShowAd = viewCount >= SessionCounterService.interstitialAdThreshold;

      if (shouldShowAd && mounted) {
        // Show ad after a short delay to avoid interrupting initial load
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (!mounted) return;

          // Make sure an interstitial is being loaded; wait briefly if needed so we don't "miss" it.
          final adShown = await AdService().showInterstitialAdWithWait();

          if (adShown) {
            await counter.resetVideoViewCount();
            // Show premium CTA after ad
            if (mounted) {
              await _showPremiumCTA(context);
            }
          }
        });
      }
      
      // Track learned sign
      await PremiumService().incrementLearnedSigns();
    } catch (e) {
      debugPrint('Error tracking video view: $e');
    }
  }

  /// Track video view when navigating to another video (for Learn Also/Opposite)
  Future<void> _trackVideoViewForNavigation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Skip ads for paidUser and admin
    if (authProvider.hasRole('paidUser') || authProvider.hasRole('admin')) {
      return;
    }

    try {
      final counter = SessionCounterService();
      final viewCount = await counter.incrementVideoViewCount();
      final shouldShowAd = viewCount >= SessionCounterService.interstitialAdThreshold;

      if (shouldShowAd && mounted) {
        AdService().ensureAdsLoaded();
        final adShown = await AdService().showInterstitialAdWithWait();

        if (adShown) {
          await counter.resetVideoViewCount();
        // Show premium CTA after ad
          if (mounted) {
          await _showPremiumCTA(context);
          }
        }
      }
      
      // Track learned sign
      await PremiumService().incrementLearnedSigns();
    } catch (e) {
      debugPrint('Error tracking video view for navigation: $e');
    }
  }

  /// Show premium CTA after interstitial ad
  Future<void> _showPremiumCTA(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.hasRole('paidUser') || authProvider.hasRole('admin')) {
      return; // Don't show CTA for premium users
    }

    // Respect monthly frequency (only once every 30 days per user when dismissed)
    final canShowCta = await PremiumService().shouldShowInterstitialCta();
    if (!canShowCta) return;

    // Show after a delay to not interrupt navigation
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final userChoseUpgrade = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(dialogContext)!.removeAllAdsForever,
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(S.of(dialogContext)!.noThanks),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(dialogContext).colorScheme.secondary,
                          foregroundColor: Theme.of(dialogContext).colorScheme.onSecondary,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(S.of(dialogContext)!.upgrade),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!mounted) return;

    if (userChoseUpgrade) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PremiumSettingsPage(),
        ),
      );
    } else {
      await PremiumService().recordInterstitialCtaDismissed();
    }
  }

  Future<void> _loadData() async {
    // Check if disposed before starting
    if (_isDisposed || !mounted) return;
    
    // Si tu utilises prefs pour les paramètres de cache, tu peux les garder ici.
    // Supprime SharedPreferences pour favoris/historique.
    // EXEMPLE :
    // final prefs = await SharedPreferences.getInstance();
    // final onlyWifi = prefs.getBool('downloadOnlyOnWiFi') ?? false;
    // final maxCacheSizeMB = prefs.getInt('maxCacheSizeMB') ?? 100;

    // Use shared cache service

    // Pour le wifi only (optionnel, à ajuster selon ton usage actuel) :
    // if (onlyWifi) {
    //   final connectivityResult = await Connectivity().checkConnectivity();
    //   if (connectivityResult != ConnectivityResult.wifi) {
    //     setState(() => _isLoading = false);
    //     return;
    //   }
    // }

    final tenantId = context.read<TenantScope>().tenantId;
    final doc = await TenantDb.conceptDoc(
      FirebaseFirestore.instance,
      widget.wordId,
      tenantId: tenantId,
    ).get();
    
    // Check again after async operation
    if (_isDisposed || !mounted) return;
    
    final data = doc.data() as Map<String, dynamic>;
    _english = data['english'] as String? ?? '';
    _bengali = data['bengali'] as String? ?? '';
    _categoryMain = data['category_main'] as String? ?? ''; // Note: Firebase uses 'category_main' with underscore
    _categorySub = data['category_sub'] as String? ?? ''; // Load subcategory
    
    // Determine if "Learn Also" should be shown: only if there is at least one other word in the same category
    if (_categoryMain.isNotEmpty) {
      try {
        final snap = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
            .where('category_main', isEqualTo: _categoryMain)
            .limit(2)
            .get();
        final hasOther = snap.docs.any((d) => d.id != widget.wordId);
        if (!hasOther) {
          _showLearnAlso = false;
        }
      } catch (_) {
        // On error, default to showing (non-fatal)
        _showLearnAlso = false;
      }
    } else {
      _showLearnAlso = false;
    }
    
    // Load a random related word for "Learn Also" section (only once) if applicable
    if (_showLearnAlso && _categoryMain.isNotEmpty && _selectedRelatedWordId == null) {
      await _loadRandomRelatedWord();
    }
    
    // Check if video is restricted and user has required role
    final restrictedCategories = {
      'JW Organisation': 'jw',
      'Biblical Content': 'jw',
    };
    final restrictedRole = restrictedCategories[_categoryMain.trim()];
    if (restrictedRole != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.userRoles.contains(restrictedRole)) {
        // User doesn't have required role, block access
        setState(() {
          _isLoading = false;
          _accessDenied = true;
        });
        return;
      }
    }
    
    // Handle antonyms - they can be List or String in Firebase
    final englishAntonyms = data['englishWordAntonyms'];
    if (englishAntonyms is List && englishAntonyms.isNotEmpty) {
      _englishWordAntonyms = englishAntonyms.map((e) => e.toString()).toList();
    } else if (englishAntonyms is String && englishAntonyms.isNotEmpty) {
      _englishWordAntonyms = [englishAntonyms];
    }
    
    final bengaliAntonyms = data['bengaliWordAntonyms'];
    if (bengaliAntonyms is List && bengaliAntonyms.isNotEmpty) {
      _bengaliWordAntonyms = bengaliAntonyms.map((e) => e.toString()).toList();
    } else if (bengaliAntonyms is String && bengaliAntonyms.isNotEmpty) {
      _bengaliWordAntonyms = [bengaliAntonyms];
    }
    
    final variants = data['variants'] as List<dynamic>?;

    if (variants != null && variants.isNotEmpty) {
      _variants = variants;
      _controllers = List<VideoPlayerController>.filled(
        variants.length,
        // Placeholder; will be replaced per index
        VideoPlayerController.networkUrl(Uri.parse('https://invalid.local/placeholder.mp4')),
        growable: false,
      );
      for (int i = 0; i < variants.length; i++) {
        // Check if disposed before each iteration
        if (_isDisposed || !mounted) {
          // Dispose any already initialized controllers
          for (var ctrl in _controllers) {
            try {
              if (ctrl.value.isInitialized) ctrl.dispose();
            } catch (_) {}
          }
          return;
        }
        
        final url = variants[i]['videoUrl'];
        try {
          final sanitizedUrl = Uri.parse(url).toString();
          final file = await CacheService.instance.getSingleFileRespectingSettings(sanitizedUrl);
          
          // Check again after async operation
          if (_isDisposed || !mounted) {
            // Dispose any already initialized controllers
            for (var ctrl in _controllers) {
              try {
                if (ctrl.value.isInitialized) ctrl.dispose();
              } catch (_) {}
            }
            return;
          }
          
          final controller = file != null
              ? VideoPlayerController.file(file)
              : VideoPlayerController.networkUrl(Uri.parse(sanitizedUrl));
          await controller.initialize();
          
          // Final check before using controller
          if (_isDisposed || !mounted) {
            try {
              controller.dispose();
            } catch (_) {}
            return;
          }
          
          controller.setLooping(true);
          _controllers[i] = controller;
        } catch (e) {
          print('Error loading video for $url: $e');
        }
      }
      if (_controllers.isNotEmpty && !_isDisposed && mounted) {
        // S'assurer que toutes les autres vidéos sont en pause
        for (int i = 1; i < _controllers.length; i++) {
          try {
            if (_controllers[i].value.isInitialized) {
              await _controllers[i].pause();
              await _controllers[i].seekTo(Duration.zero);
            }
          } catch (_) {}
        }
        // Jouer seulement la première vidéo depuis le début
        try {
          final firstController = _controllers[0];
          if (firstController.value.isInitialized && !_isDisposed) {
            await firstController.seekTo(Duration.zero);
            await firstController.play();
          }
        } catch (_) {}
        
        if (mounted && !_isDisposed) {
          setState(() {});
        }
      }
    } else {
      print('No variants found or empty list.');
    }

    setState(() => _isLoading = false);
  }

  // Load a random related word from the same category (called only once)
  Future<void> _loadRandomRelatedWord() async {
    if (_categoryMain.isEmpty) return;
    
    try {
      final tenantId = context.read<TenantScope>().tenantId;
      final snapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
          .where('category_main', isEqualTo: _categoryMain)
          .get();
      
      // Get all docs except current word
      final allDocs = snapshot.docs
          .where((doc) => doc.id != widget.wordId)
          .toList();
      
      if (allDocs.isNotEmpty) {
        // Pick ONE random word and store it
        allDocs.shuffle();
        final randomDoc = allDocs.first;
        _selectedRelatedWordId = randomDoc.id;
        _selectedRelatedWordData = randomDoc.data() as Map<String, dynamic>;
        
        // Update UI to show the selected word
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading random related word: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _controllers) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    try {
      _pageController.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controllers.isEmpty) return;
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause all video controllers when app goes to background
      for (var controller in _controllers) {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          controller.pause();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume the current video when app comes to foreground
      if (_currentIndex >= 0 && _currentIndex < _controllers.length) {
        final currentController = _controllers[_currentIndex];
        if (currentController.value.isInitialized && !currentController.value.isPlaying) {
          currentController.play();
        }
      }
    }
  }

  void _onPageChanged(int index) async {
    // Prevent multiple simultaneous transitions
    if (_isTransitioning || _isDisposed || !mounted) return;
    _isTransitioning = true;
    
    // Pause previous controller et remet au début
    if (_currentIndex >= 0 && _currentIndex < _controllers.length) {
      try {
        final previous = _controllers[_currentIndex];
        if (previous.value.isInitialized) {
          await previous.pause();
          await previous.seekTo(Duration.zero); // Remettre au début
        }
      } catch (e) {
        debugPrint('Error pausing previous controller: $e');
      }
    }
    
    // Update index and reset speed
    if (mounted && !_isDisposed) {
      setState(() {
        _currentIndex = index;
        _currentSpeed = 1.0;
      });
    }
    
    // Play new controller at default speed depuis le début
    if (index >= 0 && index < _controllers.length && !_isDisposed && mounted) {
      try {
        final current = _controllers[index];
        if (current.value.isInitialized) {
          await current.seekTo(Duration.zero); // S'assurer qu'on commence depuis le début
          current.setPlaybackSpeed(1.0);
          await current.play();
        }
      } catch (e) {
        debugPrint('Error playing new controller: $e');
      }
    }
    
    _isTransitioning = false;
  }

  Future<void> _toggleFavorite() async {
    context.read<FavoritesRepository>().toggle(widget.wordId);
  }

  String _capitalizeFirstLetter(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    return s.length == 1 ? first : '$first${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface3,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface3,
        leading: IconButton(
          icon: Icon(
            IconlyLight.arrowLeft2,
            color: Theme.of(context).colorScheme.secondary, // Orange like share button
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Force interstitial (debug)',
              icon: Icon(Icons.bug_report, color: Theme.of(context).colorScheme.secondary),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final info = await AdService().getInterstitialDebugInfo();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Interstitial: ready=${info['ready']} suppressed=${info['suppressedByRole']} forceProdAds=${info['forceProdAds']} adUnitId=${info['adUnitId']} roles=${info['roles']} lastLoadError=${info['lastLoadError']}',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
                final shown = await AdService().showInterstitialAdWithWait();
                final info2 = await AdService().getInterstitialDebugInfo();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      shown
                          ? '✅ Interstitial shown'
                          : '❌ Interstitial NOT shown. lastShowError=${info2['lastShowError']} lastLoadError=${info2['lastLoadError']} roles=${info2['roles']}',
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.share, color: Theme.of(context).colorScheme.secondary, size: 28,),
            onPressed: () async {
              await ShareService.shareVideo(
                widget.wordId,
                english: _english,
                bengali: _bengali,
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _accessDenied
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          '🔒 Restricted Content',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This video is reserved for JW members only.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
          : _variants.length <= 1
              ? _buildSingleVideoView()
              : _buildCarouselView(),
    );
  }

  Widget _buildSingleVideoView() {
    final controller = _controllers.isNotEmpty ? _controllers[0] : null;
    final videoThumbnail = _variants.isNotEmpty ? _variants[0]['videoThumbnail'] as String? : null;
    if (controller == null) {
      return Center(
        child: Container(
          width: 330.0,
          height: 400.0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        ),
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Title + Video + Buttons section (now scrollable)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display English and Bengali words above the video
                    Builder(
                      builder: (context) {
                        final locale = Localizations.localeOf(context).languageCode;
                        final englishCap = _capitalizeFirstLetter(_english);
                        final String topText = locale == 'bn' ? _bengali : englishCap;
                        final String bottomText = locale == 'bn' ? englishCap : _bengali;
                        return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                              topText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                    const SizedBox(width: 8),
                Text(
                              bottomText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                  ],
                ),
                // Category badge
                if (_categoryMain.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildCategoryBadge(context),
                ],
              ],
                        );
                      },
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final double width = 330.0;
                final double height = 400.0;
                return Center(
                  child: Container(
                    width: width,
                    height: height,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: controller.value.isInitialized
                                ? AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  )
                                : (videoThumbnail != null && videoThumbnail.isNotEmpty)
                                    ? Image.network(
                                        videoThumbnail,
                                        width: width,
                                        height: height,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Image.asset('assets/bslDic-videoThumbnail-250px.png', width: width, height: height, fit: BoxFit.cover),
                                      )
                                    : Image.asset(
                                        'assets/bslDic-videoThumbnail-250px.png',
                                        width: width,
                                        height: height,
                                        fit: BoxFit.cover,
                                      ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(Icons.fullscreen,
                                   color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), size:30),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FullscreenVideoPlayer(
                                      controller: controller,
                                      wordId: widget.wordId,
                                      english: _english,
                                      bengali: _bengali,
                                      controllers: _variants.length > 1 ? _controllers : null,
                                      currentIndex: _variants.length > 1 ? 0 : null,
                                      onPageChanged: _variants.length > 1 ? (index) {
                                        // Update state when navigating in fullscreen
                                        setState(() {
                                          _currentIndex = index;
                                        });
                                      } : null,
                                      totalVariants: _variants.length > 1 ? _variants.length : null,
                                      categoryMain: _categoryMain,
                                      categorySub: _categorySub,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _cyclePlaybackSpeed(controller),
                  icon: Icon(IconlyLight.timeCircle),
                  label: Text('${_currentSpeed.toStringAsFixed(1)}x'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    if (controller.value.isInitialized) {
                      setState(() {
                        controller.value.isPlaying ? controller.pause() : controller.play();
                      });
                    }
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
                // Favorite toggle button (persistent), styled as ElevatedButton.icon
                Consumer<FavoritesRepository>(
                        builder: (context, repo, _) {
                          final isFav = repo.contains(widget.wordId);
                          final localeCode = Localizations.localeOf(context).languageCode;

                          String labelText;
                          if (localeCode == 'en') {
                            labelText = isFav ? 'Remove from\nfavorites' : 'Add to\nFavorites';
                          } else if (localeCode == 'bn') {
                            final original = isFav ? S.of(context)!.unfavorite : S.of(context)!.favorite;
                            // Force two lines for Bengali text
                            final firstSpace = original.indexOf(' ');
                            if (firstSpace != -1) {
                              labelText = original.substring(0, firstSpace) +
                                  '\n' +
                                  original.substring(firstSpace + 1);
                            } else {
                              // If no space, try to split at a reasonable point (e.g., after 6 chars)
                              if (original.length > 6) {
                                labelText = original.substring(0, 6) + '\n' + original.substring(6);
                            } else {
                              labelText = original;
                              }
                            }
                          } else {
                            labelText = isFav ? S.of(context)!.unfavorite : S.of(context)!.favorite;
                          }

                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => repo.toggle(widget.wordId),
                            icon: Icon(
                              isFav ? IconlyBold.heart : IconlyLight.heart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            label: Text(
                              labelText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(height: 1.0),
                            ),
                          );
                        },
                ),
              ],
            ),
                ],
              ),
            ),
            // Divider separating video section from related content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Divider(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            // Learn Also + Learn The Opposite sections (now part of main scroll)
            _buildRelatedVideosSection(),
            _buildAntonymSection(),
            const SizedBox(height: 16.0), // Bottom spacing
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselView() {
    final controller = _controllers.isNotEmpty && _currentIndex < _controllers.length 
        ? _controllers[_currentIndex] 
        : null;
    final label = _variants.isNotEmpty && _currentIndex < _variants.length
        ? (_variants[_currentIndex]['label'] ?? 'Variant')
        : 'Variant';
    final videoThumbnail = _variants.isNotEmpty && _currentIndex < _variants.length
        ? (_variants[_currentIndex]['videoThumbnail'] as String?)
        : null;
    
    if (controller == null) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }
    
    return SafeArea(
      child: SingleChildScrollView(
      child: Column(
        children: [
            // Title + Video + Label + Buttons section (now scrollable)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Display English and Bengali words above the video
                  Builder(
                    builder: (context) {
                      final locale = Localizations.localeOf(context).languageCode;
                      final englishCap = _capitalizeFirstLetter(_english);
                      final String topText = locale == 'bn' ? _bengali : englishCap;
                      final String bottomText = locale == 'bn' ? englishCap : _bengali;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            topText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                              const SizedBox(width: 8),
                          Text(
                            bottomText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                            ],
                          ),
                          // Category badge
                          if (_categoryMain.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildCategoryBadge(context),
                          ],
                        ],
                      );
                    },
                      ),
                      const SizedBox(height: 8),
                  // Video with carousel arrows on sides
                  Builder(
                    builder: (context) {
                      final double width = 330.0;
                      final double height = 400.0;
                      return Center(
                        child: GestureDetector(
                          onHorizontalDragEnd: (DragEndDetails details) {
                            // Detect swipe direction
                            final double velocity = details.primaryVelocity ?? 0;
                            if (velocity > 500) {
                              // Swipe right (go to previous)
                              if (_currentIndex > 0) {
                                setState(() {
                                  _isNextDirection = false;
                                });
                                _onPageChanged(_currentIndex - 1);
                              }
                            } else if (velocity < -500) {
                              // Swipe left (go to next)
                              if (_currentIndex < _variants.length - 1) {
                                setState(() {
                                  _isNextDirection = true;
                                });
                                _onPageChanged(_currentIndex + 1);
                              }
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeOut,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                final offsetBegin = _isNextDirection 
                                    ? const Offset(1.0, 0.0)  // Slide from right for Next
                                    : const Offset(-1.0, 0.0); // Slide from left for Previous
                                
                                // Only animate the incoming widget (child with current key)
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: offsetBegin,
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                                // Only show the current child, hide previous ones immediately
                                return Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                        child: Container(
                                key: ValueKey<int>(_currentIndex),
                          width: width,
                          height: height,
                                margin: const EdgeInsets.only(top: 8, bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: controller.value.isInitialized
                                                ? AspectRatio(
                                                    aspectRatio: controller.value.aspectRatio,
                                                    child: VideoPlayer(controller),
                                                  )
                                      : (videoThumbnail != null && videoThumbnail.isNotEmpty)
                                          ? Image.network(
                                              videoThumbnail,
                                              width: width,
                                              height: height,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Image.asset('assets/bslDic-videoThumbnail-250px.png', width: width, height: height, fit: BoxFit.cover),
                                            )
                                          : Image.asset(
                                              'assets/bslDic-videoThumbnail-250px.png',
                                              width: width,
                                              height: height,
                                              fit: BoxFit.cover,
                                            ),
                                ),
                                Positioned(
                                  top: 8,
                                        right: 8,
                                  child: IconButton(
                                    icon: Icon(Icons.fullscreen,
                                               color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), size:30),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => FullscreenVideoPlayer(
                                            controller: controller,
                                            wordId: widget.wordId,
                                            english: _english,
                                            bengali: _bengali,
                                            controllers: _controllers,
                                            currentIndex: _currentIndex,
                                            onPageChanged: (index) {
                                              // Update state when navigating in fullscreen
                                              setState(() {
                                                _currentIndex = index;
                                              });
                                            },
                                            totalVariants: _variants.length,
                                            categoryMain: _categoryMain,
                                            categorySub: _categorySub,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                            // Previous button (left side, outside video frame)
                            if (_currentIndex > 0)
                              Positioned(
                                left: -20, // Negative value to place outside video frame
                                child: Opacity(
                                  opacity: 0.9, // Increased opacity for better visibility
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.chevron_left, color: Colors.white, size: 28), // Slightly smaller
                            onPressed: () {
                              if (_currentIndex > 0) {
                                          setState(() {
                                            _isNextDirection = false; // Going backwards
                                          });
                                          _onPageChanged(_currentIndex - 1);
                              }
                            },
                          ),
                                  ),
                                ),
                              ),
                            // Next button (right side, outside video frame)
                            if (_currentIndex < _variants.length - 1)
                              Positioned(
                                right: -20, // Negative value to place outside video frame
                                child: Opacity(
                                  opacity: 0.9, // Increased opacity for better visibility
                                  child: Container(
                              decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                                shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.chevron_right, color: Colors.white, size: 28), // Slightly smaller
                            onPressed: () {
                              if (_currentIndex < _variants.length - 1) {
                                          setState(() {
                                            _isNextDirection = true; // Going forward
                                          });
                                          _onPageChanged(_currentIndex + 1);
                              }
                            },
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Pagination dots instead of version text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_variants.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentIndex
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => _cyclePlaybackSpeed(controller),
                            icon: Icon(IconlyLight.timeCircle),
                            label: Text('${_currentSpeed.toStringAsFixed(1)}x'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {
                              if (controller.value.isInitialized) {
                                setState(() {
                                  controller.value.isPlaying ? controller.pause() : controller.play();
                                });
                              }
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
                          Consumer<FavoritesRepository>(
                            builder: (context, repo, _) {
                              final isFav = repo.contains(widget.wordId);
                              final localeCode = Localizations.localeOf(context).languageCode;

                              String labelText;
                              if (localeCode == 'en') {
                                labelText = isFav ? 'Remove from\nfavorites' : 'Add to\nFavorites';
                              } else if (localeCode == 'bn') {
                                final original = isFav ? S.of(context)!.unfavorite : S.of(context)!.favorite;
                                // Force two lines for Bengali text
                                final firstSpace = original.indexOf(' ');
                                if (firstSpace != -1) {
                                  labelText = original.substring(0, firstSpace) +
                                      '\n' +
                                      original.substring(firstSpace + 1);
                                } else {
                                  // If no space, try to split at a reasonable point (e.g., after 6 chars)
                                  if (original.length > 6) {
                                    labelText = original.substring(0, 6) + '\n' + original.substring(6);
                                } else {
                                  labelText = original;
                                  }
                                }
                              } else {
                                labelText = isFav ? S.of(context)!.unfavorite : S.of(context)!.favorite;
                              }

                              return ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () => repo.toggle(widget.wordId),
                                icon: Icon(
                                  isFav ? IconlyBold.heart : IconlyLight.heart,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: labelText.split('\n')[0],
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      height: 1.0, // Reduce line height
                                    ),
                                    children: labelText.contains('\n')
                                        ? [
                                            TextSpan(
                                              text: '\n${labelText.split('\n')[1]}',
                                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                height: 1.0, // Reduce line height
                                              ),
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
            // Divider separating video section from related content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Divider(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            // Learn Also + Learn The Opposite sections (now part of main scroll)
                  _buildRelatedVideosSection(),
                  _buildAntonymSection(),
            const SizedBox(height: 16.0), // Bottom spacing
                ],
              ),
      ),
    );
  }

  static Future<void> clearCustomVideoCache(BuildContext context) async {
    await CacheService.instance.emptyCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Cache cleared successfully')),
    );
  }

  // Widget to display related videos from the same category
  Widget _buildRelatedVideosSection() {
    if (_categoryMain.isEmpty || !_showLearnAlso) {
      return const SizedBox.shrink();
    }
    
    // Get the text based on current locale
    final locale = Localizations.localeOf(context).languageCode;
    final learnAlsoText = locale == 'bn' ? 'আরও শিখুন' : 'LEARN ALSO';
    
    // If no word selected yet, show loading or empty
    if (_selectedRelatedWordId == null || _selectedRelatedWordData == null) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            learnAlsoText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
              }
              
    // Use the stored word data (doesn't change on Play/Pause)
    final data = _selectedRelatedWordData!;
              final english = data['english'] as String? ?? '';
              final bengali = data['bengali'] as String? ?? '';
              final variants = data['variants'] as List<dynamic>?;
              
              // Get thumbnail
              String? thumbnailUrl;
              if (variants != null && variants.isNotEmpty) {
                final v0 = variants[0] as Map<String, dynamic>;
                thumbnailUrl = (v0['videoThumbnailSmall'] as String?)?.isNotEmpty == true
                    ? v0['videoThumbnailSmall']
                    : v0['videoThumbnail'];
              }
              
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            learnAlsoText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).colorScheme.surface2,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Theme.of(context).colorScheme.surface3,
                              child: Image.asset('assets/videoLoadingPlaceholder.webp', fit: BoxFit.cover),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: Theme.of(context).colorScheme.surface3,
                            child: Image.asset('assets/videoLoadingPlaceholder.webp', fit: BoxFit.cover),
                          ),
                  ),
              title: Builder(
                builder: (context) {
                  final locale = Localizations.localeOf(context).languageCode;
                  final enCap = _capitalizeFirstLetter(english);
                  final topText = locale == 'bn' ? bengali : enCap;
                  return Text(
                    topText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).scaffoldBackgroundColor,
                    ),
                  );
                },
                  ),
              subtitle: Builder(
                builder: (context) {
                  final locale = Localizations.localeOf(context).languageCode;
                  final enCap = _capitalizeFirstLetter(english);
                  final bottomText = locale == 'bn' ? enCap : bengali;
                  return Text(
                    bottomText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).scaffoldBackgroundColor,
                    ),
                  );
                },
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_circle_outline, color: Theme.of(context).colorScheme.secondary, size: 32),
                    onPressed: () {
                  context.read<HistoryRepository>().add(_selectedRelatedWordId!);
                      _trackVideoViewForNavigation();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoViewerPage(
                            wordId: _selectedRelatedWordId!,
                            trackOnInit: false,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                context.read<HistoryRepository>().add(_selectedRelatedWordId!);
                    _trackVideoViewForNavigation();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoViewerPage(
                          wordId: _selectedRelatedWordId!,
                          trackOnInit: false,
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  // Widget to display category badge
  Widget _buildCategoryBadge(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final categoryText = translateCategory(context, _categoryMain);
    final subcategoryText = _categorySub.isNotEmpty 
        ? translateCategory(context, _categorySub) 
        : null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
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

  // Widget to display antonym video if exists
  Widget _buildAntonymSection() {
    if (_englishWordAntonyms.isEmpty && _bengaliWordAntonyms.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Get the text based on current locale
    final locale = Localizations.localeOf(context).languageCode;
    final learnOppositeText = locale == 'bn' ? 'বিপরীত শিখুন' : 'LEARN THE OPPOSITE';
    
    return FutureBuilder<DocumentSnapshot?>(
      future: _findAntonymDocument(),
            builder: (context, snapshot) {
        // Only show the section if a document is found
        if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              
        final doc = snapshot.data!;
              final data = doc.data() as Map<String, dynamic>;
              final english = data['english'] as String? ?? '';
              final bengali = data['bengali'] as String? ?? '';
              final variants = data['variants'] as List<dynamic>?;
              
              // Get thumbnail
              String? thumbnailUrl;
              if (variants != null && variants.isNotEmpty) {
                final v0 = variants[0] as Map<String, dynamic>;
                thumbnailUrl = (v0['videoThumbnailSmall'] as String?)?.isNotEmpty == true
                    ? v0['videoThumbnailSmall']
                    : v0['videoThumbnail'];
              }
              
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                learnOppositeText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).colorScheme.surface2,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Theme.of(context).colorScheme.surface3,
                              child: Image.asset('assets/videoLoadingPlaceholder.webp', fit: BoxFit.cover),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: Theme.of(context).colorScheme.surface3,
                            child: Image.asset('assets/videoLoadingPlaceholder.webp', fit: BoxFit.cover),
                          ),
                  ),
                  title: Builder(
                    builder: (context) {
                      final locale = Localizations.localeOf(context).languageCode;
                      final enCap = _capitalizeFirstLetter(english);
                      final topText = locale == 'bn' ? bengali : enCap;
                      return Text(
                        topText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).scaffoldBackgroundColor,
                    ),
                      );
                    },
                  ),
                  subtitle: Builder(
                    builder: (context) {
                      final locale = Localizations.localeOf(context).languageCode;
                      final enCap = _capitalizeFirstLetter(english);
                      final bottomText = locale == 'bn' ? enCap : bengali;
                      return Text(
                        bottomText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).scaffoldBackgroundColor,
                    ),
                      );
                    },
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_circle_outline, color: Theme.of(context).colorScheme.secondary, size: 32),
                    onPressed: () {
                      context.read<HistoryRepository>().add(doc.id);
                      _trackVideoViewForNavigation();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoViewerPage(
                            wordId: doc.id,
                            trackOnInit: false,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    context.read<HistoryRepository>().add(doc.id);
                    _trackVideoViewForNavigation();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoViewerPage(
                          wordId: doc.id,
                          trackOnInit: false,
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
      },
    );
  }

  // Helper method to find the first existing antonym document
  Future<DocumentSnapshot?> _findAntonymDocument() async {
    final tenantId = context.read<TenantScope>().tenantId;
    // Try English antonyms first
    if (_englishWordAntonyms.isNotEmpty) {
      for (final word in _englishWordAntonyms) {
        try {
          final qs = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
              .where('english_lower', isEqualTo: word.toLowerCase())
              .limit(1)
              .get();
          if (qs.docs.isNotEmpty) return qs.docs.first;
        } catch (e) {
          print('Error querying English antonym $word: $e');
        }
      }
    }
    
    // Try Bengali antonyms if no English match found
    if (_bengaliWordAntonyms.isNotEmpty) {
      for (final word in _bengaliWordAntonyms) {
        try {
          final querySnapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
              .where('bengali', isEqualTo: word)
              .limit(1)
              .get();
          if (querySnapshot.docs.isNotEmpty) {
            return querySnapshot.docs.first;
          }
        } catch (e) {
          print('Error querying Bengali word $word: $e');
        }
      }
    }
    
    return null;
  }

  static Future<int> getCacheSizeInBytes() {
    return CacheService.instance.getApproxCacheSizeBytes();
  }
}
