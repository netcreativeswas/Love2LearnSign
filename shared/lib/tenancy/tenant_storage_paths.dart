import 'tenant_db.dart';

/// Central place for multi-tenant Storage paths.
///
/// v1 behavior:
/// - We keep the existing "videos/videos_sd/videos_hd/thumbnails/flashcards" structure
/// - but namespace it under `tenants/{tenantId}/signLanguages/{signLangId}/...`
/// - We do NOT require re-uploads later; paths are future-proof now.
class TenantStoragePaths {
  static String _base({
    String tenantId = TenantDb.defaultTenantId,
    String signLangId = TenantDb.defaultSignLangId,
  }) =>
      'tenants/$tenantId/signLanguages/$signLangId';

  static String _conceptBase({
    String tenantId = TenantDb.defaultTenantId,
    String signLangId = TenantDb.defaultSignLangId,
    required String conceptId,
  }) =>
      '${_base(tenantId: tenantId, signLangId: signLangId)}/concepts/$conceptId';

  static String videosDir({
    String tenantId = TenantDb.defaultTenantId,
    String signLangId = TenantDb.defaultSignLangId,
    required String conceptId,
  }) =>
      '${_conceptBase(tenantId: tenantId, signLangId: signLangId, conceptId: conceptId)}/videos';

  static String videosSdDir({
    String tenantId = TenantDb.defaultTenantId,
    String signLangId = TenantDb.defaultSignLangId,
    required String conceptId,
  }) =>
      '${_conceptBase(tenantId: tenantId, signLangId: signLangId, conceptId: conceptId)}/videos_sd';

  static String videosHdDir({
    String tenantId = TenantDb.defaultTenantId,
    String signLangId = TenantDb.defaultSignLangId,
    required String conceptId,
  }) =>
      '${_conceptBase(tenantId: tenantId, signLangId: signLangId, conceptId: conceptId)}/videos_hd';

  static String thumbnailsDir({
    String tenantId = TenantDb.defaultTenantId,
    String signLangId = TenantDb.defaultSignLangId,
    required String conceptId,
  }) =>
      '${_conceptBase(tenantId: tenantId, signLangId: signLangId, conceptId: conceptId)}/thumbnails';

  static String flashcardsDir({
    String tenantId = TenantDb.defaultTenantId,
    String signLangId = TenantDb.defaultSignLangId,
    required String conceptId,
  }) =>
      '${_conceptBase(tenantId: tenantId, signLangId: signLangId, conceptId: conceptId)}/flashcards';
}


