import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage user roles and permissions
class UserRoleService {
  static const String _usersCollection = 'users';
  // We check both for backward compatibility or flexibility
  static const String _roleFieldLegacy = 'role'; 
  static const String _rolesField = 'roles'; // Array field
  
  /// Supported roles
  static const String roleAdmin = 'admin';
  static const String roleEditor = 'editor';

  /// Helper to extract the highest privilege role from document data
  static String? _extractRole(Map<String, dynamic>? data) {
    if (data == null) return null;

    // 1. Check 'roles' array (Preferred method)
    if (data.containsKey(_rolesField) && data[_rolesField] is List) {
      final List<dynamic> roles = data[_rolesField];
      // Check for admin first (highest privilege)
      if (roles.contains(roleAdmin)) return roleAdmin;
      // Then check for editor
      if (roles.contains(roleEditor)) return roleEditor;
    }

    // 2. Check legacy 'role' string field
    if (data.containsKey(_roleFieldLegacy) && data[_roleFieldLegacy] is String) {
      final String role = data[_roleFieldLegacy];
      if (role == roleAdmin) return roleAdmin;
      if (role == roleEditor) return roleEditor;
    }

    return null; // No valid role found
  }

  /// Get the current user's role from Firestore
  static Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      // Prefer canonical document id: users/{uid}
      final canonical = await FirebaseFirestore.instance.collection(_usersCollection).doc(user.uid).get();
      if (canonical.exists) {
        return _extractRole(canonical.data());
      }

      // Legacy fallback: users/{displayName}__{uid} or users/{emailPrefix}__{uid}
      final candidates = <String>[];
      final dn = (user.displayName ?? '').trim();
      final email = (user.email ?? '').trim();
      final emailPrefix = email.contains('@') ? email.split('@').first.trim() : email;
      if (dn.isNotEmpty) candidates.add('${dn.replaceAll('/', '_')}__${user.uid}');
      if (emailPrefix.isNotEmpty) candidates.add('${emailPrefix.replaceAll('/', '_')}__${user.uid}');

      for (final id in candidates) {
        final snap = await FirebaseFirestore.instance.collection(_usersCollection).doc(id).get();
        if (snap.exists) return _extractRole(snap.data());
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if the current user has admin role
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == roleAdmin;
  }

  /// Check if the current user has editor role
  static Future<bool> isEditor() async {
    final role = await getUserRole();
    return role == roleEditor;
  }

  /// Check if the current user has admin or editor role
  static Future<bool> hasDashboardAccess() async {
    final role = await getUserRole();
    return role == roleAdmin || role == roleEditor;
  }

  /// Stream of user role changes
  static Stream<String?> getUserRoleStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    // Prefer canonical stream; fallback to legacy id if canonical doc doesn't exist.
    final canonicalRef = FirebaseFirestore.instance.collection(_usersCollection).doc(user.uid);
    return canonicalRef.snapshots().asyncMap((canonicalSnap) async {
      if (canonicalSnap.exists) return _extractRole(canonicalSnap.data());

      final dn = (user.displayName ?? '').trim();
      final email = (user.email ?? '').trim();
      final emailPrefix = email.contains('@') ? email.split('@').first.trim() : email;
      final candidates = <String>[];
      if (dn.isNotEmpty) candidates.add('${dn.replaceAll('/', '_')}__${user.uid}');
      if (emailPrefix.isNotEmpty) candidates.add('${emailPrefix.replaceAll('/', '_')}__${user.uid}');

      for (final id in candidates) {
        final snap = await FirebaseFirestore.instance.collection(_usersCollection).doc(id).get();
        if (snap.exists) return _extractRole(snap.data());
      }
      return null;
    });
  }
}
