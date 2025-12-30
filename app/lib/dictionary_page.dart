import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'video_viewer_page.dart';
import 'package:love_to_learn_sign/history_page.dart';
import 'widgets/custom_search_bar.dart';
import 'l10n/dynamic_l10n.dart';
import 'l10n/dynamic_l10n.dart';
import 'locale_provider.dart';
import 'tenancy/tenant_scope.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/main_btm_nav_bar.dart';
import 'widgets/main_drawer.dart';
import 'game_master.dart';
import 'services/history_repository.dart';
import 'services/favorites_repository.dart';
import 'services/share_utils.dart';
import 'package:l2l_shared/analytics/search_tracking_service.dart';
import 'dart:async';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'theme.dart';
import 'home_page.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
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
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _SortHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _DictionarySortBar extends StatelessWidget {
  final String sortBy;
  final bool ascending;
  final VoidCallback onSortByToggle;
  final VoidCallback onAscendingToggle;

  const _DictionarySortBar({
    super.key,
    required this.sortBy,
    required this.ascending,
    required this.onSortByToggle,
    required this.onAscendingToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onSortByToggle,
            child: Text(
              sortBy == 'bengali' ? S.of(context)!.bengali : S.of(context)!.english,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              ascending ? Icons.vertical_align_top : Icons.vertical_align_bottom,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            onPressed: onAscendingToggle,
          ),
        ],
      ),
    );
  }
}

class DictionaryPage extends StatefulWidget {
  final String? countryCode;
  const DictionaryPage({
    super.key,
    this.countryCode,
  });

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  String _sortBy = 'english';
  bool _ascending = true;
  final int _currentIndex = 1;
  bool _sortDefaultApplied = false;
  Timer? _debounceTimer;
  String? _lastLoggedQuery;
  // Reset pagination when category/search changes
  final GlobalKey<_DictionaryScrollableSectionState> _scrollableSectionKey = GlobalKey<_DictionaryScrollableSectionState>();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sortDefaultApplied) {
      final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
      _sortBy = locale.languageCode == 'bn' ? 'bengali' : 'english';
      _sortDefaultApplied = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _logSearch(String query, int resultCount, bool found, String? category) {
    if (query.trim().isEmpty) return;
    
    // Don't log if it's the exact same query we just logged
    if (query == _lastLoggedQuery) return;

    final tenantId = context.read<TenantScope>().tenantId;
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(seconds: 2), () {
       if (!mounted) return;
       // Double check inside timer
       if (query == _lastLoggedQuery) return;
       
       SearchTrackingService().logSearch(
         tenantId: tenantId,
         query: query, 
         resultCount: resultCount, 
         found: found,
         category: category,
       );
       _lastLoggedQuery = query;
    });
  }



  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = '';
        _selectedSubCategory = '';
      } else {
        _selectedCategory = category;
      }
      _searchQuery = '';
      _selectedSubCategory = '';
    });
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

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        // HomePage
        _navigateWithoutTransition(
          context,
          HomePage(
            countryCode: widget.countryCode,
          ),
        );
        break;
      case 1:
        // Already on DictionaryPage
        break;
      case 2:
        // GameMasterPage
        _navigateWithoutTransition(
          context,
          GameMasterPage(
            countryCode: widget.countryCode,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).locale;
    final tenantId = context.watch<TenantScope>().tenantId;
    final double topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final initialChildSize = 0.45 - (20 / screenHeight);
    // Remove the following line:
    // final currentUser = FirebaseAuth.instance.currentUser;
    // final String? userRole = 'editor'; // Placeholder, replace with your logic
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isLoggedIn = snapshot.hasData;
        final String userRole = 'editor'; // Placeholder, replace with your logic
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // Removed appBar property so DraggableScrollableSheet can cover entire screen
          endDrawer: MainDrawerWidget(
            countryCode: widget.countryCode ?? '',
            checkedLocation: true,
            isLoggedIn: isLoggedIn,
            userRole: userRole,
            deviceLanguageCode: locale.languageCode,
            deviceRegionCode: locale.countryCode,
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _selectedCategory = '';
                _selectedSubCategory = '';
              });
            },
            child: Stack(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Blue Container A as base layer (top 50%)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: double.infinity,
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Inserted MainAppBar at the top of the blue container
                        MainAppBar(
                          title: S.of(context)!.tabDictionary,
                          countryCode: widget.countryCode,
                          trailing: IconButton(
                            icon: Icon(Icons.history, color: Theme.of(context).colorScheme.onPrimary),
                            tooltip: S.of(context)!.tabHistory,
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                builder: (context) => SafeArea(
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.85,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                                            child: Text(
                                              S.of(context)!.tabHistory,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            height: 2,
                                            color: Theme.of(context).colorScheme.primary,
                                            margin: const EdgeInsets.only(bottom: 12),
                                          ),
                                          Expanded(
                                            child: DefaultTextStyle(
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(color: Theme.of(context).colorScheme.primary),
                                              child: HistoryPage(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                          child: CustomSearchBar(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            hintText: S.of(context)!.searchHint,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            S.of(context)!.selectCategory,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
                              final userRoles = authProvider.userRoles;
                              
                              // Define restricted categories
                              final restrictedCategories = {
                                'JW Organisation': 'jw',
                                'Biblical Content': 'jw',
                              };
                              
                              final allCats = snapshot.data!.docs
                                  .map((d) => (d.data() as Map<String, dynamic>)['category_main']?.toString().trim() ?? '')
                                  .where((c) => c.isNotEmpty)
                                  .toSet()
                                  .toList();
                              
                              // Filter categories based on user roles (multi-role support)
                              final cats = allCats.where((category) {
                                final restrictedRole = restrictedCategories[category];
                                if (restrictedRole == null) return true; // No restriction
                                return userRoles.contains(restrictedRole); // Only show if user has the required role
                              }).toList()
                                ..sort();
                              cats.insert(0, 'All words');

                              // Decide rows dynamically: 2 on medium screens, 3 on larger ones
                              final int columns = 3;
                              final int rows = MediaQuery.of(context).size.height >= 920 ? 3 : 2;
                              final int pageSize = rows * columns;

                              // Helper function to chunk the categories into groups of pageSize
                              List<List<String>> chunkCategories(List<String> cats) {
                                List<List<String>> chunks = [];
                                for (var i = 0; i < cats.length; i += pageSize) {
                                  chunks.add(cats.sublist(i, i + pageSize > cats.length ? cats.length : i + pageSize));
                                }
                                return chunks;
                              }

                              final pages = chunkCategories(cats);
                              // Height accounts for button height (48) + vertical padding (8) per row
                              final double categoriesHeight = rows * (48.0 + 8.0);
                              return SizedBox(
                                height: categoriesHeight,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: pages.length,
                                  itemBuilder: (context, pageIndex) {
                                    final pageCats = pages[pageIndex];
                                    // Fill up to pageSize slots with empty strings if needed
                                    final filledCats = List<String>.from(pageCats);
                                    while (filledCats.length < pageSize) {
                                      filledCats.add('');
                                    }
                                    // rows x columns
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                                      child: Column(
                                        children: List.generate(rows, (row) {
                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: List.generate(columns, (col) {
                                              final idx = row * columns + col;
                                              final category = filledCats[idx];
                                              if (category.isEmpty) {
                                                return Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: SizedBox(
                                                    width: 120,
                                                    height: 48,
                                                  ),
                                                );
                                              }
                                              final selected = _selectedCategory.isNotEmpty &&
                                                  ((category == 'All words' && _selectedCategory == 'All') ||
                                                      category == _selectedCategory);
                                              return Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: SizedBox(
                                                  width: 120,
                                                  height: 48,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: selected
                                                          ? Theme.of(context).colorScheme.secondary
                                                          : Theme.of(context).colorScheme.surface2,
                                                      foregroundColor: selected
                                                          ? Theme.of(context).colorScheme.onSecondary
                                                          : Theme.of(context).colorScheme.onSurface2,
                                                      side: BorderSide(
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                                      minimumSize: const Size(double.infinity, 40),
                                                    ),
                                                    onPressed: () {
                                                      if (category == 'All words') {
                                                        setState(() {
                                                          _selectedCategory = 'All';
                                                          _selectedSubCategory = '';
                                                        });
                                                      } else {
                                                        _onCategorySelected(category);
                                                      }
                                                    },
                                                    child: Text(
                                                      category == 'All words'
                                                          ? S.of(context)!.allWords
                                                          : translateCategory(context, category),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          );
                                        }),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Foreground: DraggableScrollableSheet for white Container B
                DraggableScrollableSheet(
                  initialChildSize: initialChildSize,
                  minChildSize: initialChildSize,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                           color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ScrollConfiguration(
                        behavior: _NoGlowBehavior(),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollUpdateNotification) {
                            final metrics = notification.metrics;
                              // Trigger load more when near bottom (200px threshold)
                            if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                                _scrollableSectionKey.currentState?.loadMore();
                              }
                            }
                            return false;
                          },
                          child: CustomScrollView(
                            controller: scrollController,
                            slivers: [
                            if (_selectedCategory.isNotEmpty && _searchQuery.isEmpty)
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _SortHeaderDelegate(
                                  child: _DictionarySortBar(
                                    sortBy: _sortBy,
                                    ascending: _ascending,
                                    onSortByToggle: () => setState(() {
                                      _sortBy = _sortBy == 'english' ? 'bengali' : 'english';
                                    }),
                                    onAscendingToggle: () => setState(() => _ascending = !_ascending),
                                  ),
                                ),
                              ),
                            if (_selectedCategory.isNotEmpty &&
                                _selectedCategory != 'All' &&
                                _searchQuery.isEmpty)
                              SliverToBoxAdapter(
                                child: Consumer<app_auth.AuthProvider>(
                                  builder: (context, authProvider, _) {
                                    // Check if category is restricted
                                    final restrictedCategories = {
                                      'JW Organisation': 'jw',
                                      'Biblical Content': 'jw',
                                    };
                                    final restrictedRole = restrictedCategories[_selectedCategory];
                                    
                                    if (restrictedRole != null && !authProvider.userRoles.contains(restrictedRole)) {
                                      return Container(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.error),
                                            const SizedBox(height: 16),
                                            Text(
                                              '🔒 Restricted Content',
                                              style: Theme.of(context).textTheme.headlineSmall,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'This category is reserved for JW members only.',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    
                                    return StreamBuilder<QuerySnapshot>(
                                    stream: TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
                                      .where('category_main', isEqualTo: _selectedCategory)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    final subs = snapshot.data!.docs
                                        .map((d) => (d.data() as Map<String, dynamic>)['category_sub']?.toString().trim() ?? '')
                                        .where((s) => s.isNotEmpty)
                                        .toSet()
                                        .toList()
                                      ..sort();
                                    final displaySubs = <String>['All', ...subs];
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                                      child: SizedBox(
                                        height: 34,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: displaySubs.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                                          itemBuilder: (context, index) {
                                            final sub = displaySubs[index];
                                            final selected = (_selectedSubCategory.isEmpty && sub == 'All') || _selectedSubCategory == sub;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (sub == 'All') {
                                                    _selectedSubCategory = '';
                                                  } else {
                                                    if (selected) {
                                                      _selectedSubCategory = '';
                                                    } else {
                                                      _selectedSubCategory = sub;
                                                    }
                                                  }
                                                });
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                height: 30,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? Theme.of(context).colorScheme.surface3
                                                      : Theme.of(context).scaffoldBackgroundColor,
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                                                ),
                                                child: Text(
                                                  sub == 'All' ? S.of(context)!.allWords : translateCategory(context, sub),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: selected
                                                        ? Theme.of(context).colorScheme.onSurface2
                                                        : Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            // List of words (search or category)
                            SliverToBoxAdapter(
                              child: _DictionaryScrollableSection(
                                key: _scrollableSectionKey,
                                  searchQuery: _searchQuery,
                                  selectedCategory: _selectedCategory,
                                  selectedSubCategory: _selectedSubCategory,
                                  sortBy: _sortBy,
                                  ascending: _ascending,
                                  onSortByToggle: () => setState(() {
                                    _sortBy = _sortBy == 'english' ? 'bengali' : 'english';
                                  }),
                                  onAscendingToggle: () => setState(() => _ascending = !_ascending),
                                onSearchCompleted: _logSearch,
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: MainBtmNavBar(
            currentIndex: 1,
            onTabSelected: _onTabSelected,
          ),
        );
      },
    );
  }

}

class _DictionaryScrollableSection extends StatefulWidget {
  final String searchQuery;
  final String selectedCategory;
  final String selectedSubCategory;
  final String sortBy;
  final bool ascending;
  final VoidCallback onSortByToggle;
  final VoidCallback onAscendingToggle;
  final Function(String, int, bool, String?)? onSearchCompleted;

  const _DictionaryScrollableSection({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.sortBy,
    required this.ascending,
    required this.onSortByToggle,
    required this.onAscendingToggle,
    this.onSearchCompleted,
  });

  @override
  State<_DictionaryScrollableSection> createState() => _DictionaryScrollableSectionState();
}

class _DictionaryScrollableSectionState extends State<_DictionaryScrollableSection> {
  static const int _batchSize = 30;
  List<QueryDocumentSnapshot> _loadedDocs = [];
  QueryDocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialBatch());
  }

  @override
  void didUpdateWidget(_DictionaryScrollableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination if category or search changed
    if (oldWidget.selectedCategory != widget.selectedCategory ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.selectedSubCategory != widget.selectedSubCategory ||
        oldWidget.sortBy != widget.sortBy ||
        oldWidget.ascending != widget.ascending) {
      setState(() {
        _loadedDocs.clear();
        _lastDocument = null;
        _hasMore = true;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialBatch());
    }
  }

  Future<void> _loadInitialBatch() async {
    if (_isLoading || !_hasMore) return;
    await _loadMoreDocuments();
  }

  void loadMore() {
    _loadMoreDocuments();
  }

  Future<void> _loadMoreDocuments() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final tenantId = context.read<TenantScope>().tenantId;
      Query query = TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId);
      
      // Apply category filter
      if (widget.selectedCategory.isNotEmpty && widget.selectedCategory != 'All') {
        query = query.where('category_main', isEqualTo: widget.selectedCategory);
      }
      
      // Apply sorting - Firestore requires index for compound queries
      // We'll sort client-side after fetching
      query = query.orderBy(widget.sortBy);
      
      // Pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      query = query.limit(_batchSize);
      
      final snapshot = await query.get();
      
      if (!mounted) return;
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }
      
      // Filter restricted content and sub-categories client-side
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final userRoles = authProvider.userRoles;
      
      final newDocs = snapshot.docs.where((doc) {
        if (_shouldFilterVideo(doc, userRoles)) return false;
        
        if (widget.selectedCategory != 'All' && widget.selectedSubCategory.isNotEmpty) {
          final data = doc.data() as Map<String, dynamic>?;
          final sub = (data?['category_sub'] ?? '').toString();
          if (sub != widget.selectedSubCategory) return false;
        }
        
        return true;
      }).toList();
      
      // Sort the new documents if descending order is needed
      if (!widget.ascending) {
        newDocs.sort((a, b) {
          final d1 = a.data() as Map<String, dynamic>;
          final d2 = b.data() as Map<String, dynamic>;
          final field = widget.sortBy;
          final val1 = (d1[field] ?? '').toString();
          final val2 = (d2[field] ?? '').toString();
          return val2.compareTo(val1); // Reverse order
        });
      }
      
      setState(() {
        _loadedDocs.addAll(newDocs);
        // Sort all loaded docs to maintain correct order
        _loadedDocs.sort((a, b) {
          final d1 = a.data() as Map<String, dynamic>;
          final d2 = b.data() as Map<String, dynamic>;
          final field = widget.sortBy;
          final val1 = (d1[field] ?? '').toString();
          final val2 = (d2[field] ?? '').toString();
          return widget.ascending ? val1.compareTo(val2) : val2.compareTo(val1);
        });
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        _hasMore = snapshot.docs.length == _batchSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading documents: $e');
    }
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    return s.length == 1 ? first : '$first${s.substring(1)}';
  }

  // Helper function to check if a video should be filtered based on restricted categories
  bool _shouldFilterVideo(QueryDocumentSnapshot doc, List<String> userRoles) {
    final data = doc.data() as Map<String, dynamic>;
    final categoryMain = (data['category_main'] ?? '').toString().trim();
    
    // Define restricted categories
    final restrictedCategories = {
      'JW Organisation': 'jw',
      'Biblical Content': 'jw',
    };
    
    final restrictedRole = restrictedCategories[categoryMain];
    if (restrictedRole == null) return false; // Not restricted, don't filter
    
    // Filter if user doesn't have the required role
    return !userRoles.contains(restrictedRole);
  }

  Widget _buildSortBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
           color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: widget.onSortByToggle,
            child: Text(
              widget.sortBy == 'bengali' ? S.of(context)!.bengali : S.of(context)!.english,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              widget.ascending ? Icons.vertical_align_top : Icons.vertical_align_bottom,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            onPressed: widget.onAscendingToggle,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWordTilesFromDocs(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
  ) {
    if (docs.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 45.0, right: 45.0, bottom: 45.0),
            child: Text(
              S.of(context)!.noResults,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    // Apply search filter if needed
    List<QueryDocumentSnapshot> filtered = docs;
    if (widget.searchQuery.isNotEmpty) {
      final lowerQuery = widget.searchQuery.toLowerCase();
      filtered = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
              final eng = (data['english'] ?? '').toString().toLowerCase();
              final ben = (data['bengali'] ?? '').toString().toLowerCase();
        final engSynonyms = (data['englishWordSynonyms'] as List<dynamic>? ?? [])
            .map((e) => e.toString().toLowerCase());
        final bnSynonyms = (data['bengaliWordSynonyms'] as List<dynamic>? ?? [])
            .map((e) => e.toString().toLowerCase());
        return eng.contains(lowerQuery) ||
            ben.contains(lowerQuery) ||
            engSynonyms.any((s) => s.contains(lowerQuery)) ||
            bnSynonyms.any((s) => s.contains(lowerQuery));
            }).toList();
    }

    // Deduplicate by english word
            final seen = <String>{};
    filtered = filtered.where((doc) {
      final eng = (doc.data() as Map<String, dynamic>)['english'] as String? ?? '';
              if (seen.contains(eng)) return false;
              seen.add(eng);
              return true;
    }).toList();

    // Sort
            filtered.sort((a, b) {
      final d1 = a.data() as Map<String, dynamic>;
      final d2 = b.data() as Map<String, dynamic>;
      final field = widget.sortBy;
      final val1 = (d1[field] ?? '').toString();
      final val2 = (d2[field] ?? '').toString();
      return widget.ascending ? val1.compareTo(val2) : val2.compareTo(val1);
            });

    // Group by first letter
            final grouped = <String, List<QueryDocumentSnapshot>>{};
    final isBnFirst = widget.sortBy == 'bengali';
            for (var doc in filtered) {
      final data = doc.data() as Map<String, dynamic>;
      final word = (isBnFirst ? data['bengali'] : data['english']) as String? ?? '';
              final letter = word.isNotEmpty ? word[0].toUpperCase() : '';
              grouped.putIfAbsent(letter, () => []).add(doc);
            }
    final letters = grouped.keys.toList()
      ..sort((a, b) => widget.ascending ? a.compareTo(b) : b.compareTo(a));

            final List<Widget> items = [];
            for (var letter in letters) {
              items.add(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      letter,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                  ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              );
              for (var doc in grouped[letter]!) {
        final data = doc.data() as Map<String, dynamic>;
                final english = data['english'] as String? ?? '';
                final bengali = data['bengali'] as String? ?? '';
                final wordId = doc.id;

        // Thumbnail logic
                final variants = data['variants'] as List?;
                String? thumbnailUrl;
                if (variants != null && variants.isNotEmpty) {
                  final map = variants[0] as Map<String, dynamic>;
                  final small = (map['videoThumbnailSmall'] ?? '').toString();
                  final original = (map['videoThumbnail'] ?? '').toString();
                  thumbnailUrl = small.isNotEmpty ? small : (original.isNotEmpty ? original : null);
                }

                Widget thumbnailWidget;
                if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
                  thumbnailWidget = Stack(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        color: Theme.of(context).colorScheme.surface3,
                child: Image.asset('assets/videoLoadingPlaceholder.webp',
                    width: 32, height: 32, fit: BoxFit.cover),
                      ),
                      Image.network(
                        thumbnailUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        cacheWidth: 64,
                        cacheHeight: 64,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ],
                  );
                } else {
                  thumbnailWidget = Container(
                    width: 32,
                    height: 32,
                    color: Theme.of(context).colorScheme.surface3,
            child: Image.asset('assets/videoLoadingPlaceholder.webp',
                width: 32, height: 32, fit: BoxFit.cover, alignment: Alignment.topCenter),
                  );
                }

                items.add(ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: thumbnailWidget,
                  onTap: () {
                    context.read<HistoryRepository>().add(wordId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                builder: (_) => VideoViewerPage(wordId: wordId),
                      ),
                    );
                  },
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: isBnFirst
                          ? [
                              TextSpan(
                                text: bengali,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: '   •   ',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: _capitalizeFirst(english),
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ]
                          : [
                              TextSpan(
                                text: _capitalizeFirst(english),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: '   •   ',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: bengali,
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 32,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.play_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          context.read<HistoryRepository>().add(wordId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoViewerPage(wordId: wordId),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12), // Add spacing between buttons
                      Consumer<FavoritesRepository>(
                        builder: (context, repo, _) {
                          final fav = repo.contains(wordId);
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              fav ? IconlyBold.heart : IconlyLight.heart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => repo.toggle(wordId),
                          );
                        },
                      ),
                      const SizedBox(width: 12), // Add spacing between buttons
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          await ShareService.shareVideo(
                            wordId,
                            english: english,
                            bengali: bengali,
                          );
                        },
                      ),
                    ],
                  ),
                ));
              }
            }

    return items;
  }

  List<Widget> _buildWordTiles(BuildContext context) {
    if (widget.selectedCategory.isEmpty && widget.searchQuery.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(45.0),
                child: Text(
              S.of(context)!.containerBText,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
                ),
          ),
        ),
      ];
    }
    if (widget.searchQuery.isNotEmpty) {
      // Search mode: filter all words, sort/group by current sortBy/ascending
    return [
      StreamBuilder<QuerySnapshot>(
          stream: TenantDb.concepts(
            FirebaseFirestore.instance,
            tenantId: context.watch<TenantScope>().tenantId,
          ).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
            final lowerQuery = widget.searchQuery.toLowerCase();
            final allDocs = snapshot.data!.docs;
          
          // Get user roles for filtering restricted content
          final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
          final userRoles = authProvider.userRoles;
          
            final filtered = allDocs.where((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            
            // Filter out restricted videos if user doesn't have required role
            if (_shouldFilterVideo(doc, userRoles)) {
              return false;
            }
            
            final eng = (data['english'] ?? '').toString().toLowerCase();
            final ben = (data['bengali'] ?? '').toString().toLowerCase();

            final engSynonyms = (data['englishWordSynonyms'] as List<dynamic>? ?? []).map((e) => e.toString().toLowerCase());
            final bnSynonyms = (data['bengaliWordSynonyms'] as List<dynamic>? ?? []).map((e) => e.toString().toLowerCase());

              return eng.contains(lowerQuery)
                || ben.contains(lowerQuery)
                || engSynonyms.any((s) => s.contains(lowerQuery))
                  || bnSynonyms.any((s) => s.contains(lowerQuery));
          }).toList();
            final seen = <String>{};
            filtered.retainWhere((doc) {
              final eng = (doc.data()! as Map<String, dynamic>)['english'] as String;
              if (seen.contains(eng)) return false;
              seen.add(eng);
              return true;
            });
            // Sort by selected field and order
          filtered.sort((a, b) {
            final d1 = a.data()! as Map<String, dynamic>;
            final d2 = b.data()! as Map<String, dynamic>;
              final field = widget.sortBy;
              return widget.ascending
                ? (d1[field] as String).compareTo(d2[field] as String)
                : (d2[field] as String).compareTo(d1[field] as String);
          });
            // Group by first letter of sort field
          final grouped = <String, List<QueryDocumentSnapshot>>{};

            // Log search analytics
            if (widget.onSearchCompleted != null) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 widget.onSearchCompleted!(widget.searchQuery, filtered.length, filtered.isNotEmpty, widget.selectedCategory.isNotEmpty ? widget.selectedCategory : null);
               });
            }

            final isBnFirst = widget.sortBy == 'bengali';
          for (var doc in filtered) {
            final data = doc.data()! as Map<String, dynamic>;
            final word = isBnFirst ? data['bengali'] : data['english'];
            final letter = word.isNotEmpty ? word[0].toUpperCase() : '';
            grouped.putIfAbsent(letter, () => []).add(doc);
          }
            final letters = grouped.keys.toList()..sort((a, b) => widget.ascending ? a.compareTo(b) : b.compareTo(a));
          final List<Widget> items = [];
          for (var letter in letters) {
            items.add(
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Text(
                    letter,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            );
            for (var doc in grouped[letter]!) {
              final data = doc.data()! as Map<String, dynamic>;
              final english = data['english'] as String? ?? '';
              final bengali = data['bengali'] as String? ?? '';
              final wordId = doc.id;
              // --- Thumbnail logic start ---
              final variants = data['variants'] as List?;
              String? thumbnailUrl;
                if (variants != null && variants.isNotEmpty) {
                  final map = variants[0] as Map<String, dynamic>;
                  final small = (map['videoThumbnailSmall'] ?? '').toString();
                  final original = (map['videoThumbnail'] ?? '').toString();
                  thumbnailUrl = small.isNotEmpty ? small : (original.isNotEmpty ? original : null);
              } else {
                thumbnailUrl = null;
              }

              Widget thumbnailWidget;
              if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
                thumbnailWidget = Stack(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      color: Theme.of(context).colorScheme.surface3,
                        child: Image.asset('assets/videoLoadingPlaceholder.webp', width: 32, height: 32, fit: BoxFit.cover),
                    ),
                    Image.network(
                      thumbnailUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                        cacheWidth: 64,
                        cacheHeight: 64,
                        filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ],
                );
              } else {
                thumbnailWidget = Container(
                  width: 32,
                  height: 32,
                  color: Theme.of(context).colorScheme.surface3,
                    child: Image.asset('assets/videoLoadingPlaceholder.webp', width: 32, height: 32, fit: BoxFit.cover, alignment: Alignment.topCenter),
                );
              }
              // --- Thumbnail logic end ---
                items.add(ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: thumbnailWidget,
                onTap: () {
                  context.read<HistoryRepository>().add(wordId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoViewerPage(
                        wordId: wordId,
                      ),
                    ),
                  );
                },
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: isBnFirst
                          ? [
                              TextSpan(
                                text: bengali,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: '   •   ',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: _capitalizeFirst(english),
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ]
                          : [
                              TextSpan(
                                text: _capitalizeFirst(english),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: '   •   ',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                              TextSpan(
                                text: bengali,
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                            ],
                    ),
                  ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      IconButton(
                             iconSize: 32,
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                             icon: Icon(
                               Icons.play_circle_rounded,
                               color: Theme.of(context).colorScheme.primary,
                             ),
                        onPressed: () {
                          context.read<HistoryRepository>().add(wordId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoViewerPage(
                                wordId: wordId,
                              ),
                            ),
                          );
                        },
                      ),
                           const SizedBox(width: 12),
                      Consumer<FavoritesRepository>(
                        builder: (context, repo, _) {
                               final fav = repo.contains(wordId);
                          return IconButton(
                                 padding: EdgeInsets.zero,
                                 constraints: const BoxConstraints(),
                            icon: Icon(
                                   fav ? IconlyBold.heart : IconlyLight.heart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => repo.toggle(wordId),
                          );
                        },
                      ),
                           const SizedBox(width: 12),
                      IconButton(
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                        icon: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          await ShareService.shareVideo(
                            wordId,
                            english: english,
                            bengali: bengali,
                          );
                        },
                      ),
                  ],
                ),
              ));
            }
          }
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
              child: Text(
                S.of(context)!.noResults,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            );
          }
            return Column(children: items);
        },
      ),
    ];
  }
    // Both "All" and category mode use pagination
    // Show loading indicator if initial load
    if (_loadedDocs.isEmpty && _isLoading) {
      return [
        const Center(child: CircularProgressIndicator()),
      ];
    }

    // Build widgets from loaded documents
    final items = _buildWordTilesFromDocs(context, _loadedDocs);

    // Add loading indicator at bottom if loading more
    if (_isLoading && _loadedDocs.isNotEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
            ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildWordTiles(context);
    return Column(children: items);
  }
}
