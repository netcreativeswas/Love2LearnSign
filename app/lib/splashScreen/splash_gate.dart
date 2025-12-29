import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:love_to_learn_sign/home_page.dart'; // remplace par ta page d’accueil
import 'package:love_to_learn_sign/splashScreen/onboarding_video_screen.dart';
import 'package:l2l_shared/debug/agent_logger.dart';
import 'package:provider/provider.dart';
import 'package:love_to_learn_sign/tenancy/apps_catalog.dart';
import 'package:love_to_learn_sign/tenancy/tenant_picker_page.dart';
import 'package:love_to_learn_sign/tenancy/tenant_scope.dart';

/// Feature flag: keep the onboarding code but disable showing it at install-time.
/// Set to `true` to re-enable the onboarding video screen.
const bool kEnableOnboardingIntro = false;

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {

  @override
  void initState() {
    super.initState();
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H3',
      'location': 'app/splashScreen/splash_gate.dart:initState',
      'message': 'SplashGate initState',
      'data': {'kEnableOnboardingIntro': kEnableOnboardingIntro},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    // Auto-route after a 3s delay (replaces the manual Next button)
    Future.delayed(const Duration(seconds: 3), _route);
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
    final hasTenantSelection = (prefs.getString('selected_app_id') ?? '').trim().isNotEmpty ||
        (prefs.getString('selected_tenant_id') ?? '').trim().isNotEmpty;
    
    print('🔍 SplashGate: hasSeenIntro = $hasSeenIntro');

    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H3',
      'location': 'app/splashScreen/splash_gate.dart:_route',
      'message': 'SplashGate route decision',
      'data': {
        'hasSeenIntro': hasSeenIntro,
        'kEnableOnboardingIntro': kEnableOnboardingIntro,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion

    // Petit délai pour afficher le splash Flutter (200–600ms)
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Onboarding disabled: behave as if it was already seen, and continue to Home.
    if (!kEnableOnboardingIntro) {
      if (!hasSeenIntro) {
        await prefs.setBool('hasSeenIntro', true);
        print('🔍 SplashGate: Onboarding disabled -> marking hasSeenIntro=true');
      } else {
        print('🔍 SplashGate: Onboarding disabled (already marked as seen)');
      }
      if (!mounted) return;

      // Co-brand picker logic:
      // - If QR/previous selection already set, go straight to home.
      // - If no selection, list apps/*; show picker only if >=2.
      if (!hasTenantSelection) {
        try {
          final apps = await AppsCatalog().fetchAvailableApps();
          if (!mounted) return;
          if (apps.length == 1) {
            // Auto-pick the only edition so the app uses a stable appId (branding/config).
            final scope = context.read<TenantScope>();
            await scope.applyInstallLink(Uri(path: '/install', queryParameters: {'app': apps.first.id}));
          } else if (apps.length >= 2) {
            // Ask user to choose an edition on first launch.
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => const TenantPickerPage(showBack: false),
              ),
            );
          }
        } catch (_) {
          // ignore and continue to home
        }
      }
      // #region agent log
      AgentLogger.log({
        'sessionId': 'debug-session',
        'runId': 'white-screen-pre',
        'hypothesisId': 'H3',
        'location': 'app/splashScreen/splash_gate.dart:_route',
        'message': 'Navigating to /home (onboarding disabled)',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      // #endregion
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    if (!hasSeenIntro) {
      print('🔍 SplashGate: Navigating to OnboardingVideoScreen');
      // #region agent log
      AgentLogger.log({
        'sessionId': 'debug-session',
        'runId': 'white-screen-pre',
        'hypothesisId': 'H4',
        'location': 'app/splashScreen/splash_gate.dart:_route',
        'message': 'Navigating to OnboardingVideoScreen',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      // #endregion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingVideoScreen()),
      );
    } else {
      print('🔍 SplashGate: Navigating to HomePage (intro already seen)');
      // #region agent log
      AgentLogger.log({
        'sessionId': 'debug-session',
        'runId': 'white-screen-pre',
        'hypothesisId': 'H3',
        'location': 'app/splashScreen/splash_gate.dart:_route',
        'message': 'Navigating to /home (intro already seen)',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      // #endregion
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash Flutter custom : logos + fond plein écran
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond uni (ou image décorative en cover si tu veux)
          Container(color: Colors.white),
          // Contenu centré (logos + button)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo App
                Image.asset('assets/icons/l2l-video-splashScreen-black.png', width: 250),
                const SizedBox(height: 24),
                // Loader between app logo and company logo
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // NetCreative logo pinned at the very bottom with 20px margin
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 1,
                child: Image.asset('assets/icons/Net-creative-logo-orange-square-350px.png', width: 90),
              ),
            ),
          ),
        ],
      ),
    );
  }
}