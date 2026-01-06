import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'spaced_repetition_service.dart';

class FlashcardNotificationService {
  static final FlashcardNotificationService _instance = FlashcardNotificationService._internal();
  factory FlashcardNotificationService() => _instance;
  FlashcardNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static const int _dailyReviewId = 300;
  static const String _scheduledDayIdsKey = 'flashReviewScheduledDayIds';
  static const int _reviewDayIdOffset = 40000000; // avoid collisions with 100/200/300

  Future<({bool enabled, int hour, int minute})> _loadReviewPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('notifyFlashcardReview') ?? true;
    final int hour = prefs.getInt('flashReviewHour') ?? 12;
    final int minute = prefs.getInt('flashReviewMinute') ?? 0;
    return (enabled: enabled, hour: hour, minute: minute);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  int _dayId(DateTime d) {
    final key = d.year * 10000 + d.month * 100 + d.day; // yyyymmdd
    return _reviewDayIdOffset + key;
  }

  Future<List<int>> _loadScheduledDayIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scheduledDayIdsKey) ?? const <String>[];
    return raw.map((s) => int.tryParse(s) ?? 0).where((v) => v > 0).toList();
  }

  Future<void> _saveScheduledDayIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scheduledDayIdsKey,
      ids.map((i) => i.toString()).toList(),
    );
  }

  Future<void> _cancelScheduledDayIds() async {
    final ids = await _loadScheduledDayIds();
    for (final id in ids) {
      try {
        await _notifications.cancel(id);
      } catch (_) {}
    }
    await _saveScheduledDayIds(const <int>[]);
  }

  /// Planifie une notification pour la révision d'un mot
  Future<void> scheduleReviewNotification(
    WordToReview word, {
    bool? enabled,
    int? hour,
    int? minute,
  }) async {
    try {
      if (word.nextReviewDate == null) return;
      // Read user prefs (toggle + time). Defaults: enabled, 12:00
      final prefs = await _loadReviewPrefs();
      final bool isEnabled = enabled ?? prefs.enabled;
      if (!isEnabled) return;
      final int h = hour ?? prefs.hour;
      final int m = minute ?? prefs.minute;

      // Build scheduled datetime at user's chosen hour/min on the review date (local tz)
      final DateTime d = word.nextReviewDate!;
      final tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, d.year, d.month, d.day, h, m);
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

      // Only schedule notifications for future dates
      // Skip words that are already due or overdue
      if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
        // Word is already due or overdue - don't schedule notification
        print('Skipping notification for word ${word.wordId}: review date is not in the future (${word.nextReviewDate})');
        return;
      }

      // Ensure channel exists on Android
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        'flashcard_review',
        'Flashcard Review',
        description: 'Notifications for flashcard review reminders',
        importance: Importance.high,
      ));

      // Play Store safe: avoid exact alarms; schedule inexact and let the OS batch if needed.
      const mode = AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        word.hashCode,
        '📚 Time to review!',
        'You have flashcards to review',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flashcard_review',
            'Flashcard Review',
            channelDescription: 'Notifications for flashcard review reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: mode,
        payload: 'review_home',
      );
    } catch (e) {
      // Log error but don't crash the app
      print('Failed to schedule notification for word ${word.wordId}: $e');
    }
  }

  /// Annule une notification planifiée
  Future<void> cancelReviewNotification(WordToReview word) async {
    final id = word.wordId.hashCode;
    await _notifications.cancel(id);
  }

  Future<void> cancelReviewNotificationById(String wordId) async {
    await _notifications.cancel(wordId.hashCode);
  }

  /// Planifie des notifications pour tous les mots à réviser
  Future<void> scheduleAllReviewNotifications() async {
    try {
      await initialize();

      // Cancel legacy strategies to avoid duplicates.
      // - per-word IDs (word.hashCode)
      // - daily repeating reminder (id=300)
      final allWords = await SpacedRepetitionService().getAllWordsToReview();
      for (final w in allWords) {
        try {
          await _notifications.cancel(w.hashCode);
        } catch (_) {}
      }
      try {
        await _notifications.cancel(_dailyReviewId);
      } catch (_) {}
      await _cancelScheduledDayIds();

      // Conditional strategy: schedule only on days that actually have reviews due (daysUntilReview == 0).
      final prefs = await _loadReviewPrefs();
      if (!prefs.enabled) return;

      final dueToday = await SpacedRepetitionService().getWordsDueToday();
      if (dueToday.isEmpty) {
        // Nothing due today => no reminder.
        return;
      }

      // Schedule a one-shot notification later today at the user's chosen time (if still in the future).
      final now = tz.TZDateTime.now(tz.local);
      final when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        prefs.hour,
        prefs.minute,
      );
      if (!when.isAfter(now)) {
        // User-configured time already passed; don't notify (due-today only).
        return;
      }

      // Ensure channel exists on Android
      final androidImpl = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        'flashcard_review',
        'Flashcard Review',
        description: 'Notifications for flashcard review reminders',
        importance: Importance.high,
      ));

      final count = dueToday.length;
      final body = count == 1
          ? 'You have 1 flashcard to review'
          : 'You have $count flashcards to review';
      final id = _dayId(DateTime(now.year, now.month, now.day));

      const mode = AndroidScheduleMode.inexactAllowWhileIdle;
      await _notifications.zonedSchedule(
        id,
        '📚 Time to review!',
        body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flashcard_review',
            'Flashcard Review',
            channelDescription: 'Notifications for flashcard review reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: mode,
        payload: 'review_home',
      );

      await _saveScheduledDayIds(<int>[id]);
    } catch (e) {
      // Log error but don't crash the app
      print('Failed to schedule all review notifications: $e');
    }
  }

  /// Schedules a single daily reminder for flashcard review (iOS-safe).
  Future<void> scheduleDailyReviewReminder({required int hour, required int minute}) async {
    try {
      // Ensure plugin is initialized
      await initialize();

      // Ensure channel exists on Android
      final androidImpl =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        'flashcard_review',
        'Flashcard Review',
        description: 'Notifications for flashcard review reminders',
        importance: Importance.high,
      ));

      // Cancel previous daily reminder to avoid duplicates
      await _notifications.cancel(_dailyReviewId);

      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!when.isAfter(now)) {
        when = when.add(const Duration(days: 1));
      }

      const mode = AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        _dailyReviewId,
        '📚 Time to review!',
        'You have flashcards to review',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flashcard_review',
            'Flashcard Review',
            channelDescription: 'Notifications for flashcard review reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: mode,
        payload: 'review_home',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Failed to schedule daily review reminder: $e');
    }
  }

  Future<void> cancelDailyReviewReminder() async {
    try {
      await _notifications.cancel(_dailyReviewId);
    } catch (_) {}
  }

  /// Annule toutes les notifications de révision
  Future<void> cancelAllReviewNotifications() async {
    await _notifications.cancelAll();
  }

  /// Planifie une notification pour de nouveaux mots (compatibilité avec l'ancien système)
  Future<void> scheduleNewWordsNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    // Créer le canal de notification si nécessaire
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    ));

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Planifie une notification d'apprentissage de mot (compatibilité avec l'ancien système)
  Future<void> scheduleLearnWordNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    // Créer le canal de notification si nécessaire
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    ));

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }
}
