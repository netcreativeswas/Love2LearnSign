import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/dynamic_l10n.dart';
import '../locale_provider.dart';
import 'package:line_icons/line_icons.dart';
import 'cupertino_sheet_container.dart';

class AppLanguageSetup extends StatelessWidget {
  const AppLanguageSetup({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).locale;

    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          builder: (ctx) {
            return CupertinoSheetContainer(
              height: 200,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: locale.languageCode == 'bn' ? 1 : 0,
                ),
                itemExtent: 32,
                onSelectedItemChanged: (idx) {
                  final newLocale = idx == 0 ? const Locale('en') : const Locale('bn');
                  Provider.of<LocaleProvider>(ctx, listen: false).setLocale(newLocale);
                  Navigator.of(ctx).pop();
                },
                children: const [
                  Center(child: Text('English')),
                  Center(child: Text('বাংলা')),
                ],
              ),
            );
          },
        );
      },
      child: Row(
        children: [
          Text(
            locale.languageCode == 'bn'
                ? S.of(context)!.bengali
                : S.of(context)!.english,
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