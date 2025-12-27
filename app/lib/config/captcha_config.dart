/// Holds the platform-specific keys used for the on-device CAPTCHA flow.
/// Replace the default placeholders with the keys from your reCAPTCHA v2
/// integration (Android requires a SafetyNet compatible site key).
class CaptchaConfig {
  /// Android reCAPTCHA site key (SafetyNet).
  static const String androidSiteKey =
      String.fromEnvironment(
        'ANDROID_RECAPTCHA_SITE_KEY',
        defaultValue: '6LcpJhgsAAAAAGSABykrbsK6ULu7Z1-Oh-CMSCu3',
      );

  /// iOS specific site key (optional if relying on DeviceCheck).
  static const String iosSiteKey =
      String.fromEnvironment('IOS_RECAPTCHA_SITE_KEY', defaultValue: '6LcpJhgsAAAAAGSABykrbsK6ULu7Z1-Oh-CMSCu3');
}
