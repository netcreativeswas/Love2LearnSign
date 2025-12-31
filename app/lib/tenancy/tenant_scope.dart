import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:l2l_shared/tenancy/app_config.dart';
import 'package:l2l_shared/tenancy/tenant_config.dart';

/// Holds the currently selected tenant/app edition for the co-brand flow.
///
/// v1 behavior:
/// - If no selection exists, we default to TenantDb.defaultTenantId (current behavior).
/// - If a QR/deep link provides a tenant/app, we persist it and expose it to the app.
class TenantScope extends ChangeNotifier {
  static const _prefsTenantId = 'selected_tenant_id';
  static const _prefsAppId = 'selected_app_id';
  static const _prefsUiLocale = 'selected_ui_locale';

  String _tenantId = TenantDb.defaultTenantId;
  String? _appId;
  String? _signLangId;
  List<String> _uiLocales = const ['en'];
  AppConfigDoc? _appConfig;
  TenantConfigDoc? _tenantConfig;

  String get tenantId => _tenantId;
  String? get appId => _appId;
  String get signLangId => _signLangId ?? TenantDb.defaultSignLangId;
  List<String> get uiLocales => _uiLocales;
  AppConfigDoc? get appConfig => _appConfig;
  TenantConfigDoc? get tenantConfig => _tenantConfig;

  /// Content language for concepts (dictionary words) for this tenant.
  ///
  /// Convention:
  /// - uiLocales[0] should be 'en'
  /// - uiLocales[1] (if present) is the tenant local language (bn/vi/km/...)
  String get contentLocale {
    final locales = uiLocales
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (locales.length >= 2) return locales[1];
    return 'en';
  }

  /// Supported search locales: English + tenant local language (deduped).
  List<String> get searchLocales {
    final local = contentLocale.trim().toLowerCase();
    final out = <String>['en'];
    if (local.isNotEmpty && local != 'en') out.add(local);
    return out;
  }

  TenantScope._();

  static Future<TenantScope> create({FirebaseFirestore? firestore}) async {
    final scope = TenantScope._();
    await scope._loadFromPrefs();
    await scope.refreshFromFirestore(firestore: firestore);
    return scope;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTenant = (prefs.getString(_prefsTenantId) ?? '').trim();
    final savedApp = (prefs.getString(_prefsAppId) ?? '').trim();
    final savedLocale = (prefs.getString(_prefsUiLocale) ?? '').trim();

    if (savedTenant.isNotEmpty) _tenantId = savedTenant;
    if (savedApp.isNotEmpty) _appId = savedApp;

    // uiLocales will be updated from Firestore; we keep the saved locale as a hint only.
    if (savedLocale.isNotEmpty) {
      _uiLocales = <String>{..._uiLocales, savedLocale}.toList();
    }
  }

  Future<void> persistSelection({
    required String tenantId,
    String? appId,
    String? uiLocale,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTenantId, tenantId);
    if (appId != null && appId.trim().isNotEmpty) {
      await prefs.setString(_prefsAppId, appId.trim());
    }
    if (uiLocale != null && uiLocale.trim().isNotEmpty) {
      await prefs.setString(_prefsUiLocale, uiLocale.trim());
    }
  }

  /// Apply an install link (QR code) selection and refresh config.
  ///
  /// Supports:
  /// - /install?tenant=TENANT_ID&ui=vi
  /// - /install?app=APP_ID&ui=vi
  Future<void> applyInstallLink(
    Uri uri, {
    FirebaseFirestore? firestore,
  }) async {
    final qp = uri.queryParameters;
    final tenant = (qp['tenant'] ?? qp['tenantId'] ?? '').trim();
    final app = (qp['app'] ?? qp['appId'] ?? '').trim();
    final ui = (qp['ui'] ?? qp['locale'] ?? '').trim();

    if (tenant.isEmpty && app.isEmpty) return;

    if (app.isNotEmpty) _appId = app;
    if (tenant.isNotEmpty) _tenantId = tenant;

    await persistSelection(tenantId: _tenantId, appId: _appId, uiLocale: ui);
    await refreshFromFirestore(firestore: firestore);
    notifyListeners();
  }

  Future<void> clearSelection({FirebaseFirestore? firestore}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTenantId);
    await prefs.remove(_prefsAppId);
    await prefs.remove(_prefsUiLocale);

    _tenantId = TenantDb.defaultTenantId;
    _appId = null;
    _signLangId = null;
    _uiLocales = const ['en'];
    _appConfig = null;
    _tenantConfig = null;

    await refreshFromFirestore(firestore: firestore);
    notifyListeners();
  }

  /// Refresh app/tenant config from Firestore.
  ///
  /// This keeps branding + uiLocales + signLangId aligned with the server.
  Future<void> refreshFromFirestore({FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;

    // 1) If we have an appId, prefer /apps/{appId}
    if (_appId != null && _appId!.trim().isNotEmpty) {
      try {
        final snap = await db.collection('apps').doc(_appId).get();
        if (snap.exists) {
          final cfg = AppConfigDoc.fromSnapshot(snap);
          _appConfig = cfg;
          if (cfg.tenantId.trim().isNotEmpty) _tenantId = cfg.tenantId.trim();
          if (cfg.signLangId.trim().isNotEmpty) _signLangId = cfg.signLangId.trim();
          _uiLocales = cfg.uiLocales.isNotEmpty ? cfg.uiLocales : const ['en'];
        }
      } catch (_) {
        // non-fatal
      }
    }

    // 2) Load /tenants/{tenantId} if it exists (public tenants are readable)
    try {
      final snap = await db.collection('tenants').doc(_tenantId).get();
      if (snap.exists) {
        final cfg = TenantConfigDoc.fromSnapshot(snap);
        _tenantConfig = cfg;
        if (cfg.signLangId.trim().isNotEmpty) _signLangId = cfg.signLangId.trim();
        if (cfg.uiLocales.isNotEmpty) _uiLocales = cfg.uiLocales;
      }
    } catch (_) {
      // non-fatal
    }
  }
}


