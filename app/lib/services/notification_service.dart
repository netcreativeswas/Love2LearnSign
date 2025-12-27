import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'spaced_repetition_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Ensure a strictly future time to avoid "Must be a date in the future"
  tz.TZDateTime _ensureFuture(tz.TZDateTime t) {
    final now = tz.TZDateTime.now(tz.local);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    if (!t.isAfter(now.add(const Duration(seconds: 5)))) {
      t = now.add(const Duration(seconds: 6));
    }
    return t;
  }

  // Compute noon (12:00) at/after a given date, guaranteed to be in the future
  tz.TZDateTime _noonOnOrAfter(DateTime date) {
    final base = tz.TZDateTime(tz.local, date.year, date.month, date.day, 12, 0);
    return _ensureFuture(base);
  }

  Future<void> initialize() async {
    // Timezone database + set device local zone
    tzdata.initializeTimeZones();
    final localName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(initSettings);
    // Permission requests are orchestrated centrally in main.dart to avoid duplicates
  }

  /// Planifie une notification pour la révision d'un mot
  Future<void> scheduleReviewNotification(WordToReview word) async {
    if (word.nextReviewDate == null) return;

    final id = word.wordId.hashCode;
    final title = '📚 Time to Review!';
    final body = 'Let’s review your flashcards for today.';

    // Schedule one-shot at 12:00 on the due date (or next valid noon if past)
    final when = _noonOnOrAfter(word.nextReviewDate!);

    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    final mode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flashcard_review',
          'Flashcard Review',
          channelDescription: 'Notifications for flashcard review reminders',
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
      androidScheduleMode: mode,
      // one-shot: no matchDateTimeComponents here
    );
  }

  /// Annule une notification planifiée
  Future<void> cancelReviewNotification(WordToReview word) async {
    final id = word.wordId.hashCode;
    await _notifications.cancel(id);
  }

  /// Planifie des notifications pour tous les mots à réviser
  Future<void> scheduleAllReviewNotifications() async {
    final service = SpacedRepetitionService();
    final allWords = await service.getAllWordsToReview();
    
    for (final word in allWords) {
      if (word.status == 'À revoir' && word.nextReviewDate != null) {
        await scheduleReviewNotification(word);
      }
    }
  }

  /// Annule toutes les notifications de révision
  Future<void> cancelAllReviewNotifications() async {
    await _notifications.cancelAll();
  }
}