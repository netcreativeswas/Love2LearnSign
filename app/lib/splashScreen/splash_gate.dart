import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:love_to_learn_sign/home_page.dart'; // remplace par ta page d’accueil
import 'package:love_to_learn_sign/splashScreen/onboarding_video_screen.dart';

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
    // Auto-route after a 3s delay (replaces the manual Next button)
    Future.delayed(const Duration(seconds: 3), _route);
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
    
    print('🔍 SplashGate: hasSeenIntro = $hasSeenIntro');

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
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    if (!hasSeenIntro) {
      print('🔍 SplashGate: Navigating to OnboardingVideoScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingVideoScreen()),
      );
    } else {
      print('🔍 SplashGate: Navigating to HomePage (intro already seen)');
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