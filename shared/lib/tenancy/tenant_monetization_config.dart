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

  TenantPricing get pricing {
    final raw = data['pricing'];
    if (raw is Map) return TenantPricing.fromMap(Map<String, dynamic>.from(raw));
    return const TenantPricing();
  }

  TenantAdsEstimates get adsEstimates {
    final raw = data['adsEstimates'];
    if (raw is Map) return TenantAdsEstimates.fromMap(Map<String, dynamic>.from(raw));
    return const TenantAdsEstimates();
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

class TenantPricing {
  final String currency; // e.g. 'USD'
  final double monthlyPrice;
  final double yearlyPrice;

  const TenantPricing({
    this.currency = 'USD',
    this.monthlyPrice = 0,
    this.yearlyPrice = 0,
  });

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString().trim()) ?? 0;
  }

  factory TenantPricing.fromMap(Map<String, dynamic> map) {
    return TenantPricing(
      currency: (map['currency'] ?? 'USD').toString(),
      monthlyPrice: _asDouble(map['monthlyPrice']),
      yearlyPrice: _asDouble(map['yearlyPrice']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'currency': currency,
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
      };
}

class TenantAdsEstimates {
  /// Manual estimated gross AdMob revenue per month (same currency as TenantPricing.currency).
  final double monthlyGross;

  const TenantAdsEstimates({this.monthlyGross = 0});

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString().trim()) ?? 0;
  }

  factory TenantAdsEstimates.fromMap(Map<String, dynamic> map) {
    return TenantAdsEstimates(
      monthlyGross: _asDouble(map['monthlyGross']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'monthlyGross': monthlyGross,
      };
}


