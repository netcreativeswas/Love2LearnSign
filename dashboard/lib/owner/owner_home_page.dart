import 'package:flutter/material.dart';

import 'assign_access_page.dart';
import 'create_tenant_page.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CardAction(
            title: 'Create tenant / app',
            subtitle: 'Create `tenants/{tenantId}` and optionally `apps/{appId}`.',
            icon: Icons.add_business,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateTenantPage()),
            ),
          ),
          const SizedBox(height: 12),
          _CardAction(
            title: 'Assign tenant access',
            subtitle: 'Write `tenants/{tenantId}/members/{uid}` and update `userTenants/{uid}`.',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AssignAccessPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}


