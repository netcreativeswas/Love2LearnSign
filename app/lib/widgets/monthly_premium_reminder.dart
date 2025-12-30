import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import '../l10n/dynamic_l10n.dart';
import '../pages/premium_settings_page.dart';
import '../tenancy/tenant_scope.dart';

/// Widget to show monthly premium reminder popup
class MonthlyPremiumReminder extends StatefulWidget {
  const MonthlyPremiumReminder({super.key});

  @override
  State<MonthlyPremiumReminder> createState() => _MonthlyPremiumReminderState();
}

class _MonthlyPremiumReminderState extends State<MonthlyPremiumReminder> {
  final PremiumService _premiumService = PremiumService();
  bool _shouldShow = false;
  int _learnedSignsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkAndShowReminder();
  }

  Future<void> _checkAndShowReminder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Don't show if user is premium or admin
    if (authProvider.hasRole('admin')) {
      return;
    }
    final tenantId = context.read<TenantScope>().tenantId;
    final isPremium = await _premiumService.isPremiumForTenant(tenantId);
    if (isPremium) {
      return;
    }

    final shouldShow = await _premiumService.shouldShowMonthlyReminder();
    final learnedCount = await _premiumService.getLearnedSignsCount();

    if (shouldShow && mounted) {
      setState(() {
        _shouldShow = true;
        _learnedSignsCount = learnedCount;
      });
      
      // Show dialog after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _shouldShow) {
          _showReminderDialog();
        }
      });
    }
  }

  void _showReminderDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.secondary,
              size: 32,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.of(context)!.yourProgress,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context)!.learnedSignsThisMonth(_learnedSignsCount),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context)!.supportAppRemoveAds,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context)!.noThanks),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PremiumSettingsPage(),
                ),
              );
            },
            child: Text(S.of(context)!.viewPremium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // This widget only shows dialogs, no UI
  }
}

