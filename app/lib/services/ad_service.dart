import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:l2l_shared/tenancy/tenant_monetization_config.dart';
import 'premium_service.dart';

// Allow testing production Ad Unit IDs in debug builds:
// flutter run/build apk --debug --dart-define=FORCE_PROD_ADS=true
const bool _forceProdAds = bool.fromEnvironment('FORCE_PROD_ADS', defaultValue: false);

/// Service for managing interstitial and rewarded ads
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _sdkInitialized = false;
  bool _nonPersonalizedAds = false;

  // Current tenant context (Option A: per-tenant ad units + per-tenant premium suppression).
  String _tenantId = TenantDb.defaultTenantId;
  TenantAdUnits _adUnits = const TenantAdUnits();
  bool _adConfigLoaded = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  Completer<bool>? _interstitialLoadCompleter;
  Completer<bool>? _rewardedLoadCompleter;
  DateTime? _lastInterstitialLoadAttemptAt;
  LoadAdError? _lastInterstitialLoadError;
  DateTime? _lastRewardedLoadAttemptAt;
  LoadAdError? _lastRewardedLoadError;
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
  static const String _prodInterstitialAdUnitIdAndroid = 'ca-app-pub-8517443606450525/7539868574';
  static const String _prodRewardedAdUnitIdAndroid = 'ca-app-pub-8517443606450525/7747768045';
  
  // Production ad unit IDs - iOS
  static const String _prodInterstitialAdUnitIdIOS = 'ca-app-pub-8517443606450525/8829765480';
  static const String _prodRewardedAdUnitIdIOS = 'ca-app-pub-8517443606450525/2452398708';

  String get _interstitialAdUnitId {
    if (kDebugMode && !_forceProdAds) {
      return _testInterstitialAdUnitId; // Always use test IDs in debug mode
    }
    // Production mode: prefer per-tenant ad unit IDs (Option A). Fallback to global IDs.
    final cfg = _adUnits;
    final fromCfg = Platform.isAndroid ? cfg.interstitialAndroid : cfg.interstitialIOS;
    if (fromCfg.trim().isNotEmpty) return fromCfg.trim();
    return Platform.isAndroid ? _prodInterstitialAdUnitIdAndroid : _prodInterstitialAdUnitIdIOS;
  }

  String get _rewardedAdUnitId {
    if (kDebugMode && !_forceProdAds) {
      return _testRewardedAdUnitId; // Always use test IDs in debug mode
    }
    // Production mode: prefer per-tenant ad unit IDs (Option A). Fallback to global IDs.
    final cfg = _adUnits;
    final fromCfg = Platform.isAndroid ? cfg.rewardedAndroid : cfg.rewardedIOS;
    if (fromCfg.trim().isNotEmpty) return fromCfg.trim();
    return Platform.isAndroid ? _prodRewardedAdUnitIdAndroid : _prodRewardedAdUnitIdIOS;
  }

  AdRequest _adRequest() => AdRequest(nonPersonalizedAds: _nonPersonalizedAds);

  /// Initialize Mobile Ads SDK
  Future<void> initialize({bool nonPersonalizedAds = false}) async {
    _nonPersonalizedAds = nonPersonalizedAds;
    if (!_sdkInitialized) {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
    }
    await _loadTenantAdConfig();
    ensureAdsLoaded();
  }

  /// Set current tenant context (Option A). Should be called when tenant changes.
  Future<void> setTenant(String tenantId) async {
    final next = tenantId.trim();
    if (next.isEmpty) return;
    if (_tenantId == next && _adConfigLoaded) return;
    _tenantId = next;
    _adConfigLoaded = false;
    await _loadTenantAdConfig();
    // Reload ads so the next requests use the correct ad unit IDs (only if SDK is initialized).
    if (_sdkInitialized) {
      dispose();
      ensureAdsLoaded();
    }
  }

  /// Update consent mode for ad requests.
  ///
  /// When enabled, ads are requested with `nonPersonalizedAds: true`.
  void setConsentMode({required bool nonPersonalizedAds}) {
    if (_nonPersonalizedAds == nonPersonalizedAds) return;
    _nonPersonalizedAds = nonPersonalizedAds;
    if (!_sdkInitialized) return;
    dispose();
    ensureAdsLoaded();
  }

  Future<void> _loadTenantAdConfig() async {
    try {
      final snap = await TenantDb.monetizationConfigDoc(
        FirebaseFirestore.instance,
        tenantId: _tenantId,
      ).get();
      if (!snap.exists) {
        _adUnits = const TenantAdUnits();
        _adConfigLoaded = true;
        return;
      }
      final cfg = TenantMonetizationConfigDoc.fromSnapshot(snap);
      _adUnits = cfg.adUnits;
      _adConfigLoaded = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to load tenant AdMob config (tenantId=$_tenantId): $e');
      }
      _adUnits = const TenantAdUnits();
      _adConfigLoaded = true;
    }
  }

  /// Load interstitial ad
  void _loadInterstitialAd() {
    if (_isLoadingInterstitial) return; // Prevent duplicate loading
    _isLoadingInterstitial = true;
    _lastInterstitialLoadAttemptAt = DateTime.now();
    _lastInterstitialLoadError = null;
    _interstitialLoadCompleter ??= Completer<bool>();
    if (kDebugMode) debugPrint('📦 Loading interstitial ad');
    
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: _adRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _isLoadingInterstitial = false;
          _interstitialRetryCount = 0; // Reset retry count on success
          _setInterstitialCallbacks(ad);
          if (kDebugMode) debugPrint('✅ Interstitial ad loaded');
          if (_interstitialLoadCompleter != null && !_interstitialLoadCompleter!.isCompleted) {
            _interstitialLoadCompleter!.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) debugPrint('❌ Interstitial ad failed to load: $error');
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
    _lastRewardedLoadAttemptAt = DateTime.now();
    _lastRewardedLoadError = null;
    _rewardedLoadCompleter ??= Completer<bool>();
    
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: _adRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          _isLoadingRewarded = false;
          _rewardedRetryCount = 0; // Reset retry count on success
          _setRewardedCallbacks(ad);
          if (kDebugMode) debugPrint('✅ Rewarded ad loaded');
          if (_rewardedLoadCompleter != null && !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _lastRewardedLoadError = error;
          if (kDebugMode) debugPrint('❌ Rewarded ad failed to load: $error');
          _isRewardedReady = false;
          _rewardedAd = null;
          _isLoadingRewarded = false;
          if (_rewardedLoadCompleter != null && !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(false);
          }
          
          // Retry with exponential backoff
          if (_rewardedRetryCount < _maxRetries) {
            _rewardedRetryCount++;
            final delay = Duration(seconds: 1 << _rewardedRetryCount); // 2, 4, 8, 16, 32s
            if (kDebugMode) {
              debugPrint('🔄 Retrying rewarded ad in ${delay.inSeconds}s (attempt $_rewardedRetryCount/$_maxRetries)');
            }
            Future.delayed(delay, () {
              // reset completer for a fresh attempt
              _rewardedLoadCompleter = Completer<bool>();
              _loadRewardedAd();
            });
          } else {
            if (kDebugMode) debugPrint('⚠️ Max retries reached for rewarded ad');
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
        if (kDebugMode) debugPrint('❌ Rewarded ad failed to show: $error');
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
    if (await _adsSuppressedForTenant()) {
      debugPrint('ℹ️ Interstitial suppressed for paid/admin user');
      _lastInterstitialShowError = 'suppressed_by_role';
      return false;
    }

    if (!_sdkInitialized) {
      debugPrint('⚠️ Interstitial requested before ads SDK initialization');
      _lastInterstitialShowError = 'sdk_not_initialized';
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
      if (kDebugMode) {
        debugPrint('⚠️ Interstitial still not shown. Last load error: $_lastInterstitialLoadError');
      }
    }
    return afterWait;
  }

  /// Show rewarded ad
  /// Returns true if user watched the ad fully and earned reward, false otherwise
  Future<bool> showRewardedAd({
    required Function() onRewardEarned,
    Function(String)? onError,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Paid users should never see ads (including rewarded).
    if (await _adsSuppressedForTenant()) {
      onError?.call('Ads are disabled for premium users.');
      if (kDebugMode) debugPrint('ℹ️ Rewarded suppressed for paid/admin user');
      return false;
    }

    if (!_sdkInitialized) {
      onError?.call('Ads are not available right now.');
      if (kDebugMode) debugPrint('⚠️ Rewarded requested before ads SDK initialization');
      return false;
    }

    if (!_isRewardedReady || _rewardedAd == null) {
      // Trigger ad load and wait briefly so we don't miss the first click.
      ensureAdsLoaded();
      final completer = _rewardedLoadCompleter;
      if (completer != null) {
        try {
          await completer.future.timeout(timeout);
        } catch (_) {
          // timeout or other issue; continue
        }
      } else {
        // No pending load; force a new attempt.
        _rewardedLoadCompleter = Completer<bool>();
        _loadRewardedAd();
        try {
          await _rewardedLoadCompleter!.future.timeout(timeout);
        } catch (_) {}
      }

      if (!_isRewardedReady || _rewardedAd == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Rewarded ad still not ready after waiting. Last load error: $_lastRewardedLoadError');
        }
        onError?.call('Ad not ready. Please try again later.');
        return false;
      }
    }

    final completer = Completer<bool>();
    final ad = _rewardedAd!;
    
    // Update callbacks with completer
    _setRewardedCallbacks(ad, completer);

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (kDebugMode) debugPrint('✅ User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
      
      // Wait for the completer to resolve (either reward earned or ad dismissed)
      return await completer.future;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error showing rewarded ad: $e');
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
    final suppressed = await _adsSuppressedForTenant();

    return {
      'kDebugMode': kDebugMode,
      'forceProdAds': _forceProdAds,
      'adUnitId': _interstitialAdUnitId,
      'tenantId': _tenantId,
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
      'suppressedByPremiumOrAdmin': suppressed,
    };
  }

  /// Force reload ads if they're not ready
  /// Call this when user tries to watch an ad but it's not available
  void ensureAdsLoaded() {
    // Never request ads unless the SDK is initialized (which should only happen
    // after UMP allows requesting ads).
    if (!_sdkInitialized) {
      if (kDebugMode) debugPrint('ℹ️ Ads SDK not initialized yet; skipping ad loads');
      return;
    }
    if (!_isInterstitialReady && !_isLoadingInterstitial) {
      if (kDebugMode) debugPrint('🔄 Force reloading interstitial ad');
      _interstitialRetryCount = 0;
      _interstitialLoadCompleter = Completer<bool>();
      _loadInterstitialAd();
    }
    if (!_isRewardedReady && !_isLoadingRewarded) {
      if (kDebugMode) debugPrint('🔄 Force reloading rewarded ad');
      _rewardedRetryCount = 0;
      _rewardedLoadCompleter = Completer<bool>();
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

  Future<bool> _adsSuppressedForTenant() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final claims = (await user.getIdTokenResult()).claims;
      final roles = claims?['roles'];
      if (roles is List) {
        final list = roles.map((e) => e.toString()).toList();
        if (list.contains('admin')) return true;
      }
      // Per-tenant premium.
      return await PremiumService().isPremiumForTenant(_tenantId);
    } catch (e) {
      debugPrint('Warning: could not check ad suppression role claims: $e');
      return false;
    }
  }
}

