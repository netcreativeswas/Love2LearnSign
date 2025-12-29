import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:l2l_shared/tenancy/app_config.dart';

import '../l10n/dynamic_l10n.dart';
import 'apps_catalog.dart';
import 'tenant_scope.dart';

class TenantPickerPage extends StatefulWidget {
  final bool showBack;

  const TenantPickerPage({
    super.key,
    this.showBack = false,
  });

  @override
  State<TenantPickerPage> createState() => _TenantPickerPageState();
}

class _TenantPickerPageState extends State<TenantPickerPage> {
  late Future<List<AppConfigDoc>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppsCatalog().fetchAvailableApps();
  }

  Future<void> _select(AppConfigDoc app) async {
    final scope = context.read<TenantScope>();
    final uri = Uri(path: '/install', queryParameters: {'app': app.id});
    await scope.applyInstallLink(uri);
    if (!mounted) return;
    // Signal selection to caller.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final currentAppId = context.watch<TenantScope>().appId;
    final currentTenantId = context.watch<TenantScope>().tenantId;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        title: Text(S.of(context)!.tabDictionary),
      ),
      body: FutureBuilder<List<AppConfigDoc>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load editions: ${snap.error}'),
              ),
            );
          }

          final apps = snap.data ?? const [];
          if (apps.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(S.of(context)!.noResults),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final app = apps[i];
              final brand = app.brand;
              final name = app.displayName.trim().isNotEmpty ? app.displayName.trim() : app.id;
              final locales = app.uiLocales.join(', ');
              final selected = (currentAppId != null && currentAppId == app.id) ||
                  (currentAppId == null && app.tenantId.trim().isNotEmpty && app.tenantId.trim() == currentTenantId);

              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surface,
                leading: ClipRRect(
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
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            child: const Icon(Icons.language),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          child: const Icon(Icons.language),
                        ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  locales.isNotEmpty ? 'UI: $locales' : 'UI: en',
                ),
                trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.chevron_right),
                onTap: () => _select(app),
              );
            },
          );
        },
      ),
    );
  }
}


