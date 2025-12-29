import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'l10n/dynamic_l10n.dart';
import 'l10n/dynamic_l10n.dart';
import 'widgets/cupertino_sheet_container.dart';
import 'package:provider/provider.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;

class FlashcardSettingsPage extends StatefulWidget {
  const FlashcardSettingsPage({super.key});

  @override
  State<FlashcardSettingsPage> createState() => _FlashcardSettingsPageState();
}

class _FlashcardSettingsPageState extends State<FlashcardSettingsPage> {
  int _numCards = 6;
  String _contentChoice = 'random';
  List<String> _categories = ['random'];
  bool _startingPoint = false;

  String _prettyChoiceLabel(BuildContext context, String value) {
    if (value == 'random') {
      return S.of(context)!.randomAllCategories;
    }
    final String locale = Localizations.localeOf(context).languageCode;
    return locale == 'bn' ? translateCategory(context, value) : value;
  }

  @override
  void initState() {
    super.initState();
    TenantDb.concepts(FirebaseFirestore.instance).get()
        .then((snapshot) {
      final Set<String> catSet = {};
      for (final d in snapshot.docs) {
        final data = d.data();
        final String main = (data['category_main'] ?? '').toString().trim();
        if (main.isNotEmpty) catSet.add(main);
      }
      var cats = catSet.toList()..sort();
      // Filter out restricted JW categories if user lacks 'jw' role
      final roles = context.mounted ? context.read<app_auth.AuthProvider>().userRoles : const <String>[];
      final hasJW = roles.contains('jw');
      if (!hasJW) {
        final restricted = {
          'JW Organisation',
          'JW Organization',
          'Biblical Content',
        };
        cats = cats.where((c) => !restricted.contains(c)).toList();
      }
      setState(() {
        // Prepend special choice 'random' (all categories). Individual items are specific category_main values.
        _categories = ['random', ...cats];
      });
    }).catchError((error) {
      // handle error if needed
      debugPrint('Failed to load categories: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(
        S.of(context)!.settings,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary) ?? TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number of flashcards option
          Text(
            S.of(context)!.numberOfFlashcards,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary) ?? TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context)!.numberOfFlashcardsDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary) ?? TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showCupertinoModalPopup(
              context: context,
              builder: (_) => CupertinoSheetContainer(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(initialItem: _numCards - 4),
                  onSelectedItemChanged: (i) => setState(() => _numCards = i + 4),
                  children: List.generate(
                    17,
                    (i) => Text(
                      '${i + 4}',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_numCards',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Flashcard content option
          Text(
            S.of(context)!.flashcardContent,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary) ?? TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context)!.flashcardContentDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary) ?? TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showCupertinoModalPopup(
              context: context,
              builder: (_) {
                final String locale = Localizations.localeOf(context).languageCode;
                return CupertinoSheetContainer(
                  height: 200,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(initialItem: (_categories.indexOf(_contentChoice) >= 0) ? _categories.indexOf(_contentChoice) : 0),
                    onSelectedItemChanged: (i) => setState(() => _contentChoice = _categories[i]),
                    children: _categories
                        .map((c) => Text(
                              _prettyChoiceLabel(context, c),
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _prettyChoiceLabel(context, _contentChoice),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Starting point option
          Text(
            S.of(context)!.flashcardStartingPointTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary) ?? TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context)!.flashcardStartingPointDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary) ?? TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showCupertinoModalPopup(
              context: context,
              builder: (_) => CupertinoSheetContainer(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(initialItem: _startingPoint ? 1 : 0),
                  onSelectedItemChanged: (i) => setState(() => _startingPoint = (i == 1)),
                  children: [
                    Text(
                      S.of(context)!.flashcardStartingPointWord,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                    Text(
                      S.of(context)!.flashcardStartingPointSign,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _startingPoint
                      ? S.of(context)!.flashcardStartingPointSign
                      : S.of(context)!.flashcardStartingPointWord,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            S.of(context)!.cancel,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'numCards': _numCards,
              'contentChoice': _contentChoice,
              'startingPoint': _startingPoint,
            });
          },
          child: Text(
            S.of(context)!.ok,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}