import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'l10n/dynamic_l10n.dart';
import 'theme.dart';
import 'email_verification_page.dart';
import 'utils/countries.dart';
import 'services/security_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;
import 'home_page.dart';
import 'country_selection_page.dart';
import 'widgets/critical_action_overlay.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _honeypotController =
      TextEditingController(); // Honeypot field (hidden)
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedCountry;
  final _formKey = GlobalKey<FormState>();
  final SecurityService _securityService = SecurityService();
  String? _selectedUserType;

  bool _isStrongPassword(String value) {
    final password = value.trim();
    if (password.length < 12) return false;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'''[!@#\$%^&*(),.?":{}|<>_\-\\/\[\];'`~+=]''')
        .hasMatch(password);
    return hasUppercase && hasLowercase && hasDigit && hasSpecial;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // SECURITY: Honeypot field validation - reject if filled (bot detection)
    if (_honeypotController.text.isNotEmpty) {
      // Silently reject - don't show error to avoid revealing honeypot
      debugPrint('Security: Honeypot field was filled - signup rejected');
      return;
    }

    // Validate password match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = S.of(context)!.passwordMismatchError;
      });
      return;
    }

    // Validate country is selected
    if (_selectedCountry == null || _selectedCountry!.isEmpty) {
      setState(() {
        _errorMessage = S.of(context)!.selectCountryError;
      });
      return;
    }

    if (_selectedUserType == null || _selectedUserType!.isEmpty) {
      setState(() {
        _errorMessage = S.of(context)!.userTypeValidator;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // SECURITY: Check rate limiting before signup
    try {
      final ipAddress = await _securityService.getClientIp();
      final rateLimitResult = await _securityService.checkRateLimit(
        _emailController.text.trim(),
        ipAddress,
      );

      if (rateLimitResult['allowed'] != true) {
        setState(() {
          _errorMessage = rateLimitResult['reason'] as String? ??
              'Too many signup attempts. Please try again later.';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error checking rate limit: $e');
      // Continue if rate limit check fails (fail open)
    }

    final authProvider = context.read<app_auth.AuthProvider>();
    final note = _noteController.text.trim();
    final error = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _displayNameController.text.trim(),
      country: _selectedCountry!,
      note: note.isEmpty ? null : note,
      userType: _selectedUserType!,
    );

    if (!mounted) return;

    if (error == null) {
      // Email/password signup requires email verification.
      // EmailVerificationPage will redirect to HomePage once verified.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        // Translate common error messages
        if (error.toLowerCase().contains('email-already-in-use') ||
            error.toLowerCase().contains('email already in use') ||
            error.toLowerCase().contains('email_already_in_use') ||
            error.toLowerCase().contains('already registered')) {
          _errorMessage = S.of(context)!.emailAlreadyExistsError;
        } else {
          _errorMessage = error;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _noteController.dispose();
    _honeypotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : theme.colorScheme.primary,
            ),
            title: Text(
              s.signUpTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : theme.colorScheme.primary,
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
              // 1. Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: s.displayNameLabel,
                  prefixIcon: Icon(IconlyLight.profile),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return s.displayNameValidatorEmpty;
                  }
                  if (value.trim().length < 2) {
                    return s.displayNameValidatorMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 2. Email
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
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 3. Country
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: S.of(context)!.countryLabel,
                  prefixIcon: Icon(IconlyLight.location),
                  helperText: S.of(context)!.countryHelperText,
                ),
                items: countries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context)!.countryValidatorEmpty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedUserType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: S.of(context)!.userTypeLabel,
                  prefixIcon: Icon(IconlyLight.profile),
                  helperText: S.of(context)!.userTypeHelperText,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: 'hearing_impaired',
                    child: Text(S.of(context)!.userTypeOptionHearingImpaired),
                  ),
                  DropdownMenuItem<String>(
                    value: 'hearing',
                    child: Text(S.of(context)!.userTypeOptionHearing),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context)!.userTypeValidator;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 4. Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: S.of(context)!.passwordLabel,
                  prefixIcon: Icon(IconlyLight.lock),
                  helperText: S.of(context)!.passwordHelperText,
                  helperStyle: const TextStyle(height: 1.0),
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
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final password = value ?? '';
                  if (password.trim().isEmpty) {
                    return S.of(context)!.passwordValidatorEmpty;
                  }
                  if (!_isStrongPassword(password)) {
                    return S.of(context)!.passwordValidatorRequirements;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 5. Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: S.of(context)!.confirmPasswordLabel,
                  prefixIcon: Icon(IconlyLight.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? IconlyLight.hide
                          : IconlyLight.show,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context)!.confirmPasswordValidatorEmpty;
                  }
                  if (value != _passwordController.text) {
                    return S.of(context)!.confirmPasswordValidatorMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 6. Note to Administrator (single line with auto-expand) - Required
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: s.noteToAdministratorLabel,
                  hintText: s.noteToAdministratorHint,
                  prefixIcon: Icon(IconlyLight.message),
                  helperText: s.noteToAdministratorHelperText,
                ),
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              // SECURITY: Honeypot field (hidden from users, visible to bots)
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 0,
                  child: TextFormField(
                    controller: _honeypotController,
                    decoration: const InputDecoration(
                      labelText: 'Website URL',
                      hintText: 'Leave this field empty',
                    ),
                    autofillHints: const [],
                    keyboardType: TextInputType.url,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
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
                      onPressed: _signUp,
                      icon: Icon(Icons.person_add),
                      label: Text(S.of(context)!.signUpButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
              const SizedBox(height: 16),
              // Google Sign-Up button
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
                          // Google user needs to select country/type
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
                          setState(() => _isLoading = false);
                        } else if (error == null || error.isEmpty) {
                          // ✅ User is auto-approved with freeUser role - redirect to home
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const HomePage()),
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
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata),
                ),
                label: Text(S.of(context)!.signUpWithGoogle),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(S.of(context)!.alreadyHaveAccount),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(S.of(context)!.signInLink),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        ),
        CriticalActionOverlay(
          visible: _isLoading,
          title: s.processingCreatingAccountTitle,
          message: s.processingCreatingAccountMessage,
        ),
      ],
    );
  }
}
