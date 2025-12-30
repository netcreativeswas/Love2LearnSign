import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // from CLI
import 'login_page.dart';
import 'admin_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'tenancy/dashboard_tenant_scope.dart';
import 'tenancy/tenant_switcher_page.dart';
import 'debug/agent_debug_log.dart';

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
          // User is authenticated; load tenant access and open dashboard.
          return DashboardTenantGate(user: snap.data!);
        }
        return const LoginPage();
      },
    );
  }
}

class DashboardTenantGate extends StatefulWidget {
  final User user;
  const DashboardTenantGate({super.key, required this.user});

  @override
  State<DashboardTenantGate> createState() => _DashboardTenantGateState();
}

class _DashboardTenantGateState extends State<DashboardTenantGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final scope = context.read<DashboardTenantScope>();
    // #region agent log
    DebugLog.log({
      'sessionId': 'debug-session',
      'runId': 'dash-access-pre',
      'hypothesisId': 'H1',
      'location': 'dashboard/main.dart:DashboardTenantGate:_bootstrap',
      'message': 'bootstrap start',
      'data': {
        'url': Uri.base.toString(),
        'uidSuffix': widget.user.uid.substring(widget.user.uid.length - 6),
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    await scope.loadAccessForUser(widget.user.uid);
    if (!mounted) return;
    setState(() => _loading = false);
    if (scope.needsTenantPick) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const TenantSwitcherPage()),
      );
      if (!mounted) return;
      setState(() {}); // refresh after pick
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final scope = context.watch<DashboardTenantScope>();
    if (scope.accessibleTenantIds.isEmpty && !scope.isPlatformAdmin) {
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
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No tenant access configured for this account.'),
          ),
        ),
      );
    }

    // AdminHome will scope all operations by DashboardTenantScope.tenantId/signLangId.
    return const AdminHome();
  }
}
