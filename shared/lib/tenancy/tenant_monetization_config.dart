import 'package:cloud_firestore/cloud_firestore.dart';

/// Tenant monetization configuration (Option A co-brand SaaS).
///
/// Location: /tenants/{tenantId}/monetization/config
///
/// Example:
/// {
///   "adUnits": {
///     "interstitialAndroid": "...",
///     "rewardedAndroid": "...",
///     "interstitialIOS": "...",
///     "rewardedIOS": "..."
///   },
///   "iapProducts": {
///     "monthlyProductIdAndroid": "premium_l2l_vsl_monthly",
///     "yearlyProductIdAndroid": "premium_l2l_vsl_yearly",
///     "monthlyProductIdIOS": "premium_l2l_vsl_monthly",
///     "yearlyProductIdIOS": "premium_l2l_vsl_yearly"
///   }
/// }
class TenantMonetizationConfigDoc {
  final String id; // 'config'
  final Map<String, dynamic> data;
  final DocumentReference<Map<String, dynamic>> ref;

  TenantMonetizationConfigDoc({
    required this.id,
    required this.data,
    required this.ref,
  });

  factory TenantMonetizationConfigDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    return TenantMonetizationConfigDoc(
      id: snap.id,
      data: snap.data() ?? <String, dynamic>{},
      ref: snap.reference,
    );
  }

  TenantAdUnits get adUnits {
    final raw = data['adUnits'];
    if (raw is Map) return TenantAdUnits.fromMap(Map<String, dynamic>.from(raw));
    return const TenantAdUnits();
  }

  TenantIapProducts get iapProducts {
    final raw = data['iapProducts'];
    if (raw is Map) return TenantIapProducts.fromMap(Map<String, dynamic>.from(raw));
    return const TenantIapProducts();
  }
}

class TenantAdUnits {
  final String interstitialAndroid;
  final String rewardedAndroid;
  final String interstitialIOS;
  final String rewardedIOS;

  const TenantAdUnits({
    this.interstitialAndroid = '',
    this.rewardedAndroid = '',
    this.interstitialIOS = '',
    this.rewardedIOS = '',
  });

  factory TenantAdUnits.fromMap(Map<String, dynamic> map) {
    return TenantAdUnits(
      interstitialAndroid: (map['interstitialAndroid'] ?? '').toString(),
      rewardedAndroid: (map['rewardedAndroid'] ?? '').toString(),
      interstitialIOS: (map['interstitialIOS'] ?? '').toString(),
      rewardedIOS: (map['rewardedIOS'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'interstitialAndroid': interstitialAndroid,
        'rewardedAndroid': rewardedAndroid,
        'interstitialIOS': interstitialIOS,
        'rewardedIOS': rewardedIOS,
      };
}

class TenantIapProducts {
  final String monthlyProductIdAndroid;
  final String yearlyProductIdAndroid;
  final String monthlyProductIdIOS;
  final String yearlyProductIdIOS;

  const TenantIapProducts({
    this.monthlyProductIdAndroid = '',
    this.yearlyProductIdAndroid = '',
    this.monthlyProductIdIOS = '',
    this.yearlyProductIdIOS = '',
  });

  factory TenantIapProducts.fromMap(Map<String, dynamic> map) {
    return TenantIapProducts(
      monthlyProductIdAndroid: (map['monthlyProductIdAndroid'] ?? map['monthlyProductId'] ?? '').toString(),
      yearlyProductIdAndroid: (map['yearlyProductIdAndroid'] ?? map['yearlyProductId'] ?? '').toString(),
      monthlyProductIdIOS: (map['monthlyProductIdIOS'] ?? map['monthlyProductId'] ?? '').toString(),
      yearlyProductIdIOS: (map['yearlyProductIdIOS'] ?? map['yearlyProductId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'monthlyProductIdAndroid': monthlyProductIdAndroid,
        'yearlyProductIdAndroid': yearlyProductIdAndroid,
        'monthlyProductIdIOS': monthlyProductIdIOS,
        'yearlyProductIdIOS': yearlyProductIdIOS,
      };
}


