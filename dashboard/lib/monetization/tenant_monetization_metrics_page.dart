import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../tenancy/dashboard_tenant_scope.dart';
import 'monetization_metrics_view.dart';

/// Tenant-admin view of monetization metrics (scoped to the selected tenant).
class TenantMonetizationMetricsPage extends StatelessWidget {
  const TenantMonetizationMetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<DashboardTenantScope>();
    return MonetizationMetricsView(
      tenantId: scope.tenantId,
      embedded: false,
    );
  }
}


