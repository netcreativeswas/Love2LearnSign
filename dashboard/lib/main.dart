import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // from CLI
import 'login_page.dart';
import 'admin_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'user_role_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    OverlaySupport.global(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Color schemes per design guide
    const lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF232F34),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFF9AA33),
      // Match website `--l2l-on-accent` (globals.css): dark text on accent.
      onSecondary: Color(0xFF232F34),
      error: Color(0xFFFF5757),
      onError: Color(0xFFFFFFFF),
      surfaceTint: Color(0xFFE4E1DD),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF232F34),
    );

    const darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF90A4AE),
      onPrimary: Color(0xFF232F34),
      secondary: Color(0xFFF9AA33),
      // Match website `--l2l-on-accent` (globals.css): dark text on accent.
      onSecondary: Color(0xFF232F34),
      error: Color(0xFFFF5757),
      onError: Color(0xFF232F34),
      surfaceTint: Color(0xFF181B1F),
      surface: Color(0xFF232F34),
      onSurface: Color(0xFFFFFFFF),
    );

    final baseText = Typography.material2021().black.apply(
          bodyColor: lightScheme.onSurface,
          displayColor: lightScheme.onSurface,
        );

    return MaterialApp(
      title: 'Love to Learn Sign Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFE4E1DD),
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.primary,
          foregroundColor: lightScheme.onPrimary,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: lightScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          toolbarTextStyle: TextStyle(
            color: lightScheme.onPrimary,
            fontSize: 12,
          ),
          iconTheme: IconThemeData(color: lightScheme.onPrimary),
          actionsIconTheme: IconThemeData(color: lightScheme.onPrimary),
        ),
        textTheme: baseText.copyWith(
          titleLarge: TextStyle(
            color: lightScheme.primary,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(color: lightScheme.onSurface),
          bodySmall:
              TextStyle(color: lightScheme.onSurface.withValues(alpha: 0.8)),
        ),
        cardTheme: CardThemeData(
          color: lightScheme.surface,
          elevation: 0,
          shadowColor: const Color(0x1F000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightScheme.secondary,
            foregroundColor: lightScheme.onSecondary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(color: lightScheme.onSurface.withValues(alpha: 0.22)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: lightScheme.secondary,
          foregroundColor: lightScheme.onSecondary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
              color: lightScheme.onSurface.withValues(alpha: 0.9),
              fontSize: 12),
          hintStyle:
              TextStyle(color: lightScheme.onSurface.withValues(alpha: 0.6)),
          filled: true,
          fillColor: lightScheme.surface.withValues(alpha: 0.95),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: lightScheme.onSurface.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightScheme.secondary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightScheme.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        iconTheme: IconThemeData(color: lightScheme.primary),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF181B1F),
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.primary,
          foregroundColor: darkScheme.onPrimary,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: darkScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          toolbarTextStyle: TextStyle(
            color: darkScheme.onPrimary,
            fontSize: 12,
          ),
          iconTheme: IconThemeData(color: darkScheme.onPrimary),
          actionsIconTheme: IconThemeData(color: darkScheme.onPrimary),
        ),
        cardTheme: CardThemeData(
          color: darkScheme.surface,
          elevation: 0,
          shadowColor: const Color(0x1F000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkScheme.secondary,
            foregroundColor: darkScheme.onSecondary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(color: darkScheme.onSurface.withValues(alpha: 0.26)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkScheme.secondary,
          foregroundColor: darkScheme.onSecondary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
              color: darkScheme.onSurface.withValues(alpha: 0.9), fontSize: 12),
          hintStyle:
              TextStyle(color: darkScheme.onSurface.withValues(alpha: 0.6)),
          filled: true,
          fillColor: darkScheme.surface.withValues(alpha: 0.95),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: darkScheme.onSurface.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: darkScheme.secondary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: darkScheme.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        iconTheme: IconThemeData(color: darkScheme.primary),
      ),
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
