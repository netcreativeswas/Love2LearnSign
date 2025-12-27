import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class SearchTrackingService {
  static final SearchTrackingService _instance = SearchTrackingService._internal();
  factory SearchTrackingService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _sessionId = const Uuid().v4(); // Anonymous session ID per app start

  SearchTrackingService._internal();

  // Main method to log a search
  Future<void> logSearch({
    required String query,
    required int resultCount,
    required bool found,
    String? category,
  }) async {
    final sanitized = _sanitizeQuery(query);
    if (sanitized == null) {
      debugPrint('Skipping analytics log for invalid query: "$query"');
      return;
    }

    try {
      await _firestore.collection('searchAnalytics').add({
        'query': sanitized,
        'query_lower': sanitized.toLowerCase(), // For easy aggregation
        'timestamp': FieldValue.serverTimestamp(),
        'found': found,
        'resultCount': resultCount,
        'sessionId': _sessionId,
        'category': category ?? 'All',
      });
      debugPrint('Search logged: $query ($resultCount results)');
    } catch (e) {
      debugPrint('Error logging search: $e');
    }
  }

  // Fetch analytics data (Top searches, missing words, etc.)
  // For a small app, we can fetch recent logs and aggregate client-side.
  Future<Map<String, dynamic>> getAnalyticsData({int days = 30}) async {
    final now = DateTime.now();
    final selectedCutoff = now.subtract(Duration(days: days));
    final cutoff7 = now.subtract(const Duration(days: 7));
    final cutoff30 = now.subtract(const Duration(days: 30));
    final fetchCutoff = now.subtract(Duration(days: days > 90 ? days : 90));

    try {
      final snapshot = await _firestore
          .collection('searchAnalytics')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(fetchCutoff))
          .orderBy('timestamp', descending: true)
          .limit(5000) // safety guard
          .get();

      final docs = snapshot.docs;

      final Map<String, _TermStats> selectedRange = {};
      final Map<String, _TermStats> sevenDayRange = {};
      final Map<String, _TermStats> thirtyDayRange = {};
      final Map<String, int> categoryFrequency = {};
      // Daily heatmap aggregation (LOCAL day buckets)
      final Map<String, int> dailySearches = {}; // yyyy-MM-dd -> count
      final Map<String, Set<String>> dailySessions = {}; // yyyy-MM-dd -> unique sessionIds

      void track(Map<String, _TermStats> map, String key, String display, bool found) {
        final stats = map.putIfAbsent(key, () => _TermStats(display));
        stats.total += 1;
        if (!found) stats.missing += 1;
      }

      for (final doc in docs) {
        final data = doc.data();
        final rawQuery = (data['query'] as String?) ?? '';
        final normalizedDisplay = rawQuery.trim();
        if (normalizedDisplay.isEmpty) continue;

        final storedLower = (data['query_lower'] as String?)?.trim() ?? '';
        final lowerKey = storedLower.isNotEmpty ? storedLower : normalizedDisplay.toLowerCase();
        final found = data['found'] as bool? ?? false;
        final category = (data['category'] as String?)?.trim();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

        if (timestamp == null) continue;

        final isInSelectedRange = !timestamp.isBefore(selectedCutoff);
        final isIn7 = !timestamp.isBefore(cutoff7);
        final isIn30 = !timestamp.isBefore(cutoff30);

        if (isInSelectedRange) {
          track(selectedRange, lowerKey, rawQuery, found);
          if (category != null && category.isNotEmpty && found) {
            categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;
          }
          // Bucket by LOCAL day so the heatmap matches what users perceive as "a day"
          // on their device / in their browser (instead of UTC).
          final local = timestamp.toLocal();
          final dayLocal = DateTime(local.year, local.month, local.day);
          final key = dayLocal.toIso8601String().substring(0, 10); // yyyy-MM-dd
          dailySearches[key] = (dailySearches[key] ?? 0) + 1;
          final sessionId = (data['sessionId'] as String?)?.trim();
          if (sessionId != null && sessionId.isNotEmpty) {
            dailySessions.putIfAbsent(key, () => <String>{}).add(sessionId);
          }
        }

        if (isIn7) {
          track(sevenDayRange, lowerKey, rawQuery, found);
        }

        if (isIn30) {
          track(thirtyDayRange, lowerKey, rawQuery, found);
        }
      }

      List<Map<String, dynamic>> _formatTotals(Map<String, _TermStats> source, {int? limit, bool missingOnly = false}) {
        final entries = source.entries.where((entry) => !missingOnly || entry.value.missing > 0).toList()
          ..sort((a, b) {
            final statA = missingOnly ? a.value.missing : a.value.total;
            final statB = missingOnly ? b.value.missing : b.value.total;
            final compare = statB.compareTo(statA);
            if (compare != 0) return compare;
            return a.value.display.toLowerCase().compareTo(b.value.display.toLowerCase());
          });

        final limited = limit != null ? entries.take(limit) : entries;
        return limited
            .map((entry) => {
                  'term': entry.value.display,
                  'count': missingOnly ? entry.value.missing : entry.value.total,
                })
            .toList();
      }

      final selectedTopSearches = _formatTotals(selectedRange, limit: 100);
      final sevenDayTopSearches = _formatTotals(sevenDayRange, limit: 50);
      final thirtyDayTopSearches = _formatTotals(thirtyDayRange, limit: 100);
      final selectedMissingWords = _formatTotals(selectedRange, missingOnly: true);

      final sortedCategories = categoryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final totalSelectedSearches = selectedRange.values.fold<int>(0, (sum, stat) => sum + stat.total);

      final heatmap = dailySearches.entries
          .map((e) => {
                'date': e.key,
                'searches': e.value,
                'sessions': (dailySessions[e.key]?.length ?? 0),
              })
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo((b['date'] as String)));

      return {
        'topSearches': selectedTopSearches,
        'topSearches7': sevenDayTopSearches,
        'topSearches30': thirtyDayTopSearches,
        'topMissing': selectedMissingWords,
        'missingWordsCopyList': selectedMissingWords.map((item) => item['term'] as String).toList(),
        'topCategories': sortedCategories.map((e) => {'category': e.key, 'count': e.value}).take(10).toList(),
        // Daily usage heatmap (LOCAL day buckets), each item: {date: yyyy-MM-dd, searches: int, sessions: int}
        'heatmap': heatmap,
        'totalSearches': totalSelectedSearches,
      };
    } catch (e) {
      // Important: don't silently return {} — it makes the dashboard look "empty"
      // when the real issue is permission/config.
      debugPrint('Error fetching analytics: $e');
      rethrow;
    }
  }

  Future<void> clearAllAnalytics() async {
    const pageSize = 200;
    while (true) {
      final batchSnapshot = await _firestore.collection('searchAnalytics').limit(pageSize).get();
      if (batchSnapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in batchSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (batchSnapshot.docs.length < pageSize) break;
    }
  }

  Future<void> clearAnalyticsOlderThan(Duration age) async {
    final cutoff = DateTime.now().subtract(age);
    const pageSize = 200;
    while (true) {
      final batchSnapshot = await _firestore
          .collection('searchAnalytics')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
          .limit(pageSize)
          .get();
      if (batchSnapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in batchSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (batchSnapshot.docs.length < pageSize) break;
    }
  }

  static final RegExp _multiSpaceRegex = RegExp(r'\s+');
  static final RegExp _validLetterRegex = RegExp(r'[a-z\u0980-\u09FF]');
  static final RegExp _letterDetector = RegExp(r'\p{L}', unicode: true);

  String? _sanitizeQuery(String input) {
    if (input.trim().isEmpty) return null;

    final collapsedSpaces = input.trim().replaceAll(_multiSpaceRegex, ' ');
    final normalized = _lowercaseEnglish(collapsedSpaces);
    final runeCount = normalized.runes.length;

    if (runeCount < 2) return null;
    if (!_validLetterRegex.hasMatch(normalized)) return null;

    final stripped = normalized.replaceAll(' ', '');
    if (stripped.isEmpty) return null;

    if (_isSingleCharNoise(stripped)) return null;
    if (!_containsOnlyAllowedScripts(normalized)) return null;

    return normalized;
  }

  static String _lowercaseEnglish(String value) {
    final buffer = StringBuffer();
    for (final code in value.runes) {
      if (_isUppercaseEnglish(code)) {
        buffer.writeCharCode(code + 32); // convert A-Z to a-z
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  static bool _isUppercaseEnglish(int codeUnit) => codeUnit >= 0x41 && codeUnit <= 0x5A;
  static bool _isEnglishLetter(int codeUnit) =>
      (codeUnit >= 0x41 && codeUnit <= 0x5A) || (codeUnit >= 0x61 && codeUnit <= 0x7A);
  static bool _isBengaliLetter(int codeUnit) => codeUnit >= 0x0980 && codeUnit <= 0x09FF;

  static bool _isSingleCharNoise(String value) {
    if (value.length <= 3) return false;
    final iterator = value.runes.iterator;
    if (!iterator.moveNext()) return false;
    final first = iterator.current;
    while (iterator.moveNext()) {
      if (iterator.current != first) return false;
    }
    return true;
  }

  static bool _containsOnlyAllowedScripts(String value) {
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final isLetter = _letterDetector.hasMatch(char);
      if (!isLetter) continue;
      if (!_isEnglishLetter(rune) && !_isBengaliLetter(rune)) {
        return false;
      }
    }
    return true;
  }
}

class _TermStats {
  _TermStats(this.display);
  final String display;
  int total = 0;
  int missing = 0;
}

