import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:l2l_shared/admin/admin_panel_page.dart';
import 'package:l2l_shared/analytics/search_analytics_page.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import 'package:provider/provider.dart';

import 'package:l2l_shared/add_word/add_word_page.dart';
import 'user_role_service.dart';
import 'admin_dashboard_page.dart';
import 'widgets/dashboard_content.dart';
import 'package:l2l_shared/words_admin/words_list_page.dart';

class AdminHome extends StatefulWidget {
  final String? userRole;
  
  const AdminHome({super.key, this.userRole});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  Future<void> _signOut() => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= DashboardContent.desktopBreakpoint;
    final isAdmin = widget.userRole == UserRoleService.roleAdmin;
    final isEditor = widget.userRole == UserRoleService.roleEditor;

    // Editor: Only access to AddWordPage (no navigation drawer)
    if (isEditor) {
      return L2LLayoutScope.dashboard(
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  'icons/Icon-512.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                const Text('Love to Learn Sign Dashboard'),
                const SizedBox(width: 8),
                Chip(
                  label: const Text('Editor', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                ),
              ],
            ),
            actions: [
              IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
            ],
          ),
          body: const DashboardContent(
            child: AddWordPage(),
          ), // Editors ONLY see AddWordPage - NO access to admin dashboard
        ),
      );
    }

    // Admin: Full access with navigation drawer
    if (isAdmin) {
      return ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: L2LLayoutScope.dashboard(
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'icons/Icon-512.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Text('Love to Learn Sign Dashboard'),
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Admin', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                  ),
                ],
              ),
              actions: [
                IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
              ],
            ),
            drawer: isDesktop
                ? null
                : Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        DrawerHeader(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Admin Menu',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Full Access',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.dashboard),
                          title: const Text('Dashboard'),
                          selected: _selectedIndex == 0,
                          onTap: () {
                            setState(() => _selectedIndex = 0);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Add Word'),
                          selected: _selectedIndex == 1,
                          onTap: () {
                            setState(() => _selectedIndex = 1);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.manage_accounts),
                          title: const Text('Admin Panel'),
                          selected: _selectedIndex == 2,
                          onTap: () {
                            setState(() => _selectedIndex = 2);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.analytics),
                          title: const Text('Search Analytics'),
                          selected: _selectedIndex == 3,
                          onTap: () {
                            setState(() => _selectedIndex = 3);
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.list_alt),
                          title: const Text('Words List'),
                          selected: _selectedIndex == 4,
                          onTap: () {
                            setState(() => _selectedIndex = 4);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
            body: isDesktop
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard),
                            label: Text('Dashboard'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.add),
                            label: Text('Add Word'),
                            ),
                          NavigationRailDestination(
                            icon: Icon(Icons.manage_accounts),
                            label: Text('Admin Panel'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics),
                            label: Text('Analytics'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.list_alt),
                            label: Text('Words List'),
                          ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: DashboardContent(
                          child: _getSelectedPage(_selectedIndex),
                        ),
                      ),
                    ],
                  )
                : DashboardContent(
                    child: _getSelectedPage(_selectedIndex),
                  ),
          ),
        ),
      );
    }

    // Fallback: should not reach here if role checking is correct
    return const Scaffold(
      body: Center(
        child: Text('Invalid role configuration'),
      ),
    );
  }

  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardPage(); // Admin-only dashboard
      case 1:
        return const AddWordPage(); // Add Word page (accessible to both admin and editor)
      case 2:
        return const AdminPanelPage();
      case 3:
        return const SearchAnalyticsPage();
      case 4:
        return WordsListPage(userRoleOverride: widget.userRole);
      default:
        return const AdminDashboardPage();
    }
  }
}
