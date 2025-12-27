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

  /// Planifie une notification pour la révision d'un mot
  Future<void> scheduleReviewNotification(WordToReview word) async {
    try {
      if (word.nextReviewDate == null) return;
      // Read user prefs (toggle + time). Defaults: enabled, 12:00
      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool('notifyFlashcardReview') ?? true;
      if (!enabled) return;
      final int hour = prefs.getInt('flashReviewHour') ?? 12;
      final int minute = prefs.getInt('flashReviewMinute') ?? 0;

      // Build scheduled datetime at user's chosen hour/min on the review date (local tz)
      final DateTime d = word.nextReviewDate!;
      final tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, d.year, d.month, d.day, hour, minute);
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

      // Exact alarms are often not permitted; fallback to inexact scheduling.
      final canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
      final mode = canExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

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
      final words = await SpacedRepetitionService().getAllWordsToReview();
      final wordsToReview = words.where((word) => word.status == 'À revoir').toList();
      
      for (final word in wordsToReview) {
        await scheduleReviewNotification(word);
      }
    } catch (e) {
      // Log error but don't crash the app
      print('Failed to schedule all review notifications: $e');
    }
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
    AndroidScheduleMode androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
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
      androidScheduleMode: androidScheduleMode,
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
    AndroidScheduleMode androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
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
      androidScheduleMode: androidScheduleMode,
      payload: payload,
    );
  }
}
