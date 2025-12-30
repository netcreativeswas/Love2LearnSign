import 'package:cloud_firestore/cloud_firestore.dart';

/// Central place for multi-tenant Firestore paths.
///
/// v1 behavior (as requested):
/// - Love2Learn app uses a single default tenant for now (no tenant selector yet)
/// - We still store data in the Phase-2 schema under `tenants/{tenantId}/...`
class TenantDb {
  static const String defaultAppId = 'love2learn';
  static const String defaultTenantId = 'l2l-bdsl';
  static const String defaultSignLangId = 'bdsl';

  static CollectionReference<Map<String, dynamic>> tenants(FirebaseFirestore db) =>
      db.collection('tenants');

  static DocumentReference<Map<String, dynamic>> tenantDoc(
    FirebaseFirestore db, {
    String tenantId = defaultTenantId,
  }) =>
      tenants(db).doc(tenantId);

  static CollectionReference<Map<String, dynamic>> concepts(
    FirebaseFirestore db, {
    String tenantId = defaultTenantId,
  }) =>
      tenantDoc(db, tenantId: tenantId).collection('concepts');

  static DocumentReference<Map<String, dynamic>> conceptDoc(
    FirebaseFirestore db,
    String conceptId, {
    String tenantId = defaultTenantId,
  }) =>
      concepts(db, tenantId: tenantId).doc(conceptId);

  static DocumentReference<Map<String, dynamic>> signDoc(
    FirebaseFirestore db, {
    String tenantId = defaultTenantId,
    required String conceptId,
    String signLangId = defaultSignLangId,
  }) =>
      conceptDoc(db, conceptId, tenantId: tenantId)
          .collection('signs')
          .doc(signLangId);

  static CollectionReference<Map<String, dynamic>> searchAnalytics(
    FirebaseFirestore db, {
    String tenantId = defaultTenantId,
  }) =>
      tenantDoc(db, tenantId: tenantId).collection('searchAnalytics');

  // --- Monetization (Option A co-brand SaaS) ---
  static DocumentReference<Map<String, dynamic>> monetizationConfigDoc(
    FirebaseFirestore db, {
    String tenantId = defaultTenantId,
  }) =>
      tenantDoc(db, tenantId: tenantId).collection('monetization').doc('config');

  static CollectionReference<Map<String, dynamic>> userEntitlements(
    FirebaseFirestore db,
    String uid,
  ) =>
      db.collection('users').doc(uid).collection('entitlements');

  static DocumentReference<Map<String, dynamic>> userEntitlementDoc(
    FirebaseFirestore db, {
    required String uid,
    required String tenantId,
  }) =>
      userEntitlements(db, uid).doc(tenantId);
}


