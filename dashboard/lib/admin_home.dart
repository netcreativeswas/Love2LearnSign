import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:l2l_shared/admin/admin_panel_page.dart';
import 'package:l2l_shared/analytics/search_analytics_page.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import 'package:provider/provider.dart';

import 'package:l2l_shared/add_word/add_word_page.dart';
import 'admin_dashboard_page.dart';
import 'widgets/dashboard_content.dart';
import 'package:l2l_shared/words_admin/words_list_page.dart';
import 'web_bridge.dart';
import 'tenancy/dashboard_tenant_scope.dart';
import 'tenancy/tenant_switcher_page.dart';
import 'owner/owner_home_page.dart';
import 'debug/agent_debug_log.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;
  bool _isSigningOut = false;
  static bool _didLogNavOnce = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      // Tell the parent to sign out + redirect (prevents bounce / flicker).
      WebBridge.notifySignedOut();
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= DashboardContent.desktopBreakpoint;
    final tenantScope = context.watch<DashboardTenantScope>();
    final role = (tenantScope.selectedTenantRole ?? '').toLowerCase().trim();
    final isAdmin = tenantScope.isPlatformAdmin || role == 'owner' || role == 'admin';
    final isEditor = isAdmin || role == 'editor';

    final items = _navItemsForRole(
      isAdmin: isAdmin,
      isEditor: isEditor,
      isPlatformAdmin: tenantScope.isPlatformAdmin,
    );

    if (!_didLogNavOnce) {
      _didLogNavOnce = true;
      // #region agent log
      DebugLog.log({
        'sessionId': 'debug-session',
        'runId': 'dash-access-pre',
        'hypothesisId': 'H5',
        'location': 'dashboard/admin_home.dart:build',
        'message': 'AdminHome computed nav',
        'data': {
          'tenantId': tenantScope.tenantId,
          'role': role,
          'isPlatformAdmin': tenantScope.isPlatformAdmin,
          'isAdmin': isAdmin,
          'isEditor': isEditor,
          'navLabels': items.map((x) => x.label).toList(),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      // #endregion
      // ignore: avoid_print
      print(
        '[DashDebug] AdminHome nav tenantId=${tenantScope.tenantId} role=$role isPlatformAdmin=${tenantScope.isPlatformAdmin} isAdmin=$isAdmin isEditor=$isEditor nav=${items.map((x) => x.label).toList()}',
      );
    }
    final selectedIndex = items.isEmpty
        ? 0
        : (_selectedIndex.clamp(0, items.length - 1));

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: L2LLayoutScope.dashboard(
        child: Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  // Minimal header (mobile) only to provide a hamburger for the Drawer.
                  title: Text(items.isNotEmpty ? items[selectedIndex].label : 'Dashboard'),
                  actions: const [],
                ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: _DashboardSidebar(
                      items: items,
                      selectedIndex: selectedIndex,
                      onSelect: (i) {
                        setState(() => _selectedIndex = i);
                        Navigator.of(context).pop(); // close drawer
                      },
                      onLogout: _signOut,
                      signingOut: _isSigningOut,
                    ),
                  ),
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                _DashboardSidebar(
                  items: items,
                  selectedIndex: selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                  onLogout: _signOut,
                  signingOut: _isSigningOut,
                ),
              if (isDesktop) const VerticalDivider(width: 1),
              Expanded(
                child: DashboardContent(
                  child: items.isEmpty ? const SizedBox.shrink() : items[selectedIndex].builder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget Function() builder;
  const _NavItem({required this.label, required this.icon, required this.builder});
}

List<_NavItem> _navItemsForRole({
  required bool isAdmin,
  required bool isEditor,
  required bool isPlatformAdmin,
}) {
  if (isEditor) {
    return [
      _NavItem(
        label: 'Add Word',
        icon: Icons.add_circle_outline,
        builder: () => Builder(
          builder: (ctx) {
            final t = ctx.watch<DashboardTenantScope>();
            return AddWordPage(tenantId: t.tenantId, signLangId: t.signLangId);
          },
        ),
      ),
    ];
  }

  if (isAdmin) {
    return [
      const _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: AdminDashboardPage.new,
      ),
      _NavItem(
        label: 'Add Word',
        icon: Icons.add_circle_outline,
        builder: () => Builder(
          builder: (ctx) {
            final t = ctx.watch<DashboardTenantScope>();
            return AddWordPage(tenantId: t.tenantId, signLangId: t.signLangId);
          },
        ),
      ),
      const _NavItem(
        label: 'Admin Panel',
        icon: Icons.manage_accounts_outlined,
        builder: AdminPanelPage.new,
      ),
      _NavItem(
        label: 'Search Analytics',
        icon: Icons.analytics_outlined,
        builder: () => Builder(
          builder: (ctx) {
            final t = ctx.watch<DashboardTenantScope>();
            final role = t.isPlatformAdmin ? 'admin' : (t.selectedTenantRole ?? 'viewer');
            return SearchAnalyticsPage(
              tenantId: t.tenantId,
              userRoleOverride: role,
            );
          },
        ),
      ),
      _NavItem(
        label: 'Words List',
        icon: Icons.list_alt_outlined,
        builder: () => Builder(
          builder: (ctx) {
            final t = ctx.watch<DashboardTenantScope>();
            final role = t.isPlatformAdmin ? 'admin' : (t.selectedTenantRole ?? 'viewer');
            return WordsListPage(
              userRoleOverride: role,
              tenantId: t.tenantId,
              signLangId: t.signLangId,
            );
          },
        ),
      ),
      if (isPlatformAdmin)
        const _NavItem(
          label: 'Owner',
          icon: Icons.security_outlined,
          builder: OwnerHomePage.new,
        ),
    ];
  }

  return const [];
}

class _DashboardSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final bool signingOut;

  const _DashboardSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    required this.signingOut,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final tenant = context.watch<DashboardTenantScope>();
    final user = auth.user;
    final displayName = (auth.displayName ?? user?.displayName ?? 'Dashboard User').trim();
    final email = (user?.email ?? '').trim();
    final roles = auth.userRoles;

    final initials = _initialsFrom(displayName.isNotEmpty ? displayName : email);

    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(color: scheme.onSurface.withValues(alpha: 0.10)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (tenant.brand.logoUrl.trim().isNotEmpty)
                      ? Image.network(
                          tenant.brand.logoUrl.trim(),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.network(
                            'icons/Icon-512.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.network(
                    'icons/Icon-512.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tenant.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (tenant.accessibleTenantIds.length >= 2)
                  IconButton(
                    tooltip: 'Change tenant',
                    onPressed: () async {
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const TenantSwitcherPage()),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: [
                for (int i = 0; i < items.length; i++)
                  _SidebarItem(
                    label: items[i].label,
                    icon: items[i].icon,
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: scheme.primary.withValues(alpha: 0.10),
                            foregroundColor: scheme.primary,
                            child: Text(
                              initials,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.isEmpty ? 'Dashboard User' : displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurface.withValues(alpha: 0.70),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (roles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: roles
                              .map(
                                (r) => Chip(
                                  label: Text(
                                    r,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: signingOut ? null : onLogout,
                    icon: signingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: Text(signingOut ? 'Signing out…' : 'Logout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.secondary,
                      foregroundColor: scheme.onSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initialsFrom(String s) {
    final parts = s.trim().split(RegExp(r'\\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first;
    final last = parts.length > 1 ? parts.last : '';
    final a = first.isNotEmpty ? first[0] : '';
    final b = last.isNotEmpty ? last[0] : '';
    final out = (a + b).toUpperCase();
    return out.isEmpty ? '?' : out;
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.secondary.withValues(alpha: 0.18) : Colors.transparent;
    final fg = selected ? scheme.secondary : scheme.onSurface.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
