import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Allow testing production Ad Unit IDs in debug builds:
// flutter run/build apk --debug --dart-define=FORCE_PROD_ADS=true
const bool _forceProdAds = bool.fromEnvironment('FORCE_PROD_ADS', defaultValue: false);

/// Service for managing interstitial and rewarded ads
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  Completer<bool>? _interstitialLoadCompleter;
  DateTime? _lastInterstitialLoadAttemptAt;
  LoadAdError? _lastInterstitialLoadError;
  Object? _lastInterstitialShowError;
  DateTime? _lastInterstitialShownAt;
  DateTime? _lastInterstitialShowAttemptAt;
  Completer<bool>? _interstitialShowCompleter;
  bool _interstitialDidShow = false;
  
  // Retry configuration
  int _interstitialRetryCount = 0;
  int _rewardedRetryCount = 0;
  static const int _maxRetries = 5;
  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;

  // Test ad unit IDs (Google's test IDs - work for testing)
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Production ad unit IDs - Android
  static const String _prodInterstitialAdUnitIdAndroid = 'ca-app-pub-8517443606450525/4756911342';
  static const String _prodRewardedAdUnitIdAndroid = 'ca-app-pub-8517443606450525/3663321522';
  
  // Production ad unit IDs - iOS
  static const String _prodInterstitialAdUnitIdIOS = 'ca-app-pub-8517443606450525/2426987822';
  static const String _prodRewardedAdUnitIdIOS = 'ca-app-pub-8517443606450525/7815045879';

  String get _interstitialAdUnitId {
    if (kDebugMode && !_forceProdAds) {
      return _testInterstitialAdUnitId; // Always use test IDs in debug mode
    }
    // Production mode: use platform-specific IDs
    return Platform.isAndroid ? _prodInterstitialAdUnitIdAndroid : _prodInterstitialAdUnitIdIOS;
  }

  String get _rewardedAdUnitId {
    if (kDebugMode && !_forceProdAds) {
      return _testRewardedAdUnitId; // Always use test IDs in debug mode
    }
    // Production mode: use platform-specific IDs
    return Platform.isAndroid ? _prodRewardedAdUnitIdAndroid : _prodRewardedAdUnitIdIOS;
  }

  /// Initialize Mobile Ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  /// Load interstitial ad
  void _loadInterstitialAd() {
    if (_isLoadingInterstitial) return; // Prevent duplicate loading
    _isLoadingInterstitial = true;
    _lastInterstitialLoadAttemptAt = DateTime.now();
    _lastInterstitialLoadError = null;
    _interstitialLoadCompleter ??= Completer<bool>();
    debugPrint('📦 Loading interstitial ad (unitId=$_interstitialAdUnitId)');
    
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _isLoadingInterstitial = false;
          _interstitialRetryCount = 0; // Reset retry count on success
          _setInterstitialCallbacks(ad);
          debugPrint('✅ Interstitial ad loaded');
          if (_interstitialLoadCompleter != null && !_interstitialLoadCompleter!.isCompleted) {
            _interstitialLoadCompleter!.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _lastInterstitialLoadError = error;
          _isInterstitialReady = false;
          _interstitialAd = null;
          _isLoadingInterstitial = false;
          if (_interstitialLoadCompleter != null && !_interstitialLoadCompleter!.isCompleted) {
            _interstitialLoadCompleter!.complete(false);
          }
          
          // Retry with exponential backoff
          if (_interstitialRetryCount < _maxRetries) {
            _interstitialRetryCount++;
            final delay = Duration(seconds: 1 << _interstitialRetryCount); // 2, 4, 8, 16, 32s
            debugPrint('🔄 Retrying interstitial ad in ${delay.inSeconds}s (attempt $_interstitialRetryCount/$_maxRetries)');
            Future.delayed(delay, () {
              // reset completer for a fresh attempt
              _interstitialLoadCompleter = Completer<bool>();
              _loadInterstitialAd();
            });
          } else {
            debugPrint('⚠️ Max retries reached for interstitial ad');
          }
        },
      ),
    );
  }

  void _setInterstitialCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        _lastInterstitialShownAt = DateTime.now();
        _interstitialDidShow = true;
        debugPrint('📺 Interstitial ad showed');
        if (_interstitialShowCompleter != null && !_interstitialShowCompleter!.isCompleted) {
          _interstitialShowCompleter!.complete(true);
        }
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        if (_interstitialShowCompleter != null && !_interstitialShowCompleter!.isCompleted) {
          _interstitialShowCompleter!.complete(_interstitialDidShow);
        }
        _loadInterstitialAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('❌ Interstitial ad failed to show: $error');
        _lastInterstitialShowError = error;
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        if (_interstitialShowCompleter != null && !_interstitialShowCompleter!.isCompleted) {
          _interstitialShowCompleter!.complete(false);
        }
        _loadInterstitialAd();
      },
    );
  }

  /// Load rewarded ad
  void _loadRewardedAd() {
    if (_isLoadingRewarded) return; // Prevent duplicate loading
    _isLoadingRewarded = true;
    
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          _isLoadingRewarded = false;
          _rewardedRetryCount = 0; // Reset retry count on success
          _setRewardedCallbacks(ad);
          debugPrint('✅ Rewarded ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Rewarded ad failed to load: $error');
          _isRewardedReady = false;
          _rewardedAd = null;
          _isLoadingRewarded = false;
          
          // Retry with exponential backoff
          if (_rewardedRetryCount < _maxRetries) {
            _rewardedRetryCount++;
            final delay = Duration(seconds: 1 << _rewardedRetryCount); // 2, 4, 8, 16, 32s
            debugPrint('🔄 Retrying rewarded ad in ${delay.inSeconds}s (attempt $_rewardedRetryCount/$_maxRetries)');
            Future.delayed(delay, _loadRewardedAd);
          } else {
            debugPrint('⚠️ Max retries reached for rewarded ad');
          }
        },
      ),
    );
  }

  void _setRewardedCallbacks(RewardedAd ad, [Completer<bool>? completer]) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        // Complete with false if user dismissed without earning reward
        if (completer != null && !completer.isCompleted) {
          completer.complete(false);
        }
        _loadRewardedAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('❌ Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        if (completer != null && !completer.isCompleted) {
          completer.complete(false);
        }
        _loadRewardedAd();
      },
    );
  }

  /// Show interstitial ad if available
  /// Returns true if ad was shown, false otherwise
  Future<bool> showInterstitialAd() async {
    // Safety net: if the user is premium/admin, never show ads even if UI gating is stale.
    if (await _adsSuppressedByRole()) {
      debugPrint('ℹ️ Interstitial suppressed for paid/admin user');
      _lastInterstitialShowError = 'suppressed_by_role';
      return false;
    }

    if (!_isInterstitialReady || _interstitialAd == null) {
      debugPrint('⚠️ Interstitial ad not ready');
      _lastInterstitialShowError = 'not_ready';
      return false;
    }

    try {
      _lastInterstitialShowAttemptAt = DateTime.now();
      _lastInterstitialShowError = null;
      _interstitialDidShow = false;
      _interstitialShowCompleter = Completer<bool>();

      debugPrint('🎬 Interstitial show() called');
      await _interstitialAd!.show();
      debugPrint('🎬 Interstitial show() returned (waiting for callbacks)');

      // Wait for either "showed" or "failed to show" callbacks. If neither fires,
      // treat as failure but keep a clear error marker for debugging.
      final didShow = await _interstitialShowCompleter!.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _lastInterstitialShowError = 'show_callback_timeout';
          return false;
        },
      );
      return didShow;
    } catch (e) {
      debugPrint('❌ Error showing interstitial ad: $e');
      _lastInterstitialShowError = e;
      return false;
    }
  }

  /// Show interstitial, waiting briefly for it to load if needed.
  /// This prevents "missed" interstitials when the counter threshold is reached
  /// before the ad has finished loading.
  Future<bool> showInterstitialAdWithWait({Duration timeout = const Duration(seconds: 10)}) async {
    // First try immediate show.
    final immediate = await showInterstitialAd();
    if (immediate) return true;

    // If not ready, trigger load and wait.
    ensureAdsLoaded();
    final completer = _interstitialLoadCompleter;
    if (completer != null) {
      try {
        await completer.future.timeout(timeout);
      } catch (_) {
        // timeout or other issue; continue
      }
    } else {
      // No pending load; force a new attempt.
      _interstitialLoadCompleter = Completer<bool>();
      _loadInterstitialAd();
      try {
        await _interstitialLoadCompleter!.future.timeout(timeout);
      } catch (_) {}
    }

    final afterWait = await showInterstitialAd();
    if (!afterWait && _lastInterstitialLoadError != null) {
      debugPrint('⚠️ Interstitial still not shown. Last load error: $_lastInterstitialLoadError');
    }
    return afterWait;
  }

  /// Show rewarded ad
  /// Returns true if user watched the ad fully and earned reward, false otherwise
  Future<bool> showRewardedAd({
    required Function() onRewardEarned,
    Function(String)? onError,
  }) async {
    // Paid users should never see ads (including rewarded).
    if (await _adsSuppressedByRole()) {
      onError?.call('Ads are disabled for premium users.');
      debugPrint('ℹ️ Rewarded suppressed for paid/admin user');
      return false;
    }

    if (!_isRewardedReady || _rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad not ready');
      onError?.call('Ad not ready. Please try again later.');
      // Trigger ad reload for next attempt
      ensureAdsLoaded();
      return false;
    }

    final completer = Completer<bool>();
    final ad = _rewardedAd!;
    
    // Update callbacks with completer
    _setRewardedCallbacks(ad, completer);

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('✅ User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
      
      // Wait for the completer to resolve (either reward earned or ad dismissed)
      return await completer.future;
    } catch (e) {
      debugPrint('❌ Error showing rewarded ad: $e');
      onError?.call('Failed to show ad. Please try again.');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }
  }

  /// Check if interstitial ad is ready
  bool get isInterstitialReady => _isInterstitialReady;

  /// Check if rewarded ad is ready
  bool get isRewardedReady => _isRewardedReady;

  // Debug helpers
  String get interstitialDebugStatus {
    final ready = _isInterstitialReady && _interstitialAd != null;
    final lastAttempt = _lastInterstitialLoadAttemptAt?.toIso8601String() ?? 'never';
    final lastErr = _lastInterstitialLoadError?.toString() ?? 'none';
    final lastShowErr = _lastInterstitialShowError?.toString() ?? 'none';
    final lastShowAttempt = _lastInterstitialShowAttemptAt?.toIso8601String() ?? 'never';
    final lastShown = _lastInterstitialShownAt?.toIso8601String() ?? 'never';
    return 'ready=$ready, loading=$_isLoadingInterstitial, retries=$_interstitialRetryCount, lastAttempt=$lastAttempt, lastError=$lastErr, lastShowAttempt=$lastShowAttempt, lastShown=$lastShown, lastShowError=$lastShowErr';
  }

  Future<Map<String, dynamic>> getInterstitialDebugInfo() async {
    final ready = _isInterstitialReady && _interstitialAd != null;
    final user = FirebaseAuth.instance.currentUser;
    final tokenResult = await user?.getIdTokenResult();
    final claims = tokenResult?.claims;
    final rolesClaim = claims?['roles'];
    final roles = rolesClaim is List ? rolesClaim.map((e) => e.toString()).toList() : <String>[];
    final suppressed = roles.contains('admin') || roles.contains('paidUser');

    return {
      'kDebugMode': kDebugMode,
      'forceProdAds': _forceProdAds,
      'adUnitId': _interstitialAdUnitId,
      'ready': ready,
      'loading': _isLoadingInterstitial,
      'retries': _interstitialRetryCount,
      'lastLoadAttempt': _lastInterstitialLoadAttemptAt?.toIso8601String(),
      'lastLoadError': _lastInterstitialLoadError?.toString(),
      'lastShowAttempt': _lastInterstitialShowAttemptAt?.toIso8601String(),
      'lastShown': _lastInterstitialShownAt?.toIso8601String(),
      'lastShowError': _lastInterstitialShowError?.toString(),
      'uid': user?.uid,
      'roles': roles,
      'suppressedByRole': suppressed,
    };
  }

  /// Force reload ads if they're not ready
  /// Call this when user tries to watch an ad but it's not available
  void ensureAdsLoaded() {
    if (!_isInterstitialReady && !_isLoadingInterstitial) {
      debugPrint('🔄 Force reloading interstitial ad');
      _interstitialRetryCount = 0;
      _interstitialLoadCompleter = Completer<bool>();
      _loadInterstitialAd();
    }
    if (!_isRewardedReady && !_isLoadingRewarded) {
      debugPrint('🔄 Force reloading rewarded ad');
      _rewardedRetryCount = 0;
      _loadRewardedAd();
    }
  }

  /// Dispose ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialReady = false;
    _isRewardedReady = false;
  }

  Future<bool> _adsSuppressedByRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final claims = (await user.getIdTokenResult()).claims;
      final roles = claims?['roles'];
      if (roles is List) {
        final list = roles.map((e) => e.toString()).toList();
        return list.contains('admin') || list.contains('paidUser');
      }
      return false;
    } catch (e) {
      debugPrint('Warning: could not check ad suppression role claims: $e');
      return false;
    }
  }
}

