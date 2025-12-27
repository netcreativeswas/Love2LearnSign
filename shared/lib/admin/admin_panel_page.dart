import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import 'package:l2l_shared/theme_extensions.dart';
import 'package:provider/provider.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _usersScrollController = ScrollController();
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCountryFilter; // null = all countries
  String? _selectedHearingStatusFilter; // null = all, 'hearing', 'deaf'
  String _selectedDateRange = 'all'; // all, today, 7, 30, 90
  String _selectedRoleFilter = 'all'; // all, none, or specific role
  late final Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onClear,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onClear,
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeLabel(String range) {
    switch (range) {
      case 'today':
        return 'Today';
      case '7':
        return 'Last 7 days';
      case '30':
        return 'Last 30 days';
      case '90':
        return 'Last 90 days';
      default:
        return 'All time';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usersScrollController.dispose();
    super.dispose();
  }

  String? _normalizeHearingStatus(Map<String, dynamic> data) {
    final hearingStatus = data['hearingStatus'] as String? ??
        data['hearing_status'] as String? ??
        data['userType'] as String?;
    if (hearingStatus == null) return null;
    final lower = hearingStatus.toLowerCase();
    if (lower.contains('hearing') && !lower.contains('impaired') && !lower.contains('deaf')) {
      return 'hearing';
    }
    if (lower.contains('deaf') || lower.contains('impaired')) {
      return 'deaf';
    }
    return null;
  }

  Widget _buildDesktopStatsPanel(
    ThemeData theme, {
    required int todayCount,
    required int last7Count,
    required int last30Count,
    required int totalUsers,
    required int hearingCount,
    required int deafCount,
  }) {
    Widget kpiChip(
      String label,
      String value, {
      required Color background,
      required Color foreground,
      Color? borderColor,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor ?? theme.colorScheme.outlineVariant, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget statPill(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
        ),
        child: Text(text, style: theme.textTheme.labelSmall),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New users', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            kpiChip(
              'Today',
              todayCount.toString(),
              background: theme.colorScheme.primaryContainer,
              foreground: theme.colorScheme.onPrimaryContainer,
              borderColor: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 8),
            kpiChip(
              '7d',
              last7Count.toString(),
              background: theme.colorScheme.secondaryContainer,
              foreground: theme.colorScheme.onSecondaryContainer,
              borderColor: theme.colorScheme.secondary.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 8),
            kpiChip(
              '30d',
              last30Count.toString(),
              background: theme.colorScheme.tertiaryContainer,
              foreground: theme.colorScheme.onTertiaryContainer,
              borderColor: theme.colorScheme.tertiary.withValues(alpha: 0.25),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total users', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                totalUsers.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  statPill('Hearing: $hearingCount'),
                  statPill('Deaf: $deafCount'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper function to extract UID from document ID
  // Document ID format: [displayName]__[UID]
  String _extractUserId(String documentId) {
    // Extract the UID part (after '__')
    if (documentId.contains('__')) {
      return documentId.split('__').last;
    }
    // Fallback: if no '__', assume it's already just the UID
    return documentId;
  }

  // Helper function to get user document reference
  // Searches by uid field (new format: [displayName]__[UID])
  Future<DocumentReference> _getUserDocumentRef(String userId) async {
    // Search by uid field (new format)
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.reference;
    }

    // If not found, throw an error
    throw Exception('User document not found for UID: $userId');
  }

  // Helper function to set Custom Claims directly via callable Cloud Function
  Future<void> _setCustomClaimsDirectly(
      String userId, List<String> roles) async {
    try {
      debugPrint(
          '🔍 _setCustomClaimsDirectly: Setting Custom Claims for user $userId with roles: $roles');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) {
        debugPrint('❌ _setCustomClaimsDirectly: User is null');
        return;
      }

      final token = await user.getIdToken();
      if (token == null) {
        debugPrint('❌ _setCustomClaimsDirectly: Token is null');
        return;
      }

      // Call the Cloud Function (Firebase Callable Functions format)
      final url =
          'https://us-central1-love-to-learn-sign.cloudfunctions.net/setCustomClaims';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'userId': userId,
            'roles': roles,
          },
        }),
      );

      debugPrint(
          '🔍 _setCustomClaimsDirectly: Response status: ${response.statusCode}');
      debugPrint(
          '🔍 _setCustomClaimsDirectly: Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint(
            '✅ _setCustomClaimsDirectly: Custom Claims set successfully');
        final result = jsonDecode(response.body);
        debugPrint('🔍 _setCustomClaimsDirectly: Result: $result');
      } else {
        debugPrint(
            '❌ _setCustomClaimsDirectly: Failed with status ${response.statusCode}');
        debugPrint('❌ _setCustomClaimsDirectly: Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ _setCustomClaimsDirectly: Error: $e');
      // Don't throw - continue with operation even if Custom Claims setting fails
    }
  }

  // Helper function to refresh admin token before Firestore operations
  Future<void> _refreshAdminToken() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        // First, ensure the UID document exists for Firestore rules
        // This document allows Firestore rules to verify admin status
        try {
          final userDocRef = await _getUserDocumentRef(user.uid);
          final userDoc = await userDocRef.get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            final currentRoles = List<String>.from(userData?['roles'] ?? []);

            debugPrint(
                '🔍 Admin Token Refresh: Current roles in Firestore: $currentRoles');
            debugPrint('🔍 Admin Token Refresh: User UID: ${user.uid}');
            debugPrint('🔍 Admin Token Refresh: Document ID: ${userDocRef.id}');

            // Trigger Cloud Function by updating the document (even if roles haven't changed)
            // This ensures Custom Claims are set
            // Add a temporary field to force the update to be detected
            await userDocRef.update({
              'roles': currentRoles, // Same roles, but triggers Cloud Function
              'updatedAt': FieldValue.serverTimestamp(),
              '_lastAdminCheck': FieldValue
                  .serverTimestamp(), // Temporary field to force update
            });
            debugPrint('✅ Triggered Custom Claims update for admin user');

            // Wait longer for Cloud Function to process (3 seconds to be safe)
            await Future.delayed(const Duration(milliseconds: 3000));
          }
        } catch (e) {
          debugPrint('❌ Warning: Could not trigger Custom Claims update: $e');
        }

        // Force token refresh to get updated Custom Claims
        final token = await user.getIdToken(true);
        debugPrint('🔍 Admin Token Refresh: Got new token');

        // Decode token to check Custom Claims (for debugging)
        try {
          if (token == null || token.isEmpty) {
            debugPrint('⚠️ Token is null or empty');
            return;
          }

          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            // Add padding if needed for base64 decoding
            String normalizedPayload =
                payload.replaceAll('-', '+').replaceAll('_', '/');
            switch (normalizedPayload.length % 4) {
              case 1:
                normalizedPayload += '===';
                break;
              case 2:
                normalizedPayload += '==';
                break;
              case 3:
                normalizedPayload += '=';
                break;
            }
            final decodedBytes = base64Decode(normalizedPayload);
            final decoded = utf8.decode(decodedBytes);
            final tokenData = jsonDecode(decoded) as Map<String, dynamic>;
            final customClaims = tokenData['roles'] as List<dynamic>?;
            debugPrint(
                '🔍 Admin Token Refresh: Custom Claims in token: $customClaims');

            if (customClaims == null || !customClaims.contains('admin')) {
              debugPrint(
                  '⚠️ WARNING: Custom Claims not found or admin role missing!');
              debugPrint(
                  '⚠️ This means the Cloud Function may not have executed yet.');
              debugPrint('⚠️ Full token data: $tokenData');
            } else {
              debugPrint('✅ Custom Claims found with admin role!');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Could not decode token for debugging: $e');
        }

        await authProvider.refreshUserRoles();
        debugPrint('✅ Admin token refreshed successfully');
      }
    } catch (e) {
      debugPrint('❌ Warning: Could not refresh admin token: $e');
      // Don't throw - continue with operation even if token refresh fails
    }
  }

  // Save user roles to Firestore (no email sent)
  // Automatically approves user if roles are assigned (and user was not already approved)
  // If noteToUpdate is provided, updates the note field in Firestore
  Future<void> _saveUserRoles(String userId, List<String> newRoles,
      {bool? wasApprovedBefore, String? noteToUpdate}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user info BEFORE refresh
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAdmin) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Only admins can modify user roles.';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Admin access required to modify roles.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      final currentUser = authProvider.user;
      debugPrint('🔍 _saveUserRoles: Current user UID: ${currentUser?.uid}');
      debugPrint('🔍 _saveUserRoles: Target user ID: $userId');
      debugPrint(
          '🔍 _saveUserRoles: Current user roles: ${authProvider.userRoles}');

      if (currentUser == null) {
        throw Exception('Current user is null');
      }

      // Set Custom Claims directly via callable Cloud Function BEFORE any Firestore operations
      debugPrint('🔍 _saveUserRoles: About to call _setCustomClaimsDirectly');
      await _setCustomClaimsDirectly(currentUser.uid, authProvider.userRoles);
      debugPrint('🔍 _saveUserRoles: _setCustomClaimsDirectly completed');

      // Wait a moment for Custom Claims to propagate
      await Future.delayed(const Duration(milliseconds: 1000));

      // Refresh admin token after setting Custom Claims
      await _refreshAdminToken();

      // Check Custom Claims AFTER refresh
      try {
        final tokenAfter = await currentUser.getIdToken(true);
        if (tokenAfter == null) return;
        final partsAfter = tokenAfter.split('.');
        if (partsAfter.length == 3) {
          final payloadAfter = partsAfter[1];
          String normalizedPayloadAfter =
              payloadAfter.replaceAll('-', '+').replaceAll('_', '/');
          switch (normalizedPayloadAfter.length % 4) {
            case 1:
              normalizedPayloadAfter += '===';
              break;
            case 2:
              normalizedPayloadAfter += '==';
              break;
            case 3:
              normalizedPayloadAfter += '=';
              break;
          }
          final decodedBytesAfter = base64Decode(normalizedPayloadAfter);
          final decodedAfter = utf8.decode(decodedBytesAfter);
          final tokenDataAfter = jsonDecode(decodedAfter) as Map<String, dynamic>;
          final customClaimsAfter = tokenDataAfter['roles'] as List<dynamic>?;
          debugPrint('🔍 _saveUserRoles: Custom Claims AFTER refresh: $customClaimsAfter');
          debugPrint('🔍 _saveUserRoles: Full token data AFTER: $tokenDataAfter');

          if (customClaimsAfter == null || !customClaimsAfter.contains('admin')) {
            debugPrint('❌ ERROR: Admin role NOT found in Custom Claims after refresh!');
            debugPrint('❌ This means Firestore rules will deny access.');
          } else {
            debugPrint('✅ Admin role found in Custom Claims after refresh');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not decode token after refresh: $e');
      }

      // Get user document reference with automatic migration
      debugPrint(
          '🔍 _saveUserRoles: Getting document reference for user: $userId');
      final docRef = await _getUserDocumentRef(userId);
      debugPrint('🔍 _saveUserRoles: Document reference ID: ${docRef.id}');
      debugPrint('🔍 _saveUserRoles: Document path: ${docRef.path}');

      final userDoc = await docRef.get();
      debugPrint('🔍 _saveUserRoles: Document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      final oldRoles = List<String>.from(userData?['roles'] ?? []);
      debugPrint('🔍 _saveUserRoles: Old roles: $oldRoles');
      debugPrint('🔍 _saveUserRoles: New roles: $newRoles');
      debugPrint(
          '🔍 _saveUserRoles: Document data UID field: ${userData?['uid']}');

      // Update roles in Firestore using the correct document reference
      debugPrint('🔍 _saveUserRoles: Attempting Firestore update...');
      final updateData = <String, dynamic>{
        'roles': newRoles,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Automatically approve user if roles are assigned and user was not already approved
      if (newRoles.isNotEmpty &&
          (wasApprovedBefore == false || wasApprovedBefore == null)) {
        updateData['approved'] = true;
        updateData['status'] = 'approved';
        debugPrint(
            '🔍 _saveUserRoles: Automatically approving user (roles assigned)');
      }

      // Update note if provided (can be empty string to clear it)
      if (noteToUpdate != null) {
        updateData['note'] =
            noteToUpdate.isEmpty ? FieldValue.delete() : noteToUpdate;
        debugPrint(
            '🔍 _saveUserRoles: Updating note: ${noteToUpdate.isEmpty ? "(cleared)" : noteToUpdate}');
      }

      debugPrint('🔍 _saveUserRoles: Update data: $updateData');
      await docRef.update(updateData);

      debugPrint('✅ _saveUserRoles: Firestore update successful!');

      // Force update Custom Claims for the target user immediately
      // This ensures that even if the Firestore trigger fails or is slow, the claims are updated
      // We use the admin's credentials (current user) to call the function
      try {
        debugPrint(
            '🔍 _saveUserRoles: Forcing Custom Claims update for target user $userId');
        await _setCustomClaimsDirectly(userId, newRoles);
        debugPrint(
            '✅ _saveUserRoles: Target user Custom Claims updated directly');
      } catch (e) {
        debugPrint(
            '⚠️ _saveUserRoles: Direct Custom Claims update failed (will rely on Firestore trigger): $e');
        // Don't throw, let the Firestore trigger handle it as fallback
      }

      // Log the approval if user was automatically approved
      if (newRoles.isNotEmpty &&
          (wasApprovedBefore == false || wasApprovedBefore == null)) {
        await FirebaseFirestore.instance.collection('roleLogs').add({
          'userId': userId,
          'documentId': docRef.id,
          'action': 'approved',
          'changedBy': authProvider.user?.uid,
          'changedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('🔍 _saveUserRoles: Logged automatic approval');
      }

      // Log the role change
      await FirebaseFirestore.instance.collection('roleLogs').add({
        'userId': userId,
        'documentId': docRef.id,
        'oldRoles': oldRoles,
        'newRoles': newRoles,
        'action': 'saved',
        'changedBy': authProvider.user?.uid,
        'changedAt': FieldValue.serverTimestamp(),
      });

      // Refresh user's token if it's the current user
      if (authProvider.user?.uid == userId) {
        try {
          await authProvider.user?.getIdToken(true);
          await authProvider.refreshUserRoles();
        } catch (e) {
          debugPrint('Warning: Could not refresh token: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.onSurface2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (newRoles.isNotEmpty &&
                            (wasApprovedBefore == false ||
                                wasApprovedBefore == null))
                        ? 'User approved and roles saved successfully'
                        : 'User settings saved successfully',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface2),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in _saveUserRoles: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ Error type: ${e.runtimeType}');

      // Check Custom Claims one more time on error
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      if (currentUser != null) {
        try {
          final tokenOnError = await currentUser.getIdToken(false);
          if (tokenOnError != null) {
            final partsOnError = tokenOnError.split('.');
            if (partsOnError.length == 3) {
              final payloadOnError = partsOnError[1];
              String normalizedPayloadOnError =
                  payloadOnError.replaceAll('-', '+').replaceAll('_', '/');
              switch (normalizedPayloadOnError.length % 4) {
                case 1:
                  normalizedPayloadOnError += '===';
                  break;
                case 2:
                  normalizedPayloadOnError += '==';
                  break;
                case 3:
                  normalizedPayloadOnError += '=';
                  break;
              }
              final decodedBytesOnError =
                  base64Decode(normalizedPayloadOnError);
              final decodedOnError = utf8.decode(decodedBytesOnError);
              final tokenDataOnError =
                  jsonDecode(decodedOnError) as Map<String, dynamic>;
              final customClaimsOnError =
                  tokenDataOnError['roles'] as List<dynamic>?;
              debugPrint('❌ Custom Claims ON ERROR: $customClaimsOnError');
              debugPrint('❌ Full token ON ERROR: $tokenDataOnError');
            }
          }
        } catch (decodeError) {
          debugPrint('⚠️ Could not decode token on error: $decodeError');
        }
      }

      String errorMsg = 'Failed to save user settings';
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permission-denied')) {
        errorMsg =
            'Permission denied. Please check Firestore rules. Make sure you have admin role.';
        debugPrint('❌ PERMISSION_DENIED detected. This means:');
        debugPrint('   1. Custom Claims may not be set correctly');
        debugPrint('   2. Firestore rules may not recognize admin role');
        debugPrint('   3. Cloud Function may not have executed yet');
      } else if (e.toString().contains('not-found') ||
          e.toString().contains('NOT_FOUND')) {
        errorMsg = 'User document not found.';
      } else if (e.toString().contains('unavailable') ||
          e.toString().contains('UNAVAILABLE')) {
        errorMsg =
            'Service unavailable. Please check your internet connection.';
      } else {
        errorMsg =
            'Error: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }

      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Send notification email to user (does not save anything)
  Future<void> _notifyUser(
      String userId, String email, String displayName) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text(
            'User email not found. Cannot send notification.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user document reference with automatic migration
      final docRef = await _getUserDocumentRef(userId);
      final userDoc = await docRef.get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('User document data is null');
      }
      final currentRoles = List<String>.from(userData['roles'] ?? []);
      final userCountry = userData['country'] as String?;

      // Call Cloud Function to send email using HTTP
      // Get Firebase Auth token for authentication
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = await authProvider.user?.getIdToken();

      if (authToken == null) {
        throw Exception('User not authenticated');
      }

      // Get Firebase project ID from Firestore instance
      final projectId = FirebaseFirestore.instance.app.options.projectId;
      final functionUrl =
          'https://us-central1-$projectId.cloudfunctions.net/sendUserRoleNotification';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'data': {
            'userId': userId,
            'email': email,
            'displayName': displayName,
            'roles': currentRoles,
            'country': userCountry,
          },
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            errorBody['error']?['message'] ?? 'Failed to send notification');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.onSurface2),
                const SizedBox(width: 8),
                Text(
                  'Notification email sent successfully',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface2),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      String errorMsg = 'Failed to send notification email';
      if (e.toString().contains('UNAUTHENTICATED') ||
          e.toString().contains('unauthenticated')) {
        errorMsg = 'Authentication error. Please sign in again.';
      } else if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permission-denied')) {
        errorMsg = 'Permission denied. Make sure you have admin role.';
      } else if (e.toString().contains('unavailable') ||
          e.toString().contains('UNAVAILABLE')) {
        errorMsg =
            'Service unavailable. Please check your internet connection.';
      } else {
        errorMsg =
            'Error: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }

      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAndDeleteUser(String userId, String displayName) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text(
          'Are you sure you want to delete this user and all their data?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final idToken = await authProvider.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Authentication error. Please sign in again.');
      }

      final projectId = FirebaseFirestore.instance.app.options.projectId;
      final response = await http.post(
        Uri.parse(
            'https://us-central1-$projectId.cloudfunctions.net/deleteUserAndData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {
            'userId': userId,
          },
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            errorBody['error']?['message'] ?? 'Failed to delete user');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Row(
              children: [
                Icon(Icons.delete_forever,
                    color: Theme.of(context).colorScheme.onSurface2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'User "$displayName" deleted successfully',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface2),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting user $userId: $e');
      setState(() {
        _errorMessage = 'Failed to delete user: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Text(
              'Failed to delete user: $e',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Toggle a role for a user (DEPRECATED - kept for backward compatibility, but not used in new dialog)
  // ignore: unused_element
  Future<void> _toggleUserRole(String userId, String role) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAdmin) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Only admins can update roles.';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Admin access required to update roles.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      // Refresh admin token before operation to ensure Custom Claims are up to date
      await _refreshAdminToken();

      // Get user document reference with automatic migration
      final docRef = await _getUserDocumentRef(userId);
      final userDoc = await docRef.get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final currentRoles = List<String>.from(
          (userDoc.data() as Map<String, dynamic>?)?['roles'] ?? []);
      final oldRoles = List<String>.from(currentRoles);

      // Toggle role
      if (currentRoles.contains(role)) {
        currentRoles.remove(role);
      } else {
        currentRoles.add(role);
      }

      // Update roles in Firestore using the correct document reference
      await docRef.update({
        'roles': currentRoles,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log the role change
      await FirebaseFirestore.instance.collection('roleLogs').add({
        'userId': userId,
        'documentId': docRef.id,
        'oldRoles': oldRoles,
        'newRoles': currentRoles,
        'action': oldRoles.contains(role) ? 'removed' : 'added',
        'role': role,
        'changedBy':
            Provider.of<AuthProvider>(context, listen: false).user?.uid,
        'changedAt': FieldValue.serverTimestamp(),
      });

      // Refresh user's token if it's the current user
      if (authProvider.user?.uid == userId) {
        // Force token refresh to get updated Custom Claims
        try {
          await authProvider.user?.getIdToken(true);
          await authProvider.refreshUserRoles();
        } catch (e) {
          debugPrint('Warning: Could not refresh token: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.onSurface2),
                const SizedBox(width: 8),
                Text(
                  oldRoles.contains(role)
                      ? 'Role $role removed successfully'
                      : 'Role $role added successfully',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface2),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating role: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error toString: ${e.toString()}');
      String errorMsg = 'Failed to update role';
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permission-denied')) {
        errorMsg =
            'Permission denied. Please check Firestore rules. Make sure you have admin role.';
      } else if (e.toString().contains('not-found') ||
          e.toString().contains('NOT_FOUND')) {
        errorMsg = 'User document not found.';
      } else if (e.toString().contains('unavailable') ||
          e.toString().contains('UNAVAILABLE')) {
        errorMsg =
            'Service unavailable. Please check your internet connection.';
      } else {
        errorMsg =
            'Error: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }

      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRoleDialog(String userIdOrDocId, List<String> currentRoles,
      String displayName, bool isApproved,
      {String? note, String? email, String? country}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only admins can manage roles.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Extract UID from document ID if needed (handles both [name]__[UID] and [UID] formats)
    final userId = _extractUserId(userIdOrDocId);
    final availableRoles = [
      'student',
      'teacher',
      'jw',
      'editor',
      'admin',
      'freeUser',
      'paidUser'
    ];
    // Local state for role changes (not saved yet)
    final selectedRoles = List<String>.from(currentRoles);
    // Local state for note (can be cleared by admin)
    String? currentNote = note;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Manage Roles for $displayName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Approval status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isApproved
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isApproved ? Icons.check_circle : Icons.pending,
                        color: isApproved
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isApproved ? 'Approved' : 'Pending Approval',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isApproved
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentNote != null && currentNote!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Note from User:',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setDialogState(() {
                                  currentNote = null; // Clear note locally
                                });
                              },
                              tooltip: 'Remove note',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentNote!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Selected roles: ${selectedRoles.isEmpty ? "None" : selectedRoles.join(", ")}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Available Roles:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...availableRoles.map((role) => CheckboxListTile(
                      title: Text(role.toUpperCase()),
                      value: selectedRoles.contains(role),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            if (!selectedRoles.contains(role)) {
                              selectedRoles.add(role);
                            }
                          } else {
                            selectedRoles.remove(role);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      debugPrint('🔍 Save User Settings button pressed');
                      Navigator.of(dialogContext).pop();
                      try {
                        // Pass the note update (empty string if cleared, null if unchanged)
                        String? noteToUpdate;
                        if (currentNote == null &&
                            note != null &&
                            note.isNotEmpty) {
                          // Note was cleared by admin
                          noteToUpdate = '';
                        } else if (currentNote != null && currentNote != note) {
                          // Note was modified (shouldn't happen in current UI, but handle it)
                          noteToUpdate = currentNote;
                        }
                        await _saveUserRoles(userId, selectedRoles,
                            wasApprovedBefore: isApproved,
                            noteToUpdate: noteToUpdate);
                      } catch (e) {
                        debugPrint('❌ Error in Save User Settings button: $e');
                      }
                    },
              icon: const Icon(Icons.save),
              label: const Text('Save User Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _notifyUser(userId, email ?? '', displayName);
              },
              icon: const Icon(Icons.email),
              label: const Text('Notify User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDashboard = L2LLayoutScope.maybeOf(context)?.isDashboard ?? false;
    final isDashboardDesktop = L2LLayoutScope.isDashboardDesktop(context);

    // Check if user is admin
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You must be an admin to access this page.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: isDashboard
          ? null
          : AppBar(
              iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
              title: Text(
                'Admin Panel',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
      body: Stack(
        children: [
          // Main content - disabled when loading
          IgnorePointer(
            ignoring: _isLoading,
            child: Opacity(
              opacity: _isLoading ? 0.5 : 1.0,
              child: isDashboardDesktop ? _buildDesktopBody(context, theme) : SingleChildScrollView(
              child: Column(
                children: [
                  // DASHBOARD SECTION (mobile-friendly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Dashboard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  StreamBuilder<QuerySnapshot>(
                      stream: _usersStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No users found'));
                        }

                        final allDocs = snapshot.data!.docs;

                        // Compute dashboard stats based on createdAt field
                        final now = DateTime.now();
                        final todayStart =
                            DateTime(now.year, now.month, now.day);
                        final last7Start =
                            now.subtract(const Duration(days: 7));
                        final last30Start =
                            now.subtract(const Duration(days: 30));

                        int todayCount = 0;
                        int last7Count = 0;
                        int last30Count = 0;

                        final countrySet = <String>{};
                        final roleSet = <String>{};

                        for (final doc in allDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final createdAt = data['createdAt'] as Timestamp?;
                          final rawCountry =
                              (data['country'] as String?)?.trim();
                          final normalizedCountry =
                              (rawCountry == null || rawCountry.isEmpty)
                                  ? 'Unknown'
                                  : rawCountry;
                          countrySet.add(normalizedCountry);

                          final roles = List<String>.from(data['roles'] ?? []);
                          for (final r in roles) {
                            if (r.trim().isNotEmpty) {
                              roleSet.add(r.trim());
                            }
                          }

                          if (createdAt == null) continue;
                          final created = createdAt.toDate();

                          if (!created.isBefore(todayStart)) {
                            todayCount++;
                          }
                          if (!created.isBefore(last7Start)) {
                            last7Count++;
                          }
                          if (!created.isBefore(last30Start)) {
                            last30Count++;
                          }
                        }

                        final totalUsers = allDocs.length;
                        final countries = countrySet.toList()
                          ..sort((a, b) {
                            if (a == 'Unknown') return 1;
                            if (b == 'Unknown') return -1;
                            return a.toLowerCase().compareTo(b.toLowerCase());
                          });
                        final rolesForFilter = roleSet.toList()
                          ..sort((a, b) =>
                              a.toLowerCase().compareTo(b.toLowerCase()));

                        // Apply combined filters: search + country + date
                        DateTime? rangeStart;
                        switch (_selectedDateRange) {
                          case 'today':
                            rangeStart = todayStart;
                            break;
                          case '7':
                            rangeStart = last7Start;
                            break;
                          case '30':
                            rangeStart = last30Start;
                            break;
                          case '90':
                            rangeStart = now.subtract(const Duration(days: 90));
                            break;
                          default:
                            rangeStart = null;
                        }

                        final filteredUsers = allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          // Search filter (email or displayName)
                          if (_searchQuery.isNotEmpty) {
                            final email =
                                (data['email'] ?? '').toString().toLowerCase();
                            final displayName = (data['displayName'] ?? '')
                                .toString()
                                .toLowerCase();
                            final matchesSearch =
                                email.contains(_searchQuery) ||
                                    displayName.contains(_searchQuery);
                            if (!matchesSearch) return false;
                          }

                          // Country filter
                          if (_selectedCountryFilter != null) {
                            final rawCountry =
                                (data['country'] as String?)?.trim();
                            final normalizedCountry =
                                (rawCountry == null || rawCountry.isEmpty)
                                    ? 'Unknown'
                                    : rawCountry;
                            if (normalizedCountry != _selectedCountryFilter) {
                              return false;
                            }
                          }

                          // Hearing status filter
                          if (_selectedHearingStatusFilter != null) {
                            final hearingStatus = data['hearingStatus'] as String? ??
                                                 data['hearing_status'] as String? ??
                                                 data['userType'] as String?;
                            String? normalizedStatus;
                            if (hearingStatus != null) {
                              final lower = hearingStatus.toLowerCase();
                              if (lower.contains('hearing') && !lower.contains('impaired') && !lower.contains('deaf')) {
                                normalizedStatus = 'hearing';
                              } else if (lower.contains('deaf') || lower.contains('impaired')) {
                                normalizedStatus = 'deaf';
                              }
                            }
                            if (normalizedStatus != _selectedHearingStatusFilter) {
                              return false;
                            }
                          }

                          // Date range filter
                          if (rangeStart != null) {
                            final createdAt = data['createdAt'] as Timestamp?;
                            if (createdAt == null) {
                              return false;
                            }
                            final created = createdAt.toDate();
                            if (created.isBefore(rangeStart)) {
                              return false;
                            }
                          }

                          // Role filter
                          if (_selectedRoleFilter != 'all') {
                            final roles =
                                List<String>.from(data['roles'] ?? []);
                            if (_selectedRoleFilter == 'none') {
                              if (roles.isNotEmpty) return false;
                            } else {
                              if (!roles.contains(_selectedRoleFilter))
                                return false;
                            }
                          }

                          return true;
                        }).toList();

                        final usersList = filteredUsers.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No users match your filters'),
                              )
                            : Column(
                                children: filteredUsers.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final email = data['email'] ?? 'No email';
                                  final displayName = data['displayName'] ?? 'No name';
                                  final country = data['country'] as String?;
                                  final roles = List<String>.from(data['roles'] ?? []);
                                  final isApproved = data['approved'] ?? false;
                                  final createdAt = data['createdAt'] as Timestamp?;
                                  final photoUrl = data['photoUrl'] as String?;
                                  final userId = data['uid'] as String? ?? _extractUserId(doc.id);
                                  final hearingStatus = data['hearingStatus'] as String? ??
                                      data['hearing_status'] as String? ??
                                      data['userType'] as String?;
                                  String? normalizedHearingStatus;
                                  if (hearingStatus != null) {
                                    final lower = hearingStatus.toLowerCase();
                                    if (lower.contains('hearing') &&
                                        !lower.contains('impaired') &&
                                        !lower.contains('deaf')) {
                                      normalizedHearingStatus = 'hearing';
                                    } else if (lower.contains('deaf') || lower.contains('impaired')) {
                                      normalizedHearingStatus = 'deaf';
                                    }
                                  }

                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Stack(
                                      children: [
                                        ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                            child: photoUrl == null
                                                ? Text(
                                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                  )
                                                : null,
                                          ),
                                          title: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(child: Text(displayName)),
                                                  if (!isApproved)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.error,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        'PENDING',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.email,
                                                      size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      email,
                                                      style: TextStyle(
                                                          fontSize: 12, color: Colors.grey[600]),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on,
                                                      size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      country ?? 'Missing country',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: country == null
                                                            ? theme.colorScheme.error
                                                            : Colors.grey[600],
                                                        fontStyle: country == null
                                                            ? FontStyle.italic
                                                            : FontStyle.normal,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (country == null)
                                                    Container(
                                                      margin: const EdgeInsets.only(left: 4),
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 4, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.errorContainer,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '⚠',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: theme.colorScheme.onErrorContainer,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: roles.isEmpty
                                                    ? [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Text(
                                                            'NO ROLES',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ]
                                                    : roles
                                                        .map(
                                                          (role) => Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: _getRoleColor(role),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              role.toUpperCase(),
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                              ),
                                              if (createdAt != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    'Joined: ${createdAt.toDate().toString().split(' ')[0]}',
                                                    style: TextStyle(
                                                        fontSize: 12, color: Colors.grey[600]),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () {
                                                  _showRoleDialog(
                                                    userId,
                                                    roles,
                                                    displayName,
                                                    isApproved,
                                                    note: data['note'] as String?,
                                                    email: email,
                                                    country: country,
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete_outline,
                                                    color: theme.colorScheme.error),
                                                onPressed: () =>
                                                    _confirmAndDeleteUser(userId, displayName),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Ear icon indicator in top-left corner
                                        if (normalizedHearingStatus != null)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface
                                                    .withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                normalizedHearingStatus == 'hearing'
                                                    ? Icons.hearing
                                                    : Icons.hearing_disabled,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );

                        final dashboardCards = _buildDashboardSection(
                          context,
                          todayCount: todayCount,
                          last7Count: last7Count,
                          last30Count: last30Count,
                          totalUsers: totalUsers,
                        );

                        final filtersAndSearch = Column(
                          children: [
                            // Filters header + button (opens modal)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Filters',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        icon: const Icon(Icons.tune, size: 18),
                                        label: const Text('Open filters'),
                                        style: TextButton.styleFrom(
                                          padding:
                                              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          foregroundColor: theme.colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          _openFilterSheet(
                                            context,
                                            countries: countries,
                                            rolesForFilter: rolesForFilter,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Filter chips (country / date / role)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (_selectedCountryFilter != null)
                                        _buildFilterChip(
                                          label: _selectedCountryFilter == 'Unknown'
                                              ? 'Country: Unknown / Missing'
                                              : 'Country: $_selectedCountryFilter',
                                          onClear: () {
                                            setState(() {
                                              _selectedCountryFilter = null;
                                            });
                                          },
                                          theme: theme,
                                        ),
                                      if (_selectedHearingStatusFilter != null)
                                        _buildFilterChip(
                                          label: _selectedHearingStatusFilter == 'hearing'
                                              ? 'Hearing Status: Hearing'
                                              : 'Hearing Status: Deaf / Hearing Impaired',
                                          onClear: () {
                                            setState(() {
                                              _selectedHearingStatusFilter = null;
                                            });
                                          },
                                          theme: theme,
                                        ),
                                      if (_selectedDateRange != 'all')
                                        _buildFilterChip(
                                          label: 'Date: ${_dateRangeLabel(_selectedDateRange)}',
                                          onClear: () {
                                            setState(() {
                                              _selectedDateRange = 'all';
                                            });
                                          },
                                          theme: theme,
                                        ),
                                      if (_selectedRoleFilter != 'all')
                                        _buildFilterChip(
                                          label: _selectedRoleFilter == 'none'
                                              ? 'Role: No role'
                                              : 'Role: ${_selectedRoleFilter.toUpperCase()}',
                                          onClear: () {
                                            setState(() {
                                              _selectedRoleFilter = 'all';
                                            });
                                          },
                                          theme: theme,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Search bar (always visible for quick access)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  labelText: 'Search users by email or name',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.toLowerCase();
                                  });
                                },
                              ),
                            ),
                          ],
                        );

                        if (isDashboardDesktop) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 380,
                                  child: Column(
                                    children: [
                                      dashboardCards,
                                      const SizedBox(height: 8),
                                      filtersAndSearch,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: usersList),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Dashboard cards
                            dashboardCards,
                            filtersAndSearch,
                            usersList,
                          ],
                        );
                      },
                  ),
                ],
                ),
              ),
            ),
          ),
          // Loading overlay - centered spinner
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Saving user settings...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection(
    BuildContext context, {
    required int todayCount,
    required int last7Count,
    required int last30Count,
    required int totalUsers,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    // Two cards per row with small horizontal spacing
    final cardWidth = (width - 16 * 2 - 8) / 2;

    Widget buildCard({
      required String title,
      required String value,
      required IconData icon,
      required Color color,
      required Color foregroundColor,
    }) {
      return SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: foregroundColor,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foregroundColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          buildCard(
            title: 'New today',
            value: todayCount.toString(),
            icon: Icons.today,
            color: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
          buildCard(
            title: 'Last 7 days',
            value: last7Count.toString(),
            icon: Icons.calendar_view_week,
            color: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          buildCard(
            title: 'Last 30 days',
            value: last30Count.toString(),
            icon: Icons.calendar_view_month,
            color: theme.colorScheme.tertiaryContainer,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
          ),
          buildCard(
            title: 'Total users',
            value: totalUsers.toString(),
            icon: Icons.groups,
            color: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.error, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              final allDocs = snapshot.data!.docs;

              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final last7Start = now.subtract(const Duration(days: 7));
              final last30Start = now.subtract(const Duration(days: 30));

              int todayCount = 0;
              int last7Count = 0;
              int last30Count = 0;
              int hearingCount = 0;
              int deafCount = 0;

              final countrySet = <String>{};
              final roleSet = <String>{};

              for (final doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;

                final rawCountry = (data['country'] as String?)?.trim();
                final normalizedCountry =
                    (rawCountry == null || rawCountry.isEmpty) ? 'Unknown' : rawCountry;
                countrySet.add(normalizedCountry);

                final roles = List<String>.from(data['roles'] ?? []);
                for (final r in roles) {
                  final trimmed = r.trim();
                  if (trimmed.isNotEmpty) roleSet.add(trimmed);
                }

                final hs = _normalizeHearingStatus(data);
                if (hs == 'hearing') hearingCount++;
                if (hs == 'deaf') deafCount++;

                final createdAt = data['createdAt'] as Timestamp?;
                if (createdAt == null) continue;
                final created = createdAt.toDate();
                if (!created.isBefore(todayStart)) todayCount++;
                if (!created.isBefore(last7Start)) last7Count++;
                if (!created.isBefore(last30Start)) last30Count++;
              }

              final totalUsers = allDocs.length;
              final countries = countrySet.toList()
                ..sort((a, b) {
                  if (a == 'Unknown') return 1;
                  if (b == 'Unknown') return -1;
                  return a.toLowerCase().compareTo(b.toLowerCase());
                });
              final rolesForFilter = roleSet.toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

              DateTime? rangeStart;
              switch (_selectedDateRange) {
                case 'today':
                  rangeStart = todayStart;
                  break;
                case '7':
                  rangeStart = last7Start;
                  break;
                case '30':
                  rangeStart = last30Start;
                  break;
                case '90':
                  rangeStart = now.subtract(const Duration(days: 90));
                  break;
                default:
                  rangeStart = null;
              }

              final filteredUsers = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                if (_searchQuery.isNotEmpty) {
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final displayName = (data['displayName'] ?? '').toString().toLowerCase();
                  if (!email.contains(_searchQuery) && !displayName.contains(_searchQuery)) return false;
                }

                if (_selectedCountryFilter != null) {
                  final rawCountry = (data['country'] as String?)?.trim();
                  final normalizedCountry =
                      (rawCountry == null || rawCountry.isEmpty) ? 'Unknown' : rawCountry;
                  if (normalizedCountry != _selectedCountryFilter) return false;
                }

                if (_selectedHearingStatusFilter != null) {
                  final hs = _normalizeHearingStatus(data);
                  if (hs != _selectedHearingStatusFilter) return false;
                }

                if (rangeStart != null) {
                  final createdAt = data['createdAt'] as Timestamp?;
                  if (createdAt == null) return false;
                  final created = createdAt.toDate();
                  if (created.isBefore(rangeStart)) return false;
                }

                if (_selectedRoleFilter != 'all') {
                  final roles = List<String>.from(data['roles'] ?? []);
                  if (_selectedRoleFilter == 'none') {
                    if (roles.isNotEmpty) return false;
                  } else {
                    if (!roles.contains(_selectedRoleFilter)) return false;
                  }
                }

                return true;
              }).toList();

              Widget buildUserCard(QueryDocumentSnapshot doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email = data['email'] ?? 'No email';
                final displayName = data['displayName'] ?? 'No name';
                final country = data['country'] as String?;
                final roles = List<String>.from(data['roles'] ?? []);
                final isApproved = data['approved'] ?? false;
                final createdAt = data['createdAt'] as Timestamp?;
                final photoUrl = data['photoUrl'] as String?;
                final userId = data['uid'] as String? ?? _extractUserId(doc.id);
                final normalizedHearingStatus = _normalizeHearingStatus(data);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Stack(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?')
                              : null,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(displayName)),
                                if (!isApproved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'PENDING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    country ?? 'Missing country',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: country == null ? theme.colorScheme.error : Colors.grey[600],
                                      fontStyle: country == null ? FontStyle.italic : FontStyle.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: roles.isEmpty
                                  ? [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'NO ROLES',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : roles
                                      .map(
                                        (role) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(role),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            role.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                            if (createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Joined: ${createdAt.toDate().toString().split(' ')[0]}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showRoleDialog(
                                  userId,
                                  roles,
                                  displayName,
                                  isApproved,
                                  note: data['note'] as String?,
                                  email: email,
                                  country: country,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                              onPressed: () => _confirmAndDeleteUser(userId, displayName),
                            ),
                          ],
                        ),
                      ),
                      if (normalizedHearingStatus != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              normalizedHearingStatus == 'hearing'
                                  ? Icons.hearing
                                  : Icons.hearing_disabled,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              final filtersAndSearch = Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Filters',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('Open filters'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              foregroundColor: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              _openFilterSheet(
                                context,
                                countries: countries,
                                rolesForFilter: rolesForFilter,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (_selectedCountryFilter != null)
                            _buildFilterChip(
                              label: _selectedCountryFilter == 'Unknown'
                                  ? 'Country: Unknown / Missing'
                                  : 'Country: $_selectedCountryFilter',
                              onClear: () => setState(() => _selectedCountryFilter = null),
                              theme: theme,
                            ),
                          if (_selectedHearingStatusFilter != null)
                            _buildFilterChip(
                              label: _selectedHearingStatusFilter == 'hearing'
                                  ? 'Hearing: Hearing'
                                  : 'Hearing: Deaf / Impaired',
                              onClear: () => setState(() => _selectedHearingStatusFilter = null),
                              theme: theme,
                            ),
                          if (_selectedDateRange != 'all')
                            _buildFilterChip(
                              label: 'Date: ${_dateRangeLabel(_selectedDateRange)}',
                              onClear: () => setState(() => _selectedDateRange = 'all'),
                              theme: theme,
                            ),
                          if (_selectedRoleFilter != 'all')
                            _buildFilterChip(
                              label: _selectedRoleFilter == 'none'
                                  ? 'Role: No role'
                                  : 'Role: ${_selectedRoleFilter.toUpperCase()}',
                              onClear: () => setState(() => _selectedRoleFilter = 'all'),
                              theme: theme,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search users by email or name',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                      ),
                    ],
                  ),
                ),
              );

              final usersPane = filteredUsers.isEmpty
                  ? const Center(child: Text('No users match your filters'))
                  : Scrollbar(
                      controller: _usersScrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _usersScrollController,
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: filteredUsers.length,
                        itemBuilder: (ctx, i) => buildUserCard(filteredUsers[i]),
                      ),
                    );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 360,
                    child: _buildDesktopStatsPanel(
                      theme,
                      todayCount: todayCount,
                      last7Count: last7Count,
                      last30Count: last30Count,
                      totalUsers: totalUsers,
                      hearingCount: hearingCount,
                      deafCount: deafCount,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        filtersAndSearch,
                        const SizedBox(height: 12),
                        Expanded(child: usersPane),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _openFilterSheet(
    BuildContext context, {
    required List<String> countries,
    required List<String> rolesForFilter,
  }) {
    final theme = Theme.of(context);
    final isDashboardDesktop = L2LLayoutScope.isDashboardDesktop(context);

    String localDateRange = _selectedDateRange;
    String localRoleFilter = _selectedRoleFilter;
    String? localCountryFilter = _selectedCountryFilter;
    String? localHearingStatusFilter = _selectedHearingStatusFilter;

    Widget content(BuildContext ctx, void Function(void Function()) setModalState, VoidCallback close) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: close,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: localCountryFilter ?? '__all',
              decoration: const InputDecoration(
                labelText: 'Country',
              ),
              isDense: true,
              items: [
                const DropdownMenuItem<String>(
                  value: '__all',
                  child: Text('All countries'),
                ),
                ...countries.map(
                  (c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(c == 'Unknown' ? 'Unknown / Missing' : c),
                  ),
                ),
              ],
              onChanged: (value) {
                setModalState(() {
                  if (value == '__all') {
                    localCountryFilter = null;
                  } else {
                    localCountryFilter = value;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: localHearingStatusFilter ?? '__all',
              decoration: const InputDecoration(
                labelText: 'Hearing Status',
              ),
              isDense: true,
              items: const [
                DropdownMenuItem<String>(
                  value: '__all',
                  child: Text('All'),
                ),
                DropdownMenuItem<String>(
                  value: 'hearing',
                  child: Text('Hearing'),
                ),
                DropdownMenuItem<String>(
                  value: 'deaf',
                  child: Text('Deaf / Hearing Impaired'),
                ),
              ],
              onChanged: (value) {
                setModalState(() {
                  if (value == '__all') {
                    localHearingStatusFilter = null;
                  } else {
                    localHearingStatusFilter = value;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: localDateRange,
              decoration: const InputDecoration(
                labelText: 'Date range',
              ),
              isDense: true,
              items: const [
                DropdownMenuItem<String>(
                  value: 'all',
                  child: Text('All time'),
                ),
                DropdownMenuItem<String>(
                  value: 'today',
                  child: Text('Today'),
                ),
                DropdownMenuItem<String>(
                  value: '7',
                  child: Text('Last 7 days'),
                ),
                DropdownMenuItem<String>(
                  value: '30',
                  child: Text('Last 30 days'),
                ),
                DropdownMenuItem<String>(
                  value: '90',
                  child: Text('Last 90 days'),
                ),
              ],
              onChanged: (value) {
                setModalState(() {
                  localDateRange = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: localRoleFilter,
              decoration: const InputDecoration(
                labelText: 'Role',
              ),
              isDense: true,
              items: [
                const DropdownMenuItem<String>(
                  value: 'all',
                  child: Text('All roles'),
                ),
                const DropdownMenuItem<String>(
                  value: 'none',
                  child: Text('No role'),
                ),
                ...rolesForFilter.map(
                  (r) => DropdownMenuItem<String>(
                    value: r,
                    child: Text(r.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (value) {
                setModalState(() {
                  localRoleFilter = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setModalState(() {
                      localCountryFilter = null;
                      localHearingStatusFilter = null;
                      localDateRange = 'all';
                      localRoleFilter = 'all';
                    });
                  },
                  child: const Text('Reset'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCountryFilter = localCountryFilter;
                      _selectedHearingStatusFilter = localHearingStatusFilter;
                      _selectedDateRange = localDateRange;
                      _selectedRoleFilter = localRoleFilter;
                    });
                    close();
                  },
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isDashboardDesktop) {
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return content(ctx, setModalState, () => Navigator.of(ctx).pop());
                  },
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return content(ctx, setModalState, () => Navigator.of(ctx).pop());
            },
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'jw':
        return Colors.purple;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'freeUser':
        return Colors.orange;
      case 'paidUser':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

