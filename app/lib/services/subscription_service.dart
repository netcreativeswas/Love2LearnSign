import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing in-app purchases and subscriptions
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<void> _subscriptionChanged = StreamController<void>.broadcast();
  
  // Product IDs - Replace with your actual product IDs from Google Play Console / App Store Connect
  static const String _monthlyProductId = 'premium_monthly';
  static const String _yearlyProductId = 'premium_yearly';
  
  // Android product IDs (if different)
  static const String _monthlyProductIdAndroid = 'premium_monthly';
  static const String _yearlyProductIdAndroid = 'premium_yearly';
  
  // iOS product IDs (if different)
  static const String _monthlyProductIdIOS = 'premium_monthly';
  static const String _yearlyProductIdIOS = 'premium_yearly';

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  Stream<void> get subscriptionChanged => _subscriptionChanged.stream;
  
  ProductDetails? get monthlyProduct {
    if (_products.isEmpty) return null;
    try {
      return _products.firstWhere(
        (p) => p.id == _monthlyProductId || p.id == _monthlyProductIdAndroid || p.id == _monthlyProductIdIOS,
      );
    } catch (e) {
      return null;
    }
  }
  
  ProductDetails? get yearlyProduct {
    if (_products.isEmpty) return null;
    try {
      return _products.firstWhere(
        (p) => p.id == _yearlyProductId || p.id == _yearlyProductIdAndroid || p.id == _yearlyProductIdIOS,
      );
    } catch (e) {
      return null;
    }
  }

  /// Initialize the subscription service
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      debugPrint('⚠️ In-App Purchase not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('❌ Purchase stream error: $error'),
    );

    // Load products
    await loadProducts();
  }

  /// Load available products
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final Set<String> productIds = {
      Platform.isAndroid ? _monthlyProductIdAndroid : _monthlyProductIdIOS,
      Platform.isAndroid ? _yearlyProductIdAndroid : _yearlyProductIdIOS,
    };

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      
      if (response.error != null) {
        debugPrint('❌ Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      debugPrint('✅ Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('❌ Exception loading products: $e');
    }
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(ProductDetails productDetails) async {
    if (!_isAvailable) {
      debugPrint('⚠️ IAP not available');
      return false;
    }

    // We must have an authenticated Firebase user so the server can link the
    // Play subscription to the correct account (Custom Claims + Firestore).
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ User is not signed in. Block purchase so Premium can be linked to an account.');
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (success) {
        debugPrint('✅ Purchase initiated for ${productDetails.id}');
      } else {
        debugPrint('❌ Failed to initiate purchase');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Exception purchasing: $e');
      return false;
    }
  }

  /// Upgrade from monthly to yearly
  Future<bool> upgradeToYearly() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ User is not signed in. Block upgrade so Premium can be linked to an account.');
      return false;
    }

    final yearly = yearlyProduct;
    if (yearly == null) {
      debugPrint('❌ Yearly product not available');
      return false;
    }

    // For Android, use updateSubscription
    if (Platform.isAndroid) {
      try {
        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: yearly,
        );
        
        // Google Play handles proration automatically
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        debugPrint('❌ Exception upgrading: $e');
        return false;
      }
    } else {
      // iOS - use buyNonConsumable (StoreKit handles proration)
      return await purchaseSubscription(yearly);
    }
  }

  /// Handle purchase updates
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('⏳ Purchase pending: ${purchase.productID}');
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        debugPrint('❌ Purchase error: ${purchase.error}');
        await _handlePurchaseError(purchase);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || 
          purchase.status == PurchaseStatus.restored) {
        debugPrint('✅ Purchase successful: ${purchase.productID}');
        await _handleSuccessfulPurchase(purchase);
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ No user logged in, cannot update subscription');
      return;
    }

    try {
      final isMonthly = purchase.productID.contains('monthly');
      final isYearly = purchase.productID.contains('yearly');
      
      if (!isMonthly && !isYearly) {
        debugPrint('⚠️ Unknown product type: ${purchase.productID}');
        return;
      }
      final platform = Platform.isAndroid ? 'android' : 'ios';

      // NOTE: Firestore rules intentionally prevent clients from updating `roles`.
      // We must verify and activate subscriptions server-side (Cloud Function),
      // then refresh the ID token to receive updated Custom Claims roles.
      if (Platform.isAndroid) {
        final token = purchase.verificationData.serverVerificationData;
        if (token.isEmpty) {
          debugPrint('❌ Missing purchase token for ${purchase.productID}');
          return;
        }

        final callable = FirebaseFunctions.instance.httpsCallable('verifyPlaySubscription');
        final result = await callable.call(<String, dynamic>{
          'productId': purchase.productID,
          'purchaseToken': token,
          'platform': platform,
        });

        debugPrint('✅ verifyPlaySubscription result: ${result.data}');
      } else {
        // iOS verification is not implemented yet (needs App Store receipt verification).
        debugPrint('⚠️ iOS subscription verification not implemented yet');
      }

      // Force-refresh token to get updated Custom Claims.
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      // Notify listeners (UI can refresh roles/status).
      _subscriptionChanged.add(null);
    } catch (e) {
      debugPrint('❌ Error updating subscription: $e');
    }
  }

  /// Handle purchase error
  Future<void> _handlePurchaseError(PurchaseDetails purchase) async {
    debugPrint('❌ Purchase error for ${purchase.productID}: ${purchase.error}');
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('⚠️ IAP not available');
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ User is not signed in. Block restore so Premium can be linked to an account.');
      return false;
    }

    try {
      await _iap.restorePurchases();
      debugPrint('✅ Restore purchases initiated');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring purchases: $e');
      return false;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _getUserDocSnapshotByUid(userId);
      if (doc == null || !doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      final isActive = data['subscription_active'] as bool? ?? false;
      
      if (!isActive) return false;

      // Check renewal date
      final renewalDate = (data['subscription_renewal_date'] as Timestamp?)?.toDate();
      if (renewalDate == null) return false;

      return DateTime.now().isBefore(renewalDate);
    } catch (e) {
      debugPrint('❌ Error checking subscription: $e');
      return false;
    }
  }

  /// Get subscription info
  Future<Map<String, dynamic>?> getSubscriptionInfo() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _getUserDocSnapshotByUid(userId);
      if (doc == null || !doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return {
        'type': data['subscription_type'] as String?,
        'start_date': (data['subscription_start_date'] as Timestamp?)?.toDate(),
        'renewal_date': (data['subscription_renewal_date'] as Timestamp?)?.toDate(),
        'platform': data['subscription_platform'] as String?,
        'active': data['subscription_active'] as bool? ?? false,
      };
    } catch (e) {
      debugPrint('❌ Error getting subscription info: $e');
      return null;
    }
  }

  Future<DocumentSnapshot?> _getUserDocSnapshotByUid(String uid) async {
    // Mirror AuthService logic: docs are commonly stored as [displayName]__[UID]
    final query = await _firestore.collection('users').where('uid', isEqualTo: uid).limit(1).get();
    if (query.docs.isNotEmpty) return query.docs.first;
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscriptionChanged.close();
  }
}

