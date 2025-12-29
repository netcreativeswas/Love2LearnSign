import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:l2l_shared/tenancy/app_config.dart';

/// Loads the public catalog of editions from Firestore `apps/*`.
///
/// Each `apps/{appId}` document represents one co-brand edition / sign language package.
class AppsCatalog {
  final FirebaseFirestore _db;

  AppsCatalog({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _apps => _db.collection('apps');

  /// Fetch a list of available apps.
  ///
  /// If `status` is used, we prefer `status == 'active'`. If the query returns empty
  /// (because docs don't have the field yet), we fall back to listing all apps.
  Future<List<AppConfigDoc>> fetchAvailableApps() async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _apps.where('status', isEqualTo: 'active').get();
      if (snap.docs.isEmpty) {
        snap = await _apps.get();
      }
    } catch (_) {
      // Fallback: list all (e.g., missing index / missing field / rules changes)
      snap = await _apps.get();
    }

    final apps = snap.docs.map(AppConfigDoc.fromSnapshot).toList();

    apps.sort((a, b) {
      final an = a.displayName.trim();
      final bn = b.displayName.trim();
      if (an.isEmpty && bn.isEmpty) return a.id.compareTo(b.id);
      if (an.isEmpty) return 1;
      if (bn.isEmpty) return -1;
      final c = an.toLowerCase().compareTo(bn.toLowerCase());
      return c != 0 ? c : a.id.compareTo(b.id);
    });

    return apps;
  }
}


