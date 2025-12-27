import 'package:flutter/material.dart';
import '../l10n/dynamic_l10n.dart';
import '../theme.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:line_icons/line_icons.dart';



class MainBtmNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainBtmNavBar({
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final items = [
      BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.house, size: 20),
        label: S.of(context)!.tabHome,
      ),
      BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.book, size: 20),
        label: S.of(context)!.tabDictionary,
      ),
      BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.dice, size: 20),
        label: S.of(context)!.tabGame,
      ),
    ];

    return SafeArea(
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        elevation: 0,
        items: items,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: colorScheme.secondary,
        unselectedItemColor: colorScheme.primary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
    );
  }
}