// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:firebase_auth/firebase_auth.dart';

import '../tenancy/dashboard_tenant_scope.dart';

class MonetizationMetricsPage extends StatelessWidget {
  final bool embedded;

  const MonetizationMetricsPage({super.key, this.embedded = false});

  static const String _runId = 'post-fix-2';

  // #region agent log
  static String _uidSuffix(String uid) {
    final u = uid.trim();
    if (u.isEmpty) return '';
    return (u.length <= 6) ? u : u.substring(u.length - 6);
  }

  static void _agentLog({
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, dynamic> data,
  }) {
    try {
      final payload = {
        'sessionId': 'debug-session',
        'runId': _runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      html.window.fetch(
        'http://127.0.0.1:7243/ingest/e742e3b3-12ea-413e-9e63-f9ff4decb905',
        {
          'method': 'POST',
          'headers': {'Content-Type': 'application/json'},
          'body': jsonEncode(payload),
        },
      );
    } catch (_) {}
  }
  // #endregion

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = context.watch<DashboardTenantScope>();
    final tenantId = scope.tenantId;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // #region agent log
    _agentLog(
      hypothesisId: 'H1',
      location: 'dashboard/lib/owner/monetization_metrics_page.dart:build',
      message: 'MonetizationMetrics build',
      data: {
        'tenantId': tenantId,
        'uidPresent': uid.isNotEmpty,
        'scope_isPlatformAdmin': scope.isPlatformAdmin,
        'scope_selectedTenantRole': scope.selectedTenantRole ?? '',
        'scope_accessibleTenantCount': scope.accessibleTenantIds.length,
      },
    );
    // #endregion

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

    // Platform admin check (client-side evidence only).
    if (uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('platform')
          .doc('platform')
          .collection('members')
          .doc(uid)
          .get()
          .then((snap) {
        // #region agent log
        _agentLog(
          hypothesisId: 'H2',
          location: 'dashboard/lib/owner/monetization_metrics_page.dart:platformMemberGet',
          message: 'platform member doc fetched',
          data: {
            'uidSuffix': _uidSuffix(uid),
            'exists': snap.exists,
          },
        );
        // #endregion
      }).catchError((e) {
        // #region agent log
        _agentLog(
          hypothesisId: 'H2',
          location: 'dashboard/lib/owner/monetization_metrics_page.dart:platformMemberGet',
          message: 'platform member doc fetch failed',
          data: {
            'uidSuffix': _uidSuffix(uid),
            'error': e.toString(),
          },
        );
        // #endregion
      });

      // Also test direct get on the *current user's* entitlement doc (should be allowed even if missing).
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('entitlements')
          .doc(tenantId)
          .get()
          .then((snap) {
        // #region agent log
        _agentLog(
          hypothesisId: 'H4',
          location: 'dashboard/lib/owner/monetization_metrics_page.dart:selfEntitlementGet',
          message: 'self entitlement get ok',
          data: {
            'exists': snap.exists,
            'tenantId': tenantId,
          },
        );
        // #endregion
      }).catchError((e) {
        // #region agent log
        _agentLog(
          hypothesisId: 'H4',
          location: 'dashboard/lib/owner/monetization_metrics_page.dart:selfEntitlementGet',
          message: 'self entitlement get failed',
          data: {
            'uidSuffix': _uidSuffix(uid),
            'tenantId': tenantId,
            'error': e.toString(),
          },
        );
        // #endregion
      });
    }

    final q = FirebaseFirestore.instance
        .collectionGroup('entitlements')
        .where('tenantId', isEqualTo: tenantId)
        .where('active', isEqualTo: true);

    // #region agent log
    _agentLog(
      hypothesisId: 'H3',
      location: 'dashboard/lib/owner/monetization_metrics_page.dart:query',
      message: 'entitlements collectionGroup query created',
      data: {
        'tenantId': tenantId,
        'filters': ['tenantId==', 'active==true'],
        'uidPresent': uid.isNotEmpty,
      },
    );
    // #endregion

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
                // #region agent log
                _agentLog(
                  hypothesisId: 'H3',
                  location: 'dashboard/lib/owner/monetization_metrics_page.dart:StreamBuilder',
                  message: 'entitlements query failed',
                  data: {
                    'tenantId': tenantId,
                    'uidPresent': uid.isNotEmpty,
                    'error': snap.error.toString(),
                  },
                );
                // #endregion
              return Text('Failed to load: ${snap.error}');
            }
            final docs = snap.data?.docs ?? const [];
              // #region agent log
              _agentLog(
                hypothesisId: 'H3',
                location: 'dashboard/lib/owner/monetization_metrics_page.dart:StreamBuilder',
                message: 'entitlements query ok',
                data: {
                  'tenantId': tenantId,
                  'uidPresent': uid.isNotEmpty,
                  'count': docs.length,
                },
              );
              // #endregion
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


