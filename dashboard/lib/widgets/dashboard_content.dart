import 'package:flutter/material.dart';

/// Dashboard-only responsive content wrapper:
/// - Centers content
/// - Constrains max width for comfortable reading on desktop
/// - Applies responsive horizontal padding
class DashboardContent extends StatelessWidget {
  static const double maxWidth = 1200;
  static const double desktopBreakpoint = 900;

  final Widget child;
  final EdgeInsets? paddingOverride;

  const DashboardContent({
    super.key,
    required this.child,
    this.paddingOverride,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= desktopBreakpoint;
    final padding =
        paddingOverride ?? EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}


