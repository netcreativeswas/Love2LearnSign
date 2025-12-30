import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../l10n/dynamic_l10n.dart';
import 'premium_settings_page.dart';
import '../login_page.dart';
import '../tenancy/tenant_scope.dart';

class PremiumExplanationPage extends StatefulWidget {
  const PremiumExplanationPage({super.key});

  @override
  State<PremiumExplanationPage> createState() => _PremiumExplanationPageState();
}

class _PremiumExplanationPageState extends State<PremiumExplanationPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final tenantId = context.read<TenantScope>().tenantId;
    await _subscriptionService.setTenant(tenantId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final monthlyProduct = _subscriptionService.monthlyProduct;
    final yearlyProduct = _subscriptionService.yearlyProduct;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.premium),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context)!.premium,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.of(context)!.unlimitedLearningAdFree,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Benefits List
            Text(
              S.of(context)!.premiumBenefits,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              context,
              Icons.block,
              S.of(context)!.noAds,
              S.of(context)!.noAdsDescription,
            ),
            _buildBenefitItem(
              context,
              Icons.quiz,
              S.of(context)!.unlimitedQuiz,
              S.of(context)!.unlimitedQuizDescription,
            ),
            _buildBenefitItem(
              context,
              Icons.style,
              S.of(context)!.unlimitedFlashcards,
              S.of(context)!.unlimitedFlashcardsDescription,
            ),
            _buildBenefitItem(
              context,
              Icons.favorite,
              S.of(context)!.supportAppDevelopment,
              S.of(context)!.supportAppDescription,
            ),
            const SizedBox(height: 32),

            // Subscription Plans
            Text(
              S.of(context)!.subscriptionPlans,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Monthly Plan
            if (monthlyProduct != null)
              _buildPlanCard(
                context,
                title: S.of(context)!.monthly,
                price: monthlyProduct.price,
                isBestValue: false,
                onTap: () => _handlePurchase(monthlyProduct),
              ),

            const SizedBox(height: 12),

            // Yearly Plan
            if (yearlyProduct != null)
              _buildPlanCard(
                context,
                title: S.of(context)!.yearly,
                price: yearlyProduct.price,
                isBestValue: true,
                onTap: () => _handlePurchase(yearlyProduct),
              ),

            const SizedBox(height: 32),

            // Continue Button
            ElevatedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                S.of(context)!.cancel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required bool isBestValue,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isBestValue ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBestValue
            ? BorderSide(
                color: Theme.of(context).colorScheme.secondary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isBestValue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              S.of(context)!.bestValue,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureSignedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return true;

    final goToLogin = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(S.of(context)!.loginTitle),
            content: Text(S.of(context)!.premiumSignInRequiredBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(S.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(S.of(context)!.loginTitle),
              ),
            ],
          ),
        ) ??
        false;

    if (goToLogin && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage(popOnSuccess: true)),
      );
    }
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<void> _handlePurchase(ProductDetails product) async {
    final ok = await _ensureSignedIn();
    if (!ok) return;

    setState(() => _isLoading = true);

    try {
      final success = await _subscriptionService.purchaseSubscription(product);
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.purchaseInitiated,
            ),
          ),
        );
        
        // Wait a moment then navigate to settings to see status
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const PremiumSettingsPage(),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.failedToInitiatePurchase,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${S.of(context)!.errorPrefix}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

