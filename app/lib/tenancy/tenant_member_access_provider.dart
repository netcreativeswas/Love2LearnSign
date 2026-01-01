import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Watches the current user's tenant member document:
/// tenants/{tenantId}/members/{uid}
///
/// Exposes tenant-scoped access flags like featureRoles (e.g. 'jw').
class TenantMemberAccessProvider extends ChangeNotifier {
  TenantMemberAccessProvider({required String tenantId}) : _tenantId = tenantId {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      _uid = u?.uid;
      _resubscribe();
    });
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _resubscribe();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _tenantId;
  String? _uid;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _memberSub;

  bool _loading = true;
  List<String> _featureRoles = const [];

  bool get loading => _loading;
  List<String> get featureRoles => _featureRoles;

  bool hasFeatureRole(String role) {
    final r = role.trim().toLowerCase();
    if (r.isEmpty) return false;
    return _featureRoles.contains(r);
  }

  bool get isJw => hasFeatureRole('jw');

  String get tenantId => _tenantId;

  void updateTenantId(String tenantId) {
    final next = tenantId.trim();
    if (next.isEmpty || next == _tenantId) return;
    _tenantId = next;
    _resubscribe();
  }

  void _resubscribe() {
    _memberSub?.cancel();
    _memberSub = null;

    if (_uid == null || _uid!.trim().isEmpty) {
      _loading = false;
      _featureRoles = const [];
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _memberSub = _db
        .collection('tenants')
        .doc(_tenantId)
        .collection('members')
        .doc(_uid)
        .snapshots()
        .listen(
      (snap) {
        final data = snap.data() ?? const <String, dynamic>{};
        final fr = data['featureRoles'];
        final roles = (fr is List)
            ? fr.map((e) => (e ?? '').toString().trim().toLowerCase()).where((e) => e.isNotEmpty).toList()
            : const <String>[];
        _featureRoles = roles.toSet().toList()..sort();
        _loading = false;
        notifyListeners();
      },
      onError: (_) {
        // Non-fatal; default to no special access.
        _featureRoles = const [];
        _loading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _memberSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}


