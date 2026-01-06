import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

  late Future<_MemberStats> _statsFuture;
  final _numFmt = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadMemberStats();
  }

  CollectionReference<Map<String, dynamic>> _membersRef() {
    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .collection('members');
  }

  Future<int> _countMembers({DateTime? start, DateTime? endExclusive}) async {
    Query<Map<String, dynamic>> q = _membersRef();
    if (start != null) {
      q = q.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (endExclusive != null) {
      q = q.where('createdAt', isLessThan: Timestamp.fromDate(endExclusive));
    }
    final agg = await q.count().get();
    return agg.count ?? 0;
  }

  Future<_MemberStats> _loadMemberStats() async {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final startTomorrow = startToday.add(const Duration(days: 1));

    // Rolling windows (inclusive of today using day boundaries).
    final start7 = startToday.subtract(const Duration(days: 6));
    final startPrev7 = start7.subtract(const Duration(days: 7));
    final start30 = startToday.subtract(const Duration(days: 29));

    // Calendar months.
    final startThisMonth = DateTime(now.year, now.month, 1);
    final startLastMonth =
        (now.month == 1) ? DateTime(now.year - 1, 12, 1) : DateTime(now.year, now.month - 1, 1);

    final totalFuture = _countMembers();
    final todayFuture = _countMembers(start: startToday, endExclusive: startTomorrow);
    final last7Future = _countMembers(start: start7, endExclusive: startTomorrow);
    final prev7Future = _countMembers(start: startPrev7, endExclusive: start7);
    final last30Future = _countMembers(start: start30, endExclusive: startTomorrow);
    final thisMonthFuture = _countMembers(start: startThisMonth, endExclusive: startTomorrow);
    final lastMonthFuture = _countMembers(start: startLastMonth, endExclusive: startThisMonth);

    final res = await Future.wait<int>([
      totalFuture,
      todayFuture,
      last7Future,
      prev7Future,
      last30Future,
      thisMonthFuture,
      lastMonthFuture,
    ]);

    final total = res[0];
    final today = res[1];
    final last7 = res[2];
    final prev7 = res[3];
    final last30 = res[4];
    final thisMonth = res[5];
    final lastMonth = res[6];

    final trend7 = _Trend.from(current: last7, previous: prev7);

    return _MemberStats(
      tenantId: widget.tenantId,
      total: total,
      today: today,
      last7: last7,
      last30: last30,
      thisMonth: thisMonth,
      lastMonth: lastMonth,
      trend7: trend7,
    );
  }

  void _refreshStats() {
    setState(() => _statsFuture = _loadMemberStats());
  }

  String _fmtCount(int v) => _numFmt.format(v);

  Widget _statCard(
    ThemeData theme, {
    required String label,
    required String value,
    String? hint,
    IconData? icon,
    Color? tint,
  }) {
    final scheme = theme.colorScheme;
    final bg = tint != null ? tint.withValues(alpha: 0.10) : scheme.surfaceContainerHighest;
    final fg = tint ?? scheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.80),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (hint != null && hint.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hint.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Members overview',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tenant: ${widget.tenantId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh stats',
                  onPressed: _refreshStats,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<_MemberStats>(
              future: _statsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Failed to load stats: ${snap.error}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                final s = snap.data;
                if (s == null) {
                  return const SizedBox.shrink();
                }

                final tiles = <Widget>[
                  _statCard(
                    theme,
                    label: 'Total members',
                    value: _fmtCount(s.total),
                    icon: Icons.group_outlined,
                    tint: scheme.primary,
                  ),
                  _statCard(
                    theme,
                    label: 'New today',
                    value: _fmtCount(s.today),
                    icon: Icons.today_outlined,
                    tint: scheme.secondary,
                  ),
                  _statCard(
                    theme,
                    label: 'Last 7 days',
                    value: _fmtCount(s.last7),
                    hint: s.trend7.label,
                    icon: Icons.date_range_outlined,
                    tint: scheme.tertiary,
                  ),
                  _statCard(
                    theme,
                    label: 'Last 30 days',
                    value: _fmtCount(s.last30),
                    icon: Icons.calendar_view_month_outlined,
                  ),
                  _statCard(
                    theme,
                    label: 'This month',
                    value: _fmtCount(s.thisMonth),
                    icon: Icons.event_available_outlined,
                  ),
                  _statCard(
                    theme,
                    label: 'Last month',
                    value: _fmtCount(s.lastMonth),
                    icon: Icons.history_outlined,
                  ),
                ];

                return LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final cols = w < 420 ? 2 : (w < 860 ? 3 : 6);
                    const gap = 12.0;
                    final tileWidth = (w - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: tiles
                          .map((t) => SizedBox(width: tileWidth, child: t))
                          .toList(growable: false),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFiltersSheet() async {
    final theme = Theme.of(context);
    final roleItems = const [
      DropdownMenuItem(value: 'all', child: Text('Role: all')),
      DropdownMenuItem(value: 'viewer', child: Text('viewer')),
      DropdownMenuItem(value: 'analyst', child: Text('analyst')),
      DropdownMenuItem(value: 'editor', child: Text('editor')),
      DropdownMenuItem(value: 'tenantadmin', child: Text('tenantAdmin')),
      DropdownMenuItem(value: 'owner', child: Text('owner')),
    ];
    final statusItems = const [
      DropdownMenuItem(value: 'all', child: Text('Status: all')),
      DropdownMenuItem(value: 'active', child: Text('active')),
      DropdownMenuItem(value: 'inactive', child: Text('inactive')),
    ];
    final premiumItems = const [
      DropdownMenuItem(value: 'all', child: Text('Premium: all')),
      DropdownMenuItem(value: 'premium', child: Text('premium')),
      DropdownMenuItem(value: 'free', child: Text('free')),
    ];
    final dateItems = const [
      DropdownMenuItem(value: 'all', child: Text('Date: all')),
      DropdownMenuItem(value: 'today', child: Text('today')),
      DropdownMenuItem(value: '7', child: Text('last 7 days')),
      DropdownMenuItem(value: '30', child: Text('last 30 days')),
      DropdownMenuItem(value: '90', child: Text('last 90 days')),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            void update(VoidCallback fn) {
              setState(fn);
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16 + MediaQuery.viewInsetsOf(sheetCtx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filters',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _roleFilter,
                    items: roleItems,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => update(() => _roleFilter = v ?? 'all'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _statusFilter,
                    items: statusItems,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => update(() => _statusFilter = v ?? 'all'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _premiumFilter,
                    items: premiumItems,
                    decoration: const InputDecoration(
                      labelText: 'Premium',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => update(() => _premiumFilter = v ?? 'all'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _dateRange,
                    items: dateItems,
                    decoration: const InputDecoration(
                      labelText: 'Date range',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => update(() => _dateRange = v ?? 'all'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _countryFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Country: all'),
                      ),
                      ...shared_countries.countries
                          .map((c) => DropdownMenuItem<String?>(value: c, child: Text(c)))
                          .toList(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => update(() => _countryFilter = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _hearingFilter,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Hearing: all'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Hearing',
                        child: Text('Hearing'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Deaf',
                        child: Text('Deaf'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Hard of Hearing',
                        child: Text('Hard of Hearing'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Hearing',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => update(() => _hearingFilter = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          update(() {
                            _roleFilter = 'all';
                            _statusFilter = 'all';
                            _premiumFilter = 'all';
                            _dateRange = 'all';
                            _countryFilter = null;
                            _hearingFilter = null;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _profileFrom(Map<String, dynamic> data) {
    final p = data['profile'];
    if (p is Map) return Map<String, dynamic>.from(p);
    return const {};
  }

  Map<String, dynamic> _billingFrom(Map<String, dynamic> data) {
    final b = data['billing'];
    if (b is Map) return Map<String, dynamic>.from(b);
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

  String _countryFlagEmoji(String countryOrCode) {
    final s = countryOrCode.trim();
    if (s.length == 2) {
      final upper = s.toUpperCase();
      final a = upper.codeUnitAt(0);
      final b = upper.codeUnitAt(1);
      // A-Z only
      if (a >= 65 && a <= 90 && b >= 65 && b <= 90) {
        const base = 0x1F1E6; // regional indicator A
        final first = base + (a - 65);
        final second = base + (b - 65);
        return String.fromCharCode(first) + String.fromCharCode(second);
      }
    }
    return '';
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
      onSaveRole: (nextRole, nextStatus) async {
        await _setRole(uid: uid, role: nextRole, status: nextStatus);
      },
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

  Future<void> _confirmAndDeleteTenantUser({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isNotEmpty && uid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account.')),
      );
      return;
    }

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete user?'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete the user account and their personal data for this tenant.\n'
                  'It will NOT delete shared content they may have uploaded as an editor.',
                ),
                const SizedBox(height: 12),
                Text('Tenant: ${widget.tenantId}'),
                Text('UID: $uid'),
                Text('Name: ${displayName.trim().isEmpty ? '(no displayName)' : displayName.trim()}'),
                Text('Email: ${email.trim().isEmpty ? '(no email)' : email.trim()}'),
                const SizedBox(height: 12),
                const Text('Type DELETE to confirm:'),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            StatefulBuilder(
              builder: (ctx, setState) {
                controller.addListener(() => setState(() {}));
                final ok = controller.text.trim() == 'DELETE';
                return TextButton(
                  onPressed: ok ? () => Navigator.of(ctx).pop(true) : null,
                  child: const Text('Delete'),
                );
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteTenantUserAndData');
      await callable.call({
        'tenantId': widget.tenantId,
        'targetUid': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted: ${displayName.trim().isEmpty ? uid : displayName.trim()}'),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final msg = e.message ?? e.code;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = L2LLayoutScope.isDashboardDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Admin Panel'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(child: _statsHeader(context)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
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
                  if (!isDesktop) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _openFiltersSheet,
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('Filters'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isDesktop)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      onChanged: (v) =>
                          setState(() => _roleFilter = v ?? 'all'),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('Status: all')),
                        DropdownMenuItem(value: 'active', child: Text('active')),
                        DropdownMenuItem(
                            value: 'inactive', child: Text('inactive')),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v ?? 'all'),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _premiumFilter,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('Premium: all')),
                        DropdownMenuItem(value: 'premium', child: Text('premium')),
                        DropdownMenuItem(value: 'free', child: Text('free')),
                      ],
                      onChanged: (v) =>
                          setState(() => _premiumFilter = v ?? 'all'),
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
                      onChanged: (v) =>
                          setState(() => _dateRange = v ?? 'all'),
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
            ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          StreamBuilder<QuerySnapshot>(
            stream: _membersRef()
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Failed to load members: ${snap.error}')),
                );
              }

              final docs = snap.data?.docs ?? const [];
              final members = <QueryDocumentSnapshot>[];
              for (final d in docs) {
                final data = (d.data() as Map<String, dynamic>?) ?? {};
                if (_matchesFilters(data)) members.add(d);
              }

              if (members.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No members found.')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
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
                      final currentUid =
                          FirebaseAuth.instance.currentUser?.uid ?? '';
                      final canDelete = uid.isNotEmpty &&
                          currentUid.isNotEmpty &&
                          uid != currentUid;

                      final isActive = status == 'active';
                      final statusLabel = isActive ? 'Active' : 'Inactive';

                      IconData hearingIcon(String raw) {
                        final s = raw.trim().toLowerCase();
                        if (s == 'deaf' || s.contains('deaf')) {
                          return Icons.hearing_disabled;
                        }
                        return Icons.hearing;
                      }

                      Widget infoRow(IconData icon, String text) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                text,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final infoLines = <Widget>[
                        if (hearing.trim().isNotEmpty)
                          infoRow(hearingIcon(hearing), _hearingLabel(hearing)),
                        if (email.trim().isNotEmpty)
                          infoRow(Icons.email_outlined, email.trim()),
                        if (country.trim().isNotEmpty)
                          infoRow(
                            Icons.place_outlined,
                            '${_countryFlagEmoji(country)} ${country.trim()}'.trim(),
                          ),
                      ];

                      final controls = Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canDelete)
                            IconButton(
                              tooltip: 'Delete user',
                              onPressed: () => _confirmAndDeleteTenantUser(
                                uid: uid,
                                displayName: name,
                                email: email,
                              ),
                              icon: const Icon(Icons.delete_forever),
                              color: theme.colorScheme.error,
                              visualDensity: const VisualDensity(
                                  horizontal: -4, vertical: -4),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: isActive,
                                  onChanged: (v) async {
                                    final nextStatus = v ? 'active' : 'inactive';
                                    try {
                                      await _setRole(
                                        uid: uid,
                                        role: role,
                                        status: nextStatus,
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Failed to set status: $e'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );

                      final card = InkWell(
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
                          child: Stack(
                            children: [
                              Column(
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
                                              name.trim().isNotEmpty
                                                  ? name.trim()
                                                  : '(no displayName)',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(fontWeight: FontWeight.w800),
                                            ),
                                            if (infoLines.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              for (int j = 0; j < infoLines.length; j++) ...[
                                                infoLines[j],
                                                if (j != infoLines.length - 1)
                                                  const SizedBox(height: 6),
                                              ],
                                            ],
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                _chip(
                                                  theme,
                                                  label: premium ? 'Premium' : 'Learner',
                                                  bg: premium
                                                      ? theme.colorScheme.secondaryContainer
                                                      : theme.colorScheme.surfaceContainerHighest,
                                                  fg: premium
                                                      ? theme.colorScheme.onSecondaryContainer
                                                      : theme.colorScheme.onSurfaceVariant,
                                                ),
                                                if (isJw)
                                                  _chip(
                                                    theme,
                                                    label: 'JW',
                                                    icon: Icons.verified_user,
                                                    bg: theme.colorScheme.tertiaryContainer,
                                                    fg: theme.colorScheme.onTertiaryContainer,
                                                  ),
                                                _chip(
                                                  theme,
                                                  label: providerLabel,
                                                  icon: providerLabel == 'Google'
                                                      ? Icons.g_mobiledata
                                                      : Icons.email,
                                                  bg: providerLabel == 'Google'
                                                      ? theme.colorScheme.primaryContainer
                                                      : theme.colorScheme.surfaceContainerHighest,
                                                  fg: providerLabel == 'Google'
                                                      ? theme.colorScheme.onPrimaryContainer
                                                      : theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(minWidth: 120),
                                        child: controls,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );

                      return Padding(
                        padding: EdgeInsets.only(bottom: i == members.length - 1 ? 0 : 10),
                        child: card,
                      );
                    },
                    childCount: members.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // (Card pills removed for mobile-first UI. Keep helper removed to avoid unused code.)
}

class _MemberStats {
  final String tenantId;
  final int total;
  final int today;
  final int last7;
  final int last30;
  final int thisMonth;
  final int lastMonth;
  final _Trend trend7;

  const _MemberStats({
    required this.tenantId,
    required this.total,
    required this.today,
    required this.last7,
    required this.last30,
    required this.thisMonth,
    required this.lastMonth,
    required this.trend7,
  });
}

class _Trend {
  final int current;
  final int previous;
  final double? pct; // null means previous==0

  const _Trend._({required this.current, required this.previous, required this.pct});

  factory _Trend.from({required int current, required int previous}) {
    if (previous <= 0) return _Trend._(current: current, previous: previous, pct: null);
    return _Trend._(current: current, previous: previous, pct: (current - previous) / previous);
  }

  String get label {
    if (previous <= 0) {
      if (current <= 0) return 'vs previous 7d: 0';
      return 'vs previous 7d: new';
    }
    final p = (pct ?? 0) * 100.0;
    final sign = p >= 0 ? '+' : '';
    return 'vs previous 7d: $sign${p.toStringAsFixed(0)}%';
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
  final Future<void> Function(String role, String status) onSaveRole;
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
    required this.onSaveRole,
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
  String _role = 'viewer';
  String _status = 'active';
  bool _jw = false;
  bool _complimentaryPremium = false;
  bool _premiumEffective = false;
  bool _saving = false;
  bool _refreshing = false;
  bool _diagnosing = false;
  String _providerLabel = '';
  String _email = '';
  String _productId = '';
  DateTime? _validUntil;

  String _normalizeRole(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'owner') return 'owner';
    if (s == 'tenantadmin' || s == 'tenant_admin') return 'tenantadmin';
    if (s == 'admin') return 'tenantadmin'; // treat legacy 'admin' as tenantadmin for tenant members
    if (s == 'editor') return 'editor';
    if (s == 'analyst') return 'analyst';
    return 'viewer';
  }

  String _normalizeStatus(String raw) {
    final s = raw.trim().toLowerCase();
    return (s == 'inactive') ? 'inactive' : 'active';
  }

  String? _normalizeHearing(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower == 'hearing') return 'Hearing';
    if (lower == 'deaf') return 'Deaf';
    if (lower == 'hard of hearing' || lower == 'hard_of_hearing') {
      return 'Hard of Hearing';
    }
    // If the stored value is already in the canonical set, keep it.
    if (s == 'Hearing' || s == 'Deaf' || s == 'Hard of Hearing') return s;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialDisplayName);
    _country = widget.initialCountry.trim().isEmpty
        ? null
        : widget.initialCountry.trim();
    _hearing = _normalizeHearing(widget.initialHearingStatus);
    _role = _normalizeRole(widget.role);
    _status = _normalizeStatus(widget.status);
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
    if (hearing.isNotEmpty) _hearing = _normalizeHearing(hearing);
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
      // Role/status is saved via a separate callable. Keep status unchanged unless edited.
      await widget.onSaveRole(_role, _status);
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

  String _pretty(dynamic v) {
    try {
      return JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return v?.toString() ?? '';
    }
  }

  Future<void> _diagnosePremium() async {
    if (_diagnosing || _saving) return;
    setState(() => _diagnosing = true);
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getEntitlementStatus');
      final res = await callable.call({
        'tenantId': widget.tenantId,
        'targetUid': widget.uid,
      });
      final data = res.data;

      if (!mounted) return;
      final json = _pretty(data);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Diagnostic premium'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: SelectableText(json),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard.')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy JSON'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Common cases:
      // - App Check missing/invalid on web dashboard build
      // - permission-denied (caller not tenant admin)
      final msg = e.toString();
      final hint = msg.contains('app-check') || msg.contains('app check')
          ? 'App Check Web is required. Build dashboard with L2L_RECAPTCHA_SITE_KEY and ensure App Check is enabled.'
          : 'Ensure you are tenant admin/owner (or platform admin).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diagnostic failed: $msg\n$hint')),
      );
    } finally {
      if (mounted) setState(() => _diagnosing = false);
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
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'viewer', child: Text('viewer')),
                    DropdownMenuItem(value: 'analyst', child: Text('analyst')),
                    DropdownMenuItem(value: 'editor', child: Text('editor')),
                    DropdownMenuItem(value: 'tenantadmin', child: Text('tenantAdmin')),
                    DropdownMenuItem(value: 'owner', child: Text('owner')),
                  ],
                  onChanged: (_saving || _refreshing)
                      ? null
                      : (v) => setState(() => _role = (v ?? _role).trim().toLowerCase()),
                ),
                const SizedBox(height: 12),
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
        onPressed:
            _refreshing || _saving || _diagnosing ? null : _diagnosePremium,
        icon: _diagnosing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.bug_report, size: 18),
        label: const Text('Diagnostic premium'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
        ),
      ),
      TextButton.icon(
        onPressed: _refreshing || _saving ? null : _refresh,
        icon: _refreshing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.refresh, size: 18),
        label: const Text('Refresh'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
        ),
      ),
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
        ),
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
