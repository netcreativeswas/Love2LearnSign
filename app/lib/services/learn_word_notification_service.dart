import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:l2l_shared/tenancy/concept_text.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class LearnWordNotificationService {
  static const int legacyDailyId = 200; // previous repeating strategy
  static const String _scheduledDayIdsKey = 'learnWordScheduledDayIds';
  static const int _dayIdOffset = 50000000; // avoid collisions with 100/200/300/flash offsets

  // Keep well under iOS pending notification limit (64) while leaving room for other schedules.
  static const int defaultDaysAhead = 21;

  int _dayId(tz.TZDateTime t) {
    final key = t.year * 10000 + t.month * 100 + t.day; // yyyymmdd
    return _dayIdOffset + key;
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

  Future<void> cancelAll(FlutterLocalNotificationsPlugin plugin) async {
    // Cancel legacy repeating id (if present).
    try {
      await plugin.cancel(legacyDailyId);
    } catch (_) {}

    // Cancel batch scheduled day ids.
    final ids = await _loadScheduledDayIds();
    for (final id in ids) {
      try {
        await plugin.cancel(id);
      } catch (_) {}
    }
    await _saveScheduledDayIds(const <int>[]);
  }

  Future<void> scheduleBatch({
    required FlutterLocalNotificationsPlugin plugin,
    required String tenantId,
    required int hour,
    required int minute,
    required String category,
    required String contentLocale,
    int daysAhead = defaultDaysAhead,
  }) async {
    await cancelAll(plugin);

    // Ensure channel exists on Android
    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'learn_word_channel',
      'Learn Word Notifications',
      description: 'Daily reminder to learn a new word',
      importance: Importance.high,
    ));

    // Load candidate concepts once, then pick deterministically per day.
    Query query = TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId);
    QuerySnapshot snap = await query.get();
    if (category != 'Random') {
      final filtered = await query.where('category_main', isEqualTo: category).get();
      if (filtered.docs.isNotEmpty) {
        snap = filtered;
      }
    }
    if (snap.docs.isEmpty) return;

    // Stable order for deterministic index selection.
    final docs = snap.docs.toList()..sort((a, b) => a.id.compareTo(b.id));

    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!first.isAfter(now)) {
      first = first.add(const Duration(days: 1));
    }

    final scheduledIds = <int>[];
    final int count = daysAhead.clamp(1, 60);

    for (int i = 0; i < count; i++) {
      final when = first.add(Duration(days: i));
      final id = _dayId(when);

      final dateKey = '${when.year.toString().padLeft(4, '0')}${when.month.toString().padLeft(2, '0')}${when.day.toString().padLeft(2, '0')}';
      final seed = '$tenantId|$category|$dateKey';
      final idx = _fnv1a32(seed) % docs.length;
      final pick = docs[idx];
      final data = (pick.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};

      final english = ConceptText.labelFor(data, lang: 'en', fallbackLang: 'en');
      final local = ConceptText.labelFor(data, lang: contentLocale, fallbackLang: 'en');

      final englishCap = english.isEmpty
          ? english
          : '${english[0].toUpperCase()}${english.substring(1)}';
      final body = local.trim().isEmpty ? englishCap : '$englishCap $local';

      final payload = jsonEncode({
        'route': '/video',
        'args': {
          'wordId': pick.id,
          'english': english,
          'bengali': local,
          'variants': (data['variants'] as List?) ?? const [],
        }
      });

      // Play Store safe: avoid exact alarms; schedule inexact and let the OS batch if needed.
      const mode = AndroidScheduleMode.inexactAllowWhileIdle;

      await plugin.zonedSchedule(
        id,
        'Learn one Sign Today!',
        body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'learn_word_channel',
            'Learn Word Notifications',
            channelDescription: 'Daily reminder to learn a new word',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            actions: const <AndroidNotificationAction>[
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
      );

      scheduledIds.add(id);
    }

    await _saveScheduledDayIds(scheduledIds);
    if (kDebugMode) {
      debugPrint('📅 LearnWord: scheduled ${scheduledIds.length} days ahead (tenantId=$tenantId, category=$category)');
    }
  }

  static int _fnv1a32(String input) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}

