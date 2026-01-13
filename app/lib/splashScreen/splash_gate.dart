import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:love_to_learn_sign/home_page.dart'; // remplace par ta page d’accueil
import 'package:love_to_learn_sign/splashScreen/onboarding_video_screen.dart';
import 'package:provider/provider.dart';
import 'package:love_to_learn_sign/tenancy/apps_catalog.dart';
import 'package:love_to_learn_sign/tenancy/tenant_picker_page.dart';
import 'package:love_to_learn_sign/tenancy/tenant_scope.dart';
import 'package:love_to_learn_sign/startup_timing.dart';

/// Feature flag: keep the onboarding code but disable showing it at install-time.
/// Set to `true` to re-enable the onboarding video screen.
const bool kEnableOnboardingIntro = false;

void _dlog(String message) {
  // Avoid spamming release logs.
  if (kDebugMode) debugPrint(message);
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {

  @override
  void initState() {
    super.initState();
    debugPrint('STARTUP_TIMING: SplashGate.initState +${sinceAppStartMs()}ms');
    // Route as soon as possible (startup perf). Keep SplashGate purely as a visual while routing.
    Future(_route);
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
    final hasTenantSelection = (prefs.getString('selected_app_id') ?? '').trim().isNotEmpty ||
        (prefs.getString('selected_tenant_id') ?? '').trim().isNotEmpty;
    
    _dlog('🔍 SplashGate: hasSeenIntro = $hasSeenIntro');

    // Tiny yield so the first frame can paint before navigation work.
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    // Onboarding disabled: behave as if it was already seen, and continue to Home.
    if (!kEnableOnboardingIntro) {
      if (!hasSeenIntro) {
        await prefs.setBool('hasSeenIntro', true);
        _dlog('🔍 SplashGate: Onboarding disabled -> marking hasSeenIntro=true');
      } else {
        _dlog('🔍 SplashGate: Onboarding disabled (already marked as seen)');
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
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    if (!hasSeenIntro) {
      _dlog('🔍 SplashGate: Navigating to OnboardingVideoScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingVideoScreen()),
      );
    } else {
      _dlog('🔍 SplashGate: Navigating to HomePage (intro already seen)');
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