import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../tenancy/dashboard_tenant_scope.dart';

class MonetizationConfigPage extends StatefulWidget {
  final bool embedded;

  const MonetizationConfigPage({super.key, this.embedded = false});

  @override
  State<MonetizationConfigPage> createState() => _MonetizationConfigPageState();
}

class _MonetizationConfigPageState extends State<MonetizationConfigPage> {
  final _formKey = GlobalKey<FormState>();

  // Ad units
  final _interstitialAndroid = TextEditingController();
  final _rewardedAndroid = TextEditingController();
  final _interstitialIOS = TextEditingController();
  final _rewardedIOS = TextEditingController();

  // IAP product ids (separate SKUs per tenant)
  final _monthlyAndroid = TextEditingController();
  final _yearlyAndroid = TextEditingController();
  final _monthlyIOS = TextEditingController();
  final _yearlyIOS = TextEditingController();

  // Optional payout config (business ops)
  final _partnerName = TextEditingController();
  final _payoutPercent = TextEditingController();
  final _payoutMode = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _docExists = false;
  String? _error;

  DocumentReference<Map<String, dynamic>> _docRef(String tenantId) {
    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection('monetization')
        .doc('config');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _interstitialAndroid.dispose();
    _rewardedAndroid.dispose();
    _interstitialIOS.dispose();
    _rewardedIOS.dispose();
    _monthlyAndroid.dispose();
    _yearlyAndroid.dispose();
    _monthlyIOS.dispose();
    _yearlyIOS.dispose();
    _partnerName.dispose();
    _payoutPercent.dispose();
    _payoutMode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tenantId = context.read<DashboardTenantScope>().tenantId;
    if (tenantId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No tenant selected.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _docRef(tenantId).get();
      _docExists = snap.exists;
      final data = snap.data() ?? <String, dynamic>{};
      final adUnits = (data['adUnits'] is Map) ? Map<String, dynamic>.from(data['adUnits']) : <String, dynamic>{};
      final iap = (data['iapProducts'] is Map) ? Map<String, dynamic>.from(data['iapProducts']) : <String, dynamic>{};
      final payout = (data['payout'] is Map) ? Map<String, dynamic>.from(data['payout']) : <String, dynamic>{};

      _interstitialAndroid.text = (adUnits['interstitialAndroid'] ?? '').toString();
      _rewardedAndroid.text = (adUnits['rewardedAndroid'] ?? '').toString();
      _interstitialIOS.text = (adUnits['interstitialIOS'] ?? '').toString();
      _rewardedIOS.text = (adUnits['rewardedIOS'] ?? '').toString();

      _monthlyAndroid.text = (iap['monthlyProductIdAndroid'] ?? iap['monthlyProductId'] ?? '').toString();
      _yearlyAndroid.text = (iap['yearlyProductIdAndroid'] ?? iap['yearlyProductId'] ?? '').toString();
      _monthlyIOS.text = (iap['monthlyProductIdIOS'] ?? iap['monthlyProductId'] ?? '').toString();
      _yearlyIOS.text = (iap['yearlyProductIdIOS'] ?? iap['yearlyProductId'] ?? '').toString();

      _partnerName.text = (payout['partnerName'] ?? '').toString();
      _payoutMode.text = (payout['payoutMode'] ?? '').toString();
      _payoutPercent.text = (payout['payoutPercent'] ?? '').toString();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tenantId = context.read<DashboardTenantScope>().tenantId;
    if (tenantId.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final ref = _docRef(tenantId);
      final now = FieldValue.serverTimestamp();

      final payload = <String, dynamic>{
        'adUnits': {
          'interstitialAndroid': _interstitialAndroid.text.trim(),
          'rewardedAndroid': _rewardedAndroid.text.trim(),
          'interstitialIOS': _interstitialIOS.text.trim(),
          'rewardedIOS': _rewardedIOS.text.trim(),
        },
        'iapProducts': {
          'monthlyProductIdAndroid': _monthlyAndroid.text.trim(),
          'yearlyProductIdAndroid': _yearlyAndroid.text.trim(),
          'monthlyProductIdIOS': _monthlyIOS.text.trim(),
          'yearlyProductIdIOS': _yearlyIOS.text.trim(),
        },
        'payout': {
          'partnerName': _partnerName.text.trim(),
          'payoutPercent': double.tryParse(_payoutPercent.text.trim()) ?? _payoutPercent.text.trim(),
          'payoutMode': _payoutMode.text.trim(),
        },
        'updatedAt': now,
      };
      if (!_docExists) payload['createdAt'] = now;

      await ref.set(payload, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _docExists = true;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Widget _field(TextEditingController c, String label, {String? hint}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (_) => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantScope = context.watch<DashboardTenantScope>();
    final theme = Theme.of(context);
    final tenantId = tenantScope.tenantId;

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Tenant: $tenantId', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('AdMob ad unit IDs',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _field(_interstitialAndroid, 'Interstitial (Android)'),
                    _field(_rewardedAndroid, 'Rewarded (Android)'),
                    _field(_interstitialIOS, 'Interstitial (iOS)'),
                    _field(_rewardedIOS, 'Rewarded (iOS)'),
                    const SizedBox(height: 18),
                    Text('IAP product IDs (separate SKUs per tenant)',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _field(_monthlyAndroid, 'Monthly productId (Android)'),
                    _field(_yearlyAndroid, 'Yearly productId (Android)'),
                    _field(_monthlyIOS, 'Monthly productId (iOS)'),
                    _field(_yearlyIOS, 'Yearly productId (iOS)'),
                    const SizedBox(height: 18),
                    Text('Payout (optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _field(_partnerName, 'Partner name'),
                    _field(_payoutPercent, 'Payout percent', hint: 'e.g. 30'),
                    _field(_payoutMode, 'Payout mode',
                        hint: 'manual | invoice | revenue_share'),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
              ),
            ],
          );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetization config'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: body,
    );
  }
}


