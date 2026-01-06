import 'package:flutter/material.dart';
import 'package:love_to_learn_sign/l10n/dynamic_l10n.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../settings_page.dart';
import '../about_this_app_page.dart';
import '../login_page.dart';
import '../signup_page.dart';
import 'package:l2l_shared/add_word/add_word_page.dart';
import 'package:l2l_shared/admin/tenant_admin_panel_page.dart';
import 'package:l2l_shared/analytics/search_analytics_page.dart';
import 'package:l2l_shared/words_admin/words_list_page.dart';
import '../tenancy/tenant_scope.dart';
import '../tenancy/tenant_member_access_provider.dart';
import '../theme.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import '../utils/role_labels.dart';
import '../services/premium_service.dart';

class MainDrawerWidget extends StatelessWidget {
  final String countryCode;
  final bool checkedLocation;
  final String? userRole;
  final bool isLoggedIn;
  final String? deviceLanguageCode;
  final String? deviceRegionCode;

  const MainDrawerWidget({
    super.key,
    required this.countryCode,
    required this.checkedLocation,
    this.userRole,
    this.isLoggedIn = false,
    this.deviceLanguageCode,
    this.deviceRegionCode,
  });

  String _formatRoleLabel(String role) {
    return roleLabel(role);
  }

  Color _roleBadgeColor(String role) {
    if (role == 'admin') return Colors.redAccent.withValues(alpha: 0.8);
    if (role == 'editor') return Colors.blueAccent.withValues(alpha: 0.8);
    return Colors.white24;
  }

  String _tenantRoleLabel(BuildContext context, String role) {
    final r = role.trim().toLowerCase();
    final s = S.of(context)!;
    switch (r) {
      case 'owner':
        return s.badgeOwner;
      case 'admin':
        return s.badgeTenantAdmin;
      case 'editor':
        return s.badgeEditor;
      case 'analyst':
        return s.badgeAnalyst;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isLoggedIn = authProvider.isAuthenticated;
        final userRoles = authProvider.userRoles;
        final displayName = authProvider.displayName ?? authProvider.user?.email?.split('@')[0] ?? 'User';
        final isAdmin = authProvider.isAdmin;
        final isEditor = authProvider.isEditor;
        final tenantId = context.watch<TenantScope>().tenantId;
        final memberAccess = context.watch<TenantMemberAccessProvider>();
        final hasJw = memberAccess.isJw;
        final tenantRole = memberAccess.tenantRole;
        final isComplimentary = memberAccess.isComplimentaryPremium;
        // Only show meaningful global roles; premium is tenant-scoped now.
        final displayRoles = userRoles
            .map((r) => r.toLowerCase().trim())
            .where((r) => r.isNotEmpty)
            .where((r) => r != 'freeuser' && r != 'paiduser' && r != 'premium')
            .toSet()
            .toList()
          ..sort();
        
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 20,
                      left: 20,
                      right: 20,
                    ),
              decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
              ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                    children: [
                        if (isLoggedIn) ...[
                          // User is logged in
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 2),
                              image: authProvider.user?.photoURL != null
                                  ? DecorationImage(
                                      image: NetworkImage(authProvider.user!.photoURL!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: authProvider.user?.photoURL == null
                                ? Center(
                              child: Text(
                                      (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                                displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          const SizedBox(height: 4),
                          Text(
                            authProvider.user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<bool>(
                            future: PremiumService().isPremiumForTenant(tenantId),
                            builder: (context, snap) {
                              final isPremium = snap.data == true;
                              final s = S.of(context)!;
                              final chips = <Widget>[];

                              // Tenant premium (source of truth: per-tenant entitlement + tenant admin role).
                              final statusLabel = (isPremium && isComplimentary)
                                  ? s.badgeComplimentaryPremium
                                  : (isPremium ? s.badgePremium : s.badgeLearner);
                              chips.add(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPremium
                                        ? Colors.amber.withValues(alpha: 0.85)
                                        : Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              );

                              // Tenant role (editor/analyst/tenantAdmin/owner).
                              final trLabel = _tenantRoleLabel(context, tenantRole);
                              if (trLabel.isNotEmpty) {
                                chips.add(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      trLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // Tenant JW access.
                              if (hasJw) {
                                chips.add(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurpleAccent.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      s.badgeJW,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // Global roles (admin/editor/etc) if any.
                              for (final role in displayRoles) {
                                final badgeColor = _roleBadgeColor(role);
                                final label = _formatRoleLabel(role);
                                chips.add(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: chips,
                              );
                            },
                          ),
                        ] else ...[
                          // Guest user
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    IconlyBold.profile,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  S.of(context)!.welcomeTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                              ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const LoginPage()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Theme.of(context).primaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: Text(
                                      S.of(context)!.loginButton,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Builder(
                                      builder: (context) {
                                        final locale = Localizations.localeOf(context).languageCode;
                                        final fullText = S.of(context)!.newUserSignUp;
                                        
                                        if (locale == 'bn') {
                                          // Bengali: "নতুন ব্যবহারকারী? নিবন্ধন"
                                          // Split at "?" and make "নিবন্ধন" bold and underlined
                                          final parts = fullText.split('?');
                                          if (parts.length == 2) {
                                            return RichText(
                                              textAlign: TextAlign.center,
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontSize: 13,
                                                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                                ),
                                                children: [
                                                  TextSpan(text: '${parts[0]}? '),
                                                  TextSpan(
                                                    text: parts[1].trim(),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      decoration: TextDecoration.underline,
                                                      decorationColor: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        } else {
                                          // English: "New user? Please sign up"
                                          // Split at "sign up" and make it bold and underlined
                                          final signUpIndex = fullText.toLowerCase().indexOf('sign up');
                                          if (signUpIndex != -1) {
                                            return RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 13,
                                          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                        ),
                                        children: [
                                                  TextSpan(text: fullText.substring(0, signUpIndex)),
                                          TextSpan(
                                                    text: fullText.substring(signUpIndex),
                                                    style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.white,
                                            ),
                          ),
                        ],
                                      ),
                                            );
                                          }
                                        }
                                        // Fallback: just show the text
                                        return Text(
                                          fullText,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 13,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
              ),
            ),
            ListTile(
              leading: const Icon(IconlyLight.setting),
              title: Text(S.of(context)!.settings),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(S.of(context).drawerAboutThisApp),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutThisAppPage()),
                );
              },
            ),
                // Words List (admin + editor)
                if (isLoggedIn && (isAdmin || isEditor))
                  ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text('Words List'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordsListPage(
                            userRoleOverride: isAdmin ? 'admin' : 'editor',
                          ),
                        ),
                );
              },
            ),
                // Admin Panel (tenant-scoped; admins only)
                if (isLoggedIn && isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Admin Panel'),
                    onTap: () {
                      if (!authProvider.isAdmin) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Admin access required'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                        return;
                      }
                      final tenantId = context.read<TenantScope>().tenantId.trim();
                      if (tenantId.isEmpty) {
                        Navigator.of(context).pop(); // close drawer
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Tenant not ready. Please try again.'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(); // close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TenantAdminPanelPage(tenantId: tenantId),
                        ),
                      );
                    },
                  ),
                  // Search Analytics (admins only)
                  if (isLoggedIn && isAdmin)
                    ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: const Text('Search Analytics'),
                      onTap: () {
                        final tenantId = context.read<TenantScope>().tenantId;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SearchAnalyticsPage(
                              countryCode: countryCode,
                              tenantId: tenantId,
                              userRoleOverride: 'admin',
                            ),
                          ),
                  );
                },
              ),
                ],
              ),
            ),
            if (isLoggedIn)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.onSurface2,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                                  child: Text(
                                    S.of(context)!.logoutSuccess,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface2),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                      }
                },
                      icon: Icon(
                        IconlyLight.logout,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: Text(
                        S.of(context)!.drawerLogout,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
        );
      },
    );
  }
}