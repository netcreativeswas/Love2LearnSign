import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import 'package:l2l_shared/utils/countries.dart' as shared_countries;

Widget _chip(
  ThemeData theme, {
  required String label,
  IconData? icon,
  Color? bg,
  Color? fg,
}) {
  final background = bg ?? theme.colorScheme.surfaceContainerHighest;
  final foreground = fg ?? theme.colorScheme.onSurface;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ],
    ),
  );
}

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

  String _roleFilter = 'all'; // all/viewer/editor/tenantadmin/owner/analyst
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

  List<String> _featureRolesFrom(Map<String, dynamic> data) {
    final v = data['featureRoles'];
    if (v is List) {
      return v
          .map((e) => (e ?? '').toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _signInProviderLabel(Map<String, dynamic> profile) {
    final p = (profile['signInProvider'] ?? profile['provider'] ?? '')
        .toString()
        .trim();
    // We only show Google vs Email per your request.
    if (p == 'google.com') return 'Google';
    if (p == 'password') return 'Email';
    if (p.isEmpty) return 'Email'; // fallback (best-effort)
    return 'Email';
  }

  IconData _hearingIcon(String hearing) {
    final h = hearing.toLowerCase().trim();
    if (h.contains('deaf')) return Icons.hearing_disabled;
    return Icons.hearing;
  }

  String _hearingLabel(String hearing) {
    final h = hearing.trim();
    if (h.isEmpty) return '';
    return h;
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
    final country =
        (profile['countryCode'] ?? profile['country'] ?? '').toString().trim();
    final hearing = (profile['hearingStatus'] ?? profile['userType'] ?? '')
        .toString()
        .trim();

    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      final hay =
          '$uid $email $name $country $hearing $role $status'.toLowerCase();
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
      if (hearing.toLowerCase().trim() != _hearingFilter!.toLowerCase().trim())
        return false;
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
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('setTenantMemberRole');
    await callable.call({
      'tenantId': widget.tenantId,
      'targetUid': uid,
      'role': role,
      'status': status,
    });
  }

  Future<void> _setAccess({
    required String uid,
    bool? jw,
    bool? premium,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('setTenantMemberAccess');
    final payload = <String, dynamic>{
      'tenantId': widget.tenantId,
      'targetUid': uid,
    };
    if (jw != null) payload['jw'] = jw;
    if (premium != null) payload['premium'] = premium;
    await callable.call(payload);
  }

  Future<void> _updateMemberProfile({
    required String uid,
    required String displayName,
    required String country,
    required String hearingStatus,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('updateTenantMemberProfile');
    await callable.call({
      'tenantId': widget.tenantId,
      'targetUid': uid,
      'displayName': displayName.trim(),
      'country': country.trim(),
      'hearingStatus': hearingStatus.trim(),
    });
  }

  Future<Map<String, dynamic>?> _refreshMemberProfileFromAuth({
    required String uid,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('refreshTenantMemberProfileFromAuth');
    final res = await callable.call({
      'tenantId': widget.tenantId,
      'targetUid': uid,
    });
    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return null;
  }

  Future<void> _showMemberDetails(
      BuildContext context, Map<String, dynamic> data) async {
    final isDesktop = L2LLayoutScope.isDashboardDesktop(context);
    final profile = _profileFrom(data);
    final billing = _billingFrom(data);
    final featureRoles = _featureRolesFrom(data);
    final uid = (data['uid'] ?? '').toString();
    final role = (data['role'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final email = (profile['email'] ?? '').toString();
    final name = (profile['displayName'] ?? '').toString();
    final country =
        (profile['countryCode'] ?? profile['country'] ?? '').toString();
    final hearing =
        (profile['hearingStatus'] ?? profile['userType'] ?? '').toString();
    final productId = (billing['productId'] ?? '').toString();
    final validUntil = billing['validUntil'];
    final premium = _isPremium(data);
    final isComplimentary = billing['isComplimentary'] == true;
    final isJw = featureRoles.contains('jw');
    final providerLabel = _signInProviderLabel(profile);

    final editor = _EditMemberDialog(
      tenantId: widget.tenantId,
      uid: uid,
      email: email,
      role: role,
      status: status,
      premium: premium,
      jw: isJw,
      complimentaryPremium: isComplimentary,
      providerLabel: providerLabel,
      initialDisplayName: name,
      initialCountry: country,
      initialHearingStatus: hearing,
      productId: productId,
      validUntil: validUntil is Timestamp ? validUntil.toDate() : null,
      onSave: (nextName, nextCountry, nextHearing) async {
        await _updateMemberProfile(
          uid: uid,
          displayName: nextName,
          country: nextCountry,
          hearingStatus: nextHearing,
        );
      },
      onSaveAccess: (nextJw, nextComplimentaryPremium) async {
        await _setAccess(
          uid: uid,
          jw: nextJw,
          premium: nextComplimentaryPremium,
        );
      },
      onRefresh: () async {
        return await _refreshMemberProfileFromAuth(uid: uid);
      },
      isBottomSheet: !isDesktop,
    );

    if (!isDesktop) {
      final theme = Theme.of(context);
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: theme.colorScheme.surface,
        builder: (sheetContext) {
          final h = MediaQuery.sizeOf(sheetContext).height;
          return SizedBox(height: h * 0.92, child: editor);
        },
      );
    }

    return showDialog<void>(
      context: context,
      builder: (_) => editor,
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
                    DropdownMenuItem(
                        value: 'tenantadmin', child: Text('tenantAdmin')),
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
                    DropdownMenuItem(
                        value: 'inactive', child: Text('inactive')),
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
                        .map((c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)))
                        .toList(),
                  ],
                  onChanged: (v) => setState(() => _countryFilter = v),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _hearingFilter,
                  hint: const Text('Hearing: all'),
                  items: const [
                    DropdownMenuItem<String?>(
                        value: null, child: Text('Hearing: all')),
                    DropdownMenuItem<String?>(
                        value: 'Hearing', child: Text('Hearing')),
                    DropdownMenuItem<String?>(
                        value: 'Deaf', child: Text('Deaf')),
                    DropdownMenuItem<String?>(
                        value: 'Hard of Hearing',
                        child: Text('Hard of Hearing')),
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
                  return Center(
                      child: Text('Failed to load members: ${snap.error}'));
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
                    final role = (data['role'] ?? 'viewer')
                        .toString()
                        .toLowerCase()
                        .trim();
                    final status = (data['status'] ?? 'active')
                        .toString()
                        .toLowerCase()
                        .trim();
                    final email = (profile['email'] ?? '').toString();
                    final name = (profile['displayName'] ?? '').toString();
                    final country =
                        (profile['countryCode'] ?? profile['country'] ?? '')
                            .toString();
                    final hearing =
                        (profile['hearingStatus'] ?? profile['userType'] ?? '')
                            .toString();
                    final premium = _isPremium(data);
                    final featureRoles = _featureRolesFrom(data);
                    final isJw = featureRoles.contains('jw');
                    final providerLabel = _signInProviderLabel(profile);
                    final isNarrow = MediaQuery.sizeOf(context).width < 520;

                    final controls = Column(
                      crossAxisAlignment: isNarrow
                          ? CrossAxisAlignment.stretch
                          : CrossAxisAlignment.end,
                      children: [
                        DropdownButton<String>(
                          isExpanded: isNarrow,
                          value: role,
                          items: const [
                            DropdownMenuItem(
                                value: 'viewer', child: Text('viewer')),
                            DropdownMenuItem(
                                value: 'analyst', child: Text('analyst')),
                            DropdownMenuItem(
                                value: 'editor', child: Text('editor')),
                            DropdownMenuItem(
                                value: 'tenantadmin',
                                child: Text('tenantAdmin')),
                            DropdownMenuItem(
                                value: 'owner', child: Text('owner')),
                          ],
                          onChanged: (v) async {
                            final next = (v ?? role).toLowerCase().trim();
                            if (next == role) return;
                            try {
                              await _setRole(
                                  uid: uid, role: next, status: status);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to set role: $e')),
                              );
                            }
                          },
                        ),
                        Row(
                          mainAxisSize:
                              isNarrow ? MainAxisSize.max : MainAxisSize.min,
                          mainAxisAlignment: isNarrow
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.end,
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
                                  await _setRole(
                                      uid: uid, role: role, status: nextStatus);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Failed to set status: $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    );

                    return InkWell(
                      onTap: () => _showMemberDetails(context, data),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.trim().isNotEmpty
                                            ? name.trim()
                                            : '(no displayName)',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          if (hearing.trim().isNotEmpty)
                                            Tooltip(
                                              message: _hearingLabel(hearing),
                                              child: Icon(
                                                _hearingIcon(hearing),
                                                size: 18,
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          _chip(
                                            theme,
                                            label:
                                                premium ? 'Premium' : 'Learner',
                                            bg: premium
                                                ? theme.colorScheme
                                                    .secondaryContainer
                                                : theme.colorScheme
                                                    .surfaceContainerHighest,
                                            fg: premium
                                                ? theme.colorScheme
                                                    .onSecondaryContainer
                                                : theme.colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                          if (isJw)
                                            _chip(
                                              theme,
                                              label: 'JW',
                                              icon: Icons.verified_user,
                                              bg: theme.colorScheme
                                                  .tertiaryContainer,
                                              fg: theme.colorScheme
                                                  .onTertiaryContainer,
                                            ),
                                          _chip(
                                            theme,
                                            label: providerLabel,
                                            icon: providerLabel == 'Google'
                                                ? Icons.g_mobiledata
                                                : Icons.email,
                                            bg: providerLabel == 'Google'
                                                ? theme.colorScheme
                                                    .primaryContainer
                                                : theme.colorScheme
                                                    .surfaceContainerHighest,
                                            fg: providerLabel == 'Google'
                                                ? theme.colorScheme
                                                    .onPrimaryContainer
                                                : theme.colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email.trim().isNotEmpty
                                            ? email.trim()
                                            : uid,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _pill(theme, 'role=$role'),
                                          _pill(theme, 'status=$status'),
                                          if (country.trim().isNotEmpty)
                                            _pill(theme, 'country=$country'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isNarrow) ...[
                                  const SizedBox(width: 12),
                                  controls,
                                ],
                              ],
                            ),
                            if (isNarrow) ...[
                              const SizedBox(height: 12),
                              controls,
                            ],
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
        style:
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EditMemberDialog extends StatefulWidget {
  final String tenantId;
  final String uid;
  final String email;
  final String role;
  final String status;
  final bool premium;
  final bool jw;
  final bool complimentaryPremium;
  final String providerLabel;
  final String initialDisplayName;
  final String initialCountry;
  final String initialHearingStatus;
  final String productId;
  final DateTime? validUntil;
  final Future<void> Function(
      String displayName, String country, String hearingStatus) onSave;
  final Future<void> Function(bool jw, bool complimentaryPremium) onSaveAccess;
  final Future<Map<String, dynamic>?> Function() onRefresh;
  final bool isBottomSheet;

  const _EditMemberDialog({
    required this.tenantId,
    required this.uid,
    required this.email,
    required this.role,
    required this.status,
    required this.premium,
    required this.jw,
    required this.complimentaryPremium,
    required this.providerLabel,
    required this.initialDisplayName,
    required this.initialCountry,
    required this.initialHearingStatus,
    required this.productId,
    required this.validUntil,
    required this.onSave,
    required this.onSaveAccess,
    required this.onRefresh,
    this.isBottomSheet = false,
  });

  @override
  State<_EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<_EditMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _country;
  String? _hearing;
  bool _jw = false;
  bool _complimentaryPremium = false;
  bool _premiumEffective = false;
  bool _saving = false;
  bool _refreshing = false;
  String _providerLabel = '';
  String _email = '';
  String _productId = '';
  DateTime? _validUntil;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialDisplayName);
    _country = widget.initialCountry.trim().isEmpty
        ? null
        : widget.initialCountry.trim();
    _hearing = widget.initialHearingStatus.trim().isEmpty
        ? null
        : widget.initialHearingStatus.trim();
    _providerLabel = widget.providerLabel;
    _email = widget.email;
    _jw = widget.jw;
    _complimentaryPremium = widget.complimentaryPremium;
    _premiumEffective = widget.premium || _complimentaryPremium;
    _productId = widget.productId;
    _validUntil = widget.validUntil;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _applyProfileFromResult(Map<String, dynamic>? res) {
    final profile = (res?['profile'] is Map)
        ? Map<String, dynamic>.from(res!['profile'] as Map)
        : <String, dynamic>{};
    final billing = (res?['billing'] is Map)
        ? Map<String, dynamic>.from(res!['billing'] as Map)
        : <String, dynamic>{};
    final displayName = (profile['displayName'] ?? '').toString().trim();
    final email = (profile['email'] ?? '').toString().trim();
    final provider = (profile['signInProvider'] ?? '').toString().trim();
    final country =
        (profile['country'] ?? profile['countryCode'] ?? '').toString().trim();
    final hearing = (profile['hearingStatus'] ?? profile['userType'] ?? '')
        .toString()
        .trim();

    if (displayName.isNotEmpty) _nameCtrl.text = displayName;
    if (country.isNotEmpty) _country = country;
    if (hearing.isNotEmpty) _hearing = hearing;
    if (email.isNotEmpty) _email = email;
    _providerLabel = provider == 'google.com' ? 'Google' : 'Email';

    // Keep premium display in sync if server returns billing.
    final isPremium = billing['isPremium'] == true;
    final isComplimentary = billing['isComplimentary'] == true;
    final productId = (billing['productId'] ?? '').toString().trim();
    final validUntil = billing['validUntil'];
    _complimentaryPremium = isComplimentary || _complimentaryPremium;
    _premiumEffective = isPremium || _complimentaryPremium;
    if (productId.isNotEmpty) _productId = productId;
    if (validUntil is Timestamp) _validUntil = validUntil.toDate();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSaveAccess(_jw, _complimentaryPremium);
      await widget.onSave(
        _nameCtrl.text.trim(),
        (_country ?? '').trim(),
        (_hearing ?? '').trim(),
      );
      if (!mounted) return;

      // Immediately pull fresh values and keep the modal open (equivalent to auto re-open).
      final res = await widget.onRefresh();
      if (!mounted) return;
      _applyProfileFromResult(res);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing || _saving) return;
    setState(() => _refreshing = true);
    try {
      final res = await widget.onRefresh();
      if (!mounted) return;
      _applyProfileFromResult(res);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshed from Auth.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premiumNow = _premiumEffective || _complimentaryPremium;

    final title = Row(
      children: [
        Expanded(
          child: Text(
            _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Member',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: premiumNow
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            premiumNow ? 'Premium' : 'Learner',
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (widget.isBottomSheet) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ],
    );

    final body = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _email.trim().isNotEmpty ? _email.trim() : widget.uid,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(theme, label: 'role=${widget.role.toLowerCase()}'),
              _chip(theme, label: 'status=${widget.status.toLowerCase()}'),
              _chip(theme,
                  label: _providerLabel,
                  icon: _providerLabel == 'Google'
                      ? Icons.g_mobiledata
                      : Icons.email),
              if (_jw) _chip(theme, label: 'JW', icon: Icons.verified_user),
              if (_complimentaryPremium)
                _chip(theme, label: 'Complimentary', icon: Icons.card_giftcard),
              if (_productId.trim().isNotEmpty)
                _chip(theme, label: _productId.trim()),
              if (_validUntil != null)
                _chip(theme, label: 'until ${_validUntil!.toIso8601String()}'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          SwitchListTile(
            title: const Text('JW access'),
            subtitle: const Text(
                'Allow access to JW-only categories/words for this tenant.'),
            value: _jw,
            onChanged: (_saving || _refreshing)
                ? null
                : (v) => setState(() => _jw = v),
          ),
          SwitchListTile(
            title: const Text('Complimentary Premium'),
            subtitle: const Text(
                'Grant premium for this tenant (no expiry). Does not remove paid subscriptions.'),
            value: _complimentaryPremium,
            onChanged: (_saving || _refreshing)
                ? null
                : (v) => setState(() {
                      _complimentaryPremium = v;
                      _premiumEffective =
                          widget.premium || _complimentaryPremium;
                    }),
          ),
          const Divider(),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Display Name is required';
                    if (s.length < 2) return 'Too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  items: shared_countries.countries
                      .map((c) =>
                          DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _country = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _hearing,
                  decoration: const InputDecoration(
                    labelText: 'Hearing Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Hearing', child: Text('Hearing')),
                    DropdownMenuItem(value: 'Deaf', child: Text('Deaf')),
                    DropdownMenuItem(
                        value: 'Hard of Hearing',
                        child: Text('Hard of Hearing')),
                  ],
                  onChanged: (v) => setState(() => _hearing = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final actions = [
      TextButton.icon(
        onPressed: _refreshing || _saving ? null : _refresh,
        icon: _refreshing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.refresh, size: 18),
        label: const Text('Refresh'),
      ),
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Save'),
      ),
    ];

    if (!widget.isBottomSheet) {
      return AlertDialog(
        title: title,
        content: SizedBox(width: 520, child: body),
        actions: actions,
      );
    }

    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 8),
            Expanded(child: body),
            const Divider(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
