import 'package:cloud_firestore/cloud_firestore.dart';

/// Public app/tenant discovery document.
///
/// Recommended location (public read): /apps/{appId}
///
/// Example:
/// {
///   "tenantId": "l2l-bdsl",
///   "signLangId": "bdsl",
///   "displayName": "Love to Learn Sign",
///   "poweredByEnabled": true,
///   "uiLocales": ["en", "bn"],
///   "brand": {
///     "logoUrl": "https://.../logo.png",
///     "primary": 0xFF232F34,
///     "secondary": 0xFFF9AA33
///   }
/// }
class AppConfigDoc {
  final String id; // appId
  final Map<String, dynamic> data;
  final DocumentReference<Map<String, dynamic>> ref;

  AppConfigDoc({
    required this.id,
    required this.data,
    required this.ref,
  });

  factory AppConfigDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    return AppConfigDoc(
      id: snap.id,
      data: snap.data() ?? <String, dynamic>{},
      ref: snap.reference,
    );
  }

  String get tenantId => (data['tenantId'] ?? '').toString();
  String get signLangId => (data['signLangId'] ?? '').toString();
  String get displayName => (data['displayName'] ?? '').toString();
  bool get poweredByEnabled => (data['poweredByEnabled'] is bool) ? data['poweredByEnabled'] as bool : true;

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

class TenantBranding {
  final String logoUrl;
  final int? primary; // ARGB int (e.g. 0xFF232F34)
  final int? secondary;

  const TenantBranding({
    this.logoUrl = '',
    this.primary,
    this.secondary,
  });

  factory TenantBranding.fromMap(Map<String, dynamic> map) {
    int? toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) {
        final s = v.trim();
        // Accept "0xFF..." or "#RRGGBB" / "#AARRGGBB"
        int? parsed;
        if (s.startsWith('0x')) {
          parsed = int.tryParse(s.substring(2), radix: 16);
        } else if (s.startsWith('#')) {
          parsed = int.tryParse(s.substring(1), radix: 16);
          // If user provided #RRGGBB, promote to 0xFFRRGGBB for Flutter Colors.
          if (parsed != null && s.length == 7) {
            parsed = (0xFF000000 | parsed);
          }
        } else {
          parsed = int.tryParse(s);
        }
        // If user provided RRGGBB as int, promote to 0xFFRRGGBB.
        if (parsed != null && parsed >= 0 && parsed <= 0x00FFFFFF) {
          parsed = (0xFF000000 | parsed);
        }
        return parsed;
      }
      return null;
    }

    return TenantBranding(
      logoUrl: (map['logoUrl'] ?? '').toString(),
      primary: toInt(map['primary']),
      secondary: toInt(map['secondary']),
    );
  }

  Map<String, dynamic> toMap() {
    final out = <String, dynamic>{};
    if (logoUrl.isNotEmpty) out['logoUrl'] = logoUrl;
    if (primary != null) out['primary'] = primary;
    if (secondary != null) out['secondary'] = secondary;
    return out;
  }
}


