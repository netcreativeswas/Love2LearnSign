import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import 'package:l2l_shared/utils/countries.dart' as shared_countries;

class TenantAdminPanelPage extends StatefulWidget {
  final String tenantId;

  const TenantAdminPanelPage({
    super.key,
    required this.tenantId,
  });

  @override
  State<TenantAdminPanelPage> createState() => _TenantAdminPanelPageState();
}

class _TenantAdminPanelPageState extends State<TenantAdminPanelPage> {
  final _searchController = TextEditingController();
  String _search = '';

  String _roleFilter = 'all'; // all/viewer/editor/admin/owner/analyst
  String _statusFilter = 'all'; // all/active/inactive
  String? _countryFilter; // null == all
  String? _hearingFilter; // null == all
  String _dateRange = 'all'; // all/today/7/30/90
  String _premiumFilter = 'all'; // all/premium/free

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _profileFrom(Map<String, dynamic> data) {
    final p = data['profile'];
    if (p is Map) return Map<String, dynamic>.from(p as Map);
    return const {};
  }

  Map<String, dynamic> _billingFrom(Map<String, dynamic> data) {
    final b = data['billing'];
    if (b is Map) return Map<String, dynamic>.from(b as Map);
    return const {};
  }

  bool _isPremium(Map<String, dynamic> data) {
    final billing = _billingFrom(data);
    final isPremiumFlag = billing['isPremium'] == true;
    final validUntil = billing['validUntil'];
    if (!isPremiumFlag) return false;
    if (validUntil is Timestamp) {
      return DateTime.now().isBefore(validUntil.toDate());
    }
    return true;
  }

  bool _inDateRange(Map<String, dynamic> data) {
    if (_dateRange == 'all') return true;
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) return false;
    final dt = createdAt.toDate();
    final now = DateTime.now();

    if (_dateRange == 'today') {
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }

    final days = int.tryParse(_dateRange);
    if (days == null) return true;
    return dt.isAfter(now.subtract(Duration(days: days)));
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    final profile = _profileFrom(data);

    final uid = (data['uid'] ?? '').toString();
    final role = (data['role'] ?? '').toString().toLowerCase().trim();
    final status = (data['status'] ?? 'active').toString().toLowerCase().trim();
    final email = (profile['email'] ?? '').toString().toLowerCase().trim();
    final name = (profile['displayName'] ?? '').toString().toLowerCase().trim();
    final country = (profile['countryCode'] ?? profile['country'] ?? '').toString().trim();
    final hearing = (profile['hearingStatus'] ?? profile['userType'] ?? '').toString().trim();

    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      final hay = '$uid $email $name $country $hearing $role $status'.toLowerCase();
      if (!hay.contains(q)) return false;
    }

    if (_roleFilter != 'all') {
      if (role != _roleFilter) return false;
    }

    if (_statusFilter != 'all') {
      if (status != _statusFilter) return false;
    }

    if (_countryFilter != null && _countryFilter!.trim().isNotEmpty) {
      if (country != _countryFilter) return false;
    }

    if (_hearingFilter != null && _hearingFilter!.trim().isNotEmpty) {
      if (hearing.toLowerCase().trim() != _hearingFilter!.toLowerCase().trim()) return false;
    }

    if (_premiumFilter == 'premium' && !_isPremium(data)) return false;
    if (_premiumFilter == 'free' && _isPremium(data)) return false;

    if (!_inDateRange(data)) return false;
    return true;
  }

  Future<void> _setRole({
    required String uid,
    required String role,
    required String status,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('setTenantMemberRole');
    await callable.call({
      'tenantId': widget.tenantId,
      'targetUid': uid,
      'role': role,
      'status': status,
    });
  }

  Future<void> _showMemberDetails(BuildContext context, Map<String, dynamic> data) async {
    final profile = _profileFrom(data);
    final billing = _billingFrom(data);
    final uid = (data['uid'] ?? '').toString();
    final role = (data['role'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final email = (profile['email'] ?? '').toString();
    final name = (profile['displayName'] ?? '').toString();
    final country = (profile['countryCode'] ?? profile['country'] ?? '').toString();
    final hearing = (profile['hearingStatus'] ?? profile['userType'] ?? '').toString();
    final productId = (billing['productId'] ?? '').toString();
    final validUntil = billing['validUntil'];

    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Member'),
        content: SingleChildScrollView(
          child: SelectableText(
            [
              'tenantId: ${widget.tenantId}',
              'uid: $uid',
              'displayName: $name',
              'email: $email',
              'country: $country',
              'hearingStatus: $hearing',
              'role: $role',
              'status: $status',
              'premium: ${_isPremium(data)}',
              if (productId.isNotEmpty) 'productId: $productId',
              if (validUntil is Timestamp) 'validUntil: ${validUntil.toDate().toIso8601String()}',
            ].where((l) => l.trim().isNotEmpty).join('\n'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = L2LLayoutScope.isDashboardDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Admin Panel')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search (name, email, country, uid)...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _roleFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Role: all')),
                    DropdownMenuItem(value: 'viewer', child: Text('viewer')),
                    DropdownMenuItem(value: 'analyst', child: Text('analyst')),
                    DropdownMenuItem(value: 'editor', child: Text('editor')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                    DropdownMenuItem(value: 'owner', child: Text('owner')),
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Status: all')),
                    DropdownMenuItem(value: 'active', child: Text('active')),
                    DropdownMenuItem(value: 'inactive', child: Text('inactive')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _premiumFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Premium: all')),
                    DropdownMenuItem(value: 'premium', child: Text('premium')),
                    DropdownMenuItem(value: 'free', child: Text('free')),
                  ],
                  onChanged: (v) => setState(() => _premiumFilter = v ?? 'all'),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _dateRange,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Date: all')),
                    DropdownMenuItem(value: 'today', child: Text('today')),
                    DropdownMenuItem(value: '7', child: Text('last 7 days')),
                    DropdownMenuItem(value: '30', child: Text('last 30 days')),
                    DropdownMenuItem(value: '90', child: Text('last 90 days')),
                  ],
                  onChanged: (v) => setState(() => _dateRange = v ?? 'all'),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _countryFilter,
                  hint: const Text('Country: all'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Country: all'),
                    ),
                    ...shared_countries.countries
                        .map((c) => DropdownMenuItem<String?>(value: c, child: Text(c)))
                        .toList(),
                  ],
                  onChanged: (v) => setState(() => _countryFilter = v),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _hearingFilter,
                  hint: const Text('Hearing: all'),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Hearing: all')),
                    DropdownMenuItem<String?>(value: 'Hearing', child: Text('Hearing')),
                    DropdownMenuItem<String?>(value: 'Deaf', child: Text('Deaf')),
                    DropdownMenuItem<String?>(value: 'Hard of Hearing', child: Text('Hard of Hearing')),
                  ],
                  onChanged: (v) => setState(() => _hearingFilter = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tenants')
                  .doc(widget.tenantId)
                  .collection('members')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Failed to load members: ${snap.error}'));
                }

                final docs = snap.data?.docs ?? const [];
                final members = <QueryDocumentSnapshot>[];
                for (final d in docs) {
                  final data = (d.data() as Map<String, dynamic>?) ?? {};
                  if (_matchesFilters(data)) members.add(d);
                }

                if (members.isEmpty) {
                  return const Center(child: Text('No members found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = members[i];
                    final data = (doc.data() as Map<String, dynamic>?) ?? {};
                    final profile = _profileFrom(data);
                    final uid = (data['uid'] ?? doc.id).toString();
                    final role = (data['role'] ?? 'viewer').toString().toLowerCase().trim();
                    final status = (data['status'] ?? 'active').toString().toLowerCase().trim();
                    final email = (profile['email'] ?? '').toString();
                    final name = (profile['displayName'] ?? '').toString();
                    final country = (profile['countryCode'] ?? profile['country'] ?? '').toString();
                    final hearing = (profile['hearingStatus'] ?? profile['userType'] ?? '').toString();
                    final premium = _isPremium(data);

                    return InkWell(
                      onTap: () => _showMemberDetails(context, data),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.trim().isNotEmpty ? name.trim() : '(no displayName)',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email.trim().isNotEmpty ? email.trim() : uid,
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _pill(theme, 'role=$role'),
                                          _pill(theme, 'status=$status'),
                                          if (country.trim().isNotEmpty) _pill(theme, 'country=$country'),
                                          if (hearing.trim().isNotEmpty) _pill(theme, 'hearing=$hearing'),
                                          if (premium) _pill(theme, 'premium', color: theme.colorScheme.secondaryContainer),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    DropdownButton<String>(
                                      value: role,
                                      items: const [
                                        DropdownMenuItem(value: 'viewer', child: Text('viewer')),
                                        DropdownMenuItem(value: 'analyst', child: Text('analyst')),
                                        DropdownMenuItem(value: 'editor', child: Text('editor')),
                                        DropdownMenuItem(value: 'admin', child: Text('admin')),
                                        DropdownMenuItem(value: 'owner', child: Text('owner')),
                                      ],
                                      onChanged: (v) async {
                                        final next = (v ?? role).toLowerCase().trim();
                                        if (next == role) return;
                                        try {
                                          await _setRole(uid: uid, role: next, status: status);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to set role: $e')),
                                          );
                                        }
                                      },
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Active',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Switch(
                                          value: status == 'active',
                                          onChanged: (v) async {
                                            final nextStatus = v ? 'active' : 'inactive';
                                            try {
                                              await _setRole(uid: uid, role: role, status: nextStatus);
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to set status: $e')),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(ThemeData theme, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}


