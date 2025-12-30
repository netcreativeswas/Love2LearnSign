// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:l2l_shared/tenancy/app_config.dart';
import 'package:l2l_shared/tenancy/tenant_config.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'dart:html' as html;

class TenantAccess {
  final String role;
  final String status;
  const TenantAccess({required this.role, required this.status});
}

class DashboardTenantScope extends ChangeNotifier {
  String _tenantId = TenantDb.defaultTenantId;
  String? _appId;
  AppConfigDoc? _appConfig;
  TenantConfigDoc? _tenantConfig;

  bool _accessLoaded = false;
  final Map<String, TenantAccess> _accessibleTenants = {};
  String? _selectedTenantRole;
  bool _isPlatformAdmin = false;

  String get tenantId => _tenantId;
  String? get appId => _appId;
  AppConfigDoc? get appConfig => _appConfig;
  TenantConfigDoc? get tenantConfig => _tenantConfig;
  bool get accessLoaded => _accessLoaded;
  bool get isPlatformAdmin => _isPlatformAdmin;
  List<String> get accessibleTenantIds => _accessibleTenants.keys.toList()..sort();
  String? get selectedTenantRole => _selectedTenantRole;

  String get signLangId {
    final a = _appConfig?.signLangId.trim() ?? '';
    if (a.isNotEmpty) return a;
    final t = _tenantConfig?.signLangId.trim() ?? '';
    if (t.isNotEmpty) return t;
    return TenantDb.defaultSignLangId;
  }

  String get displayName {
    final a = _appConfig?.displayName.trim() ?? '';
    if (a.isNotEmpty) return a;
    final t = _tenantConfig?.displayName.trim() ?? '';
    if (t.isNotEmpty) return t;
    return 'Love to Learn Sign Dashboard';
  }

  TenantBranding get brand {
    final a = _appConfig?.brand;
    if (a != null) return a;
    final t = _tenantConfig?.brand;
    if (t != null) return t;
    return const TenantBranding();
  }

  DashboardTenantScope._();

  static Future<DashboardTenantScope> create({FirebaseFirestore? firestore}) async {
    final scope = DashboardTenantScope._();
    await scope._loadFromUrl();
    scope._loadFromLocalStorage();
    await scope.refreshFromFirestore(firestore: firestore);
    return scope;
  }

  Future<void> _loadFromUrl() async {
    final qp = Uri.base.queryParameters;
    final tenant = (qp['tenant'] ?? qp['tenantId'] ?? '').trim();
    final app = (qp['app'] ?? qp['appId'] ?? '').trim();
    if (app.isNotEmpty) _appId = app;
    if (tenant.isNotEmpty) _tenantId = tenant;
  }

  static const String _lsTenantId = 'dashboard_selected_tenant_id';

  void _loadFromLocalStorage() {
    if (!kIsWeb) return;
    final saved = (html.window.localStorage[_lsTenantId] ?? '').trim();
    if (saved.isNotEmpty) {
      _tenantId = saved;
    }
  }

  Future<void> _saveTenantToLocalStorage(String tenantId) async {
    if (!kIsWeb) return;
    html.window.localStorage[_lsTenantId] = tenantId;
  }

  Future<void> loadAccessForUser(String uid, {FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;
    _accessLoaded = false;
    _accessibleTenants.clear();
    _selectedTenantRole = null;
    notifyListeners();

    // 1) Load userTenants/{uid}
    try {
      final snap = await db.collection('userTenants').doc(uid).get();
      final data = snap.data() ?? <String, dynamic>{};
      final tenants = data['tenants'];
      if (tenants is Map) {
        for (final e in tenants.entries) {
          final tenantId = e.key.toString().trim();
          if (tenantId.isEmpty) continue;
          final v = e.value;
          if (v is Map) {
            final role = (v['role'] ?? '').toString().trim();
            final status = (v['status'] ?? 'active').toString().trim();
            _accessibleTenants[tenantId] = TenantAccess(role: role, status: status);
          } else {
            _accessibleTenants[tenantId] = const TenantAccess(role: 'viewer', status: 'active');
          }
        }
      }
    } catch (e) {
      // If this fails (e.g., rules not deployed yet), treat as no access.
    }

    // 2) Determine platform admin (best-effort).
    _isPlatformAdmin = false;
    try {
      final platformSnap = await db.collection('platform').doc('platform').collection('members').doc(uid).get();
      _isPlatformAdmin = platformSnap.exists;
    } catch (e) {
      _isPlatformAdmin = false;
    }

    // 3) Choose initial tenant:
    // - URL override already loaded into _tenantId
    // - else localStorage loaded into _tenantId
    // If the chosen tenant isn't in accessible list, pick:
    // - if 1 tenant: auto
    // - else: leave as-is and let UI prompt.
    final ids = accessibleTenantIds;
    if (ids.isNotEmpty && !_accessibleTenants.containsKey(_tenantId)) {
      if (ids.length == 1) {
        _tenantId = ids.first;
        await _saveTenantToLocalStorage(_tenantId);
      }
    }

    _selectedTenantRole = _accessibleTenants[_tenantId]?.role;

    // 4) Load tenant/app configs for branding + signLangId.
    await refreshFromFirestore(firestore: db);

    _accessLoaded = true;
    notifyListeners();
  }

  bool get needsTenantPick {
    final ids = accessibleTenantIds;
    if (ids.length < 2) return false;
    return !_accessibleTenants.containsKey(_tenantId);
  }

  Future<void> selectTenant(String tenantId, {FirebaseFirestore? firestore}) async {
    final t = tenantId.trim();
    if (t.isEmpty) return;
    _tenantId = t;
    _selectedTenantRole = _accessibleTenants[_tenantId]?.role;
    await _saveTenantToLocalStorage(_tenantId);
    await refreshFromFirestore(firestore: firestore);
    notifyListeners();
  }

  Future<void> refreshFromFirestore({FirebaseFirestore? firestore}) async {
    final db = firestore ?? FirebaseFirestore.instance;

    if (_appId != null && _appId!.trim().isNotEmpty) {
      try {
        final snap = await db.collection('apps').doc(_appId).get();
        if (snap.exists) {
          final cfg = AppConfigDoc.fromSnapshot(snap);
          _appConfig = cfg;
          if (cfg.tenantId.trim().isNotEmpty) _tenantId = cfg.tenantId.trim();
        }
      } catch (_) {}
    }

    try {
      final snap = await db.collection('tenants').doc(_tenantId).get();
      if (snap.exists) {
        _tenantConfig = TenantConfigDoc.fromSnapshot(snap);
      }
    } catch (_) {}
  }

  ThemeData themeFor(Brightness brightness) {
    final b = brand;
    final primary = b.primary != null ? Color(b.primary!) : const Color(0xFF232F34);
    final secondary = b.secondary != null ? Color(b.secondary!) : const Color(0xFFF9AA33);

    Color onFor(Color c) =>
        (ThemeData.estimateBrightnessForColor(c) == Brightness.dark) ? Colors.white : const Color(0xFF232F34);

    var scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
      primary: primary,
      onPrimary: onFor(primary),
      secondary: secondary,
      onSecondary: onFor(secondary),
    );

    final baseText = Typography.material2021().black.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: (brightness == Brightness.dark) ? const Color(0xFF181B1F) : const Color(0xFFE4E1DD),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary),
        actionsIconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      textTheme: baseText.copyWith(
        titleLarge: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: scheme.onSurface),
        bodySmall: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
    );
  }
}


