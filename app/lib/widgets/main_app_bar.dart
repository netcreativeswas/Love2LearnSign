import 'package:flutter/material.dart';
import '../l10n/dynamic_l10n.dart';
import 'package:line_icons/line_icons.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? countryCode;
  final bool checkedLocation;
  final Widget? trailing;
  final String? title;
  final bool showMenuButton;
  final bool showBackButton;
  final VoidCallback? onBack;

  const MainAppBar({
    super.key,
    required this.countryCode,
    this.checkedLocation = false,
    this.trailing,
    this.title,
    this.showMenuButton = true,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              color: Theme.of(context).colorScheme.onPrimary,
              onPressed: onBack ??
                  () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
            )
          : null,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? S.of(context)!.loveToLearnSign,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          Text(
            S.of(context)!.headlineSignLanguage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
      actions: [
        if (trailing != null) trailing!,
        if (showMenuButton)
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(LineIcons.verticalEllipsis),
            onPressed: () {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null) {
                scaffold.openEndDrawer();
              } else {
                debugPrint("No Scaffold found in context for opening endDrawer.");
              }
            },
          ),
        ),
      ],
    );
  }
}