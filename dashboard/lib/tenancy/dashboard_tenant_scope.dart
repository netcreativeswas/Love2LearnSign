import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:l2l_shared/tenancy/app_config.dart';
import 'package:l2l_shared/tenancy/tenant_config.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';

class DashboardTenantScope extends ChangeNotifier {
  String _tenantId = TenantDb.defaultTenantId;
  String? _appId;
  AppConfigDoc? _appConfig;
  TenantConfigDoc? _tenantConfig;

  String get tenantId => _tenantId;
  String? get appId => _appId;
  AppConfigDoc? get appConfig => _appConfig;
  TenantConfigDoc? get tenantConfig => _tenantConfig;

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


