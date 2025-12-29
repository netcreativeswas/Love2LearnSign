import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // from CLI
import 'login_page.dart';
import 'admin_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'user_role_service.dart';
import 'package:provider/provider.dart';
import 'tenancy/dashboard_tenant_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final tenantScope = await DashboardTenantScope.create();

  runApp(
    OverlaySupport.global(
      child: ChangeNotifierProvider<DashboardTenantScope>.value(
        value: tenantScope,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = context.watch<DashboardTenantScope>();

    return MaterialApp(
      title: scope.displayName,
      theme: scope.themeFor(Brightness.light),
      darkTheme: scope.themeFor(Brightness.dark),
      home: const AuthGate(),
    );
  }
}

/// Shows LoginPage if not signed in, otherwise AdminHome (with role-based access).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasData) {
          // User is authenticated, check role and show appropriate dashboard
          return const RoleBasedDashboard();
        }
        return const LoginPage();
      },
    );
  }
}

/// Widget that checks user role and shows appropriate dashboard
class RoleBasedDashboard extends StatelessWidget {
  const RoleBasedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: UserRoleService.getUserRoleStream(),
      builder: (context, roleSnapshot) {
        // Show loading while checking role
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (roleSnapshot.hasError) {
          // Check for permission denied error
          final error = roleSnapshot.error.toString();
          final isPermissionError = error.contains('permission-denied') ||
              error.contains('insufficient permissions') ||
              error.contains('Missing or insufficient permissions');

          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        isPermissionError
                            ? Icons.security
                            : Icons.error_outline,
                        size: 64,
                        color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      isPermissionError
                          ? 'Permission Denied'
                          : 'Error checking role',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermissionError
                          ? 'Your account is not authorized to read user roles.\nPlease ask an administrator to update Firestore Security Rules.'
                          : 'Details: $error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final role = roleSnapshot.data;

        // Check if user has dashboard access (admin or editor)
        if (role == UserRoleService.roleAdmin ||
            role == UserRoleService.roleEditor) {
          return AdminHome(userRole: role);
        }

        // User authenticated but no valid role - show access denied
        // Also handles case where role is null (document doesn't exist)
        return Scaffold(
          appBar: AppBar(
            title: const Text('Access Denied'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account does not have permission to access the dashboard.',
                    textAlign: TextAlign.center,
                  ),
                  if (role == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '(No role assigned to this user)',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please contact an administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
