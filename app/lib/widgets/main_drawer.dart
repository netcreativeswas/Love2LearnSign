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
import 'package:l2l_shared/admin/admin_panel_page.dart';
import 'package:l2l_shared/analytics/search_analytics_page.dart';
import 'package:l2l_shared/words_admin/words_list_page.dart';
import '../theme.dart';
import 'package:l2l_shared/auth/auth_provider.dart';

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
    // Keep underlying role keys unchanged (used for auth logic), only prettify display.
    switch (role) {
      case 'freeuser':
      case 'freeUser':
        return 'Free User';
      case 'paiduser':
      case 'paidUser':
      case 'premium':
        return 'Paid User';
      case 'admin':
        return 'Admin';
      case 'editor':
        return 'Editor';
      default:
        // Generic fallback: handle camelCase / snake_case / lowercase
        final r = role.replaceAll('_', ' ').trim();
        final spaced = r.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
        return spaced
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .map((p) => p[0].toUpperCase() + p.substring(1))
            .join(' ');
    }
  }

  Color _roleBadgeColor(String role) {
    if (role == 'admin') return Colors.redAccent.withValues(alpha: 0.8);
    if (role == 'editor') return Colors.blueAccent.withValues(alpha: 0.8);
    if (role == 'paidUser' || role == 'paiduser' || role == 'premium') {
      return Colors.amber.withValues(alpha: 0.8);
    }
    return Colors.white24;
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
                          if (userRoles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                          Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: userRoles.map((role) {
                                final badgeColor = _roleBadgeColor(role);
                                final label = _formatRoleLabel(role);

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(12),
                                    // border: Border.all(color: Colors.white30, width: 0.5), // Removed border
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
                                );
                              }).toList(),
                            ),
                          ],
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
                // Admin Panel (admins only) with pending users badge
                if (isLoggedIn && isAdmin)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: Row(
                          children: [
                            const Text('Admin Panel'),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: pendingCount > 0
                            ? Icon(
                                Icons.notifications_active,
                                color: Theme.of(context).colorScheme.error,
                                size: 20,
                              )
                            : null,
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
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                          );
                        },
                      );
                    },
                  ),
                  // Search Analytics (admins only)
                  if (isLoggedIn && isAdmin)
                    ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: const Text('Search Analytics'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SearchAnalyticsPage(countryCode: countryCode)),
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