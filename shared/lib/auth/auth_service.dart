import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool _kAuthLogs = bool.fromEnvironment('L2L_LOG_AUTH', defaultValue: false);

void _authLog(String message) {
  if (kDebugMode && _kAuthLogs) debugPrint(message);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // On web, instantiating GoogleSignIn triggers google_sign_in_web initialization,
  // which asserts if the google-signin-client_id meta tag is missing.
  // We keep it null on web and use Firebase Auth popup instead.
  late final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  List<String> _legacyUserDocIdCandidates(User user, {required String uid}) {
    // Historically some installs used doc ids like "{displayName}__{uid}".
    String safe(String s) => s.trim().replaceAll('/', '_');
    final dn = safe(user.displayName ?? '');
    final email = safe(user.email ?? '');
    final emailPrefix = email.contains('@') ? email.split('@').first.trim() : email;

    final out = <String>[];
    if (dn.isNotEmpty) out.add('${dn}__$uid');
    if (emailPrefix.isNotEmpty) out.add('${emailPrefix}__$uid');
    // Keep order but remove duplicates.
    return out.toSet().toList();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Refresh token to get latest custom claims
      await credential.user?.getIdToken(true);

      // Load user profile (non-blocking - don't fail login if profile load fails)
      try {
        await _loadUserProfile(credential.user!.uid);
      } catch (e) {
        // Log error but don't prevent login
        _authLog('Warning: Failed to load user profile: $e');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email, password, and display name
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName, {
    String? country,
    String? note,
    required String userType,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // SECURITY: Send email verification before creating profile
      await credential.user?.sendEmailVerification();

      // Create user profile in Firestore (pending approval)
      try {
        await _createUserProfile(
          credential.user!.uid,
          email.trim(),
          displayName,
          country: country,
          note: note,
          userType: userType,
          provider: 'email',
        );
      } catch (e) {
        // If Firestore creation fails, log but don't fail the signup
        // The user is already authenticated, so we should continue
        _authLog('Warning: Failed to create user profile in Firestore: $e');
        // Don't throw - the user is authenticated and can retry profile creation later
      }

      // Refresh token to get latest custom claims
      await credential.user?.getIdToken(true);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if user's email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Reload user to get latest email verification status
    await user.reload();
    return user.emailVerified;
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    await user.sendEmailVerification();
  }

  // Create user profile in Firestore
  // Google Sign-In: AUTO-APPROVE with freeUser role (email already verified by Google)
  // Email/Password: PENDING until email verification
  Future<void> _createUserProfile(
    String uid,
    String email,
    String displayName, {
    String? photoUrl,
    String? country,
    String? note,
    String? provider,
    String? userType,
  }) async {
    try {
      // Distinguish between Google (auto-approved) and Email/Password (pending)
      final isGoogleSignIn = provider == 'google';
      
      final userData = {
        'uid': uid, // Store original UID for reference
        'email': email,
        'displayName': displayName,
        // Google: auto-assign freeUser role, Email: empty until email verification
        'roles': isGoogleSignIn ? ['freeUser'] : [],
        // Google: auto-approved, Email: pending until email verification
        'status': isGoogleSignIn ? 'approved' : 'pending',
        // Google: approved immediately, Email: requires email verification
        'approved': isGoogleSignIn ? true : false,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add country if provided
      if (country != null && country.isNotEmpty) {
        userData['country'] = country;
      }

      // Add note if provided
      if (note != null && note.isNotEmpty) {
        userData['note'] = note;
      }

      // Add provider if provided (e.g., 'google', 'email')
      if (provider != null && provider.isNotEmpty) {
        userData['provider'] = provider;
      }
      if (userType != null && userType.isNotEmpty) {
        userData['userType'] = userType;
      }

      // Always use UID as the document id to avoid duplicates and simplify security rules.
      await _firestore.collection('users').doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Load user profile from Firestore
  Future<Map<String, dynamic>?> _loadUserProfile(String uid) async {
    try {
      // Prefer canonical location: users/{uid}
      final canonicalRef = _firestore.collection('users').doc(uid);
      final canonicalSnap = await canonicalRef.get();

      DocumentSnapshot<Map<String, dynamic>>? resolvedSnap;
      if (canonicalSnap.exists) {
        resolvedSnap = canonicalSnap;
      } else {
        // Legacy fallback (read-only): try common legacy ids without requiring collection queries.
        final user = _auth.currentUser;
        if (user != null) {
          final candidates = _legacyUserDocIdCandidates(user, uid: uid);
          for (final id in candidates) {
            final legacySnap = await _firestore.collection('users').doc(id).get();
            if (legacySnap.exists) {
              resolvedSnap = legacySnap;
              break;
            }
          }
        }
        resolvedSnap ??= canonicalSnap; // doesn't exist
      }

      if (resolvedSnap.exists) {
        final data = resolvedSnap.data();
        if (data == null) return null;

        // Store in SharedPreferences for quick access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', data['email'] ?? '');
        await prefs.setString('user_displayName', data['displayName'] ?? '');

        // Support both old format (role: string) and new format (roles: array)
        List<String> rolesList = [];
        if (data.containsKey('roles')) {
          // New format: roles array
          final roles = data['roles'] as List<dynamic>? ?? [];
          rolesList = roles.map((r) => r.toString()).toList();
        } else if (data.containsKey('role')) {
          // Old format: single role string - migrate to array
          final oldRole = data['role'] as String?;
          if (oldRole != null && oldRole.isNotEmpty) {
            rolesList = [oldRole];
          }
        }

        await prefs.setString('user_roles', rolesList.join(','));
        await prefs.setString('user_status', data['status'] ?? 'approved'); // Default to approved for old users
        await prefs.setBool('user_approved', data['approved'] ?? true); // Default to approved for old users
        return data;
      }
      // If document doesn't exist, set pending status
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      if (user != null) {
        await prefs.setString('user_email', user.email ?? '');
        await prefs.setString('user_displayName', user.displayName ?? user.email?.split('@')[0] ?? '');
        await prefs.setString('user_roles', ''); // Empty roles
        await prefs.setString('user_status', 'pending');
        await prefs.setBool('user_approved', false);
      }
      return null;
    } catch (e) {
      // Don't throw - just log and return null
      _authLog('Warning: Failed to load user profile from Firestore: $e');

      // If it's a permission error, try to get roles from Custom Claims as fallback
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        try {
          final user = _auth.currentUser;
          if (user != null) {
            // Try to get roles from Custom Claims
            final roles = await getUserRoles();
            if (roles.isNotEmpty && roles.contains('admin')) {
              // User has admin role in Custom Claims, assume approved
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_email', user.email ?? '');
              await prefs.setString('user_displayName', user.displayName ?? user.email?.split('@')[0] ?? '');
              await prefs.setString('user_roles', roles.join(','));
              await prefs.setString('user_status', 'approved');
              await prefs.setBool('user_approved', true);
              _authLog('✅ Loaded user data from Custom Claims (admin user)');
              return {
                'email': user.email,
                'displayName': user.displayName ?? user.email?.split('@')[0],
                'roles': roles,
                'status': 'approved',
                'approved': true,
              };
            }
          }
        } catch (_) {
          // Ignore errors getting Custom Claims
        }
      }

      // Set pending values in SharedPreferences only if we couldn't get Custom Claims
      try {
        final prefs = await SharedPreferences.getInstance();
        final user = _auth.currentUser;
        if (user != null) {
          await prefs.setString('user_email', user.email ?? '');
          await prefs.setString('user_displayName', user.displayName ?? user.email?.split('@')[0] ?? '');
          await prefs.setString('user_roles', ''); // Empty roles
          await prefs.setString('user_status', 'pending');
          await prefs.setBool('user_approved', false);
        }
      } catch (_) {
        // Ignore errors setting defaults
      }
      return null;
    }
  }

  /// Get the current user's profile from Firestore (or cached fallbacks).
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _loadUserProfile(user.uid);
  }

  // Get user roles array from custom claims or Firestore
  Future<List<String>> getUserRoles() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // First, try to get roles from custom claims (JWT token)
      _authLog('🔍 getUserRoles: Force refreshing token...');
      final idTokenResult = await user.getIdTokenResult(true);
      final customClaims = idTokenResult.claims;
      _authLog('🔍 getUserRoles: Custom Claims: $customClaims');

      if (customClaims != null && customClaims.containsKey('roles')) {
        final roles = customClaims['roles'];
        _authLog('🔍 getUserRoles: Found roles in Custom Claims: $roles');
        if (roles is List) {
          final rolesList = roles.map((r) => r.toString()).toList();
          // Cache in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_roles', rolesList.join(','));
          return rolesList;
        }
      }

      // Fallback to Firestore
      // Prefer canonical doc id: users/{uid}
      final canonical = await _firestore.collection('users').doc(user.uid).get();
      if (canonical.exists) {
        final data = canonical.data();
        if (data == null) return [];

        // Support both old format (role: string) and new format (roles: array)
        List<String> rolesList = [];
        if (data.containsKey('roles')) {
          // New format: roles array
          final roles = data['roles'] as List<dynamic>? ?? [];
          rolesList = roles.map((r) => r.toString()).toList();
        } else if (data.containsKey('role')) {
          // Old format: single role string - migrate to array
          final oldRole = data['role'] as String?;
          if (oldRole != null && oldRole.isNotEmpty) {
            rolesList = [oldRole];
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_roles', rolesList.join(','));
        return rolesList;
      }

      // Legacy fallback (read-only): try common legacy ids.
      final candidates = _legacyUserDocIdCandidates(user, uid: user.uid);
      for (final id in candidates) {
        final snap = await _firestore.collection('users').doc(id).get();
        if (!snap.exists) continue;
        final data = snap.data();
        if (data == null) continue;

        List<String> rolesList = [];
        if (data.containsKey('roles')) {
          final roles = data['roles'] as List<dynamic>? ?? [];
          rolesList = roles.map((r) => r.toString()).toList();
        } else if (data.containsKey('role')) {
          final oldRole = data['role'] as String?;
          if (oldRole != null && oldRole.isNotEmpty) {
            rolesList = [oldRole];
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_roles', rolesList.join(','));
        return rolesList;
      }

      return []; // No roles by default
    } catch (e) {
      // Fallback to cached roles
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user_roles') ?? '';
      return cached.isEmpty ? [] : cached.split(',');
    }
  }

  // Get user status (pending/approved)
  Future<String> getUserStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'guest';

      // Prefer canonical doc id
      final canonical = await _firestore.collection('users').doc(user.uid).get();
      if (canonical.exists) {
        final data = canonical.data();
        return data?['status'] ?? 'pending';
      }

      // Legacy fallback (read-only): try common legacy ids.
      final candidates = _legacyUserDocIdCandidates(user, uid: user.uid);
      for (final id in candidates) {
        final snap = await _firestore.collection('users').doc(id).get();
        if (!snap.exists) continue;
        final data = snap.data();
        if (data == null) continue;
        return (data['status'] ?? 'pending').toString();
      }
      return 'pending';
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_status') ?? 'pending';
    }
  }

  // Check if user is approved
  Future<bool> isUserApproved() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Prefer canonical doc id
      final canonical = await _firestore.collection('users').doc(user.uid).get();
      if (canonical.exists) {
        final data = canonical.data();
        return data?['approved'] ?? false;
      }

      // Legacy fallback (read-only): try common legacy ids.
      final candidates = _legacyUserDocIdCandidates(user, uid: user.uid);
      for (final id in candidates) {
        final snap = await _firestore.collection('users').doc(id).get();
        if (!snap.exists) continue;
        final data = snap.data();
        if (data == null) continue;
        return data['approved'] == true;
      }
      return false;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('user_approved') ?? false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn?.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_displayName');
    await prefs.remove('user_roles');
    await prefs.remove('user_status');
    await prefs.remove('user_approved');
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // WEB: prefer Firebase Auth popup (avoids google_sign_in_web clientId meta requirement)
      if (kIsWeb) {
        _authLog('🔑 Starting Google Sign-In (Web)...');
        final provider = GoogleAuthProvider()..addScope('email')..addScope('profile');
        
        // Add timeout for web popup
        final userCredential = await _auth.signInWithPopup(provider).timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            _authLog('❌ Google Sign-In popup timeout');
            throw Exception('Sign-in timed out. Please try again.');
          },
        );

        _authLog('✅ Google Sign-In popup successful');

        // Refresh token to get latest custom claims
        await userCredential.user?.getIdToken(true).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            _authLog('⚠️ Token refresh timeout (non-critical)');
            return null;
          },
        );

        // Load user profile (non-blocking)
        try {
          await _loadUserProfile(userCredential.user!.uid);
        } catch (e) {
          _authLog('Warning: Failed to load user profile: $e');
        }

        return userCredential;
      }

      // MOBILE: Use google_sign_in plugin
      final googleSignIn = _googleSignIn;
      if (googleSignIn == null) {
        _authLog('❌ Google Sign-In not available');
        return null;
      }

      _authLog('🔑 Starting Google Sign-In (Mobile)...');
      
      // Trigger the authentication flow with timeout
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn().timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          _authLog('❌ Google Sign-In timeout');
          return null;
        },
      );
      
      if (googleUser == null) {
        _authLog('❌ Google Sign-In cancelled or timed out');
        return null; // cancelled or timeout
      }

      _authLog('✅ Google account selected');

      // Obtain the auth details from the request with timeout
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _authLog('❌ Google authentication timeout');
          throw Exception('Authentication timed out. Please try again.');
        },
      );

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _authLog('🔑 Signing in to Firebase with Google credential...');

      // Once signed in, return the UserCredential with timeout
      final userCredential = await _auth.signInWithCredential(credential).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _authLog('❌ Firebase sign-in timeout');
          throw Exception('Firebase sign-in timed out. Please check your internet connection.');
        },
      );

      _authLog('✅ Firebase sign-in successful');

      // Refresh token to get latest custom claims with timeout
      await userCredential.user?.getIdToken(true).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _authLog('⚠️ Token refresh timeout (non-critical)');
          return null;
        },
      );

      // Load user profile (non-blocking - don't fail login if profile load fails)
      try {
        await _loadUserProfile(userCredential.user!.uid);
      } catch (e) {
        // Log error but don't prevent login
        _authLog('Warning: Failed to load user profile: $e');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _authLog('❌ FirebaseAuthException during Google Sign-In: ${e.code}');
      throw _handleAuthException(e);
    } on TimeoutException catch (_) {
      _authLog('❌ Google Sign-In timeout');
      throw Exception('Sign-in timed out. Please check your internet connection and try again.');
    } catch (e) {
      _authLog('❌ Unexpected error during Google Sign-In');
      rethrow;
    }
  }

  // Complete Google sign-up after additional info
  Future<void> completeGoogleSignUp(
    String uid,
    String email,
    String displayName,
    String? photoUrl,
    String country,
    String userType,
  ) async {
    try {
      // IMPORTANT:
      // - If users/{uid} already exists, client updates must NOT touch roles/approved/status
      //   (Firestore rules block those keys even if values are unchanged).
      // - So we only update allowed profile fields in that case.
      final userRef = _firestore.collection('users').doc(uid);
      final snap = await userRef.get();
      if (!snap.exists) {
        await _createUserProfile(
          uid,
          email,
          displayName,
          country: country,
          provider: 'google',
          photoUrl: photoUrl,
          userType: userType,
        );
      } else {
        await userRef.set(
          <String, dynamic>{
            'country': country.trim(),
            'userType': userType.trim(),
            // Optional compatibility fields (dashboard/joinTenant read either key).
            'countryCode': country.trim(),
            'hearingStatus': userType.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // Refresh token to get latest custom claims
      final user = _auth.currentUser;
      await user?.getIdToken(true);
    } catch (e) {
      throw Exception('Failed to complete Google sign up: $e');
    }
  }

  // Handle FirebaseAuthException and return a user-friendly error message
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided for that user.');
      case 'email-already-in-use':
        return Exception('The account already exists for that email.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'user-disabled':
        return Exception('This user has been disabled.');
      case 'operation-not-allowed':
        return Exception('Operation not allowed. Please enable it in the console.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      default:
        return Exception('Authentication error: ${e.message}');
    }
  }
}

