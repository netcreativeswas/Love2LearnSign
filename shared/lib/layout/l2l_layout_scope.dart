import 'package:flutter/widgets.dart';

/// Small shared layout scope so shared pages can render dashboard-specific desktop
/// layouts without affecting the mobile app.
///
/// By default (when not present), [isDashboard] is false.
class L2LLayoutScope extends InheritedWidget {
  static const double defaultDesktopBreakpoint = 900;

  final bool isDashboard;
  final double desktopBreakpoint;

  const L2LLayoutScope({
    super.key,
    required super.child,
    required this.isDashboard,
    this.desktopBreakpoint = defaultDesktopBreakpoint,
  });

  factory L2LLayoutScope.dashboard({
    Key? key,
    required Widget child,
    double desktopBreakpoint = defaultDesktopBreakpoint,
  }) {
    return L2LLayoutScope(
      key: key,
      child: child,
      isDashboard: true,
      desktopBreakpoint: desktopBreakpoint,
    );
  }

  static L2LLayoutScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<L2LLayoutScope>();
  }

  static L2LLayoutScope of(BuildContext context) {
    return maybeOf(context) ?? const L2LLayoutScope(child: SizedBox.shrink(), isDashboard: false);
  }

  static bool isDashboardDesktop(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null || !scope.isDashboard) return false;
    final width = MediaQuery.sizeOf(context).width;
    return width >= scope.desktopBreakpoint;
  }

  @override
  bool updateShouldNotify(L2LLayoutScope oldWidget) {
    return isDashboard != oldWidget.isDashboard || desktopBreakpoint != oldWidget.desktopBreakpoint;
  }
}


