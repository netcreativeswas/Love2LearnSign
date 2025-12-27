import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'video_viewer_page.dart';
import 'l10n/dynamic_l10n.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:provider/provider.dart';
import 'services/favorites_repository.dart';
import 'package:l2l_shared/auth/auth_provider.dart';

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
  String _sortBy = 'english';
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
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
            stream: FirebaseFirestore.instance.collection('bangla_dictionary_eng_bnsl').snapshots(),
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
                        _sortBy = _sortBy == 'english' ? 'bengali' : 'english';
                      }),
                      child: Text(
                        _sortBy == 'bengali' ? S.of(context)!.bengali : S.of(context)!.english,
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
          stream: FirebaseFirestore.instance
              .collection('bangla_dictionary_eng_bnsl')
              .where('category', isEqualTo: selectedCategory)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            
            // Get user roles for filtering restricted content
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final userRoles = authProvider.userRoles;
            
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
              
              return !userRoles.contains(restrictedRole);
            }
            
            final seen = <String>{};
            final filtered = docs.where((doc) {
              // Filter out restricted videos if user doesn't have required role
              if (shouldFilterVideo(doc)) {
                return false;
              }
              
              final data = doc.data()! as Map<String, dynamic>;
              final word = data['english'] ?? '';
              if (seen.contains(word)) return false;
              seen.add(word);
              return true;
            }).toList();
            filtered.sort((a, b) {
              final d1 = a.data()! as Map<String, dynamic>;
              final d2 = b.data()! as Map<String, dynamic>;
              final field = _sortBy == 'bengali' ? 'bengali' : 'english';
              return _ascending
                  ? (d1[field] as String).compareTo(d2[field] as String)
                  : (d2[field] as String).compareTo(d1[field] as String);
            });
            // Build a flat list of widgets
            final List<Widget> items = [];
            final Map<String, List<QueryDocumentSnapshot>> grouped = {};
            final isBn = _sortBy == 'bengali';
            for (var doc in filtered) {
              final data = doc.data()! as Map<String, dynamic>;
              final word = isBn ? data['bengali'] : data['english'];
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
                items.add(ListTile(
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: isBn
                              ? (doc.data()! as Map<String, dynamic>)['bengali']
                              : (doc.data()! as Map<String, dynamic>)['english'],
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '   •   '),
                        TextSpan(
                          text: isBn
                              ? (doc.data()! as Map<String, dynamic>)['english']
                              : (doc.data()! as Map<String, dynamic>)['bengali'],
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
                          final data = doc.data() as Map<String, dynamic>;
                          final wordId = doc.id;
                          final english = data['english'] ?? '';
                          final bengali = data['bengali'] ?? '';
                          String? videoUrl;
                          if (data['variants'] != null &&
                              data['variants'] is List &&
                              (data['variants'] as List).isNotEmpty &&
                              (data['variants'] as List).first is Map &&
                              ((data['variants'] as List).first as Map).containsKey('videoUrl')) {
                            videoUrl = ((data['variants'] as List).first as Map)['videoUrl'] as String?;
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
            .map((variant) => variant['videoUrl'])
            .whereType<String>();
      } else if (word['videoUrl'] != null) {
        return [word['videoUrl'] as String];
      }
      return const <String>[];
    }).toSet();

    for (final url in videoUrls) {
      await CacheService.instance.getSingleFileRespectingSettings(url);
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