import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/dynamic_l10n.dart';
import '../locale_provider.dart';
import '../tenancy/tenant_scope.dart';
import 'package:line_icons/line_icons.dart';
import 'cupertino_sheet_container.dart';

class AppLanguageSetup extends StatelessWidget {
  const AppLanguageSetup({super.key});

  String _labelForCode(BuildContext context, String code) {
    switch (code) {
      case 'bn':
        return 'বাংলা';
      case 'en':
        return 'English';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).locale;
    final tenantLocales = context.watch<TenantScope>().uiLocales;

    // Only show languages that are both tenant-allowed and app-allowed.
    final allowed = context.watch<LocaleProvider>().allowedLocaleCodes;
    final codes = <String>{
      'en',
      ...tenantLocales.map((c) => c.trim().toLowerCase()).where((c) => c.isNotEmpty),
    }.where((c) => allowed.contains(c)).toList()
      ..sort();
    final currentIndex = codes.indexOf(locale.languageCode).clamp(0, (codes.isEmpty ? 0 : codes.length - 1));

    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          builder: (ctx) {
            return CupertinoSheetContainer(
              height: 220,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: currentIndex,
                ),
                itemExtent: 32,
                onSelectedItemChanged: (idx) {
                  final code = (idx >= 0 && idx < codes.length) ? codes[idx] : 'en';
                  Provider.of<LocaleProvider>(ctx, listen: false).setLocale(Locale(code));
                  Navigator.of(ctx).pop();
                },
                children: codes
                    .map((c) => Center(child: Text(_labelForCode(ctx, c))))
                    .toList(growable: false),
              ),
            );
          },
        );
      },
      child: Row(
        children: [
          Text(
            _labelForCode(context, locale.languageCode),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LineIcons.globe,
            color:Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}