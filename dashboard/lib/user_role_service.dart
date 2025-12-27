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
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final docData = querySnapshot.docs.first.data();
      return _extractRole(docData);
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

    return FirebaseFirestore.instance
        .collection(_usersCollection)
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final data = snapshot.docs.first.data();
      return _extractRole(data);
    });
  }
}
