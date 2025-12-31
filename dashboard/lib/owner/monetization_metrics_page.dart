import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../tenancy/dashboard_tenant_scope.dart';
import '../monetization/monetization_metrics_view.dart';

class MonetizationMetricsPage extends StatelessWidget {
  final bool embedded;

  const MonetizationMetricsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<DashboardTenantScope>();
    final tenantId = scope.tenantId;

    return MonetizationMetricsView(
      tenantId: tenantId,
      embedded: embedded,
    );
  }
}


