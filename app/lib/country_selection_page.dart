import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'utils/countries.dart';
import 'theme.dart';
import 'home_page.dart';
import 'l10n/dynamic_l10n.dart';
import 'tenancy/tenant_scope.dart';
import 'widgets/critical_action_overlay.dart';

class CountrySelectionPage extends StatefulWidget {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  const CountrySelectionPage({
    super.key,
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  @override
  State<CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<CountrySelectionPage> {
  String? _selectedCountry;
  String? _selectedUserType;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _completeSignUp() async {
    if (_selectedCountry == null || _selectedCountry!.isEmpty) {
      setState(() {
        _errorMessage = S.of(context)!.countryValidatorEmpty;
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

    try {
      final authProvider = context.read<AuthProvider>();
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      final isApple =
          user?.providerData.any((p) => p.providerId == 'apple.com') ?? false;
      final provider = isApple ? 'apple' : 'google';

      await authProvider.completeOAuthSignUp(
        widget.uid,
        widget.email,
        widget.displayName,
        widget.photoUrl,
        _selectedCountry!,
        _selectedUserType!,
        provider: provider,
      );

      if (!mounted) return;

      // Load user data to refresh roles and status
      await authProvider.loadUserData();
      // Refresh tenant membership denormalized profile used by the dashboard:
      // tenants/{tenantId}/members/{uid}.profile pulls country/hearing from users/{uid}.
      await context.read<TenantScope>().ensureTenantMembership();

      // ✅ User is auto-approved with freeUser role - redirect to home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to complete sign up: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const SizedBox(height: 24),
              // Logo with error handling
              Image.asset(
                'assets/l2l-logo.png',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if image fails to load
                  return Icon(
                    Icons.sign_language,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context)!.googleSignUpCompleteSteps,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: S.of(context)!.countryLabel,
                  prefixIcon: Icon(IconlyLight.location),
                  helperText: S.of(context)!.countryHelperText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    _errorMessage = null;
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
                decoration: InputDecoration(
                  labelText: S.of(context)!.userTypeLabel,
                  prefixIcon: Icon(IconlyLight.profile),
                  helperText: S.of(context)!.userTypeHelperText,
                  helperStyle: const TextStyle(height: 1.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  {
                    'value': 'hearing_impaired',
                    'label': S.of(context)!.userTypeOptionHearingImpaired,
                    'icon': Icons.hearing_disabled,
                  },
                  {
                    'value': 'hearing',
                    'label': S.of(context)!.userTypeOptionHearing,
                    'icon': Icons.hearing,
                  },
                ].map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'] as String,
                    child: Row(
                      children: [
                        Icon(option['icon'] as IconData, size: 20),
                        const SizedBox(width: 8),
                        Text(option['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value;
                    _errorMessage = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context)!.userTypeValidator;
                  }
                  return null;
                },
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
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _completeSignUp,
                      icon: Icon(Icons.check),
                      label: const Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSurface2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
        ),
        CriticalActionOverlay(
          visible: _isLoading,
          title: s.processingFinishingSetupTitle,
          message: s.processingFinishingSetupMessage,
          onCancel: () {
            setState(() => _isLoading = false);
            Navigator.of(context).maybePop();
          },
          onRetry: () {
            _completeSignUp();
          },
        ),
      ],
    );
  }
}

