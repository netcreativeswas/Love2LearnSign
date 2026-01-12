import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../add_word/add_word_page.dart';
import '../layout/l2l_layout_scope.dart';
import 'edit_word_page.dart';
import 'words_repository.dart';

class WordManagementPage extends StatefulWidget {
  final String tenantId;
  final String signLangId;

  /// Dashboard passes this since it does not use the mobile AuthProvider.
  /// Expected values: 'admin' or 'editor'.
  final String? userRoleOverride;

  const WordManagementPage({
    super.key,
    required this.tenantId,
    required this.signLangId,
    this.userRoleOverride,
  });

  @override
  State<WordManagementPage> createState() => _WordManagementPageState();
}

class _WordManagementPageState extends State<WordManagementPage> {
  static const double desktopBreakpoint = 900;
  static const int pageSize = 30;
  static const int minQueryChars = 2;

  late final WordsRepository _repo;

  final TextEditingController _search = TextEditingController();
  final ScrollController _resultsScroll = ScrollController();

  Timer? _debounce;
  String _query = '';
  String _searchLang = 'en';

  bool _loadingLatest = false;
  bool _loadingCount = false;
  bool _loadingResults = false;

  int? _wordCount;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latest3 = const [];

  bool _hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  String? _selectedWordId; // null => Add mode

  @override
  void initState() {
    super.initState();
    _repo = WordsRepository(tenantId: widget.tenantId, signLangId: widget.signLangId);
    _resultsScroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshAll();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _resultsScroll.dispose();
    super.dispose();
  }

  bool get _isSearching => _query.trim().length >= minQueryChars;

  bool _containsBengali(String s) => RegExp(r'[\u0980-\u09FF]').hasMatch(s);

  String get _localLangGuess {
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

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadCount(),
      _loadLatest3(),
      _refreshSearchResults(),
    ]);
  }

  Future<void> _loadCount() async {
    if (_loadingCount) return;
    setState(() => _loadingCount = true);
    try {
      final c = await _repo.countWords();
      if (!mounted) return;
      setState(() => _wordCount = c);
    } finally {
      if (mounted) setState(() => _loadingCount = false);
    }
  }

  Future<void> _loadLatest3() async {
    if (_loadingLatest) return;
    setState(() => _loadingLatest = true);
    try {
      final docs = await _repo.fetchLatestWords(limit: 3);
      if (!mounted) return;
      setState(() => _latest3 = docs);
    } finally {
      if (mounted) setState(() => _loadingLatest = false);
    }
  }

  Future<void> _refreshSearchResults() async {
    setState(() {
      _docs.clear();
      _lastDoc = null;
      _hasMore = true;
      _loadingResults = false;
    });
    if (_isSearching) {
      await _loadMore();
    } else {
      setState(() {
        _hasMore = false;
        _loadingResults = false;
      });
    }
  }

  void _onScroll() {
    if (!_isSearching) return;
    if (_loadingResults || !_hasMore) return;
    final pos = _resultsScroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingResults || !_hasMore) return;
    if (!_isSearching) return;
    setState(() => _loadingResults = true);
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
        _loadingResults = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingResults = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load words: $e')),
      );
    }
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      if (!mounted) return;
      setState(() {
        _query = v;
        if (_containsBengali(v)) _searchLang = 'bn';
      });
      await _refreshSearchResults();
    });
  }

  String _fmtInt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');

  String _titleFromDoc(Map<String, dynamic> data, {required String lang}) {
    final english = (data['english'] ?? '').toString().trim();
    final bengali = (data['bengali'] ?? '').toString().trim();
    final isBn = lang.toLowerCase() == 'bn';
    final t = isBn ? bengali : english;
    if (t.isNotEmpty) return t;
    // Fallback: try the other legacy field.
    final other = isBn ? english : bengali;
    if (other.isNotEmpty) return other;
    // Fallback: labels map (multi-locale schema).
    final labels = data['labels'];
    if (labels is Map) {
      final v = (labels[lang] ?? labels['en'] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return '(untitled)';
  }

  String _subtitleFromDoc(Map<String, dynamic> data, {required String primaryLang}) {
    final english = (data['english'] ?? '').toString().trim();
    final bengali = (data['bengali'] ?? '').toString().trim();
    final isBn = primaryLang.toLowerCase() == 'bn';
    final other = isBn ? english : bengali;
    return other.isEmpty ? '' : other;
  }

  void _selectWord(String wordId) {
    if (wordId.trim().isEmpty) return;
    setState(() => _selectedWordId = wordId);
  }

  void _goAddMode() {
    setState(() => _selectedWordId = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= desktopBreakpoint;

    final left = _LeftPanel(
      wordCount: _wordCount,
      countLoading: _loadingCount,
      latestDocs: _latest3,
      latestLoading: _loadingLatest,
      onTapLatest: (wordId) => _selectWord(wordId),
      searchController: _search,
      query: _query,
      onQueryChanged: _onQueryChanged,
      showResults: _isSearching,
      searchLang: _searchLang,
      supportedSearchLangs: _supportedSearchLangs,
      onSearchLangChanged: (next) async {
        final v = next.trim().toLowerCase();
        if (v.isEmpty || v == _searchLang) return;
        setState(() => _searchLang = v);
        await _refreshSearchResults();
      },
      resultsScroll: _resultsScroll,
      resultDocs: _docs,
      resultsLoading: _loadingResults,
      hasMore: _hasMore,
      onTapResult: (wordId) => _selectWord(wordId),
      titleFromDoc: (data) => _titleFromDoc(data, lang: _searchLang),
      subtitleFromDoc: (data) => _subtitleFromDoc(data, primaryLang: _searchLang),
      formatCount: _fmtInt,
    );

    final right = _RightPanel(
      mode: _selectedWordId == null ? _WordMode.add : _WordMode.edit,
      selectedWordId: _selectedWordId,
      onAddWord: _goAddMode,
      child: _selectedWordId == null
          ? AddWordPage(
              tenantId: widget.tenantId,
              signLangId: widget.signLangId,
              embedded: true,
              dashboardMaxWidth: double.infinity,
              onSaved: () async {
                await _loadCount();
                await _loadLatest3();
              },
            )
          : EditWordView(
              wordId: _selectedWordId!,
              tenantId: widget.tenantId,
              signLangId: widget.signLangId,
              userRoleOverride: widget.userRoleOverride,
              embedded: true,
              onSaved: () async {
                await _loadCount();
                await _loadLatest3();
                if (_isSearching) await _refreshSearchResults();
              },
              onDeleted: () async {
                _goAddMode();
                await _loadCount();
                await _loadLatest3();
                if (_isSearching) await _refreshSearchResults();
              },
            ),
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left “panel” as a top section
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: left,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: right,
            ),
          ),
        ],
      );
    }

    // Desktop: true split-pane.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 420,
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: left,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: right,
          ),
        ),
      ],
    );
  }
}

enum _WordMode { add, edit }

class _RightPanel extends StatelessWidget {
  final _WordMode mode;
  final String? selectedWordId;
  final VoidCallback onAddWord;
  final Widget child;

  const _RightPanel({
    required this.mode,
    required this.selectedWordId,
    required this.onAddWord,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDashboard = L2LLayoutScope.maybeOf(context)?.isDashboard ?? false;
    final title = mode == _WordMode.add ? 'Add Word' : 'Edit Word';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (mode == _WordMode.edit && (selectedWordId ?? '').isNotEmpty)
                      Text(
                        selectedWordId!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onAddWord,
                icon: const Icon(Icons.add),
                label: const Text('Add Word'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: isDashboard
              ? child
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: child,
                ),
        ),
      ],
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final int? wordCount;
  final bool countLoading;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> latestDocs;
  final bool latestLoading;
  final ValueChanged<String> onTapLatest;

  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  final bool showResults;
  final String searchLang;
  final List<String> supportedSearchLangs;
  final ValueChanged<String> onSearchLangChanged;

  final ScrollController resultsScroll;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> resultDocs;
  final bool resultsLoading;
  final bool hasMore;
  final ValueChanged<String> onTapResult;

  final String Function(Map<String, dynamic> data) titleFromDoc;
  final String Function(Map<String, dynamic> data) subtitleFromDoc;
  final String Function(int n) formatCount;

  const _LeftPanel({
    required this.wordCount,
    required this.countLoading,
    required this.latestDocs,
    required this.latestLoading,
    required this.onTapLatest,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.showResults,
    required this.searchLang,
    required this.supportedSearchLangs,
    required this.onSearchLangChanged,
    required this.resultsScroll,
    required this.resultDocs,
    required this.resultsLoading,
    required this.hasMore,
    required this.onTapResult,
    required this.titleFromDoc,
    required this.subtitleFromDoc,
    required this.formatCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final countText = countLoading
        ? 'Total words: …'
        : (wordCount == null ? 'Total words: —' : 'Total words: ${formatCount(wordCount!)}');

    Widget latestList() {
      if (latestLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: LinearProgressIndicator(minHeight: 2),
        );
      }
      if (latestDocs.isEmpty) {
        return Text(
          'No recent words yet.',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        );
      }
      return Column(
        children: latestDocs.map((d) {
          final data = d.data();
          final title = titleFromDoc(data);
          final subtitle = subtitleFromDoc(data);
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
            subtitle: subtitle.isEmpty
                ? null
                : Text(subtitle, overflow: TextOverflow.ellipsis, maxLines: 1),
            onTap: () => onTapLatest(d.id),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(countText, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Last added', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        latestList(),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            searchController.clear();
                            onQueryChanged('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (showResults && supportedSearchLangs.length > 1)
              DropdownButton<String>(
                value: supportedSearchLangs.contains(searchLang) ? searchLang : supportedSearchLangs.first,
                items: supportedSearchLangs
                    .map((l) => DropdownMenuItem(value: l, child: Text(l.toUpperCase())))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onSearchLangChanged(v);
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: !showResults
              ? Center(
                  child: Text(
                    'Type at least 2 characters to search.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  controller: resultsScroll,
                  itemCount: resultDocs.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == resultDocs.length) {
                      if (resultsLoading) {
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

                    final doc = resultDocs[index];
                    final data = doc.data();
                    final title = titleFromDoc(data);
                    final subtitle = subtitleFromDoc(data);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
                      subtitle: subtitle.isEmpty
                          ? null
                          : Text(subtitle, overflow: TextOverflow.ellipsis, maxLines: 1),
                      onTap: () => onTapResult(doc.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

