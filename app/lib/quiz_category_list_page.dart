import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'quiz_page.dart'; // Use unified quiz page
import 'l10n/dynamic_l10n.dart';
import 'l10n/dynamic_l10n.dart';
import 'tenancy/tenant_scope.dart';
import 'package:provider/provider.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;

class QuizCategoryListPage extends StatelessWidget {
  final bool reviewedMode;
  final bool speedMode;
  final int questionCount;
  final int timeLimit;
  final bool useMainCategoriesOnly;

  const QuizCategoryListPage({
    super.key,
    this.reviewedMode = false,
    this.speedMode = false,
    this.questionCount = 10,
    this.timeLimit = 10,
    this.useMainCategoriesOnly = true,
  });

  Future<Map<String, int>> fetchCategories({required String tenantId}) async {
    final snapshot = await TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId).get();
    final Map<String, int> categoryCount = {};

    for (final doc in snapshot.docs) {
      final category = (doc['category_main'] as String?)?.trim();
      final key = (category == null || category.isEmpty) ? 'Uncategorized' : category;
      categoryCount[key] = (categoryCount[key] ?? 0) + 1;
    }

    return categoryCount;
  }

  String _localizedCount(BuildContext context, int count) {
    final locale = Localizations.localeOf(context).languageCode;
    final digits = count.toString();
    if (locale != 'bn') return digits;
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return digits.split('').map((ch) {
      final i = en.indexOf(ch);
      return i >= 0 ? bn[i] : ch;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = context.watch<TenantScope>().tenantId;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context)!.chooseCategory,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.normal
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: fetchCategories(tenantId: tenantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${S.of(context)!.errorPrefix}: ${snapshot.error}',
              ),
            );
          }

          final categoryMap = snapshot.data ?? {};
          var categories = categoryMap.keys.toList()..sort();
          // Filter out restricted JW categories if user lacks 'jw' role
          final userRoles = context.read<app_auth.AuthProvider>().userRoles;
          final hasJW = userRoles.contains('jw');
          if (!hasJW) {
            final restricted = {
              'JW Organisation',
              'JW Organization',
              'Biblical Content',
            };
            categories = categories.where((c) => !restricted.contains(c)).toList();
          }
          if (categories.isEmpty) {
            return Center(
              child: Text(S.of(context)!.noCategories),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context)!.infoMinimumCategories,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length + 1, // +1 for "Random (all categories)"
                  itemBuilder: (context, index) {
                    // First item is "Random (all categories)"
                    if (index == 0) {
                      return ListTile(
                        leading: Icon(Icons.shuffle, color: Theme.of(context).colorScheme.primary),
                        title: Text(
                          S.of(context)!.randomAllCategories,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          S.of(context)!.wordsFromEntireDatabase,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Icon(Icons.arrow_forward, color: Theme.of(context).iconTheme.color),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizPage(
                                reviewedMode: reviewedMode,
                                speedMode: speedMode,
                                questionCount: questionCount,
                                timeLimit: timeLimit,
                                useMainCategoriesOnly: useMainCategoriesOnly,
                                category: null, // null = random mode
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // Rest are categories (adjust index)
                    final categoryIndex = index - 1;
                    final category = categories[categoryIndex];
                    final count = categoryMap[category] ?? 0;
                    final isEnabled = count >= 4;

                    return Opacity(
                      opacity: isEnabled ? 1.0 : 0.6,
                      child: ListTile(
                        title: Text(
                           '${translateCategory(context, category)} (${_localizedCount(context, count)})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        trailing: isEnabled
                            ? Icon(Icons.arrow_forward, color: Theme.of(context).iconTheme.color)
                            : Icon(Icons.lock_outline, color: Theme.of(context).iconTheme.color),
                        onTap: () {
                          if (isEnabled) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizPage(
                                  category: category, // specific category
                                  reviewedMode: reviewedMode,
                                  speedMode: speedMode,
                                  questionCount: questionCount,
                                  timeLimit: timeLimit,
                                  useMainCategoriesOnly: useMainCategoriesOnly,
                                ),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                contentPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                                content: Text(
                                   S.of(context)!.infoMinimumCategories,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
                                ),
                                actionsPadding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text(S.of(ctx)!.ok),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
