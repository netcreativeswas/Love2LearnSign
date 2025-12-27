import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking video views and game sessions
class SessionCounterService {
  static final SessionCounterService _instance =
      SessionCounterService._internal();
  factory SessionCounterService() => _instance;
  SessionCounterService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _interstitialAdThreshold = 8;
  static const int _rewardedAdUnlockSessions = 3;
  static const int _monthlyTokenRegenAmount = 2;
  static const int _tokenCap = 10;
  static const int rewardBundleSize = _rewardedAdUnlockSessions;
  static const int tokenCap = _tokenCap;
  static const int interstitialAdThreshold = _interstitialAdThreshold;

  /// Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Get current month key (YYYY-MM format)
  String get _currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Increment video view counter and check if interstitial ad should be shown
  /// Returns true if interstitial ad should be shown
  Future<bool> incrementVideoView() async {
    final count = await incrementVideoViewCount();
    if (count >= _interstitialAdThreshold) {
      await resetVideoViewCount();
      return true;
    }
    return false;
  }

  /// Increment video view counter and return the updated count.
  /// Does NOT reset automatically at threshold (callers can decide when to reset,
  /// e.g. only after a successful interstitial show).
  Future<int> incrementVideoViewCount() async {
    final userId = _userId;
    if (userId == null) {
      debugPrint('⚠️ No user logged in, using local video view counter');
      return await _incrementVideoViewCountLocal();
    }

    try {
      final counterRef = _firestore.collection('user_counters').doc(userId);
      final doc = await counterRef.get();
      int currentCount = 0;

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentCount = (data['videoViews'] as int?) ?? 0;
      }

      final newCount = currentCount + 1;
      await counterRef.set({
        'videoViews': newCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('📹 Video view count: $newCount');
      return newCount;
    } catch (e) {
      debugPrint('❌ Error incrementing video view: $e');
      return await _incrementVideoViewCountLocal();
    }
  }

  /// Reset video view counter to 0 (remote when signed in, local otherwise).
  Future<void> resetVideoViewCount() async {
    final userId = _userId;
    if (userId == null) {
      await _resetVideoViewCountLocal();
      return;
    }

    try {
      final counterRef = _firestore.collection('user_counters').doc(userId);
        await counterRef.set({
          'videoViews': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error resetting video view remotely: $e');
      await _resetVideoViewCountLocal();
    }
  }

  /// Fallback to local storage for video views
  Future<bool> _incrementVideoViewLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'video_views_${_userId ?? 'anonymous'}';
      final currentCount = prefs.getInt(key) ?? 0;
      final newCount = currentCount + 1;
      await prefs.setInt(key, newCount);

      if (newCount >= _interstitialAdThreshold) {
        await prefs.setInt(key, 0);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error in local video view tracking: $e');
      return false;
    }
  }

  Future<int> _incrementVideoViewCountLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'video_views_${_userId ?? 'anonymous'}';
      final currentCount = prefs.getInt(key) ?? 0;
      final newCount = currentCount + 1;
      await prefs.setInt(key, newCount);
      return newCount;
    } catch (e) {
      debugPrint('❌ Error in local video view tracking: $e');
      return 0;
    }
  }

  Future<void> _resetVideoViewCountLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'video_views_${_userId ?? 'anonymous'}';
      await prefs.setInt(key, 0);
    } catch (e) {
      debugPrint('❌ Error resetting local video view counter: $e');
    }
  }

  /// Check if user can start a flashcard session.
  Future<
      ({
        bool canStart,
        int tokens,
        int maxTokens,
      })> checkFlashcardSession() async {
    final tokens = await _getTokenBalance(_TokenType.flashcard);
    return (canStart: tokens > 0, tokens: tokens, maxTokens: _tokenCap);
  }

  /// Record a flashcard session start (returns true if a token was consumed).
  Future<bool> recordFlashcardSession() async {
    return _consumeToken(_TokenType.flashcard);
  }

  /// Add flashcard tokens via rewarded ad.
  Future<int> unlockFlashcardSessions() async {
    final tokens =
        await _addTokens(_TokenType.flashcard, _rewardedAdUnlockSessions);
    debugPrint('✅ Flashcard tokens restored to $tokens');
    return tokens;
  }

  /// Check if user can start a quiz session.
  Future<
      ({
        bool canStart,
        int tokens,
        int maxTokens,
      })> checkQuizSession() async {
    final tokens = await _getTokenBalance(_TokenType.quiz);
    return (canStart: tokens > 0, tokens: tokens, maxTokens: _tokenCap);
  }

  /// Record a quiz session start (returns true if a token was consumed).
  Future<bool> recordQuizSession() async {
    return _consumeToken(_TokenType.quiz);
  }

  /// Add quiz tokens via rewarded ad.
  Future<int> unlockQuizSessions() async {
    final tokens =
        await _addTokens(_TokenType.quiz, _rewardedAdUnlockSessions);
    debugPrint('✅ Quiz tokens restored to $tokens');
    return tokens;
  }

  Future<int> _getTokenBalance(_TokenType type) async {
    final state = await _ensureTokenState(type);
    return state.tokens;
  }

  Future<bool> _consumeToken(_TokenType type) async {
    final state = await _ensureTokenState(type);
    if (state.tokens <= 0) {
      return false;
    }
    await _setTokenCount(type, state.tokens - 1);
    return true;
  }

  Future<int> _addTokens(_TokenType type, int amount) async {
    final state = await _ensureTokenState(type);
    if (state.tokens >= _tokenCap) {
      return state.tokens;
    }
    final newTotal = math.min(state.tokens + amount, _tokenCap);
    await _setTokenCount(type, newTotal);
    return newTotal;
  }

  Future<_TokenState> _ensureTokenState(_TokenType type) async {
    final userId = _userId;
    if (userId == null) {
      return _ensureTokenStateLocal(type);
    }

    try {
      final counterRef = _firestore.collection('user_counters').doc(userId);
      final snapshot = await counterRef.get();
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final tokensField = _tokenFieldName(type);
      final refreshField = _refreshFieldName(type);

      int tokens = (data[tokensField] as int?) ?? _monthlyTokenRegenAmount;
      String lastRefresh = (data[refreshField] as String?) ?? '';
      final currentMonth = _currentMonthKey;

      if (lastRefresh != currentMonth) {
        tokens = math.min(tokens + _monthlyTokenRegenAmount, _tokenCap);
        lastRefresh = currentMonth;
      }

      await counterRef.set({
        tokensField: tokens,
        refreshField: lastRefresh,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return _TokenState(tokens);
    } catch (e) {
      debugPrint('❌ Error ensuring token state remotely: $e');
      return _ensureTokenStateLocal(type);
    }
  }

  Future<void> _setTokenCount(_TokenType type, int tokens) async {
    final clamped = math.max(0, math.min(tokens, _tokenCap));
    final userId = _userId;
    if (userId == null) {
      await _setTokenCountLocal(type, clamped);
      return;
    }

    try {
      final counterRef = _firestore.collection('user_counters').doc(userId);
      await counterRef.set({
        _tokenFieldName(type): clamped,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error setting token count remotely: $e');
      // Fallback to local storage if Firestore fails (e.g., permission denied for freeUser)
      await _setTokenCountLocal(type, clamped);
    }
  }

  Future<_TokenState> _ensureTokenStateLocal(_TokenType type) async {
    final prefs = await SharedPreferences.getInstance();
    final tokensKey = _guestTokenKey(type);
    final refreshKey = _guestRefreshKey(type);

    int tokens = prefs.getInt(tokensKey) ?? _monthlyTokenRegenAmount;
    final currentMonth = _currentMonthKey;
    String lastRefresh = prefs.getString(refreshKey) ?? '';

    if (lastRefresh != currentMonth) {
      tokens = math.min(tokens + _monthlyTokenRegenAmount, _tokenCap);
      lastRefresh = currentMonth;
    }

    await prefs.setInt(tokensKey, tokens);
    await prefs.setString(refreshKey, lastRefresh);

    return _TokenState(tokens);
  }

  Future<void> _setTokenCountLocal(_TokenType type, int tokens) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = math.max(0, math.min(tokens, _tokenCap));
    await prefs.setInt(_guestTokenKey(type), clamped);
    await prefs.setString(_guestRefreshKey(type), _currentMonthKey);
  }

  String _tokenFieldName(_TokenType type) {
    switch (type) {
      case _TokenType.flashcard:
        return 'flashcardTokens';
      case _TokenType.quiz:
        return 'quizTokens';
    }
  }

  String _refreshFieldName(_TokenType type) {
    switch (type) {
      case _TokenType.flashcard:
        return 'flashcardLastTokenRefresh';
      case _TokenType.quiz:
        return 'quizLastTokenRefresh';
    }
  }

  String _guestTokenKey(_TokenType type) => 'guest_${type.name}_tokens';

  String _guestRefreshKey(_TokenType type) =>
      'guest_${type.name}_last_refresh';
}

enum _TokenType { flashcard, quiz }

class _TokenState {
  _TokenState(this.tokens);
  final int tokens;
}
