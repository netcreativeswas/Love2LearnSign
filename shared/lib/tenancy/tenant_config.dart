import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_config.dart';

/// Tenant configuration document.
///
/// Recommended location: /tenants/{tenantId}
///
/// Must exist for multi-tenant rules (visibility checks).
class TenantConfigDoc {
  final String id; // tenantId
  final Map<String, dynamic> data;
  final DocumentReference<Map<String, dynamic>> ref;

  TenantConfigDoc({
    required this.id,
    required this.data,
    required this.ref,
  });

  factory TenantConfigDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    return TenantConfigDoc(
      id: snap.id,
      data: snap.data() ?? <String, dynamic>{},
      ref: snap.reference,
    );
  }

  String get displayName => (data['displayName'] ?? '').toString();
  String get visibility => (data['visibility'] ?? 'public').toString(); // public|private

  /// The default sign language content for this tenant (v1: 1 tenant = 1 sign language).
  String get signLangId => (data['signLangId'] ?? '').toString();
  String get signLangName => (data['signLangName'] ?? '').toString();

  /// Localized display name for the tenant sign language.
  ///
  /// Recommended shape:
  /// signLangNameI18n: { "en": "...", "bn": "...", "vi": "..." }
  Map<String, String> get signLangNameI18n {
    final raw = data['signLangNameI18n'];
    if (raw is Map) {
      final out = <String, String>{};
      for (final e in raw.entries) {
        final k = e.key.toString().trim().toLowerCase();
        final v = (e.value ?? '').toString().trim();
        if (k.isEmpty || v.isEmpty) continue;
        out[k] = v;
      }
      return out;
    }
    return const <String, String>{};
  }

  /// Best-effort localized label for the sign language.
  ///
  /// Fallback order:
  /// - signLangNameI18n[localeCode]
  /// - signLangName (legacy)
  /// - signLangId (stable id)
  String signLangLabelForLocale(String localeCode) {
    final code = localeCode.trim().toLowerCase();
    final i18n = signLangNameI18n;
    final localized = i18n[code];
    if (localized != null && localized.trim().isNotEmpty) return localized.trim();
    if (signLangName.trim().isNotEmpty) return signLangName.trim();
    if (signLangId.trim().isNotEmpty) return signLangId.trim();
    return '';
  }

  List<String> get uiLocales {
    final raw = data['uiLocales'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return const ['en'];
  }

  TenantBranding get brand {
    final raw = data['brand'];
    if (raw is Map) return TenantBranding.fromMap(Map<String, dynamic>.from(raw));
    return const TenantBranding();
  }
}


