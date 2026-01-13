import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles EU/UK consent via Google UMP (User Messaging Platform).
///
/// This must run BEFORE requesting ads. If consent is required, a form will be
/// shown to the user.
class AdConsentService {
  AdConsentService._();

  static final AdConsentService instance = AdConsentService._();

  /// Refresh consent info and show a consent form if required.
  ///
  /// Returns true if ads can be requested after this completes.
  Future<bool> ensureConsent({bool tagForUnderAgeOfConsent = false}) async {
    // Consent info update uses callbacks; wrap in a Future so the rest of the app
    // can await it reliably.
    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: tagForUnderAgeOfConsent,
      consentDebugSettings: null,
    );

    final updateCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => updateCompleter.complete(),
      (FormError error) => updateCompleter.completeError(error),
    );

    try {
      await updateCompleter.future.timeout(const Duration(seconds: 12));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UMP: consent info update failed (non-fatal): $e');
      }
      // Fail open: do not block the app if consent update fails.
      // We still attempt canRequestAds() below.
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
      if (kDebugMode) {
        debugPrint('UMP: consent form failed (non-fatal): $e');
      }
      // Fail open; UMP will keep its prior state.
    }

    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UMP: canRequestAds check failed (non-fatal): $e');
      }
      return true;
    }
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

