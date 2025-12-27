import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'services/favorites_repository.dart';
import 'video_viewer_page.dart';
import 'widgets/custom_search_bar.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:l2l_shared/auth/auth_provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Map<String, bool> _expandedState = {};
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExpandedState();
  }

  void _loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final state = <String, bool>{};
    for (final key in keys) {
      if (key.startsWith('expanded_')) {
        state[key.replaceFirst('expanded_', '')] = prefs.getBool(key) ?? true;
      }
    }
    setState(() {
      _expandedState = state;
    });
  }

  void _setExpandedState(String category, bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('expanded_$category', expanded);
    setState(() {
      _expandedState[category] = expanded;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // CustomSearchBar with full width, no padding/margin.
          CustomSearchBar(
            controller: _searchController,
            hintText: S.of(context)!.searchHint,
            onChanged: (value) {
              setState(() {
                _searchText = value.toLowerCase();
              });
            },
          ),
          Expanded(
            child: Consumer<FavoritesRepository>(
              builder: (context, repo, _) {
                final ids = repo.value;
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bangla_dictionary_eng_bnsl').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
                    
                    final docs = snapshot.data!.docs
                        .where((doc) {
                          // Filter out restricted videos if user doesn't have required role
                          if (shouldFilterVideo(doc)) {
                            return false;
                          }
                          
                          final data = doc.data() as Map<String, dynamic>;
                          final english = (data['english'] ?? '').toString().toLowerCase();
                          final bengali = (data['bengali'] ?? '').toString().toLowerCase();
                          return ids.contains(doc.id) &&
                                 (english.contains(_searchText) || bengali.contains(_searchText));
                        })
                        .toList();
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(S.of(context)!.noFavorites),
                      );
                    }

                    final grouped = SplayTreeMap<String, List<QueryDocumentSnapshot>>();
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final category = data['category'] ?? 'Uncategorized';
                      grouped.putIfAbsent(category, () => []).add(doc);
                    }

                    return ListView(
                      children: grouped.entries.map((entry) {
                        final category = entry.key;
                        final items = entry.value;

                        return ExpansionTile(
                          title: Text(
                            // keep category dynamic via legacy later if needed; for now show raw
                            category,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          initiallyExpanded: _expandedState[category] ?? true,
                          onExpansionChanged: (expanded) => _setExpandedState(category, expanded),
                          children: items.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final english = data['english'] ?? '';
                            final bengali = data['bengali'] ?? '';
                            final wordId = doc.id;

                            return ListTile(
                              title: Text(
                                '$english ($bengali)',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.play_arrow, color: Theme.of(context).iconTheme.color),
                                    onPressed: () {
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
                                  IconButton(
                                    icon: Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
                                    onPressed: () {
                                      context.read<FavoritesRepository>().toggle(wordId);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}