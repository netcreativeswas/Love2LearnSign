import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:l2l_shared/tenancy/app_config.dart';
import 'package:l2l_shared/tenancy/tenant_config.dart';

import '../locale_provider.dart';
import '../tenancy/apps_catalog.dart';
import '../tenancy/tenant_config_loader.dart';
import '../tenancy/tenant_scope.dart';

class SignLanguageSettingsPage extends StatefulWidget {
  const SignLanguageSettingsPage({super.key});

  @override
  State<SignLanguageSettingsPage> createState() => _SignLanguageSettingsPageState();
}

class _SignLanguageSettingsData {
  final List<AppConfigDoc> apps;
  final Map<String, TenantConfigDoc> tenants;

  const _SignLanguageSettingsData({
    required this.apps,
    required this.tenants,
  });
}

class _SignLanguageSettingsPageState extends State<SignLanguageSettingsPage> {
  late Future<_SignLanguageSettingsData> _future;
  String? _selectedAppId;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SignLanguageSettingsData> _load() async {
    final apps = await AppsCatalog().fetchAvailableApps();
    final tenantIds = apps.map((a) => a.tenantId.trim()).where((s) => s.isNotEmpty);
    final tenants = await TenantConfigLoader.fetchByIds(FirebaseFirestore.instance, tenantIds);
    return _SignLanguageSettingsData(apps: apps, tenants: tenants);
  }

  String _labelFor(AppConfigDoc app, Map<String, TenantConfigDoc> tenants) {
    final tenantId = app.tenantId.trim();
    final t = tenants[tenantId];
    if (t != null) {
      final uiCode = Localizations.localeOf(context).languageCode;
      final label = t.signLangLabelForLocale(uiCode).trim();
      if (label.isNotEmpty) return label;
    }
    if (app.signLangId.trim().isNotEmpty) return app.signLangId.trim();
    if (tenantId.isNotEmpty) return tenantId;
    return app.id;
  }

  Future<void> _applySelection(String appId) async {
    if (_applying) return;
    setState(() => _applying = true);

    // Blocking transition.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Changing sign language and interface language…',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final scope = context.read<TenantScope>();
      // Force UI locale default to English for the new tenant.
      final uri = Uri(path: '/install', queryParameters: {'app': appId, 'ui': 'en'});
      await scope.applyInstallLink(uri);
      if (!mounted) return;

      // Ensure English becomes the selected UI language (allowed locales will be synced from tenant config).
      context.read<LocaleProvider>().setLocale(const Locale('en'));

      // Close dialog
      Navigator.of(context).pop();
      // Return success to caller
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      // Close dialog
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change sign language. Please try again.')),
      );
      setState(() => _applying = false);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentAppId = context.watch<TenantScope>().appId;
    final currentTenantId = context.watch<TenantScope>().tenantId;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign language')),
      body: FutureBuilder<_SignLanguageSettingsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load sign languages: ${snap.error}'),
              ),
            );
          }

          final data = snap.data;
          final apps = data?.apps ?? const [];
          final tenants = data?.tenants ?? const <String, TenantConfigDoc>{};
          if (apps.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No sign languages available.'),
              ),
            );
          }

          // Initialize selection once we have data.
          _selectedAppId ??= (currentAppId != null && currentAppId.trim().isNotEmpty)
              ? currentAppId
              : apps.firstWhere(
                  (a) => a.tenantId.trim().isNotEmpty && a.tenantId.trim() == currentTenantId,
                  orElse: () => apps.first,
                ).id;

          final canApply = !_applying &&
              _selectedAppId != null &&
              _selectedAppId!.trim().isNotEmpty &&
              (_selectedAppId != currentAppId);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change sign language',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This changes the dictionary and videos. The interface language will reset to English.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final app = apps[i];
                    final brand = app.brand;
                    final label = _labelFor(app, tenants);
                    final selected = _selectedAppId == app.id;
                    final locales = app.uiLocales.join(', ');

                    return Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _applying ? null : () => setState(() => _selectedAppId = app.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (brand.logoUrl.trim().isNotEmpty)
                                    ? Image.network(
                                        brand.logoUrl.trim(),
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 44,
                                          height: 44,
                                          color: scheme.primary.withValues(alpha: 0.12),
                                          child: const Icon(Icons.language),
                                        ),
                                      )
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        color: scheme.primary.withValues(alpha: 0.12),
                                        child: const Icon(Icons.language),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      locales.isNotEmpty ? 'UI: $locales' : 'UI: en',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: scheme.onSurface.withValues(alpha: 0.70),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: app.id,
                                groupValue: _selectedAppId,
                                onChanged: _applying ? null : (v) => setState(() => _selectedAppId = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canApply ? () => _applySelection(_selectedAppId!.trim()) : null,
                      child: Text(_applying ? 'Applying…' : 'Apply'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


