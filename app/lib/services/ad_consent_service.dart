import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Debug-only UMP knobs (never commit real device IDs):
// - flutter run --dart-define=UMP_DEBUG_EEA=true --dart-define=UMP_TEST_DEVICE_IDS=HASH1,HASH2
const bool _umpDebugEea = bool.fromEnvironment('UMP_DEBUG_EEA', defaultValue: false);
const String _umpTestDeviceIdsCsv = String.fromEnvironment('UMP_TEST_DEVICE_IDS', defaultValue: '');

class AdConsentResult {
  final bool canRequestAds;
  final ConsentStatus consentStatus;
  final PrivacyOptionsRequirementStatus privacyOptionsRequirementStatus;
  final Object? lastError;

  /// If true, call ad loads with `AdRequest(nonPersonalizedAds: true)`.
  ///
  /// Note: When using UMP + TCF strings, the Mobile Ads SDK can also enforce
  /// personalization automatically. This flag is a conservative switch that
  /// can be used by the app logic to force NPA requests when needed.
  final bool shouldUseNonPersonalizedAds;

  const AdConsentResult({
    required this.canRequestAds,
    required this.consentStatus,
    required this.privacyOptionsRequirementStatus,
    required this.shouldUseNonPersonalizedAds,
    this.lastError,
  });
}

/// Handles EU/UK consent via Google UMP (User Messaging Platform).
///
/// This must run BEFORE requesting ads. If consent is required, a form will be
/// shown to the user.
class AdConsentService {
  AdConsentService._();

  static final AdConsentService instance = AdConsentService._();

  /// Refresh consent info and show a consent form if required.
  ///
  /// Returns an [AdConsentResult] that indicates whether ads can be requested,
  /// and whether the app should force non-personalized requests.
  Future<AdConsentResult> ensureConsent({bool tagForUnderAgeOfConsent = false}) async {
    // Consent info update uses callbacks; wrap in a Future so the rest of the app
    // can await it reliably.
    ConsentDebugSettings? debugSettings;
    if (kDebugMode && _umpDebugEea) {
      final ids = _umpTestDeviceIdsCsv
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      debugSettings = ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: ids.isEmpty ? null : ids,
      );
    }

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: tagForUnderAgeOfConsent,
      consentDebugSettings: debugSettings,
    );

    Object? lastError;

    ConsentStatus _safeStatus() => ConsentStatus.unknown;
    PrivacyOptionsRequirementStatus _safePrivacyStatus() => PrivacyOptionsRequirementStatus.unknown;

    ConsentStatus consentStatus;
    try {
      consentStatus = await ConsentInformation.instance.getConsentStatus();
    } catch (_) {
      consentStatus = _safeStatus();
    }

    final updateCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => updateCompleter.complete(),
      (FormError error) => updateCompleter.completeError(error),
    );

    try {
      await updateCompleter.future.timeout(const Duration(seconds: 12));
    } catch (e) {
      lastError = e;
      if (kDebugMode) {
        debugPrint('UMP: consent info update failed (non-fatal): $e');
      }
    }

    // Load & show form if required.
    try {
      final formCompleter = Completer<void>();
      await ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) {
        if (formError != null) {
          formCompleter.completeError(formError);
        } else {
          formCompleter.complete();
        }
      });
      await formCompleter.future.timeout(const Duration(seconds: 30));
    } catch (e) {
      lastError = e;
      if (kDebugMode) {
        debugPrint('UMP: consent form failed (non-fatal): $e');
      }
      // Fail open; UMP will keep its prior state.
    }

    // Read final statuses after the update/form cycle.
    try {
      consentStatus = await ConsentInformation.instance.getConsentStatus();
    } catch (_) {
      consentStatus = consentStatus;
    }

    PrivacyOptionsRequirementStatus privacyStatus;
    try {
      privacyStatus = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    } catch (_) {
      privacyStatus = _safePrivacyStatus();
    }

    bool canRequestAds;
    try {
      canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      lastError = e;
      if (kDebugMode) {
        debugPrint('UMP: canRequestAds check failed (non-fatal): $e');
      }
      // Be conservative: if we cannot determine, do not request ads.
      canRequestAds = false;
    }

    // Conservative NPA switch:
    // - If consent is not required, allow normal ads.
    // - If consent is obtained, allow normal ads (SDK will enforce personalization constraints via UMP/TCF).
    // - Otherwise, prefer non-personalized mode if ads can be requested.
    final shouldUseNonPersonalizedAds =
        canRequestAds && !(consentStatus == ConsentStatus.notRequired || consentStatus == ConsentStatus.obtained);

    return AdConsentResult(
      canRequestAds: canRequestAds,
      consentStatus: consentStatus,
      privacyOptionsRequirementStatus: privacyStatus,
      shouldUseNonPersonalizedAds: shouldUseNonPersonalizedAds,
      lastError: lastError,
    );
  }

  /// Show the privacy options form (if required by UMP / regulations).
  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? err) {
      if (err != null) {
        completer.completeError(err);
      } else {
        completer.complete();
      }
    });
    await completer.future.timeout(const Duration(seconds: 30));
  }

  /// Reset consent (debug/testing only). Do not expose this in production UI unless intended.
  Future<void> resetForTesting() => ConsentInformation.instance.reset();
}

