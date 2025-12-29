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


