import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:l2l_shared/auth/auth_service.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;
import 'services/security_service.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'l10n/dynamic_l10n.dart';
import 'widgets/critical_action_overlay.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final SecurityService _securityService = SecurityService();
  bool _isChecking = false;
  bool _isResending = false;
  bool _isApproving = false;
  StreamSubscription<User?>? _authStateSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkEmailVerification();
    
    // Listen to auth state changes to automatically detect when user verifies email
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        // User state changed, check verification status
        _checkEmailVerification();
      }
    });
    
    // Polling: Check verification status every 5 seconds when page is visible
    // This ensures cross-device verification is detected (e.g., user verifies on computer, phone detects it)
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStateSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
  
  void _startPolling() {
    // Check every 5 seconds if email is verified
    // This is important for cross-device scenarios (user verifies on computer, phone detects it)
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isChecking) {
        _checkEmailVerification();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app comes back to foreground, check if email was verified
    if (state == AppLifecycleState.resumed && mounted) {
      // Immediately check when app resumes (user might have verified on another device)
      _checkEmailVerification();
      // Restart polling when app comes to foreground
      _pollingTimer?.cancel();
      _startPolling();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Stop polling when app goes to background to save battery
      _pollingTimer?.cancel();
    }
  }

  Future<void> _checkEmailVerification() async {
    if (_isChecking || _isApproving) return;
      _isChecking = true;

    try {
      // Reload user to get latest email verification status
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        await user.getIdToken(true); // Force token refresh
      }
      
      final isVerified = await _authService.isEmailVerified();
      
      if (isVerified) {
        if (!mounted) return;
        
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
        setState(() {
          _isApproving = true;
        });
        
        try {
          // Call Cloud Function to approve user and assign freeUser role
          final approveResult = await _securityService.approveUserAfterEmailVerification();
          
          if (!mounted) return;
          
          if (approveResult['success'] == true) {
            // Force token refresh to get updated Custom Claims
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await user.getIdToken(true);
            }
            
            // Reload user data to get updated roles and status
            await authProvider.loadUserData();
            
            if (!mounted) return;
            
            // Redirect to HomePage (user stays logged in with freeUser role)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context)!.emailVerifiedApprovedMessage,
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            setState(() {
              _isApproving = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(approveResult['error'] ?? S.of(context)!.verifyStatusError)),
              );
            }
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isApproving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context)!.verifyStatusError)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context)!.verifyStatusError)),
        );
      }
    } finally {
        _isChecking = false;
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
    });

    try {
      await _authService.resendEmailVerification();
      
      if (!mounted) return;
      
      setState(() {
        _isResending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.verifyEmailResentSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.verifyEmailResentError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';
    final s = S.of(context)!;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            s.verifyYourEmailTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.verifyEmailInfoBody,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            s.verifyEmailSentTo,
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              email,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed:
                                _isResending ? null : _resendVerificationEmail,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isResending)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(Icons.refresh),
                                const SizedBox(width: 8),
                                Text(
                                  _isResending
                                      ? s.sendingLabel
                                      : s.resendVerificationEmail,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.verifyEmailAutoRedirectHint,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isApproving
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            s.approvingYourAccount,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        CriticalActionOverlay(
          visible: _isApproving,
          title: s.processingFinishingSetupTitle,
          message: s.processingFinishingSetupMessage,
        ),
      ],
    );
  }
}

