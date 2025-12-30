import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'quiz_settings.dart';
import 'quiz_page.dart'; // Unified quiz page
import 'l10n/dynamic_l10n.dart';
import 'theme.dart';
import 'services/ad_service.dart';
import 'services/premium_service.dart';
import 'services/session_counter_service.dart';
import 'pages/premium_settings_page.dart';
import 'flashcard_settings.dart';
import 'flashcard_page.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/main_btm_nav_bar.dart';
import 'widgets/main_drawer.dart';
import 'dictionary_page.dart';
import 'home_page.dart';
import 'widgets/review_sessions_row.dart';
import 'services/spaced_repetition_service.dart';
import 'package:provider/provider.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;
import 'package:audioplayers/audioplayers.dart';
import 'tenancy/tenant_scope.dart';

class GameMasterPage extends StatefulWidget {
  final String? countryCode;
  final bool showQuizOptionsOnStart;

  const GameMasterPage({
    super.key,
    this.countryCode,
    this.showQuizOptionsOnStart = false,
  });

  @override
  State<GameMasterPage> createState() => _GameMasterPageState();
}

class _GameMasterPageState extends State<GameMasterPage>
    with WidgetsBindingObserver {
  final AudioPlayer _tokenSoundPlayer = AudioPlayer();
  bool _showFlashcardOptions = false;
  bool _showQuizOptions = false;
  bool _gmReviewSortByVolume = false;
  DateTime? _lastDay;

  String _localizeEnBn(BuildContext context, String en, String bn) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'bn' ? bn : en;
  }

  String _localizedCount(BuildContext context, int value) {
    final locale = Localizations.localeOf(context).languageCode;
    final digits = value.toString();
    if (locale != 'bn') return digits;
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return digits.split('').map((ch) {
      final i = en.indexOf(ch);
      return i >= 0 ? bn[i] : ch;
    }).join();
  }

  Widget _buildSessionBadge(
      BuildContext context, int tokens, int maxTokens) {
    final isZero = tokens == 0;
    final theme = Theme.of(context);
    final label = S.of(context)!.freeSessions(
      tokens,
      maxTokens,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isZero
            ? theme.colorScheme.error.withOpacity(0.1)
            : theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isZero
              ? theme.colorScheme.error.withOpacity(0.5)
              : theme.colorScheme.secondary.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isZero ? Icons.lock_clock : Icons.check_circle_outline,
            size: 16,
            color: isZero
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isZero
                  ? theme.colorScheme.error
                  : theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Common button used when the user has 0 free sessions and can watch an ad
  /// to restore 3 tokens/sessions.
  Widget _buildWatchAdRestoreButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.play_circle_fill),
          label: Text(
            S.of(context)?.watchAdRestoreTokensButton ??
                'Watch Ad to add 3 tokens',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Future<void> _handleQuizStart(BuildContext context, String? category) async {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final tenantId = context.read<TenantScope>().tenantId;
    final isPrivileged =
        authProvider.hasRole('admin') || await PremiumService().isPremiumForTenant(tenantId);

    if (!isPrivileged) {
      final status = await SessionCounterService().checkQuizSession();
      if (!status.canStart) {
        if (!mounted) return;
        _showQuizRewardedAdDialog(context, category);
        return;
      }
    }

    if (!mounted) return;
    final result = await showQuizSettings(context);
    if (result == null) {
      return;
    }

    if (!isPrivileged) {
      final recorded = await SessionCounterService().recordQuizSession();
      if (!recorded) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.monthlyLimitReached ?? 'Monthly Limit Reached',
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(
          reviewedMode: result.reviewedMode,
          speedMode: result.speedMode,
          questionCount: result.questionCount,
          timeLimit: result.timeLimit,
          useMainCategoriesOnly: true,
          category: category,
        ),
      ),
    );
  }

  Future<void> _showQuizRewardedAdDialog(
      BuildContext context, String? category) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title:
            Text(S.of(context)?.monthlyLimitReached ?? 'Monthly Limit Reached'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.of(context)?.quizLimitReachedMessage ??
                'You have used your 2 free quiz sessions for this month.'),
            const SizedBox(height: 10),
            Text(S.of(context)?.watchAd ??
                'Watch an ad to unlock 3 more sessions, or go Premium for unlimited access!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(context)?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Show Rewarded Ad
              AdService().showRewardedAd(
                onRewardEarned: () async {
                  // Unlock 3 sessions
                  await SessionCounterService().unlockQuizSessions();
                  if (!mounted) return;
                  // Jouer le son de récompense
                  _tokenSoundPlayer.play(AssetSource('sounds/get-token.mp3'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(S.of(context)?.quizSessionsUnlocked ??
                            '3 Quiz sessions unlocked!')),
                  );
                  // Start the game immediately
                  _handleQuizStart(context, category);
                },
                onError: (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                },
              );
            },
            child: Text(S.of(context)?.watchAd ?? 'Watch Ad'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuizWatchAdRestore(BuildContext context) async {
    AdService().showRewardedAd(
      onRewardEarned: () async {
        await SessionCounterService().unlockQuizSessions();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.quizSessionsUnlocked ??
                  '3 Quiz sessions unlocked!',
            ),
          ),
        );
        // Refresh UI (FutureBuilders) to reflect new remaining sessions
        setState(() {});
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  Future<void> _handleFlashcardGameStart(BuildContext context) async {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final tenantId = context.read<TenantScope>().tenantId;
    final isPrivileged =
        authProvider.hasRole('admin') || await PremiumService().isPremiumForTenant(tenantId);

    if (!isPrivileged) {
      final status = await SessionCounterService().checkFlashcardSession();
      if (!status.canStart) {
        if (!mounted) return;
        _showFlashcardRewardedAdDialog(context);
        return;
      }
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FlashcardSettingsPage(),
    );
    if (result == null) {
      return;
    }

    if (!isPrivileged) {
      final recorded = await SessionCounterService().recordFlashcardSession();
      if (!recorded) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.monthlyLimitReached ?? 'Monthly Limit Reached',
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardPage(
          numCards: result['numCards'] as int,
          contentChoice: result['contentChoice'] as String,
          startingPoint: result['startingPoint'] as bool,
        ),
      ),
    );
  }

  Future<void> _showFlashcardRewardedAdDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(S.of(context)?.monthlyLimitReached ?? 'Monthly Limit Reached'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.of(context)?.flashcardLimitReachedMessage ??
                'You have used your 2 free flashcard sessions for this month.'),
            const SizedBox(height: 10),
            Text(S.of(context)?.watchAd ??
                'Watch an ad to unlock 3 more sessions!'),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PremiumSettingsPage()),
                );
              },
              child:
                  Text(S.of(context)?.upgradeToPremium ?? 'Upgrade to Premium'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(context)?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AdService().showRewardedAd(
                onRewardEarned: () async {
                  await SessionCounterService().unlockFlashcardSessions();
                  if (!mounted) return;
                  // Jouer le son de récompense
                  _tokenSoundPlayer.play(AssetSource('sounds/get-token.mp3'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            S.of(context)?.flashcardSessionsUnlocked ??
                                '3 Flashcard sessions unlocked!')),
                  );
                  _handleFlashcardGameStart(context);
                },
                onError: (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                },
              );
            },
            child: Text(S.of(context)?.watchAd ?? 'Watch Ad'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFlashcardWatchAdRestore(BuildContext context) async {
    AdService().showRewardedAd(
      onRewardEarned: () async {
        await SessionCounterService().unlockFlashcardSessions();
        if (!mounted) return;
        // Jouer le son de récompense
        _tokenSoundPlayer.play(AssetSource('sounds/get-token.mp3'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context)?.flashcardSessionsUnlocked ??
                  '3 Flashcard sessions unlocked!',
            ),
          ),
        );
        // Refresh UI (FutureBuilders) to reflect new remaining sessions
        setState(() {});
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  void _navigateWithoutTransition(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _buildQuizContentWithoutGestureDetector() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, left: 0, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎯 ${S.of(context)?.chooseQuizCategory ?? 'Choose Quiz Category'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                iconSize: 18,
                padding: EdgeInsets.zero,
                tooltip: _localizeEnBn(context, 'Info', 'তথ্য'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(S.of(context)?.chooseQuizCategory ??
                            'Choose Quiz Category'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.of(context)?.quizCategoriesInfo ??
                                'Categories must have at least 4 words to be playable.'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(S.of(context)?.ok ?? 'OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Consumer<app_auth.AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.hasRole('admin')) {
                    return const SizedBox(height: 8);
                  }

                  final tenantId = context.watch<TenantScope>().tenantId;
                  return FutureBuilder<bool>(
                    future: PremiumService().isPremiumForTenant(tenantId),
                    builder: (context, premiumSnap) {
                      final isPremium = premiumSnap.data == true;
                      if (isPremium) return const SizedBox(height: 8);

                      return FutureBuilder<
                          ({
                            bool canStart,
                            int tokens,
                            int maxTokens,
                          })>(
                        future: SessionCounterService().checkQuizSession(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(height: 8);
                          }
                          final data = snapshot.data!;
                          final tokens = data.tokens;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSessionBadge(
                                context,
                                tokens,
                                data.maxTokens,
                              ),
                              if (tokens <=
                                  data.maxTokens -
                                      SessionCounterService.rewardBundleSize) ...[
                                const SizedBox(height: 4),
                                _buildWatchAdRestoreButton(
                                  context: context,
                                  onPressed: () =>
                                      _handleQuizWatchAdRestore(context),
                                ),
                              ],
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              // "Random (all categories)" option
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextButton(
                  onPressed: () async {
                    await _handleQuizStart(context, null);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context)?.randomAllCategories ??
                                  'Random (all categories)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 2.5,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final textPainter = TextPainter(
                                    text: TextSpan(
                                      text:
                                          S.of(context)?.randomAllCategories ??
                                              'Random (all categories)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    textDirection: ui.TextDirection.ltr,
                                  )..layout();
                                  return SizedBox(
                                    width: textPainter.width,
                                    height: 2.5,
                                    child: Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Categories list
              FutureBuilder<Map<String, int>>(
                future: _fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${S.of(context)?.errorPrefix ?? 'Error'}: ${snapshot.error}',
                      ),
                    );
                  }

                  final categoryMap = snapshot.data ?? {};
                  var categories = categoryMap.keys.toList()..sort();
                  // JW filtering for selectors if user lacks 'jw' role
                  try {
                    final roles =
                        context.read<app_auth.AuthProvider>().userRoles;
                    if (!roles.contains('jw')) {
                      final restricted = {
                        'JW Organisation',
                        'JW Organization',
                        'Biblical Content',
                      };
                      categories = categories
                          .where((c) => !restricted.contains(c))
                          .toList();
                    }
                  } catch (_) {}

                  if (categories.isEmpty) {
                    return Center(
                      child: Text(S.of(context)?.noCategories ??
                          'No categories available'),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final count = categoryMap[category] ?? 0;
                          final isEnabled = count >= 4;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: Opacity(
                                opacity: isEnabled ? 1.0 : 0.7,
                                child: TextButton(
                                  onPressed: () async {
                                    if (!isEnabled) {
                                      await showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  16.0, 16.0, 16.0, 8.0),
                                          content: Text(
                                            S
                                                    .of(context)
                                                    ?.infoMinimumCategories ??
                                                'Categories must have at least 4 words',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(fontSize: 18),
                                          ),
                                          actionsPadding: const EdgeInsets.only(
                                              bottom: 8.0,
                                              left: 16.0,
                                              right: 16.0),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: Text(
                                                  S.of(context)?.ok ?? 'OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    await _handleQuizStart(context, category);
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final String labelText =
                                                '${translateCategory(context, category)} (${_localizedCount(context, count)})';
                                            final TextStyle? labelStyle =
                                                Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    );
                                            // Measure the label width to size the underline exactly to the text
                                            final tp = TextPainter(
                                              text: TextSpan(
                                                  text: labelText,
                                                  style: labelStyle),
                                              textDirection:
                                                  ui.TextDirection.ltr,
                                            )..layout();

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(labelText,
                                                    style: labelStyle),
                                                if (isEnabled) ...[
                                                  const SizedBox(height: 4),
                                                  SizedBox(
                                                    width: tp.width,
                                                    height: 2.5,
                                                    child: Container(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      Icon(
                                        isEnabled
                                            ? Icons.arrow_forward
                                            : Icons.lock,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<Map<String, int>> _fetchCategories() async {
    final tenantId = context.read<TenantScope>().tenantId;
    final snapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId).get();
    final Map<String, int> categoryCount = {};

    for (final doc in snapshot.docs) {
      final category = (doc['category_main'] as String?)?.trim();
      // Localize the placeholder label for empty categories right here for this page
      final key = (category == null || category.isEmpty)
          ? _localizeEnBn(context, 'Uncategorized', 'অন্যান্য')
          : category;
      categoryCount[key] = (categoryCount[key] ?? 0) + 1;
    }

    return categoryCount;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showQuizOptions = widget.showQuizOptionsOnStart;
    if (_showQuizOptions) {
      _showFlashcardOptions = false;
    }
    _lastDay = DateTime.now();
    // Précharger le son de récompense pour éviter le retard
    _preloadTokenSound();
  }

  Future<void> _preloadTokenSound() async {
    try {
      // Configurer pour latence minimale et volume à 1.0
      await _tokenSoundPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _tokenSoundPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint('Error preloading token sound: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenSoundPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastDay == null ||
          now.year != _lastDay!.year ||
          now.month != _lastDay!.month ||
          now.day != _lastDay!.day) {
        setState(() {}); // triggers FutureBuilder to refetch
      }
      _lastDay = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        // Replace with real user role logic if available
        final String userRole = 'editor'; // Placeholder, replace as needed
        final locale = Localizations.localeOf(context);
        final isLoggedIn = snapshot.hasData;
        return Scaffold(
          endDrawer: MainDrawerWidget(
            countryCode: widget.countryCode ?? '',
            checkedLocation: true,
            isLoggedIn: isLoggedIn,
            userRole: userRole,
            deviceLanguageCode: locale.languageCode,
            deviceRegionCode: locale.countryCode,
          ),
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              children: [
                // Container A: AppBar + 3 buttons
                GestureDetector(
                  onTap: () {
                    // Clic à l'extérieur des boutons ramène au Container B vide
                    if (_showFlashcardOptions) {
                      setState(() {
                        _showFlashcardOptions = false;
                      });
                    }
                    if (_showQuizOptions) {
                      setState(() {
                        _showQuizOptions = false;
                      });
                    }
                  },
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SafeArea(
                          top: true,
                          bottom: false,
                          child: SizedBox(
                            height: 56,
                            child: MainAppBar(
                              title: S.of(context)?.tabGame ?? 'Game',
                              countryCode: widget.countryCode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 140,
                              child: _buildGameButton(
                                context,
                                IconlyLight.category,
                                S.of(context)?.quizGame ?? 'Quiz',
                                () {
                                  // Show quiz options in Container B
                                  setState(() {
                                    _showQuizOptions = true;
                                    _showFlashcardOptions =
                                        false; // Hide flashcard options
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: _buildGameButton(
                                context,
                                IconlyLight.paper,
                                S.of(context)?.flashcardGame ??
                                    'Flashcard Game',
                                () {
                                  // Show flashcard options in Container B
                                  setState(() {
                                    _showFlashcardOptions = true;
                                    _showQuizOptions =
                                        false; // Hide quiz options
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Container B: content + bottom nav
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        // Scrollable content area
                        Expanded(
                          child: _showQuizOptions
                              ? Column(
                                  children: [
                                    // Zone cliquable au-dessus pour fermer
                                    GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        setState(() {
                                          _showQuizOptions = false;
                                        });
                                      },
                                      child: const SizedBox(height: 8),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child:
                                            _buildQuizContentWithoutGestureDetector(),
                                      ),
                                    ),
                                  ],
                                )
                              : _showFlashcardOptions
                                  ? SingleChildScrollView(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        children: [
                                          // Zone cliquable au-dessus pour fermer
                                          GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onTap: () {
                                              setState(() {
                                                _showFlashcardOptions = false;
                                              });
                                            },
                                            child: const SizedBox(height: 8),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(
                                                top: 12, left: 0, right: 10),
                                            child: Text(
                                              '🎯 ${S.of(context)?.flashcardOptions ?? 'Flashcard Options'}',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            child: Column(
                                              children: [
                                                Consumer<app_auth.AuthProvider>(
                                                  builder: (context,
                                                      authProvider, _) {
                                                    final isPrivileged =
                                                        authProvider.hasRole(
                                                                'admin') ||
                                                            authProvider
                                                                .hasRole(
                                                                    'paidUser');
                                                    if (isPrivileged) {
                                                      return const SizedBox(
                                                          height: 8);
                                                    }
                                                    return FutureBuilder<
                                                        ({
                                                          bool canStart,
                                                          int tokens,
                                                          int maxTokens
                                                        })>(
                                                      future:
                                                          SessionCounterService()
                                                              .checkFlashcardSession(),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (!snapshot.hasData) {
                                                          return const SizedBox(
                                                              height: 8);
                                                        }
                                                        final data =
                                                            snapshot.data!;
                                                        final tokens =
                                                            data.tokens;

                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            _buildSessionBadge(
                                                                context,
                                                                tokens,
                                                                data.maxTokens),
                                                            if (tokens <=
                                                                data.maxTokens -
                                                                    SessionCounterService
                                                                        .rewardBundleSize) ...[
                                                              const SizedBox(
                                                                  height: 4),
                                                              _buildWatchAdRestoreButton(
                                                                context:
                                                                    context,
                                                                onPressed: () =>
                                                                    _handleFlashcardWatchAdRestore(
                                                                        context),
                                                              ),
                                                            ],
                                                            const SizedBox(
                                                                height: 8),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                                // Bouton "Nouveau jeu de Flashcard" (restylé)
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      1,
                                                  height: 60,
                                                  child: TextButton(
                                                    onPressed: () async {
                                                      await _handleFlashcardGameStart(
                                                          context);
                                                    },
                                                    style: TextButton.styleFrom(
                                                      backgroundColor: Theme.of(
                                                              context)
                                                          .colorScheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                              alpha: 0.4),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 14,
                                                          horizontal: 18),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                S
                                                                        .of(context)
                                                                        ?.newFlashcardGame ??
                                                                    'New Flashcard Game',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .onSurfaceVariant,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              SizedBox(
                                                                height: 2.5,
                                                                child:
                                                                    LayoutBuilder(
                                                                  builder: (context,
                                                                      constraints) {
                                                                    final textPainter =
                                                                        TextPainter(
                                                                      text:
                                                                          TextSpan(
                                                                        text: S.of(context)?.newFlashcardGame ??
                                                                            'New Flashcard Game',
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .titleMedium
                                                                            ?.copyWith(
                                                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                      ),
                                                                      textDirection: ui
                                                                          .TextDirection
                                                                          .ltr,
                                                                    )..layout();
                                                                    return SizedBox(
                                                                      width: textPainter
                                                                          .width,
                                                                      height:
                                                                          2.5,
                                                                      child:
                                                                          Container(
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .secondary,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.arrow_forward,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                FutureBuilder<
                                                    Map<DateTime,
                                                        List<String>>>(
                                                  future:
                                                      SpacedRepetitionService()
                                                          .getWordsGroupedByDay(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }
                                                    final gmMap =
                                                        snapshot.data ?? {};
                                                    if (gmMap.isEmpty) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }
                                                    return ReviewSessionsRow(
                                                      reviewBoxWordsByDay:
                                                          gmMap,
                                                      reviewSortByVolume:
                                                          _gmReviewSortByVolume,
                                                      onToggleSort:
                                                          (bool value) async {
                                                        setState(() {
                                                          _gmReviewSortByVolume =
                                                              value;
                                                        });
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    )
                                  : Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            top: 30, left: 20, right: 20),
                                        child: Text(
                                          S.of(context)?.chooseGame ??
                                              'Choose Game',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(fontSize: 16),
                                        ),
                                      ),
                                    ),
                        ),
                        // Bottom navigation
                        SafeArea(
                          top: false,
                          bottom: true,
                          child: MainBtmNavBar(
                            currentIndex: 2,
                            onTabSelected: (int index) {
                              if (index == 0) {
                                _navigateWithoutTransition(
                                  context,
                                  HomePage(
                                    countryCode: widget.countryCode,
                                  ),
                                );
                              } else if (index == 1) {
                                _navigateWithoutTransition(
                                  context,
                                  DictionaryPage(
                                    countryCode: widget.countryCode,
                                  ),
                                );
                              } else if (index == 2) {
                                // stay
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildGameButton(
    BuildContext context, IconData icon, String label, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface2,
          ),
          child: Icon(icon,
              size: 28, color: Theme.of(context).colorScheme.onSurface2),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface2,
              ),
        ),
      ],
    ),
  );
}
