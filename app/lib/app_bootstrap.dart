import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';

import 'package:l2l_shared/auth/auth_provider.dart';

import 'firebase_options.dart';
import 'theme_provider.dart';
import 'locale_provider.dart';
import 'services/favorites_repository.dart';
import 'services/history_repository.dart';
import 'services/flashcard_notification_service.dart';
import 'services/spaced_repetition_service.dart';
import 'services/ad_service.dart';
import 'services/subscription_service.dart';
import 'services/notification_permission_service.dart';

import 'tenancy/tenant_scope.dart';
import 'tenancy/tenant_member_access_provider.dart';
import 'app_root.dart'; // For MyApp, SubscriptionSyncer, flutterLocalNotificationsPlugin
import 'startup_timing.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _initialized = false;
  Object? _error;

  // Dependencies to inject into MultiProvider
  late ThemeProvider _themeProvider;
  late TenantScope _tenantScope;
  late FavoritesRepository _favoritesRepo;
  late HistoryRepository _historyRepo;
  bool _deferredStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeCriticalSystems();
  }

  Future<void> _initializeCriticalSystems() async {
    try {
      // CRITICAL PATH (keep minimal): what we need to render the real app quickly.
      // 1) Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2) Firestore settings (cheap; avoid warnings)
      await _initFirestoreAndLocale();

      // 2.5) Timezone must be initialized before any zoned scheduling (local notifications).
      await _initTimezone();

      // 3) ThemeProvider (prefs)
      _themeProvider = await ThemeProvider.create();

      // 4) TenantScope fast path: prefs first, Firestore refresh in background with timeout.
      _tenantScope = await TenantScope.createFast(refreshTimeout: const Duration(seconds: 3));

      // 5) Local repos (prefs)
      _favoritesRepo = await FavoritesRepository.create();
      _historyRepo = await HistoryRepository.create();

      // Listeners (Monetization) - best-effort; do not block UI.
      var lastTenantId = _tenantScope.tenantId;
      _tenantScope.addListener(() {
        final tid = _tenantScope.tenantId;
        if (tid == lastTenantId) return;
        lastTenantId = tid;
        AdService().setTenant(tid);
        SubscriptionService().setTenant(tid);
      });

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }

      // DEFERRED PATH: anything that can take time / loop / hit network.
      // Run after first frame so the user sees the app ASAP.
      if (!_deferredStarted) {
        _deferredStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future(_runDeferredInit);
        });
      }

    } catch (e, stack) {
      debugPrint('Bootstrap Init Failed: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
    }
  }

  Future<void> _runDeferredInit() async {
    // App Check (network) - non-blocking for UI
    await _initAppCheck();

    // Request permission (iOS) + subscribe to topic for server push new words digest.
    await _initMessagingAndPermissions();

    // Notification channels + scheduling can be expensive on some devices
    await _initNotificationsChannels();
    await _initNotificationServices();
  }

  Future<void> _initMessagingAndPermissions() async {
    try {
      // Android 13+ runtime notification permission (required for notifications to show).
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final granted = await NotificationPermissionService.areNotificationsEnabled()
              .timeout(const Duration(seconds: 3), onTimeout: () => true);
          if (!granted) {
            await NotificationPermissionService.requestPermission()
                .timeout(const Duration(seconds: 10), onTimeout: () => false);
          }
        } catch (_) {
          // non-fatal
        }
      }

      // iOS requires explicit permission prompt to show notifications.
      if (!kIsWeb && Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Subscribe to new words digest topic (idempotent).
      await FirebaseMessaging.instance.subscribeToTopic('new_words');
    } catch (e) {
      debugPrint('FCM permission/topic subscribe failed (non-fatal): $e');
    }
  }

  Future<void> _initAppCheck() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await FirebaseAppCheck.instance.activate(
          appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      }
    } catch (e) {
      debugPrint('App Check activation failed: $e');
    }
  }

  Future<void> _initFirestoreAndLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // final savedLocale = prefs.getString('app_locale') ?? 'en'; // Not used here directly
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      debugPrint('Failed to set Firebase locale/settings: $e');
    }
  }

  Future<void> _initNotificationsChannels() async {
    const AndroidNotificationChannel learnChannel = AndroidNotificationChannel(
      'learn_word_channel',
      'Learn Word Notifications',
      description: 'Reminder to learn a new word',
      importance: Importance.high,
    );
    final androidImpl = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(learnChannel);
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      debugPrint('Failed to get platform timezone: $e');
      tz.setLocalLocation(tz.local);
    }
  }

  Future<void> _initNotificationServices() async {
    try {
      final spacedRepetitionService = SpacedRepetitionService();
      final flashcardNotificationService = FlashcardNotificationService();

      await flashcardNotificationService.initialize();
      await spacedRepetitionService.cleanupOldWords();

      try {
        await flashcardNotificationService.scheduleAllReviewNotifications();
      } catch (e) {
        debugPrint('Warning: Could not schedule review notifications: $e');
      }
    } catch (e) {
      debugPrint('Warning: Could not initialize notification services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('STARTUP_TIMING: firstFrame +${sinceAppStartMs()}ms');
    });
    // If initialized, show the main app
    if (_initialized) {
      return OverlaySupport.global(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>(
                create: (_) => LocaleProvider()),
            ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
            ChangeNotifierProvider<TenantScope>.value(value: _tenantScope),
            ChangeNotifierProxyProvider<TenantScope, TenantMemberAccessProvider>(
              create: (ctx) => TenantMemberAccessProvider(
                tenantId: ctx.read<TenantScope>().tenantId,
              ),
              update: (_, scope, prev) {
                if (prev == null) return TenantMemberAccessProvider(tenantId: scope.tenantId);
                prev.updateTenantId(scope.tenantId);
                return prev;
              },
            ),
            ChangeNotifierProvider<FavoritesRepository>.value(
                value: _favoritesRepo),
            ChangeNotifierProvider<HistoryRepository>.value(value: _historyRepo),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ],
          child: SubscriptionSyncer(
            child: MyApp(),
          ),
        ),
      );
    }

    // If error, show retry screen
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Initialization Failed', style: TextStyle(color: Colors.black)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(_error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                    _initializeCriticalSystems();
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
      );
    }

    // Default: Splash Screen (Loading)
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Centered Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SplashLogo(), // Reusable logo widget
                  SizedBox(height: 24),
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 24),
                ],
              ),
            ),
            // Bottom Logo
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: BottomLogo(), // Reusable bottom logo
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/icons/l2l-video-splashScreen-black.png', width: 250);
  }
}

class BottomLogo extends StatelessWidget {
  const BottomLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1,
      child: Image.asset('assets/icons/Net-creative-logo-orange-square-350px.png', width: 90),
    );
  }
}

