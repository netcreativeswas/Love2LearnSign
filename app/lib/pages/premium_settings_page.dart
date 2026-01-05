import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:overlay_support/overlay_support.dart';
import '../services/subscription_service.dart';
import '../services/premium_service.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import '../l10n/dynamic_l10n.dart';
import '../tenancy/tenant_scope.dart';
// PremiumExplanationPage kept for optional marketing/info screens, but purchasing happens here.
import '../login_page.dart';
import '../widgets/critical_action_overlay.dart';

class PremiumSettingsPage extends StatefulWidget {
  final bool startProcessingOnOpen;

  const PremiumSettingsPage({
    super.key,
    this.startProcessingOnOpen = false,
  });

  @override
  State<PremiumSettingsPage> createState() => _PremiumSettingsPageState();
}

class _PremiumSettingsPageState extends State<PremiumSettingsPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PremiumService _premiumService = PremiumService();
  bool _isLoading = false;
  bool _isProcessingCritical = false;
  bool _isPremium = false;
  Map<String, dynamic>? _subscriptionInfo;
  StreamSubscription<SubscriptionChangeEvent>? _subChanged;
  bool _didPromptSignInOnOpen = false;
  bool _autoCloseOnNextSuccess = false;

  @override
  void initState() {
    super.initState();
    _isProcessingCritical = widget.startProcessingOnOpen;
    _subChanged = _subscriptionService.subscriptionChanged.listen((evt) async {
      if (!mounted) return;
      // Refresh roles + status after a purchase/restore completes.
      await Provider.of<AuthProvider>(context, listen: false).loadUserData();
      await _loadSubscriptionStatus();

      final msg = (evt.message ?? '').trim();
      if (msg.isNotEmpty && mounted) {
        final isSuccess = evt.success && (evt.active == true);
        showSimpleNotification(
          Text(
            msg,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          background: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
          foreground: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }

      if (_isProcessingCritical && mounted) {
        setState(() => _isProcessingCritical = false);
      }

      // If the user initiated a purchase from THIS screen, auto-close on successful activation.
      // (Do not auto-close on Restore; that flow shows the Premium status card.)
      if (_autoCloseOnNextSuccess && evt.success && (evt.active == true)) {
        _autoCloseOnNextSuccess = false;
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.of(context).maybePop();
      }
    });
    _loadSubscriptionStatus();

    // If user opened Premium while logged out (e.g. from Settings/snackbar),
    // prompt sign-in once so we can link purchases to an account.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_didPromptSignInOnOpen) return;
      if (FirebaseAuth.instance.currentUser != null) return;
      _didPromptSignInOnOpen = true;
      final ok = await _ensureSignedIn();
      if (ok && mounted) {
        await Provider.of<AuthProvider>(context, listen: false).loadUserData();
        await _loadSubscriptionStatus();
      }
    });
  }

  @override
  void dispose() {
    _subChanged?.cancel();
    super.dispose();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() => _isLoading = true);

    final tenantId = context.read<TenantScope>().tenantId;
    await _subscriptionService.setTenant(tenantId);
    final isPremium = await _premiumService.isPremiumForTenant(tenantId);
    final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _subscriptionInfo = subscriptionInfo;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.hasRole('admin');
    final s = S.of(context)!;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              s.upgradeToPremium,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isAdmin || _isPremium) ...[
                        // Already Premium
                        _buildPremiumStatusCard(context),
                        const SizedBox(height: 24),
                        if (_subscriptionInfo != null &&
                            _subscriptionInfo!['type'] == 'monthly') ...[
                          // Show upgrade to yearly option
                          _buildUpgradeToYearlyCard(context),
                          const SizedBox(height: 24),
                        ],
                      ] else ...[
                        // Not Premium - Show plans
                        _buildBenefitsSection(context),
                        const SizedBox(height: 24),
                        _buildPlansSection(context),
                        const SizedBox(height: 24),
                      ],

                      // Restore Purchase Button
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleRestorePurchase,
                        icon: const Icon(Icons.restore),
                        label: Text(s.restorePurchase),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        CriticalActionOverlay(
          visible: _isProcessingCritical,
          title: s.processingPremiumActivatingTitle,
          message: s.processingPremiumActivatingMessage,
          showActionsWhileProcessing: true,
          onCancel: () {
            setState(() => _isProcessingCritical = false);
          },
          onRetry: () async {
            await _loadSubscriptionStatus();
          },
        ),
      ],
    );
  }

  Widget _buildPremiumStatusCard(BuildContext context) {
    final renewalDate = _subscriptionInfo?['renewal_date'] as DateTime?;
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.star,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context)!.premiumMember,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            if (renewalDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '${S.of(context)!.renews} ${_formatDate(renewalDate)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeToYearlyCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _handleUpgradeToYearly,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context)!.switchToYearlyPlan,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.of(context)!.saveMoreBestValue,
                      style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildBenefitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.premiumBenefits,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(context, Icons.block, S.of(context)!.noAds),
        _buildBenefitItem(context, Icons.quiz, S.of(context)!.unlimitedQuiz),
        _buildBenefitItem(context, Icons.style, S.of(context)!.unlimitedFlashcards),
        _buildBenefitItem(context, Icons.favorite, S.of(context)!.supportAppDevelopment),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(BuildContext context) {
    final monthlyProduct = _subscriptionService.monthlyProduct;
    final yearlyProduct = _subscriptionService.yearlyProduct;
    final tenantScope = context.watch<TenantScope>();

    String tenantDisplayName() {
      final a = tenantScope.appConfig?.displayName.trim() ?? '';
      if (a.isNotEmpty) return a;
      final t = tenantScope.tenantConfig?.displayName.trim() ?? '';
      if (t.isNotEmpty) return t;
      return tenantScope.tenantId;
    }
    final tenantName = tenantDisplayName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.subscriptionPlans,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.8,
            ),
          ),
          child: Text(
            S.of(context)!.subscriptionAppliesToSelectedDictionary(tenantName),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        if (monthlyProduct != null)
          _buildPlanCard(
            context,
            title: S.of(context)!.monthly,
            price: monthlyProduct.price,
            isBestValue: false,
            onTap: () => _handlePurchase(monthlyProduct),
          ),
        const SizedBox(height: 12),
        if (yearlyProduct != null)
          _buildPlanCard(
            context,
            title: S.of(context)!.yearly,
            price: yearlyProduct.price,
            isBestValue: true,
            onTap: () => _handlePurchase(yearlyProduct),
          ),
      ],
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
        onTap: _isLoading ? null : onTap,
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
                              style: const TextStyle(
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
              ElevatedButton(
                onPressed: _isLoading ? null : onTap,
                child: Text(S.of(context)!.upgrade),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

    setState(() => _isProcessingCritical = true);
    try {
      _autoCloseOnNextSuccess = true;
      final success = await _subscriptionService.purchaseSubscription(product);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? S.of(context)!.purchaseInitiated
                : S.of(context)!.failedToInitiatePurchase,
          ),
        ),
      );

      if (!success && mounted) {
        _autoCloseOnNextSuccess = false;
        setState(() => _isProcessingCritical = false);
        return;
      }

      // Purchase updates + role refresh happen via subscriptionChanged listener.
      // We still refresh the current UI state quickly.
      await _loadSubscriptionStatus();
    } catch (e) {
      if (!mounted) return;
      _autoCloseOnNextSuccess = false;
      setState(() => _isProcessingCritical = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context)!.errorPrefix}: $e'),
        ),
      );
    }
  }

  Future<void> _handleUpgradeToYearly() async {
    final ok = await _ensureSignedIn();
    if (!ok) return;

    setState(() => _isProcessingCritical = true);

    try {
      _autoCloseOnNextSuccess = true;
      final success = await _subscriptionService.upgradeToYearly();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.upgradeInitiated,
            ),
          ),
        );
        await _loadSubscriptionStatus();
      } else if (mounted) {
        _autoCloseOnNextSuccess = false;
        setState(() => _isProcessingCritical = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.failedToInitiateUpgrade,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _autoCloseOnNextSuccess = false;
        setState(() => _isProcessingCritical = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${S.of(context)!.errorPrefix}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleRestorePurchase() async {
    final ok = await _ensureSignedIn();
    if (!ok) return;

    setState(() => _isLoading = true);

    try {
      // Restore should NOT auto-close the Premium page; user expects to see the status card.
      _autoCloseOnNextSuccess = false;
      final success = await _subscriptionService.restorePurchases();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.restoringPurchases,
            ),
          ),
        );
        
        // Wait a moment for restore to process
        await Future.delayed(const Duration(seconds: 2));
        await _loadSubscriptionStatus();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)!.noPurchasesFound,
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

