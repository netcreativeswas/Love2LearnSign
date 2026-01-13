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

  /// Fast UI helper: get last cached token balance (may be null if never cached).
  Future<int?> getCachedQuizTokens() => _getCachedTokens(_TokenType.quiz);

  /// Fast UI helper: get last cached token balance (may be null if never cached).
  Future<int?> getCachedFlashcardTokens() => _getCachedTokens(_TokenType.flashcard);

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

    // Verify user is still authenticated before making Firestore request
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      debugPrint('⚠️ User no longer authenticated (userId changed or logged out). Using local storage fallback.');
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
      final errorStr = e.toString();
      final isPermissionError = errorStr.contains('permission-denied') || 
                                 errorStr.contains('PERMISSION_DENIED') ||
                                 errorStr.contains('permission_denied');
      
      if (isPermissionError) {
        debugPrint('⚠️ Permission denied for user_counters videoViews (userId: $userId). Possible causes: App Check not initialized, token expired, or user logged out. Using local storage fallback.');
      } else {
        debugPrint('❌ Error incrementing video view: $e');
      }
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

    // Verify user is still authenticated before making Firestore request
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      debugPrint('⚠️ User no longer authenticated (userId changed or logged out). Using local storage fallback.');
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
      final errorStr = e.toString();
      final isPermissionError = errorStr.contains('permission-denied') || 
                                 errorStr.contains('PERMISSION_DENIED') ||
                                 errorStr.contains('permission_denied');
      
      if (isPermissionError) {
        debugPrint('⚠️ Permission denied for user_counters videoViews reset (userId: $userId). Possible causes: App Check not initialized, token expired, or user logged out. Using local storage fallback.');
      } else {
        debugPrint('❌ Error resetting video view remotely: $e');
      }
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
    final tokens = await _optimisticAddTokens(
      _TokenType.flashcard,
      _rewardedAdUnlockSessions,
    );
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
    final tokens = await _optimisticAddTokens(
      _TokenType.quiz,
      _rewardedAdUnlockSessions,
    );
    debugPrint('✅ Quiz tokens restored to $tokens');
    return tokens;
  }

  /// Optimistically add tokens and update local cache immediately for snappy UI.
  /// Firestore is updated in the background (best-effort) to avoid a 1–3s UI lag after rewarded ads.
  Future<int> _optimisticAddTokens(_TokenType type, int amount) async {
    final userId = _userId;

    // Compute baseline from cached/local state (fast).
    int current;
    if (userId == null) {
      current = (await _ensureTokenStateLocal(type, userId: null)).tokens;
    } else {
      final cached = await _getCachedTokens(type);
      if (cached != null) {
        current = cached;
      } else {
        current = (await _ensureTokenStateLocal(type, userId: userId)).tokens;
      }
    }

    if (current >= _tokenCap) return current;
    final next = math.min(current + amount, _tokenCap);

    // Update local storage immediately (what the UI reads for instant display).
    if (userId == null) {
      await _setTokenCountLocal(type, next, userId: null);
    } else {
      await _cacheTokens(type, userId: userId, tokens: next, lastRefresh: _currentMonthKey);
    }

    // Best-effort remote sync (do not block UI).
    if (userId != null) {
      Future(() async {
        try {
          final counterRef = _firestore.collection('user_counters').doc(userId);
          await counterRef.set({
            _tokenFieldName(type): next,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('⚠️ Token remote sync failed (non-fatal): $e');
        }
      });
    }

    return next;
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
      return _ensureTokenStateLocal(type, userId: null);
    }

    // Verify user is still authenticated before making Firestore request
    // This prevents race conditions where user logs out between getting userId and making request
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      debugPrint('⚠️ User no longer authenticated (userId changed or logged out). Using local storage fallback.');
      return _ensureTokenStateLocal(type, userId: userId);
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

      // Cache locally for instant UI on next visit (even if Firestore is slow).
      await _cacheTokens(type, userId: userId, tokens: tokens, lastRefresh: lastRefresh);
      return _TokenState(tokens);
    } catch (e) {
      final errorStr = e.toString();
      final isPermissionError = errorStr.contains('permission-denied') || 
                                 errorStr.contains('PERMISSION_DENIED') ||
                                 errorStr.contains('permission_denied');
      
      if (isPermissionError) {
        debugPrint('⚠️ Permission denied for user_counters (userId: $userId). Possible causes: App Check not initialized, token expired, or user logged out. Using local storage fallback.');
      } else {
        debugPrint('❌ Error ensuring token state remotely: $e');
      }
      // Fallback to local storage if Firestore fails (e.g., permission denied, App Check / network issues).
      return _ensureTokenStateLocal(type, userId: userId);
    }
  }

  Future<void> _setTokenCount(_TokenType type, int tokens) async {
    final clamped = math.max(0, math.min(tokens, _tokenCap));
    final userId = _userId;
    if (userId == null) {
      await _setTokenCountLocal(type, clamped, userId: null);
      return;
    }

    // Verify user is still authenticated before making Firestore request
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      debugPrint('⚠️ User no longer authenticated (userId changed or logged out). Using local storage fallback.');
      await _setTokenCountLocal(type, clamped, userId: userId);
      return;
    }

    try {
      final counterRef = _firestore.collection('user_counters').doc(userId);
      await counterRef.set({
        _tokenFieldName(type): clamped,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Keep cache in sync.
      await _cacheTokens(type, userId: userId, tokens: clamped, lastRefresh: _currentMonthKey);
    } catch (e) {
      final errorStr = e.toString();
      final isPermissionError = errorStr.contains('permission-denied') || 
                                 errorStr.contains('PERMISSION_DENIED') ||
                                 errorStr.contains('permission_denied');
      
      if (isPermissionError) {
        debugPrint('⚠️ Permission denied for user_counters write (userId: $userId). Possible causes: App Check not initialized, token expired, or user logged out. Using local storage fallback.');
      } else {
        debugPrint('❌ Error setting token count remotely: $e');
      }
      // Fallback to local storage if Firestore fails (e.g., permission denied for freeUser)
      await _setTokenCountLocal(type, clamped, userId: userId);
    }
  }

  Future<_TokenState> _ensureTokenStateLocal(_TokenType type, {required String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final tokensKey = userId == null ? _guestTokenKey(type) : _userTokenKey(userId, type);
    final refreshKey = userId == null ? _guestRefreshKey(type) : _userRefreshKey(userId, type);

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

  Future<void> _setTokenCountLocal(_TokenType type, int tokens, {required String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = math.max(0, math.min(tokens, _tokenCap));
    final tokensKey = userId == null ? _guestTokenKey(type) : _userTokenKey(userId, type);
    final refreshKey = userId == null ? _guestRefreshKey(type) : _userRefreshKey(userId, type);
    await prefs.setInt(tokensKey, clamped);
    await prefs.setString(refreshKey, _currentMonthKey);
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

  String _userTokenKey(String userId, _TokenType type) => 'user_${userId}_${type.name}_tokens';

  String _userRefreshKey(String userId, _TokenType type) => 'user_${userId}_${type.name}_last_refresh';

  Future<void> _cacheTokens(
    _TokenType type, {
    required String userId,
    required int tokens,
    required String lastRefresh,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userTokenKey(userId, type), tokens);
      await prefs.setString(_userRefreshKey(userId, type), lastRefresh);
    } catch (_) {
      // non-fatal
    }
  }

  Future<int?> _getCachedTokens(_TokenType type) async {
    try {
      final uid = _userId;
      final prefs = await SharedPreferences.getInstance();
      final key = uid == null ? _guestTokenKey(type) : _userTokenKey(uid, type);
      return prefs.getInt(key);
    } catch (_) {
      return null;
    }
  }
}

enum _TokenType { flashcard, quiz }

class _TokenState {
  _TokenState(this.tokens);
  final int tokens;
}
