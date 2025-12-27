import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'home_page.dart';
import 'package:provider/provider.dart';
import 'l10n/dynamic_l10n.dart';
import 'theme.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;
import 'package:l2l_shared/auth/auth_service.dart';
import 'signup_page.dart';
import 'email_verification_page.dart';
import 'country_selection_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  /// When true, a successful login will `pop(true)` instead of navigating to Home.
  /// Useful for flows where the user must sign in first (e.g. Premium purchase),
  /// and we want to resume the previous screen/action after authentication.
  final bool popOnSuccess;

  const LoginPage({
    super.key,
    this.popOnSuccess = false,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<app_auth.AuthProvider>();
    final error = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (error == null || error.isEmpty) {
      // Check if email is verified
      final authService = AuthService();
      final isEmailVerified = await authService.isEmailVerified();
      
      if (!isEmailVerified) {
        // Email not verified, redirect to verification page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
          (Route<dynamic> route) => false,
        );
        return;
      }
      
      // Load user data to refresh roles
      final authProvider = context.read<app_auth.AuthProvider>();
      await authProvider.loadUserData();
      
      // All users are auto-approved with freeUser role - no pending check needed
      // Show SnackBar before navigating away
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onSurface2),
              const SizedBox(width: 8),
              Text(
                S.of(context)!.loginSuccess,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface2),
              ),
            ],
          ),
        ),
      );

      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        // Ensure we have a meaningful error message
        _errorMessage = error.isNotEmpty 
            ? error 
            : 'An error occurred during login. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : theme.colorScheme.primary,
        ),
        title: Text(
          S.of(context)!.loginTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: S.of(context)!.emailLabel,
                  prefixIcon: Icon(IconlyLight.message),
            ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.of(context)!.validatorEnterEmail;
                  }
                  if (!value.contains('@')) {
                    return S.of(context)!.validatorValidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: S.of(context)!.passwordLabel,
                  prefixIcon: Icon(IconlyLight.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? IconlyLight.hide : IconlyLight.show,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signIn(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/reset-password');
                },
                child: Text(S.of(context)!.forgotPassword),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
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
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ),
              if (_errorMessage != null) const SizedBox(height: 16),
            _isLoading
                  ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _signIn,
                    icon: Icon(Icons.login),
                    label: Text(S.of(context)!.loginButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSurface2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                    ),
              const SizedBox(height: 16),
              // Google Sign-In button
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });

                        final authProvider = context.read<app_auth.AuthProvider>();
                        final error = await authProvider.signInWithGoogle();

                        if (!mounted) return;

                        if (error == 'COUNTRY_SELECTION_NEEDED') {
                          // Google user needs to update country - show country selection
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CountrySelectionPage(
                                  uid: user.uid,
                                  email: user.email ?? '',
                                  displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
                                  photoUrl: user.photoURL,
                                ),
                              ),
                            );
                          }
                          setState(() {
                            _isLoading = false;
                          });
                        } else if (error == null || error.isEmpty) {
                          // ✅ User is auto-approved with freeUser role - redirect to home
                          if (widget.popOnSuccess) {
                            Navigator.of(context).pop(true);
                            return;
                          }
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        } else {
                          setState(() {
                            _errorMessage = error;
                            _isLoading = false;
                          });
                        }
                      },
                icon: Image.asset(
                  'assets/icons/google_logo.png',
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.g_mobiledata),
                ),
                label: Text(S.of(context)!.signInWithGoogle),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.of(context)!.dontHaveAccount),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    child: Text(S.of(context)!.signUpLink),
                  ),
          ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
