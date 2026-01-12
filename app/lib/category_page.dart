import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:l2l_shared/tenancy/concept_text.dart';
import 'package:l2l_shared/tenancy/concept_media.dart';
import 'services/cache_service.dart';
import 'services/prefetch_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'video_viewer_page.dart';
import 'l10n/dynamic_l10n.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:provider/provider.dart';
import 'tenancy/tenant_scope.dart';
import 'tenancy/tenant_member_access_provider.dart';
import 'services/favorites_repository.dart';

// disable overscroll glow/stretch to avoid setState during layout errors
class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    super.key,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  String? selectedCategory;
  String _sortLang = 'en';
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final tenantScope = context.watch<TenantScope>();
    final tenantId = tenantScope.tenantId;
    final localLang = tenantScope.contentLocale.trim().toLowerCase();
    return ScrollConfiguration(
      behavior: _NoGlowBehavior(),
      child: NestedScrollView(
      headerSliverBuilder: (context, innerScrolled) => [
        // Top padding sliver
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 20),
        ),
        // Category grid sliver replaced with StreamBuilder
        SliverToBoxAdapter(
          child: StreamBuilder<QuerySnapshot>(
            stream: TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // Extract distinct non-empty categories
              final cats = snapshot.data!.docs
                  .map((d) => (d.data() as Map<String, dynamic>)['category']?.toString().trim() ?? '')
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList();
              cats.sort((a, b) => _ascending ? a.compareTo(b) : b.compareTo(a));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio:  (1) / 0.4, // adjust height ratio as needed
                  ),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    final category = cats[index];
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategory == category
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                           disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                          foregroundColor: selectedCategory == category
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedCategory = selectedCategory == category ? null : category;
                          });
                        },
                        child: Text(
                          translateCategory(context, category),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // Fixed sort header if a category is selected
        if (selectedCategory != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SortHeaderDelegate(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (localLang.isEmpty || localLang == 'en') {
                          _sortLang = 'en';
                        } else {
                          _sortLang = _sortLang == 'en' ? localLang : 'en';
                        }
                      }),
                      child: Text(
                        _sortLang == 'en'
                            ? S.of(context)!.english
                            : (localLang == 'bn' ? S.of(context)!.bengali : localLang.toUpperCase()),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                       IconButton(
                      icon: Icon(
                        _ascending
                            ? Icons.vertical_align_top
                            : Icons.vertical_align_bottom,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _ascending = !_ascending),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
      body: Builder(builder: (ctx) {
        if (selectedCategory == null) {
          return Center(
            child: Text(
              S.of(ctx)!.selectCategory,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          );
        }
        return StreamBuilder<QuerySnapshot>(
          stream: TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
              .where('category', isEqualTo: selectedCategory)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            
            // Tenant-scoped access for filtering restricted content (e.g. JW).
            final hasJw = context.watch<TenantMemberAccessProvider>().isJw;
            
            // Helper function to check if a video should be filtered
            bool shouldFilterVideo(QueryDocumentSnapshot doc) {
              final data = doc.data() as Map<String, dynamic>;
              final categoryMain = (data['category_main'] ?? '').toString().trim();
              
              final restrictedCategories = {
                'JW Organisation': 'jw',
                'Biblical Content': 'jw',
              };
              
              final restrictedRole = restrictedCategories[categoryMain];
              if (restrictedRole == null) return false;
              
              if (restrictedRole == 'jw') return !hasJw;
              return false;
            }
            
            final seen = <String>{};
            final filtered = docs.where((doc) {
              // Filter out restricted videos if user doesn't have required role
              if (shouldFilterVideo(doc)) {
                return false;
              }
              
              if (seen.contains(doc.id)) return false;
              seen.add(doc.id);
              return true;
            }).toList();
            filtered.sort((a, b) {
              final d1 = a.data()! as Map<String, dynamic>;
              final d2 = b.data()! as Map<String, dynamic>;
              final v1 = ConceptText.labelFor(d1, lang: _sortLang, fallbackLang: 'en');
              final v2 = ConceptText.labelFor(d2, lang: _sortLang, fallbackLang: 'en');
              return _ascending ? v1.compareTo(v2) : v2.compareTo(v1);
            });
            // Build a flat list of widgets
            final List<Widget> items = [];
            final Map<String, List<QueryDocumentSnapshot>> grouped = {};
            final primaryLang = _sortLang;
            final secondaryLang = (_sortLang == 'en') ? localLang : 'en';
            for (var doc in filtered) {
              final data = doc.data()! as Map<String, dynamic>;
              final word = ConceptText.labelFor(data, lang: primaryLang, fallbackLang: 'en');
              final letter = word.isNotEmpty ? word[0].toUpperCase() : '';
              grouped.putIfAbsent(letter, () => []).add(doc);
            }
            final letters = grouped.keys.toList()
              ..sort((a, b) => _ascending ? a.compareTo(b) : b.compareTo(a));
            for (var letter in letters) {
              items.add(Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(letter, style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
              ));
              for (var doc in grouped[letter]!) {
                final data = doc.data()! as Map<String, dynamic>;
                final primary = ConceptText.labelFor(data, lang: primaryLang, fallbackLang: 'en');
                final secondary = ConceptText.labelFor(data, lang: secondaryLang, fallbackLang: 'en');
                final hasSecondary = secondary.trim().isNotEmpty && secondary.trim() != primary.trim();
                items.add(ListTile(
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: hasSecondary
                          ? [
                        TextSpan(
                                text: primary,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '   •   '),
                              TextSpan(text: secondary),
                            ]
                          : [
                        TextSpan(
                                text: primary,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play and favorite buttons
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () async {
                          final wordId = doc.id;
                          String? videoUrl;
                          if (data['variants'] != null &&
                              data['variants'] is List &&
                              (data['variants'] as List).isNotEmpty &&
                              (data['variants'] as List).first is Map &&
                              (((data['variants'] as List).first as Map).containsKey('videos_480') ||
                                  ((data['variants'] as List).first as Map).containsKey('videoUrl'))) {
                            videoUrl = ConceptMedia.video480FromVariant(
                              Map<String, dynamic>.from((data['variants'] as List).first as Map),
                            );
                          } else if (data['videoUrl'] != null) {
                            videoUrl = data['videoUrl'] as String?;
                          }
                          if (videoUrl != null) {
                            // Preload respecting user settings (Wi‑Fi only, etc.)
                            CacheService.instance.getSingleFileRespectingSettings(videoUrl);
                          }
                          Future.microtask(() {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoViewerPage(
                                  wordId: wordId,
                                  videoUrl: videoUrl,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                       Consumer<FavoritesRepository>(
                         builder: (context, repo, _) => IconButton(
                           icon: Icon(
                             repo.contains(doc.id)
                                 ? Icons.favorite
                                 : Icons.favorite_border,
                             color: Theme.of(context).colorScheme.primary,
                           ),
                           onPressed: () => repo.toggle(doc.id),
                         ),
                       ),
                    ],
                  ),
                ));
              }
            }
            return ListView(
              children: items,
            );
          },
        );
      }),
      ),
    );
  }
}
  Future<void> _precacheCategoryVideos(List<QueryDocumentSnapshot> docs) async {
    final prefs = await SharedPreferences.getInstance();

    final precacheEnabled = prefs.getBool('precacheEnabled') ?? true;
    final wifiOnly = prefs.getBool('wifiOnly') ?? false;

    if (!precacheEnabled) return;

    if (wifiOnly) {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) return;
    }

    final words = docs.map((d) => d.data() as Map<String, dynamic>).toList();
    final videoUrls = words.expand<String>((word) {
      if (word['variants'] != null && word['variants'] is List) {
        return (word['variants'] as List)
            .map((variant) => variant is Map
                ? ConceptMedia.video480FromVariant(Map<String, dynamic>.from(variant))
                : '')
            .where((u) => u.isNotEmpty);
      } else if (word['videoUrl'] != null) {
        return [word['videoUrl'] as String];
      }
      return const <String>[];
    }).toSet();

    for (final url in videoUrls) {
      PrefetchQueue.instance.enqueue(url);
    }
  }
class _SortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SortHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => child is PreferredSizeWidget
      ? (child as PreferredSizeWidget).preferredSize.height
      : kToolbarHeight;
  @override
  double get minExtent => maxExtent;
  @override
  bool shouldRebuild(covariant _SortHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}