import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_native_timezone_updated_gradle/flutter_native_timezone_updated_gradle.dart';

import 'firebase_options.dart';
import 'home_page.dart';
import 'package:overlay_support/overlay_support.dart';
import 'password_reset_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'l10n/dynamic_l10n.dart';
import 'locale_provider.dart';
import 'theme.dart';
import 'services/location_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'video_viewer_page.dart';
import 'splashScreen/splash_gate.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:app_links/app_links.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'tenancy/tenant_scope.dart';

import 'url_strategy_stub.dart'
    if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart';

// import 'dart:ui' as ui;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/favorites_repository.dart';
import 'services/history_repository.dart';
import 'services/spaced_repetition_service.dart';
import 'services/flashcard_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'services/notification_permission_service.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'services/subscription_service.dart';
import 'package:l2l_shared/debug/agent_logger.dart';
import 'package:l2l_shared/tenancy/app_config.dart' show TenantBranding;

// LoggingObserver for navigation event logging (only in debug mode)
class LoggingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      final routeName = route.settings.name ??
          route.settings.arguments?.toString() ??
          'unnamed';
      final prevName = previousRoute?.settings.name ??
          previousRoute?.settings.arguments?.toString() ??
          'none';
      debugPrint('PUSHED $routeName from $prevName');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      final routeName = route.settings.name ??
          route.settings.arguments?.toString() ??
          'unnamed';
      final prevName = previousRoute?.settings.name ??
          previousRoute?.settings.arguments?.toString() ??
          'none';
      debugPrint('POPPED $routeName to $prevName');
    }
  }
}

Future<void> _requestExactAlarmPermission() async {
  if (Platform.isAndroid) {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  } else {
    // Not Android: do nothing or print debug statement if desired
    // debugPrint('_requestExactAlarmPermission called on non-Android platform');
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  debugPrint('🔍 DeepLink Debug: main() started');
  WidgetsFlutterBinding.ensureInitialized();

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'pixel9pro-pre',
    'hypothesisId': 'H3',
    'location': 'app/main.dart:main',
    'message': 'main() start',
    'data': {'kIsWeb': kIsWeb},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion

  FlutterError.onError = (details) {
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'pixel9pro-pre',
      'hypothesisId': 'H1',
      'location': 'app/main.dart:FlutterError.onError',
      'message': 'FlutterError',
      'data': {
        'exception': details.exceptionAsString(),
        'library': details.library,
        'context': details.context?.toDescription(),
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    FlutterError.presentError(details);
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'pixel9pro-pre',
      'hypothesisId': 'H1',
      'location': 'app/main.dart:PlatformDispatcher.onError',
      'message': 'Unhandled error',
      'data': {'error': error.toString()},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    return false;
  };

  // Remove the hash (#) from Flutter web URLs
  setUrlStrategy(PathUrlStrategy());

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'white-screen-pre',
    'hypothesisId': 'H2',
    'location': 'app/main.dart:main',
    'message': 'before Firebase.initializeApp',
    'data': {'platform': Platform.operatingSystem},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'white-screen-pre',
    'hypothesisId': 'H2',
    'location': 'app/main.dart:main',
    'message': 'after Firebase.initializeApp',
    'data': {},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion

  // Set Firebase locale based on app locale (reduces X-Firebase-Locale warnings)
  try {
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H6',
      'location': 'app/main.dart:main',
      'message': 'before SharedPreferences.getInstance (locale)',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('app_locale') ?? 'en';
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
    );
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H6',
      'location': 'app/main.dart:main',
      'message': 'after SharedPreferences.getInstance (locale)',
      'data': {'savedLocale': savedLocale},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    // Note: Firebase Auth locale is set automatically based on device locale
    // This is just to reduce warnings
  } catch (e) {
    debugPrint('Failed to set Firebase locale: $e');
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H6',
      'location': 'app/main.dart:main',
      'message': 'locale prefs failed',
      'data': {'error': e.toString()},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
  }
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // === Création des canaux de notification Android ===
  const AndroidNotificationChannel learnChannel = AndroidNotificationChannel(
    'learn_word_channel', // Channel ID must match zonedSchedule
    'Learn Word Notifications', // Channel name visible in settings
    description: 'Reminder to learn a new word',
    importance: Importance.high,
  );
  final androidImpl =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'white-screen-pre',
    'hypothesisId': 'H6',
    'location': 'app/main.dart:main',
    'message': 'before createNotificationChannel',
    'data': {'androidImplNull': androidImpl == null},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion
  await androidImpl?.createNotificationChannel(learnChannel);

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'white-screen-pre',
    'hypothesisId': 'H6',
    'location': 'app/main.dart:main',
    'message': 'after createNotificationChannel',
    'data': {},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion
  // ================================================

  // Initialize timezone data
  tz.initializeTimeZones();
  // Use platform timezone via MethodChannel; fallback to Dart's zone name
  try {
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H6',
      'location': 'app/main.dart:main',
      'message': 'before FlutterTimezone.getLocalTimezone',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    final String tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H6',
      'location': 'app/main.dart:main',
      'message': 'after FlutterTimezone.getLocalTimezone',
      'data': {'tzName': tzName},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
  } catch (e) {
    debugPrint('Failed to get platform timezone: $e');
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H6',
      'location': 'app/main.dart:main',
      'message': 'FlutterTimezone.getLocalTimezone failed',
      'data': {'error': e.toString()},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    // Fallback to system timezone
    tz.setLocalLocation(tz.local);
  }

  // Initialiser les services de notification
  try {
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H7',
      'location': 'app/main.dart:main',
      'message': 'notification init block: start',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
    final spacedRepetitionService = SpacedRepetitionService();
    final flashcardNotificationService = FlashcardNotificationService();
    final notificationService = NotificationService();

    await flashcardNotificationService.initialize();
    await notificationService.initialize();

    // Nettoyer les anciens mots et programmer les notifications
    await spacedRepetitionService.cleanupOldWords();

    // Programmer les notifications de révision (avec gestion d'erreur)
    try {
      await flashcardNotificationService.scheduleAllReviewNotifications();
    } catch (e) {
      debugPrint('Warning: Could not schedule review notifications: $e');
      // Continue without notifications
    }

    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H7',
      'location': 'app/main.dart:main',
      'message': 'notification init block: end',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion
  } catch (e) {
    debugPrint('Warning: Could not initialize notification services: $e');
    // Continue without notifications
  }

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'white-screen-pre',
    'hypothesisId': 'H8',
    'location': 'app/main.dart:main',
    'message': 'before ThemeProvider.create',
    'data': {},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion

  final themeProvider = await ThemeProvider.create();
  final tenantScope = await TenantScope.create();

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'white-screen-pre',
    'hypothesisId': 'H8',
    'location': 'app/main.dart:main',
    'message': 'after ThemeProvider.create',
    'data': {},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion
  final prefs = await SharedPreferences.getInstance();

  final favoritesRepo = await FavoritesRepository.create();
  final favoritesNotifier = favoritesRepo.notifier;

  final historyRepo = await HistoryRepository.create();
  final historyNotifier = historyRepo.notifier;

  // #region agent log
  AgentLogger.log({
    'sessionId': 'debug-session',
    'runId': 'white-screen-pre',
    'hypothesisId': 'H2',
    'location': 'app/main.dart:main',
    'message': 'before runApp',
    'data': {},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  // #endregion

  runApp(
    OverlaySupport.global(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleProvider>(
              create: (_) => LocaleProvider()),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<TenantScope>.value(value: tenantScope),
          ChangeNotifierProvider<FavoritesRepository>.value(
              value: favoritesRepo),
          ChangeNotifierProvider<HistoryRepository>.value(value: historyRepo),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MyApp(
            // Repos are provided via Provider; no need to pass notifiers down
            ),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // #region agent log
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'white-screen-pre',
      'hypothesisId': 'H5',
      'location': 'app/main.dart:main',
      'message': 'first frame rendered',
      'data': {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion

    // Defer potentially blocking plugin init (permissions/FCM/ads/subscriptions)
    // until after the first frame so startup never gets stuck on a white screen.
    Future(() async {
      // Reconcile subscription roles (paidUser/freeUser exclusivity) on login/startup.
      // This ensures that when a subscription expires (end-of-period), roles revert to freeUser.
      fb_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) return;
        try {
          final callable = FirebaseFunctions.instance
              .httpsCallable('reconcileSubscriptionRoles');
          await callable
              .call(<String, dynamic>{}).timeout(const Duration(seconds: 15));
          await user.getIdToken(true).timeout(const Duration(seconds: 15));
          debugPrint('✅ reconcileSubscriptionRoles: roles refreshed');
        } catch (e) {
          debugPrint('⚠️ reconcileSubscriptionRoles failed (non-fatal): $e');
        }
      });

      // #region agent log
      AgentLogger.log({
        'sessionId': 'debug-session',
        'runId': 'white-screen-pre',
        'hypothesisId': 'H9',
        'location': 'app/main.dart:postFrame',
        'message': 'post-startup init start',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      // #endregion

      // Runtime notification permission (Android 13+)
      if (Platform.isAndroid) {
        try {
          // #region agent log
          AgentLogger.log({
            'sessionId': 'debug-session',
            'runId': 'white-screen-pre',
            'hypothesisId': 'H10',
            'location': 'app/main.dart:postFrame',
            'message': 'before notification permission status',
            'data': {},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          // #endregion

          final granted =
              await NotificationPermissionService.areNotificationsEnabled()
                  .timeout(const Duration(seconds: 3), onTimeout: () => true);

          // #region agent log
          AgentLogger.log({
            'sessionId': 'debug-session',
            'runId': 'white-screen-pre',
            'hypothesisId': 'H10',
            'location': 'app/main.dart:postFrame',
            'message': 'after notification permission status',
            'data': {'granted': granted},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          // #endregion

          if (!granted) {
            // #region agent log
            AgentLogger.log({
              'sessionId': 'debug-session',
              'runId': 'white-screen-pre',
              'hypothesisId': 'H10',
              'location': 'app/main.dart:postFrame',
              'message': 'before notification permission request',
              'data': {},
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
            // #endregion

            final requested =
                await NotificationPermissionService.requestPermission().timeout(
                    const Duration(seconds: 10),
                    onTimeout: () => false);

            // #region agent log
            AgentLogger.log({
              'sessionId': 'debug-session',
              'runId': 'white-screen-pre',
              'hypothesisId': 'H10',
              'location': 'app/main.dart:postFrame',
              'message': 'after notification permission request',
              'data': {'granted': requested},
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
            // #endregion
          }
        } catch (e) {
          // #region agent log
          AgentLogger.log({
            'sessionId': 'debug-session',
            'runId': 'white-screen-pre',
            'hypothesisId': 'H10',
            'location': 'app/main.dart:postFrame',
            'message': 'notification permission check/request failed',
            'data': {'error': e.toString()},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          // #endregion
        }
      }

      // Subscribe to FCM topic (does not require notification permission)
      try {
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H11',
          'location': 'app/main.dart:postFrame',
          'message': 'before FCM subscribeToTopic',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
        await messaging
            .subscribeToTopic('new_words')
            .timeout(const Duration(seconds: 8));
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H11',
          'location': 'app/main.dart:postFrame',
          'message': 'after FCM subscribeToTopic',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
      } catch (e) {
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H11',
          'location': 'app/main.dart:postFrame',
          'message': 'FCM subscribeToTopic failed',
          'data': {'error': e.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
      }

      // Initialize Ad Service
      try {
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H12',
          'location': 'app/main.dart:postFrame',
          'message': 'before AdService.initialize',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
        await AdService().initialize().timeout(const Duration(seconds: 15));
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H12',
          'location': 'app/main.dart:postFrame',
          'message': 'after AdService.initialize',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
      } catch (e) {
        debugPrint('Warning: Could not initialize ad service: $e');
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H12',
          'location': 'app/main.dart:postFrame',
          'message': 'AdService.initialize failed',
          'data': {'error': e.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
      }

      // Initialize Subscription Service
      try {
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H13',
          'location': 'app/main.dart:postFrame',
          'message': 'before SubscriptionService.initialize',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
        await SubscriptionService()
            .initialize()
            .timeout(const Duration(seconds: 15));
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H13',
          'location': 'app/main.dart:postFrame',
          'message': 'after SubscriptionService.initialize',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
      } catch (e) {
        debugPrint('Warning: Could not initialize subscription service: $e');
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H13',
          'location': 'app/main.dart:postFrame',
          'message': 'SubscriptionService.initialize failed',
          'data': {'error': e.toString()},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion
      }

      // #region agent log
      AgentLogger.log({
        'sessionId': 'debug-session',
        'runId': 'white-screen-pre',
        'hypothesisId': 'H9',
        'location': 'app/main.dart:postFrame',
        'message': 'post-startup init end',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      // #endregion
    });
  });
}

/// Planifie une notification pour de nouveaux mots
Future<void> _scheduleNewWordsNotification({
  required int id,
  required String channelId,
  required String channelName,
  required String channelDescription,
  required String title,
  required String body,
  required DateTime scheduledDate,
  required String payload,
  AndroidScheduleMode androidScheduleMode =
      AndroidScheduleMode.exactAllowWhileIdle,
}) async {
  // Create the channel if needed
  final androidImpl =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.high,
  ));

  // Ensure strictly-future scheduled time (+6s nudge avoids equality edge case)
  tz.TZDateTime when = tz.TZDateTime.from(scheduledDate, tz.local);
  final now = tz.TZDateTime.now(tz.local);
  if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
  if (!when.isAfter(now.add(const Duration(seconds: 5)))) {
    when = now.add(const Duration(seconds: 6));
  }

  // exact→inexact fallback
  final canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
  final mode = canExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    when,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidScheduleMode: mode,
    payload: payload,
  );
}

/// Planifie une notification d'apprentissage de mot
Future<void> _scheduleLearnWordNotification({
  required int id,
  required String channelId,
  required String channelName,
  required String channelDescription,
  required String title,
  required String body,
  required DateTime scheduledDate,
  required String payload,
  AndroidScheduleMode androidScheduleMode =
      AndroidScheduleMode.exactAllowWhileIdle,
}) async {
  // Create the channel if needed
  final androidImpl =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.high,
  ));

  // Ensure strictly-future scheduled time (+6s nudge avoids equality edge case)
  tz.TZDateTime when = tz.TZDateTime.from(scheduledDate, tz.local);
  final now = tz.TZDateTime.now(tz.local);
  if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
  if (!when.isAfter(now.add(const Duration(seconds: 5)))) {
    when = now.add(const Duration(seconds: 6));
  }

  // exact→inexact fallback
  final canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
  final mode = canExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    when,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'OPEN_LEARN_WORD',
            'Watch video',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidScheduleMode: mode,
    payload: payload,
    matchDateTimeComponents:
        DateTimeComponents.time, // repeat daily at this time
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _countryCode;
  bool _checkedLocation = false;
  String? _lastDeepLinkId;
  late final AppLinks _appLinks;
  List<String> _lastAllowedLocaleCodes = const [];

  @override
  void initState() {
    debugPrint('🔍 DeepLink Debug: initState entered');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectCountry();
    _appLinks = AppLinks();
    // Handle deep links while the app is running
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔍 DeepLink Debug: uriLinkStream event, uri=$uri');
      _navigateToUri(uri);
    }, onError: (_) {});
    // Also handle initial link (cold start) if provided.
    Future(() async {
      try {
        final uri = await _appLinks.getInitialLink();
        if (uri != null) {
          debugPrint('🔍 DeepLink Debug: initialLink uri=$uri');
          _navigateToUri(uri);
        }
      } catch (_) {
        // ignore
      }
    });
    _initNotifications().then((_) async {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // Only prompt on Android 13+ (SDK 34+)
        if (androidInfo.version.sdkInt >= 34) {
          final prefs = await SharedPreferences.getInstance();
          final alreadyRequested =
              prefs.getBool('requestedExactAlarm') ?? false;
          if (!alreadyRequested) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: navigatorKey.currentContext!,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: Text('Enable exact alarms for reminders'),
                  content: Text(
                      'To deliver reminders at the precise time, Android requires a special permission.\n\n'
                      'You will be redirected to the system Settings to allow "Alarms & reminders" for this app. '
                      'After enabling it (or if you choose not to), press Back to return here and finish setup.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        prefs.setBool('requestedExactAlarm', true);
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Not now'),
                    ),
                    TextButton(
                      onPressed: () {
                        _requestExactAlarmPermission();
                        prefs.setBool('requestedExactAlarm', true);
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Continue'),
                    ),
                  ],
                ),
              );
            });
          }
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'white-screen-pre',
          'hypothesisId': 'H14',
          'location': 'app/main.dart:MyApp.initState',
          'message': 'scheduleDailyTasks start',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion

        scheduleDailyTasks(
          flutterLocalNotificationsPlugin,
          tenantId: context.read<TenantScope>().tenantId,
        ).then((_) {
          // #region agent log
          AgentLogger.log({
            'sessionId': 'debug-session',
            'runId': 'white-screen-pre',
            'hypothesisId': 'H14',
            'location': 'app/main.dart:MyApp.initState',
            'message': 'scheduleDailyTasks done',
            'data': {},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          // #endregion
        }).catchError((e) {
          debugPrint('Failed to schedule daily tasks: $e');
          // #region agent log
          AgentLogger.log({
            'sessionId': 'debug-session',
            'runId': 'white-screen-pre',
            'hypothesisId': 'H14',
            'location': 'app/main.dart:MyApp.initState',
            'message': 'scheduleDailyTasks failed',
            'data': {'error': e.toString()},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          // #endregion
        });
      });
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Ensure OPEN_LEARN_WORD action is handled first
        if (response.actionId == 'OPEN_LEARN_WORD' &&
            response.payload != null) {
          final data = jsonDecode(response.payload!);
          final args = data['args'] as Map<String, dynamic>;
          navigatorKey.currentState?.pushNamed(
            data['route'] as String,
            arguments: args,
          );
          return;
        }
        final payload = response.payload;
        // If user tapped the notification body (no actionId), payload still carries routing JSON.
        if (payload != null && payload.trim().startsWith('{')) {
          try {
            final data = jsonDecode(payload);
            if (data is Map && data.containsKey('route')) {
              navigatorKey.currentState?.pushNamed(
                data['route'] as String,
                arguments: data['args'],
              );
              return;
            }
          } catch (_) {}
        }
        if (payload == 'new_words') {
          // Open Home page to show "What's New" row
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => HomePage(countryCode: _countryCode)),
            (route) => false,
          );
          return;
        }
        if (payload == 'review_home') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => HomePage(countryCode: _countryCode)),
            (route) => false,
          );
          return;
        }
        // Handle learn-word tap via JSON payload: navigate directly to the video page
        if (payload != null && payload.startsWith('{')) {
          final data = jsonDecode(payload);
          navigatorKey.currentState?.pushNamed(
            data['route'] as String,
            arguments: data['args'] as Map<String, dynamic>,
          );
          return;
        }
      },
    );

    // Add action button for Learn Word notification on Android
    final androidImpl =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
          'learn_group', 'Learn Notifications'),
    );

    // Handle app launch via notification tap/action
    final details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final response = details!.notificationResponse!;
      if (response.actionId == 'OPEN_LEARN_WORD' && response.payload != null) {
        // Store pending payload for HomePage to consume after initial navigation
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingNotificationPayload', response.payload!);
        return;
      }
      // Fallback: if payload JSON (learn-word body tap)
      if (response.payload != null && response.payload!.startsWith('{')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingNotificationPayload', response.payload!);
        return;
      }
      if (response.payload == 'review_home') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => HomePage(countryCode: _countryCode)),
          (route) => false,
        );
        return;
      }
      // New words tap from terminated state
      if (response.payload == 'new_words') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => HomePage(countryCode: _countryCode)),
          (route) => false,
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _detectCountry();
    }
  }

  Future<void> _detectCountry() async {
    try {
      final countryCode = await LocationService.getCountryCode();
      setState(() {
        _countryCode = countryCode;
      });
    } catch (e) {
      debugPrint('Location detection failed: $e');
    }
  }

  void _navigateToUri(Uri uri) {
    final segments = uri.pathSegments;
    // Co-brand install link: /install?tenant=...&app=...&ui=...
    if (segments.isNotEmpty && segments.first == 'install') {
      try {
        final scope = context.read<TenantScope>();
        scope.applyInstallLink(uri);
      } catch (_) {
        // ignore if provider not ready
      }
      return;
    }
    if (segments.length == 2 && segments.first == 'word') {
      final id = segments[1];
      // Skip if this ID was just handled
      if (id == _lastDeepLinkId) return;
      _lastDeepLinkId = id;
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: RouteSettings(name: '/word/$id'),
          builder: (_) => VideoViewerPage(
            wordId: id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantScope>();
    final branding = tenant.appConfig?.brand ?? tenant.tenantConfig?.brand ?? const TenantBranding();
    final primary = branding.primary != null ? Color(branding.primary!) : null;
    final secondary = branding.secondary != null ? Color(branding.secondary!) : null;

    return Consumer<LocaleProvider>(
      builder: (context, localeProv, _) {
        // Sync allowed locales from tenant config, but only keep locales that exist in compiled localizations.
        final supported = S.supportedLocales.map((l) => l.languageCode.toLowerCase()).toSet();
        final desired = <String>{
          'en',
          ...tenant.uiLocales.map((c) => c.trim().toLowerCase()).where((c) => c.isNotEmpty),
        }.where((c) => supported.contains(c)).toList()
          ..sort();

        if (!_sameStringList(_lastAllowedLocaleCodes, desired)) {
          _lastAllowedLocaleCodes = desired;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            localeProv.setAllowedLocaleCodes(desired);
          });
        }

        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [LoggingObserver()],
          locale: localeProv.locale,
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.themed(
            brightness: Brightness.light,
            primary: primary,
            secondary: secondary,
          ),
          darkTheme: AppTheme.themed(
            brightness: Brightness.dark,
            primary: primary,
            secondary: secondary,
          ),
          themeMode: context.watch<ThemeProvider>().mode,
          title: (tenant.appConfig?.displayName.trim().isNotEmpty == true)
              ? tenant.appConfig!.displayName.trim()
              : ((tenant.tenantConfig?.displayName.trim().isNotEmpty == true)
                  ? tenant.tenantConfig!.displayName.trim()
                  : 'Love to Learn Sign'),
          debugShowCheckedModeBanner: false,
          routes: {
            // Route to home so SplashGate can pushReplacementNamed('/home')
            // while preserving the current country code.
            '/home': (context) => HomePage(countryCode: _countryCode),
            '/reset-password': (context) => const PasswordResetPage(),
            '/main': (context) => HomePage(countryCode: _countryCode),
          },
          onGenerateRoute: (settings) {
            // Handle dynamic routes
            // Direct route for notifications passing arguments map: {'wordId': ...}
            if (settings.name == '/video') {
              final args = settings.arguments;
              if (args is Map<String, dynamic>) {
                final String? wordId = args['wordId'] as String?;
                if (wordId != null && wordId.isNotEmpty) {
                  return MaterialPageRoute(
                    builder: (context) => VideoViewerPage(wordId: wordId),
                    settings: settings,
                  );
                }
              }
            }
            if (settings.name?.startsWith('/video') == true) {
              // Extract wordId from route
              final uri = Uri.parse(settings.name!);
              final segments = uri.pathSegments;
              if (segments.length >= 2 && segments[0] == 'video') {
                final wordId = segments[1];
                return MaterialPageRoute(
                  builder: (context) => VideoViewerPage(wordId: wordId),
                  settings: settings,
                );
              }
            }

            // Handle word routes from notifications
            if (settings.name?.startsWith('/word/') == true) {
              final wordId = settings.name!.substring('/word/'.length);
              return MaterialPageRoute(
                builder: (context) => VideoViewerPage(wordId: wordId),
                settings: settings,
              );
            }

            // Default fallback
            return MaterialPageRoute(
              builder: (context) => HomePage(countryCode: _countryCode),
              settings: settings,
            );
          },
          onUnknownRoute: (settings) {
            // Fallback for any unknown routes
            return MaterialPageRoute(
              builder: (context) => HomePage(countryCode: _countryCode),
            );
          },
          home: const SplashGate(),
        );
      },
    );
  }
}

bool _sameStringList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Future<void> scheduleDailyTasks(
  FlutterLocalNotificationsPlugin plugin, {
  required String tenantId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final now = tz.TZDateTime.now(tz.local);

  // 1) New words summary at 12 PM (only if new words in last 24h)
  if (prefs.getBool('notifyNewWords') ?? true) {
    final since = DateTime.now().subtract(Duration(hours: 24));
    final newWordsSnapshot = await TenantDb.concepts(
      FirebaseFirestore.instance,
      tenantId: tenantId,
    )
        .where('addedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    if (newWordsSnapshot.docs.isNotEmpty) {
      final nextNoon =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 12);
      final scheduledNoon =
          nextNoon.isBefore(now) ? nextNoon.add(Duration(days: 1)) : nextNoon;
      final titleNew =
          S.of(navigatorKey.currentContext!)!.notificationNewWordsTitle;
      // Build body with English/Bengali pairs (max 5)
      final maxWords = 5;
      final wordLines = newWordsSnapshot.docs.take(maxWords).map((d) {
        final data = d.data();
        final en = data['english'] ?? '';
        final bn = data['bengali'] ?? '';
        return "$en — $bn";
      }).join('\n');
      final others = newWordsSnapshot.docs.length > maxWords ? '\n…' : '';
      final bodyNew = wordLines + others;
      await _scheduleNewWordsNotification(
        id: 100,
        channelId: 'new_words_channel',
        channelName: 'New Words Notifications',
        channelDescription: 'Notifications for new words',
        title: titleNew,
        body: bodyNew,
        scheduledDate: scheduledNoon,
        payload: 'new_words',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  // 2) Learn-word reminder at user-selected hour and minute
  final learnHour = prefs.getInt('learnWordHour') ?? 10;
  final learnMinute = prefs.getInt('learnWordMinute') ?? 0;
  final category = prefs.getString('notificationCategory') ?? 'Random';
  debugPrint(
      'LearnWord prefs: hour=$learnHour, minute=$learnMinute, category=$category');
  if (prefs.getBool('notifyLearnWord') ?? true) {
    final nextLearnTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, learnHour, learnMinute);
    final scheduledLearn = nextLearnTime.isBefore(now)
        ? nextLearnTime.add(Duration(days: 1))
        : nextLearnTime;
    // Build query based on category
    Query query = TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId);
    var snapshot = await query.get();
    if (snapshot.docs.isEmpty) return;
    if (category != 'Random') {
      query = query.where('category_main', isEqualTo: category);
      snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        // If no docs in this category, fallback to all words
        final allSnapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId).get();
        if (allSnapshot.docs.isEmpty) return;
        snapshot = allSnapshot;
      }
    }
    final docs = snapshot.docs.toList()..shuffle();
    if (docs.isEmpty) return;
    final pick = docs.first;
    final wordEnglish = pick['english'] as String;
    final wordBengali = pick['bengali'] as String;
    // Capitalize first letter of English word
    final wordEnglishCapitalized = wordEnglish.isEmpty
        ? wordEnglish
        : '${wordEnglish[0].toUpperCase()}${wordEnglish.substring(1)}';
    // Format body: Capitalized English word + Bengali word
    final bodyText = '$wordEnglishCapitalized $wordBengali';
    final args = jsonEncode({
      'route': '/video',
      'args': {
        'wordId': pick.id,
        'english': wordEnglish,
        'bengali': wordBengali,
        'variants': pick['variants'],
      }
    });
    // Schedule learn-word reminder
    final titleLearn = 'Learn one Sign Today!';
    await _scheduleLearnWordNotification(
      id: 200,
      channelId: 'learn_word_channel',
      channelName: 'Learn Word Notifications',
      channelDescription: 'Daily reminder to learn a new word',
      title: titleLearn,
      body: bodyText,
      scheduledDate: scheduledLearn,
      payload: args,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

Future<void> sendNewWordsNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required String tenantId,
}) async {
  final ctx = navigatorKey.currentContext!;
  final locale = Localizations.localeOf(ctx);
  final isBengali = locale.languageCode == 'bn';

  final since = DateTime.now().subtract(Duration(days: 1));
  final snapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
      .where('addedAt', isGreaterThan: Timestamp.fromDate(since))
      .get();

  if (snapshot.docs.isEmpty) return;

  final maxWords = 5;
  final wordLines = snapshot.docs.take(maxWords).map((doc) {
    final data = doc.data();
    final en = (data['english'] ?? '').toString();
    final bn = (data['bengali'] ?? '').toString();
    final enUpper = en.toUpperCase();
    return isBengali ? "• $bn / $enUpper" : "• $enUpper / $bn";
  }).join('\n');

  final others = snapshot.docs.length > maxWords ? '\n…' : '';
  final body = "$wordLines$others";
  final title = S.of(ctx)!.notificationNewWordsTitle;
  await plugin.show(
    101,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'new_words_channel',
        'New Words',
        channelDescription: 'Daily summary of new words added',
        importance: Importance.high,
      ),
    ),
  );
}

Future<void> sendLearnWordNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required String tenantId,
}) async {
  final snapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId).get();
  if (snapshot.docs.isEmpty) return;
  final docs = snapshot.docs..shuffle();
  final pick = docs.first;
  final wordEnglish = pick['english'] as String;
  final wordBengali = pick['bengali'] as String;
  // Capitalize first letter of English word
  final wordEnglishCapitalized = wordEnglish.isEmpty
      ? wordEnglish
      : '${wordEnglish[0].toUpperCase()}${wordEnglish.substring(1)}';
  // Format body: Capitalized English word + Bengali word
  final bodyText = '$wordEnglishCapitalized $wordBengali';
  final ctx = navigatorKey.currentContext!;
  final title = S.of(ctx)!.notificationLearnWordTitle;
  final args = jsonEncode({
    'route': '/video',
    'args': {
      'wordId': pick.id,
      'english': wordEnglish,
      'bengali': wordBengali,
      'variants': pick['variants'],
    }
  });
  await plugin.show(
    201,
    title,
    bodyText,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'learn_word_channel',
        'Learn Word',
        channelDescription: 'Daily word learning reminder',
        importance: Importance.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'OPEN_LEARN_WORD',
            'Watch video',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: args,
  );
}
