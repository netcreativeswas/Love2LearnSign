import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';

const bool _kAuthLogs = bool.fromEnvironment('L2L_LOG_AUTH', defaultValue: false);

void _authLog(String message) {
  if (kDebugMode && _kAuthLogs) debugPrint(message);
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  List<String> _userRoles = [];
  String _userStatus = 'guest';
  bool _isApproved = false;
  String? _displayName;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  User? get user => _user;
  List<String> get userRoles => _userRoles;
  String get userStatus => _userStatus;
  bool get isApproved => _isApproved;
  String? get displayName => _displayName;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isPending => _userStatus == 'pending' || !_isApproved;
  bool get isAdmin => _userRoles.contains('admin');
  bool get isEditor => _userRoles.contains('editor');
  bool get isJW => _userRoles.contains('jw');
  bool get isTeacher => _userRoles.contains('teacher');
  bool get isStudent => _userRoles.contains('student');

  // Helper methods for role checking
  bool hasRole(String role) => _userRoles.contains(role);
  bool hasAnyRole(List<String> roles) => roles.any((role) => _userRoles.contains(role));

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await loadUserData();
      } else {
        _userRoles = [];
        _userStatus = 'guest';
        _isApproved = false;
        _displayName = null;
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  // Load user data (roles, status, profile, etc.)
  Future<void> loadUserData() async {
    if (_user == null) {
      _userRoles = [];
      _userStatus = 'guest';
      _isApproved = false;
      _displayName = null;
      _userProfile = null;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Get roles array from custom claims or Firestore
      _authLog('🔍 AuthProvider: Fetching user roles...');
      _userRoles = await _authService.getUserRoles();
      _authLog('🔍 AuthProvider: Roles fetched: $_userRoles');

      // Get user status
      _userStatus = await _authService.getUserStatus();

      // Get approval status
      _isApproved = await _authService.isUserApproved();

      // Get user profile
      _userProfile = await _authService.getUserProfile();

      // Get display name
      _displayName = _user?.displayName ?? _userProfile?['displayName'] ?? _user?.email?.split('@')[0];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _authLog('Error loading user data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);

      // Load user data (non-blocking - don't fail login if this fails)
      try {
        await loadUserData();
      } catch (e) {
        _authLog('Warning: Failed to load user data after login: $e');
        // User is still authenticated, just couldn't load profile data
      }

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Extract a user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Failed to load user profile')) {
        // If it's just a profile loading issue, don't show it as an error
        // The user is authenticated, profile loading can happen later
        return null; // Success - user is logged in
      }
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      return errorMessage;
    }
  }

  // Sign up
  Future<String?> signUp(String email, String password, String displayName,
      {String? country, String? note, required String userType}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signUpWithEmailAndPassword(email, password, displayName,
          country: country, note: note, userType: userType);

      // Load user data (non-blocking - don't fail signup if this fails)
      try {
        await loadUserData();
      } catch (e) {
        _authLog('Warning: Failed to load user data after signup: $e');
        // User is authenticated, profile loading can happen later
      }

      _isLoading = false;
      notifyListeners();

      // ✅ New users are auto-approved with freeUser role - return success
      _authLog('✅ Sign-up complete - user auto-approved with freeUser role');
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      // Provide user-friendly error messages
      String errorMsg = 'Failed to create account';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('email-already-in-use') ||
          errorString.contains('email already in use') ||
          errorString.contains('email_already_in_use')) {
        errorMsg = 'This email is already registered. Please go to the Sign In page.';
      } else if (errorString.contains('weak-password') || errorString.contains('weak password')) {
        errorMsg = 'Password is too weak. Please choose a stronger password.';
      } else if (errorString.contains('invalid-email') || errorString.contains('invalid email')) {
        errorMsg = 'Invalid email address. Please check your email and try again.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMsg = 'Network error. Please check your internet connection.';
      } else if (errorString.contains('permission_denied') || errorString.contains('failed to create user profile')) {
        // If Firestore permission error but user is authenticated
        // The user account was created successfully, just the profile couldn't be saved
        // User is auto-approved, so return success
        _authLog('✅ User authenticated (profile creation had permission error, but user is approved)');
        return null; // Success - user is authenticated and auto-approved
      } else {
        // Remove "Exception: " prefix if present
        errorMsg = e.toString().startsWith('Exception: ')
            ? e.toString().substring(11)
            : e.toString();
        // Limit length
        if (errorMsg.length > 100) {
          errorMsg = errorMsg.substring(0, 100) + '...';
        }
      }

      return errorMsg;
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User cancelled
        _isLoading = false;
        notifyListeners();
        return 'Sign-in cancelled';
      }

      // Load user data (non-blocking - don't fail login if this fails)
      try {
        await loadUserData();
      } catch (e) {
        _authLog('Warning: Failed to load user data after Google sign in: $e');
        // User is authenticated, profile loading can happen later
      }

      _isLoading = false;
      notifyListeners();

      // Check if user profile exists - if not, need to complete signup
      final profile = await _authService.getUserProfile();
      if (profile == null) {
        // No user profile exists - need to complete signup with country selection
        _authLog('⚠️ No user profile found - redirecting to country selection');
        return 'COUNTRY_SELECTION_NEEDED';
      }

      // Check if country needs to be selected (profile exists but country is "Unknown" or missing)
      final country = profile['country'];
      final userType = profile['userType'];
      final needsCountry =
          country == null || (country is String && country.trim().isEmpty) || country == 'Unknown';
      final needsUserType =
          userType == null || (userType is String && userType.trim().isEmpty);
      if (needsCountry || needsUserType) {
        _authLog('⚠️ User profile incomplete (country: $country, userType: $userType) - redirecting to country selection');
        return 'COUNTRY_SELECTION_NEEDED';
      }

      // ✅ User is auto-approved with freeUser role - no pending approval check needed
      _authLog('✅ Google Sign-In complete - user approved with freeUser role');
      return null; // Success - redirect to home
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      _authLog('AuthProvider signInWithGoogle error: $e');

      // Provide user-friendly error messages
      String errorMsg = 'Failed to sign in with Google';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('apiexception: 10') ||
          errorString.contains('developer_error') ||
          errorString.contains('sign_in_failed')) {
        errorMsg = 'Google Sign-In configuration error. Please check:\n'
            '1. SHA-1 fingerprint is configured in Firebase Console\n'
            '2. Package name matches Firebase configuration\n'
            '3. Google Sign-In is enabled in Firebase Authentication';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMsg = 'Network error. Please check your internet connection.';
      } else if (errorString.contains('cancelled') || errorString.contains('cancel')) {
        errorMsg = 'Sign-in cancelled';
      } else {
        errorMsg = 'Google Sign-In error: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }

      return errorMsg;
    }
  }

  // Sign in with Apple (iOS only)
  Future<String?> signInWithApple() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.signInWithApple();
      if (result == null) {
        _isLoading = false;
        notifyListeners();
        return 'Sign-in cancelled';
      }

      // Load user data (non-blocking)
      try {
        await loadUserData();
      } catch (e) {
        _authLog('Warning: Failed to load user data after Apple sign in: $e');
      }

      _isLoading = false;
      notifyListeners();

      // Check if user profile exists - if not, need to complete signup
      final profile = await _authService.getUserProfile();
      if (profile == null) {
        _authLog('⚠️ No user profile found - redirecting to country selection');
        return 'COUNTRY_SELECTION_NEEDED';
      }

      final country = profile['country'];
      final userType = profile['userType'];
      final needsCountry =
          country == null || (country is String && country.trim().isEmpty) || country == 'Unknown';
      final needsUserType =
          userType == null || (userType is String && userType.trim().isEmpty);
      if (needsCountry || needsUserType) {
        _authLog('⚠️ User profile incomplete (country: $country, userType: $userType) - redirecting to country selection');
        return 'COUNTRY_SELECTION_NEEDED';
      }

      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      _authLog('AuthProvider signInWithApple error: $e');
      return 'Failed to sign in with Apple';
    }
  }

  // Complete Google Sign-Up after country selection
  Future<String?> completeGoogleSignUp(
    String uid,
    String email,
    String displayName,
    String? photoUrl,
    String country,
    String userType,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.completeGoogleSignUp(
        uid,
        email,
        displayName,
        photoUrl,
        country,
        userType,
      );

      await loadUserData();

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Failed to complete sign up: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      _user = null;
      _userRoles = [];
      _userStatus = 'guest';
      _isApproved = false;
      _displayName = null;
      _userProfile = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Refresh user roles (useful after role changes)
  Future<void> refreshUserRoles() async {
    if (_user != null) {
      // Force token refresh to get latest custom claims
      await _user?.getIdToken(true);
      await loadUserData();
    }
  }

  // Check if user can access restricted category
  bool canAccessCategory(String? restrictedRole) {
    if (restrictedRole == null) return true; // No restriction
    return _userRoles.contains(restrictedRole);
  }

  // Get count of pending users (for admin notification)
  Future<int> getPendingUsersCount() async {
    try {
      if (!isAdmin) return 0;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      _authLog('Error getting pending users count: $e');
      return 0;
    }
  }

  // Helper to access provider easily
  static AuthProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<AuthProvider>(context, listen: listen);
}

