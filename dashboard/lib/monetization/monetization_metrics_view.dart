import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:l2l_shared/tenancy/tenant_monetization_config.dart';

class MonetizationMetricsView extends StatelessWidget {
  final String tenantId;
  final bool embedded;

  const MonetizationMetricsView({
    super.key,
    required this.tenantId,
    this.embedded = false,
  });

  DocumentReference<Map<String, dynamic>> _configRef(String tenantId) {
    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('monetization')
        .doc('config');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _entitlementsStream(String tenantId) {
    return FirebaseFirestore.instance
        .collectionGroup('entitlements')
        .where('tenantId', isEqualTo: tenantId)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString().trim()) ?? 0;
  }

  static String _fmtUsd(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = tenantId.trim();
    if (t.isEmpty) {
      return const Center(child: Text('No tenant selected.'));
    }

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tenant: $t', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _configRef(t).snapshots(),
          builder: (context, cfgSnap) {
            if (cfgSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (cfgSnap.hasError) {
              return Text('Failed to load config: ${cfgSnap.error}');
            }

            final cfgDoc = cfgSnap.data;
            final cfgData = cfgDoc?.data() ?? <String, dynamic>{};
            final cfg = cfgDoc != null && cfgDoc.exists
                ? TenantMonetizationConfigDoc.fromSnapshot(cfgDoc)
                : null;

            // pricing + ads estimates (manual) from shared model
            final pricing = cfg?.pricing ?? const TenantPricing();
            final ads = cfg?.adsEstimates ?? const TenantAdsEstimates();
            final currency = (pricing.currency.trim().isEmpty ? 'USD' : pricing.currency.trim()).toUpperCase();

            // payout percent (stored by dashboard as number or string)
            final payoutRaw = (cfgData['payout'] is Map) ? Map<String, dynamic>.from(cfgData['payout']) : <String, dynamic>{};
            final payoutPercent = _asDouble(payoutRaw['payoutPercent']).clamp(0, 100);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _entitlementsStream(t),
              builder: (context, entSnap) {
                if (entSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (entSnap.hasError) {
                  return Text('Failed to load: ${entSnap.error}');
                }

                final docs = entSnap.data?.docs ?? const [];

                int monthlyCount = 0;
                int yearlyCount = 0;
                for (final d in docs) {
                  final data = d.data();
                  final st = (data['subscriptionType'] ?? '').toString().toLowerCase();
                  if (st == 'yearly') yearlyCount++;
                  if (st == 'monthly') monthlyCount++;
                }

                final subsMonthlyGross = monthlyCount * pricing.monthlyPrice;
                final subsYearlyGross = yearlyCount * pricing.yearlyPrice;
                final adsMonthlyGross = ads.monthlyGross;
                final adsYearlyGross = ads.monthlyGross * 12;

                final totalMonthlyGross = subsMonthlyGross + adsMonthlyGross;
                final totalYearlyGross = subsYearlyGross + adsYearlyGross;

                double partnerShare(double total) => total * (payoutPercent / 100.0);
                double platformShare(double total) => total - partnerShare(total);

                Widget moneyRow(String label, double total, {required bool yearly}) {
                  final totalStr = currency == 'USD' ? _fmtUsd(total) : total.toStringAsFixed(2);
                  final partner = partnerShare(total);
                  final platform = platformShare(total);
                  final partnerStr = currency == 'USD' ? _fmtUsd(partner) : partner.toStringAsFixed(2);
                  final platformStr = currency == 'USD' ? _fmtUsd(platform) : platform.toStringAsFixed(2);
                  return ListTile(
                    dense: true,
                    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      [
                        'Total: $totalStr ${currency == 'USD' ? '' : currency}',
                        'Partner (${payoutPercent.toStringAsFixed(0)}%): $partnerStr ${currency == 'USD' ? '' : currency}',
                        'Platform: $platformStr ${currency == 'USD' ? '' : currency}',
                      ].join('\n'),
                    ),
                  );
                }

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
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.monetization_on_outlined),
                            title: Text('Revenue (manual estimates)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              'Currency: $currency\n'
                              'Subs: monthly=$monthlyCount yearly=$yearlyCount\n'
                              'Prices: monthly=${pricing.monthlyPrice} yearly=${pricing.yearlyPrice}\n'
                              'Ads est.: monthly=${ads.monthlyGross}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const Divider(height: 1),
                          moneyRow('Monthly (Subscriptions + Ads)', totalMonthlyGross, yearly: false),
                          moneyRow('Yearly (Subscriptions + Ads)', totalYearlyGross, yearly: true),
                        ],
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
                        final subscriptionType = (data['subscriptionType'] ?? '').toString();
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.verified_outlined),
                          title: Text(uid.isEmpty ? d.id : uid),
                          subtitle: Text(
                            [
                              if (subscriptionType.isNotEmpty) 'type=$subscriptionType',
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
            );
          },
        ),
      ],
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetization metrics'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: content,
    );
  }
}


