import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:provider/provider.dart';

import 'edit_word_page.dart';
import 'words_repository.dart';
import '../tenancy/tenant_db.dart';

class WordsListPage extends StatefulWidget {
  final String? userRoleOverride; // for dashboard editor flow (no AuthProvider)
  final String tenantId;
  final String signLangId;

  const WordsListPage({
    super.key,
    this.userRoleOverride,
    this.tenantId = TenantDb.defaultTenantId,
    this.signLangId = TenantDb.defaultSignLangId,
  });

  @override
  State<WordsListPage> createState() => _WordsListPageState();
}

class _WordsListPageState extends State<WordsListPage> {
  static const double desktopBreakpoint = 900;
  static const int pageSize = 30;
  static const int minQueryChars = 2;

  late final WordsRepository _repo;
  final ScrollController _scroll = ScrollController();

  Timer? _debounce;
  String _query = '';
  String _searchLang = 'en'; // 'en' or tenant local language (best-effort)

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  int? _wordCount;

  String? _selectedWordId; // desktop split view
  String? _backfillCursorDocId;

  @override
  void initState() {
    super.initState();
    _repo = WordsRepository(tenantId: widget.tenantId, signLangId: widget.signLangId);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCount();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  bool _isAdminOrEditor(BuildContext context) {
    final override = widget.userRoleOverride?.toLowerCase().trim();
    if (override == 'admin' || override == 'editor') return true;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      return auth.isAdmin || auth.isEditor;
    } catch (_) {
      return false;
    }
  }

  bool _isAdmin(BuildContext context) {
    final override = widget.userRoleOverride?.toLowerCase().trim();
    if (override == 'admin') return true;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      return auth.isAdmin;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadCount() async {
    final c = await _repo.countWords();
    if (!mounted) return;
    setState(() => _wordCount = c);
  }

  void _onScroll() {
    if (!_hasMore || _isLoading) return;
    if (!_isSearching) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  bool get _isSearching => _query.trim().length >= minQueryChars;

  bool _containsBengali(String s) => RegExp(r'[\u0980-\u09FF]').hasMatch(s);

  String get _localLangGuess {
    // Best-effort mapping; dashboard does not expose uiLocales yet.
    // Keep BN for the default BDSL tenant.
    final s = widget.signLangId.trim().toLowerCase();
    if (s == 'bdsl') return 'bn';
    return 'en';
  }

  List<String> get _supportedSearchLangs {
    final out = <String>['en'];
    final local = _localLangGuess;
    if (local.isNotEmpty && local != 'en') out.add(local);
    return out;
  }

  Future<void> _refresh() async {
    setState(() {
      _docs.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    if (_isSearching) {
      await _loadMore();
    } else {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    if (!_isSearching) return;
    setState(() => _isLoading = true);
    try {
      final snap = await _repo.fetchSearchPage(
        langCode: _searchLang,
        queryLower: _query.trim().toLowerCase(),
        limit: pageSize,
        startAfter: _lastDoc,
      );

      if (!mounted) return;
      final newDocs = snap.docs;
      setState(() {
        _docs.addAll(newDocs);
        _lastDoc = newDocs.isNotEmpty ? newDocs.last : _lastDoc;
        _hasMore = newDocs.length == pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load words: $e')),
      );
    }
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() {
        _query = v;
        // Auto-detect Bengali script only; otherwise keep current selection.
        if (_containsBengali(v)) _searchLang = 'bn';
      });
      await _refresh();
    });
  }

  Future<void> _runBackfill() async {
    try {
      const limit = 500;
      int totalScanned = 0;
      int totalUpdated = 0;
      int batches = 0;
      bool done = false;
      String? cursor = _backfillCursorDocId;

      // Run a bounded loop to avoid very long UI blocks. User can click again to continue.
      while (!done && batches < 10) {
        // Backfill both search-lower fields + canonical video URLs.
        await _repo.backfillWordLowerFields(limit: limit, startAfterDocId: cursor);
        final res = await _repo.backfillWordVideoFields(limit: limit, startAfterDocId: cursor);
        final scanned = (res['scanned'] is int) ? res['scanned'] as int : 0;
        final updated = (res['updated'] is int) ? res['updated'] as int : 0;
        totalScanned += scanned;
        totalUpdated += updated;
        batches++;

        cursor = (res['nextStartAfterDocId'] ?? '').toString();
        done = res['done'] == true || scanned == 0;
        if (cursor.isEmpty) {
          done = true;
        }
      }

      if (!mounted) return;
      setState(() => _backfillCursorDocId = done ? null : cursor);
      if (!mounted) return;
      await _loadCount();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Backfill complete'),
          content: Text(
            'Batches: $batches\n'
            'Scanned: $totalScanned\n'
            'Updated: $totalUpdated\n'
            'Done: $done\n'
            '${done ? '' : 'Run again to continue.'}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backfill failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdminOrEditor(context)) {
      return const _AccessDenied();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= desktopBreakpoint;

        final list = _WordsListPanel(
          scroll: _scroll,
          docs: _docs,
          isLoading: _isLoading,
          hasMore: _hasMore,
          wordCount: _wordCount,
          query: _query,
          onQueryChanged: _onQueryChanged,
          onTapWord: (wordId) async {
            if (isDesktop) {
              setState(() => _selectedWordId = wordId);
            } else {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditWordPage(
                    wordId: wordId,
                    userRoleOverride: widget.userRoleOverride,
                  ),
                ),
              );
              await _refresh();
            }
          },
          showBackfill: _isAdmin(context),
          onBackfill: _runBackfill,
          showResults: _isSearching,
          searchLang: _searchLang,
          supportedSearchLangs: _supportedSearchLangs,
          onSearchLangChanged: (v) {
            final next = v.trim().toLowerCase();
            if (next.isEmpty || next == _searchLang) return;
            setState(() => _searchLang = next);
            _refresh();
          },
        );

        if (!isDesktop) return list;

        return Row(
          children: [
            SizedBox(width: 420, child: list),
            const VerticalDivider(width: 1),
            Expanded(
              child: _selectedWordId == null
                  ? const _EmptySelection()
                  : EditWordView(
                      wordId: _selectedWordId!,
                      userRoleOverride: widget.userRoleOverride,
                      embedded: true,
                      onDeleted: () async {
                        setState(() => _selectedWordId = null);
                        await _refresh();
                      },
                      onSaved: () async {
                        await _refresh();
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _WordsListPanel extends StatelessWidget {
  final ScrollController scroll;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool isLoading;
  final bool hasMore;
  final int? wordCount;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onTapWord;
  final bool showBackfill;
  final Future<void> Function() onBackfill;
  final bool showResults;
  final String searchLang;
  final List<String> supportedSearchLangs;
  final ValueChanged<String> onSearchLangChanged;

  const _WordsListPanel({
    required this.scroll,
    required this.docs,
    required this.isLoading,
    required this.hasMore,
    required this.wordCount,
    required this.query,
    required this.onQueryChanged,
    required this.onTapWord,
    required this.showBackfill,
    required this.onBackfill,
    required this.showResults,
    required this.searchLang,
    required this.supportedSearchLangs,
    required this.onSearchLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Words List'),
        actions: [
          if (showBackfill)
            TextButton(
              onPressed: onBackfill,
              style: TextButton.styleFrom(foregroundColor: cs.onPrimary),
              child: const Text('Backfill search'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CountChip(count: wordCount),
                    const Spacer(),
                    if (showResults)
                      (supportedSearchLangs.length <= 1)
                          ? const SizedBox.shrink()
                          : DropdownButton<String>(
                              value: supportedSearchLangs.contains(searchLang) ? searchLang : supportedSearchLangs.first,
                              items: supportedSearchLangs
                                  .map(
                                    (l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(l.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                onSearchLangChanged(v);
                              },
                            ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'Search (prefix)…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty ? null : const Icon(Icons.keyboard_return),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !showResults
                ? const _SearchEmptyState()
                : ListView.separated(
                    controller: scroll,
                    itemCount: docs.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == docs.length) {
                        if (isLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!hasMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: Text('End of results')),
                          );
                        }
                        return const SizedBox(height: 12);
                      }

                      final doc = docs[index];
                      final data = doc.data();
                      final english = (data['english'] ?? '').toString();
                      final bengali = (data['bengali'] ?? '').toString();
                      final isBn = searchLang.toLowerCase() == 'bn';
                      final title = isBn
                          ? (bengali.isEmpty ? '(no bn)' : bengali)
                          : (english.isEmpty ? '(no en)' : english);

                      return ListTile(
                        title: Text(title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onTapWord(doc.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int? count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count == null ? 'Words: …' : 'Words: $count';
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Access denied. Admin or Editor role required.'),
        ),
      ),
    );
  }
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Search for a word to edit.'),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Type at least 2 characters to search.'),
      ),
    );
  }
}


