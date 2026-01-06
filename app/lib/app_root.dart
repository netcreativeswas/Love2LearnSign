import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:l2l_shared/tenancy/app_config.dart' show TenantBranding;
import 'package:l2l_shared/tenancy/concept_text.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'home_page.dart';
import 'l10n/dynamic_l10n.dart';
import 'locale_provider.dart';
import 'password_reset_page.dart';
import 'services/location_service.dart';
import 'services/subscription_service.dart';
import 'tenancy/tenant_member_access_provider.dart';
import 'tenancy/tenant_scope.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'video_viewer_page.dart';
import 'splashScreen/splash_gate.dart';
import 'package:app_links/app_links.dart';

// LoggingObserver for navigation event logging (only in debug mode)
class LoggingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      final routeName =
          route.settings.name ?? route.settings.arguments?.toString() ?? 'unnamed';
      final prevName = previousRoute?.settings.name ??
          previousRoute?.settings.arguments?.toString() ??
          'none';
      debugPrint('PUSHED $routeName from $prevName');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      final routeName =
          route.settings.name ?? route.settings.arguments?.toString() ?? 'unnamed';
      final prevName = previousRoute?.settings.name ??
          previousRoute?.settings.arguments?.toString() ??
          'none';
      debugPrint('POPPED $routeName to $prevName');
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Listens for subscription lifecycle events and refreshes auth roles globally.
/// This ensures the drawer badge + premium gating update immediately after an in-app purchase,
/// without requiring the user to tap "Restore purchase".
class SubscriptionSyncer extends StatefulWidget {
  final Widget child;
  const SubscriptionSyncer({super.key, required this.child});

  @override
  State<SubscriptionSyncer> createState() => _SubscriptionSyncerState();
}

class _SubscriptionSyncerState extends State<SubscriptionSyncer> {
  StreamSubscription<SubscriptionChangeEvent>? _sub;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _sub = SubscriptionService().subscriptionChanged.listen((evt) async {
      if (!mounted) return;
      if (_refreshing) return;
      // Only refresh when we have an authenticated user.
      if (fb_auth.FirebaseAuth.instance.currentUser == null) return;

      try {
        _refreshing = true;
        await context.read<AuthProvider>().loadUserData();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ SubscriptionSyncer: failed to refresh roles: $e');
        }
      } finally {
        _refreshing = false;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _countryCode;
  String? _lastDeepLinkId;
  late final AppLinks _appLinks;
  List<String> _lastAllowedLocaleCodes = const [];
  String? _lastTenantKeyForLocale;

  @override
  void initState() {
    debugPrint('🔍 DeepLink Debug: initState entered');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectCountry();
    _appLinks = AppLinks();

    // Handle FCM taps (app opened from background/terminated by push notification).
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleFcmTap(msg);
    });
    Future(() async {
      try {
        final msg = await FirebaseMessaging.instance.getInitialMessage();
        if (msg != null) _handleFcmTap(msg);
      } catch (_) {
        // ignore
      }
    });

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scheduleDailyTasks(
          flutterLocalNotificationsPlugin,
          tenantId: context.read<TenantScope>().tenantId,
        ).catchError((e) {
          debugPrint('Failed to schedule daily tasks: $e');
        });
      });
    });
  }

  void _handleFcmTap(RemoteMessage msg) async {
    final data = msg.data;
    final kind = data['kind']?.toString();

    // New words digest: open Home (it already shows What's New based on Firestore/new words logic)
    if (kind == 'new_words_digest') {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage(countryCode: _countryCode)),
        (route) => false,
      );
      return;
    }

    // Default: open home.
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomePage(countryCode: _countryCode)),
      (route) => false,
    );
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
        if (response.actionId == 'OPEN_LEARN_WORD' && response.payload != null) {
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
            MaterialPageRoute(builder: (_) => HomePage(countryCode: _countryCode)),
            (route) => false,
          );
          return;
        }

        if (payload == 'review_home') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage(countryCode: _countryCode)),
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

    // Handle app launch via notification tap/action
    final details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final response = details!.notificationResponse!;

      // Store pending payload for HomePage to consume after initial navigation
      if ((response.actionId == 'OPEN_LEARN_WORD' && response.payload != null) ||
          (response.payload != null && response.payload!.startsWith('{'))) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingNotificationPayload', response.payload!);
        return;
      }

      if (response.payload == 'review_home' || response.payload == 'new_words') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomePage(countryCode: _countryCode)),
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
          builder: (_) => VideoViewerPage(wordId: id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantScope>();
    final branding =
        tenant.appConfig?.brand ?? tenant.tenantConfig?.brand ?? const TenantBranding();
    final primary = branding.primary != null ? Color(branding.primary!) : null;
    final secondary = branding.secondary != null ? Color(branding.secondary!) : null;

    return Consumer<LocaleProvider>(
      builder: (context, localeProv, _) {
        // Sync allowed locales from tenant config, but only keep locales that exist in compiled localizations.
        final supported =
            S.supportedLocales.map((l) => l.languageCode.toLowerCase()).toSet();
        final desired = <String>{
          'en',
          ...tenant.uiLocales
              .map((c) => c.trim().toLowerCase())
              .where((c) => c.isNotEmpty),
        }.where((c) => supported.contains(c)).toList()
          ..sort();

        if (!_sameStringList(_lastAllowedLocaleCodes, desired)) {
          _lastAllowedLocaleCodes = desired;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            localeProv.setAllowedLocaleCodes(desired);
          });
        }

        // When the tenant/app edition changes, reset UI language to English by default.
        final tenantKey = '${tenant.tenantId}|${tenant.appId ?? ''}';
        if (_lastTenantKeyForLocale == null) {
          _lastTenantKeyForLocale = tenantKey; // baseline; don't override on first build
        } else if (_lastTenantKeyForLocale != tenantKey) {
          _lastTenantKeyForLocale = tenantKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            localeProv.setLocale(const Locale('en'));
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

Future<String> _getTenantContentLocale(String tenantId) async {
  try {
    final snap = await FirebaseFirestore.instance.collection('tenants').doc(tenantId).get();
    final data = snap.data() ?? <String, dynamic>{};
    final uiLocales = data['uiLocales'];
    if (uiLocales is List && uiLocales.length >= 2) {
      final v = uiLocales[1].toString().trim().toLowerCase();
      if (v.isNotEmpty) return v;
    }
  } catch (_) {
    // ignore
  }
  return 'en';
}

Future<void> scheduleDailyTasks(
  FlutterLocalNotificationsPlugin plugin, {
  required String tenantId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final now = tz.TZDateTime.now(tz.local);
  final contentLocale = await _getTenantContentLocale(tenantId);

  // Learn-word reminder at user-selected hour and minute
  // (New words is handled via FCM daily digest; avoid duplicate local notifications.)
  final learnHour = prefs.getInt('learnWordHour') ?? 10;
  final learnMinute = prefs.getInt('learnWordMinute') ?? 0;
  final category = prefs.getString('notificationCategory') ?? 'Random';
  debugPrint('LearnWord prefs: hour=$learnHour, minute=$learnMinute, category=$category');
  if (prefs.getBool('notifyLearnWord') ?? true) {
    // Ensure we don't leave an old schedule behind.
    try {
      await flutterLocalNotificationsPlugin.cancel(200);
    } catch (_) {}

    final nextLearnTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      learnHour,
      learnMinute,
    );
    final scheduledLearn = nextLearnTime.isBefore(now)
        ? nextLearnTime.add(const Duration(days: 1))
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
        final allSnapshot =
            await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId).get();
        if (allSnapshot.docs.isEmpty) return;
        snapshot = allSnapshot;
      }
    }

    final docs = snapshot.docs.toList()..shuffle();
    if (docs.isEmpty) return;
    final pick = docs.first;
    final pickData = pick.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final wordEnglish = ConceptText.labelFor(pickData, lang: 'en', fallbackLang: 'en');
    final wordLocal =
        ConceptText.labelFor(pickData, lang: contentLocale, fallbackLang: 'en');

    final wordEnglishCapitalized = wordEnglish.isEmpty
        ? wordEnglish
        : '${wordEnglish[0].toUpperCase()}${wordEnglish.substring(1)}';
    final bodyText = '$wordEnglishCapitalized $wordLocal';

    final args = jsonEncode({
      'route': '/video',
      'args': {
        'wordId': pick.id,
        'english': wordEnglish,
        'bengali': wordLocal,
        'variants': pick['variants'],
      }
    });

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
    );
  }
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
}) async {
  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidImpl?.createNotificationChannel(AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.high,
  ));

  tz.TZDateTime when = tz.TZDateTime.from(scheduledDate, tz.local);
  final now = tz.TZDateTime.now(tz.local);
  if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
  if (!when.isAfter(now.add(const Duration(seconds: 5)))) {
    when = now.add(const Duration(seconds: 6));
  }

  const mode = AndroidScheduleMode.inexactAllowWhileIdle;

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
    matchDateTimeComponents: DateTimeComponents.time,
  );
}


