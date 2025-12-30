import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_tenant_scope.dart';

class TenantSwitcherPage extends StatefulWidget {
  const TenantSwitcherPage({super.key});

  @override
  State<TenantSwitcherPage> createState() => _TenantSwitcherPageState();
}

class _TenantSwitcherPageState extends State<TenantSwitcherPage> {
  late Future<List<_TenantRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_TenantRow>> _load() async {
    final scope = context.read<DashboardTenantScope>();
    final ids = scope.accessibleTenantIds;
    final db = FirebaseFirestore.instance;

    final futures = ids.map((id) async {
      try {
        final snap = await db.collection('tenants').doc(id).get();
        final data = snap.data() ?? <String, dynamic>{};
        final name = (data['displayName'] ?? '').toString().trim();
        return _TenantRow(
          tenantId: id,
          displayName: name.isNotEmpty ? name : id,
          role: scope.selectedTenantRole,
        );
      } catch (_) {
        return _TenantRow(tenantId: id, displayName: id, role: null);
      }
    }).toList();

    final rows = await Future.wait(futures);
    rows.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<DashboardTenantScope>();
    final current = scope.tenantId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose tenant'),
      ),
      body: FutureBuilder<List<_TenantRow>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data ?? const [];
          if (rows.isEmpty) {
            return const Center(child: Text('No tenant access configured.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final row = rows[i];
              final selected = row.tenantId == current;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: Theme.of(context).colorScheme.surface,
                title: Text(row.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(row.tenantId),
                trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.chevron_right),
                onTap: () async {
                  final nav = Navigator.of(context);
                  await scope.selectTenant(row.tenantId);
                  if (!mounted) return;
                  nav.pop(true);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TenantRow {
  final String tenantId;
  final String displayName;
  final String? role;
  const _TenantRow({
    required this.tenantId,
    required this.displayName,
    required this.role,
  });
}


