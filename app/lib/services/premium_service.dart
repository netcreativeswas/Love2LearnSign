import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing premium state and monthly reminders
class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _lastReminderKey = 'last_premium_reminder_date';
  static const String _learnedSignsCountKey = 'learned_signs_count';
  static const String _interstitialCtaDismissedKey = 'interstitial_cta_dismissed_date';

  /// Check if user is premium
  Future<bool> isPremium() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      // Prefer Custom Claims (fast + works even if local Firestore doc ID isn't uid).
      final user = FirebaseAuth.instance.currentUser;
      final tokenResult = await user?.getIdTokenResult();
      final claims = tokenResult?.claims;
      final rolesClaim = claims?['roles'];
      if (rolesClaim is List) {
        final roles = rolesClaim.map((e) => e.toString()).toList();
        if (roles.contains('paidUser') || roles.contains('admin')) {
          return true;
        }
      }

      // Fallback: Firestore (for older clients / if claims are not set yet).
      final doc = await _getUserDocSnapshotByUid(userId);
      if (doc == null || !doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final roles = List<String>.from(data['roles'] ?? []);
      if (!roles.contains('paidUser')) return false;
      
      // Verify subscription is active + not expired
        final isActive = data['subscription_active'] as bool? ?? false;
        if (!isActive) return false;

        final renewalDate = (data['subscription_renewal_date'] as Timestamp?)?.toDate();
        if (renewalDate == null) return false;

        return DateTime.now().isBefore(renewalDate);
    } catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      return false;
    }
  }

  Future<DocumentSnapshot?> _getUserDocSnapshotByUid(String uid) async {
    // Mirror AuthService logic: docs are commonly stored as [displayName]__[UID]
    final query = await _firestore.collection('users').where('uid', isEqualTo: uid).limit(1).get();
    if (query.docs.isNotEmpty) return query.docs.first;
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Increment learned signs count
  Future<void> incrementLearnedSigns() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('${_learnedSignsCountKey}_$userId') ?? 0;
      await prefs.setInt('${_learnedSignsCountKey}_$userId', currentCount + 1);
    } catch (e) {
      debugPrint('❌ Error incrementing learned signs: $e');
    }
  }

  /// Get learned signs count for current month
  Future<int> getLearnedSignsCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('${_learnedSignsCountKey}_$userId') ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting learned signs count: $e');
      return 0;
    }
  }

  /// Check if monthly reminder should be shown
  Future<bool> shouldShowMonthlyReminder() async {
    // Don't show if user is premium
    if (await isPremium()) return false;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReminderStr = prefs.getString('${_lastReminderKey}_$userId');
      
      if (lastReminderStr == null) {
        // First time - show reminder
        await prefs.setString('${_lastReminderKey}_$userId', DateTime.now().toIso8601String());
        return true;
      }

      final lastReminder = DateTime.parse(lastReminderStr);
      final daysSinceReminder = DateTime.now().difference(lastReminder).inDays;

      // Show reminder if 30+ days have passed
      if (daysSinceReminder >= 30) {
        await prefs.setString('${_lastReminderKey}_$userId', DateTime.now().toIso8601String());
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking monthly reminder: $e');
      return false;
    }
  }

  /// Reset learned signs count (call at start of new month)
  Future<void> resetMonthlyCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_learnedSignsCountKey}_$userId', 0);
    } catch (e) {
      debugPrint('❌ Error resetting monthly count: $e');
    }
  }

  /// Check if the interstitial premium CTA should be shown (max once per 30 days per user)
  Future<bool> shouldShowInterstitialCta() async {
    // Premium users do not see the CTA
    if (await isPremium()) return false;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _interstitialCtaDismissedKey + '_' + userId;
      final lastDismissedStr = prefs.getString(key);

      if (lastDismissedStr == null) {
        return true;
      }

      final lastDismissed = DateTime.tryParse(lastDismissedStr);
      if (lastDismissed == null) {
        return true;
      }

      final daysSinceDismissed = DateTime.now().difference(lastDismissed).inDays;
      return daysSinceDismissed >= 30;
    } catch (e) {
      debugPrint('❌ Error checking interstitial CTA frequency: $e');
      return true;
    }
  }

  /// Record that user dismissed the interstitial CTA (clicked "No thanks" or closed dialog)
  Future<void> recordInterstitialCtaDismissed() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _interstitialCtaDismissedKey + '_' + userId;
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error recording interstitial CTA dismissal: $e');
    }
  }
}

