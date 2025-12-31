import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../tenancy/dashboard_tenant_scope.dart';

class MonetizationMetricsPage extends StatelessWidget {
  final bool embedded;

  const MonetizationMetricsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = context.watch<DashboardTenantScope>();
    final tenantId = scope.tenantId;

    if (tenantId.isEmpty) {
      final body = const Center(child: Text('No tenant selected.'));
      if (embedded) return body;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Monetization metrics'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: body,
      );
    }

    final q = FirebaseFirestore.instance
        .collectionGroup('entitlements')
        .where('tenantId', isEqualTo: tenantId)
        .where('active', isEqualTo: true);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tenant: $tenantId', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(
          'Active subscribers (from users/{uid}/entitlements/{tenantId})',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Text('Failed to load: ${snap.error}');
            }
            final docs = snap.data?.docs ?? const [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.people_alt_outlined),
                        const SizedBox(width: 10),
                        Text(
                          'Active: ${docs.length}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (docs.isNotEmpty) ...[
                  Text('Sample (first 20):', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...docs.take(20).map((d) {
                    final data = d.data();
                    final uid = (data['uid'] ?? '').toString();
                    final productId = (data['productId'] ?? '').toString();
                    final validUntil = (data['validUntil'] as Timestamp?)?.toDate();
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.verified_outlined),
                      title: Text(uid.isEmpty ? d.id : uid),
                      subtitle: Text(
                        [
                          if (productId.isNotEmpty) 'productId=$productId',
                          if (validUntil != null) 'validUntil=${validUntil.toIso8601String()}',
                        ].join(' | '),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetization metrics'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: body,
    );
  }
}


