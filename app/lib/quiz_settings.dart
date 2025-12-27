import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'l10n/dynamic_l10n.dart';
import 'widgets/cupertino_sheet_container.dart';

/// Holds the quiz settings.
class QuizSettings {
  bool reviewedMode;
  bool speedMode;
  int questionCount;
  int timeLimit;

  QuizSettings({
    this.reviewedMode = true,
    this.speedMode = false,
    this.questionCount = 6,
    this.timeLimit = 10,
  });
}

/// Shows a dialog to configure quiz settings and returns the chosen values.
Future<QuizSettings?> showQuizSettings(BuildContext context) async {
  final settings = QuizSettings();
  return showDialog<QuizSettings>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Text(
              S.of(context)!.settings,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            content: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  activeTrackColor: Theme.of(context).colorScheme.secondary,
                  title: Text(
                    S.of(context)!.reviewedModeTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  subtitle: Text(
                     S.of(context)!.reviewedModeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  value: settings.reviewedMode,
                  onChanged: (val) => setState(() => settings.reviewedMode = val),
                ),
                SwitchListTile(
                  activeTrackColor: Theme.of(context).colorScheme.secondary,
                  title: Text(
                    S.of(context)!.speedModeTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  subtitle: Text(
                    S.of(context)!.speedModeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  value: settings.speedMode,
                  onChanged: (val) => setState(() => settings.speedMode = val),
                ),
                if (settings.speedMode)
                  ListTile(
                    title: Text(
                      S.of(context)!.timeLimitTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    trailing: GestureDetector(
                      onTap: () async {
                        int temp = settings.timeLimit;
                        final result = await showModalBottomSheet<int>(
                          context: context,
                          builder: (ctx2) {
                            return CupertinoSheetContainer(
                              height: 250,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Text(
                                       S.of(context)!.setTimeLimitTitle,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                                    ),
                                  ),
                                  Expanded(
                                    child: CupertinoPicker(
                                      scrollController: FixedExtentScrollController(
                                        initialItem: [3,5,7,10,15,20,25,30].indexOf(temp),
                                      ),
                                      itemExtent: 32,
                                      onSelectedItemChanged: (index) {
                                        temp = [3,5,7,10,15,20,25,30][index];
                                      },
                                      children: [3,5,7,10,15,20,25,30]
                                          .map((s) => Center(
                                                child: Text(
                                                  '${s}s',
                                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        setState(() => settings.timeLimit = result ?? temp);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${settings.timeLimit}s',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontSize: 16, color: Theme.of(context).colorScheme.primary) ??
                                TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ListTile(
                  title: Text(
                    S.of(context)!.numberOfQuestions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  trailing: GestureDetector(
                    onTap: () async {
                      int temp = settings.questionCount;
                      final result = await showModalBottomSheet<int>(
                        context: context,
                        builder: (ctx2) {
                          return CupertinoSheetContainer(
                            height: 250,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                     S.of(context)!.setQuestionCountTitle,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: FixedExtentScrollController(
                                      initialItem: temp - 4,
                                    ),
                                    itemExtent: 32,
                                    onSelectedItemChanged: (index) {
                                      temp = index + 4;
                                    },
                                    children: List<Widget>.generate(
                                      17,
                                      (i) => Center(
                                        child: Text(
                                          '${i + 4}',
                                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      setState(() => settings.questionCount = result ?? temp);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${settings.questionCount}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 16, color: Theme.of(context).colorScheme.primary) ??
                              TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  S.of(context)!.cancel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, settings),
                child: Text(
                  S.of(context)!.ok,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}