// ignore_for_file: unused_field, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:l2l_shared/analytics/search_tracking_service.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:l2l_shared/debug/agent_logger.dart';
import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

enum SearchSortMode { frequency, alphabetical }

class SearchAnalyticsPage extends StatefulWidget {
  final String countryCode;
  const SearchAnalyticsPage({super.key, this.countryCode = 'GB'});

  @override
  State<SearchAnalyticsPage> createState() => _SearchAnalyticsPageState();
}

class _SearchAnalyticsPageState extends State<SearchAnalyticsPage> {
  int _selectedDays = 30;
  late Future<Map<String, dynamic>> _analyticsFuture;
  bool _isClearing = false;
  SearchSortMode _searchSortMode = SearchSortMode.frequency;
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();
  final ScrollController _topSearchesScrollController = ScrollController();
  final ScrollController _missingWordsScrollController = ScrollController();
  final ScrollController _categoriesScrollController = ScrollController();
  final Map<String, bool> _panelExpanded = {
    'missing': true,
    'top': true,
    'categories': true,
  };
  static const double _panelBodyHeight = 280;

  // Heatmap UI: choose which metric drives the color intensity.
  // Tooltip always shows both searches + sessions.
  String _heatmapMetric = 'searches'; // 'searches' | 'sessions'

  double _panelBodyHeightFor(BuildContext context) {
    // On dashboard desktop we want panels tall enough to read comfortably,
    // while keeping internal scrolling inside lists.
    if (L2LLayoutScope.isDashboardDesktop(context)) {
      final h = MediaQuery.sizeOf(context).height;
      return (h - 320).clamp(320, 560).toDouble();
    }
    return _panelBodyHeight;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _topSearchesScrollController.dispose();
    _missingWordsScrollController.dispose();
    _categoriesScrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    _analyticsFuture = SearchTrackingService().getAnalyticsData(days: _selectedDays);
  }

  void _onFilterChanged(int days) {
    if (_selectedDays == days) return;
    setState(() {
      _selectedDays = days;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // #region agent log
    // NOTE: keep payload minimal, no secrets.
    AgentLogger.log({
      'sessionId': 'debug-session',
      'runId': 'pixel9pro-pre',
      'hypothesisId': 'H1',
      'location': 'shared/search_analytics_page.dart:build',
      'message': 'SearchAnalyticsPage build',
      'data': {
        'selectedDays': _selectedDays,
        'heatmapMetric': _heatmapMetric,
        'isDashboard': L2LLayoutScope.maybeOf(context)?.isDashboard ?? false,
        'isDashboardDesktop': L2LLayoutScope.isDashboardDesktop(context),
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // #endregion

    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    final theme = Theme.of(context);
    final isDashboard = L2LLayoutScope.maybeOf(context)?.isDashboard ?? false;
    final isDashboardDesktop = L2LLayoutScope.isDashboardDesktop(context);
    return Scaffold(
      appBar: isDashboard
          ? null
          : AppBar(
              title: const Text('Search Analytics'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
            ),
      body: Column(
        children: [
          if (!isDashboardDesktop) _buildTimeFilter(theme),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _analyticsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data ?? {};
                final totalSearches = data['totalSearches'] as int? ?? 0;
                // IMPORTANT: keep build() pure (no state mutation). Sort copies derived from snapshot data.
                final selectedTop = _prepareSearchList(data['topSearches']);
                final missingWords =
                    _prepareMissingWords(List<Map<String, dynamic>>.from(data['topMissing'] ?? const []));
                final missingCopyList =
                    missingWords.map((item) => (item['term'] ?? '').toString()).toList();
                final categories =
                    _prepareCategoryList(List<Map<String, dynamic>>.from(data['topCategories'] ?? const []));
                final heatmap = List<Map<String, dynamic>>.from(data['heatmap'] ?? []);

                final listPadding = isDashboard ? EdgeInsets.zero : const EdgeInsets.all(16);

                if (isDashboardDesktop) {
                  // Desktop layout (dashboard-only):
                  // - Heatmap full width at top
                  // - Below: fixed TimeRange sidebar and scrollable accordion area
                  final sidebar = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Time range',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(width: double.infinity, child: _filterButton(theme, 7, '7 Days')),
                              const SizedBox(height: 8),
                              SizedBox(width: double.infinity, child: _filterButton(theme, 30, '30 Days')),
                              const SizedBox(height: 8),
                              SizedBox(width: double.infinity, child: _filterButton(theme, 90, '90 Days')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(theme, totalSearches),
                      const SizedBox(height: 12),
                      // Maintenance should live under Total Searches in the left sidebar (desktop dashboard)
                      _buildMaintenanceCard(theme),
                    ],
                  );

                  final rightColumn = SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchSortControls(theme),
                        const SizedBox(height: 12),
                        // Accordions must remain (Missing / Top / Categories)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTopSearchesPanel(
                                theme,
                                panelKey: 'top',
                                title: 'Top Searches',
                                data: selectedTop,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMissingWordsPanel(theme, missingWords, missingCopyList),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCategoryPanel(theme, categories),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );

                  return Padding(
                    padding: listPadding,
                    child: Column(
                      children: [
                        // Heatmap full width on top
                        _buildHeatmapCard(theme, heatmap),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 280, child: sidebar),
                              const SizedBox(width: 16),
                              Expanded(child: rightColumn),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: listPadding,
                  children: [
                    _buildSummaryCard(theme, totalSearches),
                    const SizedBox(height: 16),
                    _buildSearchSortControls(theme),
                    const SizedBox(height: 16),
                    _buildMissingWordsPanel(theme, missingWords, missingCopyList),
                    const SizedBox(height: 16),
                    _buildTopSearchesPanel(
                      theme,
                      panelKey: 'top',
                      title: 'Top Searches',
                      data: selectedTop,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryPanel(theme, categories),
                    const SizedBox(height: 16),
                    _buildHeatmapCard(theme, heatmap),
                    const SizedBox(height: 16),
                    _buildMaintenanceCard(theme),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterButton(theme, 7, '7 Days'),
          const SizedBox(width: 10),
          _filterButton(theme, 30, '30 Days'),
          const SizedBox(width: 10),
          _filterButton(theme, 90, '90 Days'),
        ],
      ),
    );
  }

  Widget _filterButton(ThemeData theme, int days, String label) {
    final isSelected = _selectedDays == days;
    return ElevatedButton(
      onPressed: () => _onFilterChanged(days),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
        foregroundColor: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
      ),
      child: Text(label),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, int total) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Searches',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              _numberFormat.format(total),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              'in last $_selectedDays days',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSortControls(ThemeData theme) {
    return Row(
      children: [
        Text('Sort search lists:', style: theme.textTheme.bodyMedium),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('Frequency'),
          selected: _searchSortMode == SearchSortMode.frequency,
          onSelected: (selected) {
            if (selected && _searchSortMode != SearchSortMode.frequency) {
              setState(() {
                _searchSortMode = SearchSortMode.frequency;
                // Re-sort will happen automatically in build when data is prepared
              });
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('A → Z'),
          selected: _searchSortMode == SearchSortMode.alphabetical,
          onSelected: (selected) {
            if (selected && _searchSortMode != SearchSortMode.alphabetical) {
              setState(() {
                _searchSortMode = SearchSortMode.alphabetical;
                // Re-sort will happen automatically in build when data is prepared
              });
            }
          },
        ),
      ],
    );
  }

  // (Desktop-only card variants removed; desktop uses accordions for lists.)

  Widget _buildTopSearchesPanel(
    ThemeData theme, {
    required String panelKey,
    required String title,
    required List<Map<String, dynamic>> data,
  }) {
    final body = data.isEmpty
        ? _buildEmptyState(theme, 'No data available.')
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Scrollbar(
              thumbVisibility: true,
              controller: _topSearchesScrollController,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                controller: _topSearchesScrollController,
                itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = data[index];
                  return ListTile(
                    dense: true,
                    leading: Text(
                      '#${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    title: Text(item['term'] as String),
                    trailing: Text(
                      _numberFormat.format(item['count'] ?? 0),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          );

    return _buildAccordionPanel(
      theme: theme,
      panelKey: panelKey,
      title: '$title (${data.length})',
      icon: Icons.trending_up,
      child: body,
    );
  }

  Widget _buildMissingWordsPanel(
    ThemeData theme,
    List<Map<String, dynamic>> data,
    List<String> copyList,
  ) {
    final body = data.isEmpty
        ? _buildEmptyState(theme, 'No missing words recorded.')
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: data.isEmpty ? null : () => _copyMissingWords(copyList),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                    style: TextButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _missingWordsScrollController,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      controller: _missingWordsScrollController,
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final term = (item['term'] ?? '').toString();
                        final count = item['count'] as int? ?? 0;
                        return ListTile(
                          dense: true,
                          title: Text(term, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text(
                            '$count ${count == 1 ? 'search' : 'searches'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );

    return _buildAccordionPanel(
      theme: theme,
      panelKey: 'missing',
      title: 'Missing Words (${data.length})',
      icon: Icons.warning_amber,
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Missing Words (${data.length})'),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Searches with 0 results',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Missing Words'),
                      content: const Text('Searches with 0 results'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
      child: body,
    );
  }

  Widget _buildCategoryPanel(ThemeData theme, List<Map<String, dynamic>> data) {
    final body = data.isEmpty
        ? _buildEmptyState(theme, 'No category data available.')
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Scrollbar(
              thumbVisibility: true,
              controller: _categoriesScrollController,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                controller: _categoriesScrollController,
                itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = data[index];
                  final category = (item['category'] ?? 'Unknown').toString();
                  final count = item['count'] as int? ?? 0;
                  return ListTile(
                    dense: true,
                    leading: Text(
                      '#${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    title: Text(category),
                    trailing: Text(
                      _numberFormat.format(count),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          );

    return _buildAccordionPanel(
      theme: theme,
      panelKey: 'categories',
      title: 'Most Searched Categories (${data.length})',
      icon: Icons.category,
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Most Searched\n'),
                TextSpan(text: 'Categories (${data.length})'),
              ],
            ),
            style: const TextStyle(height: 1.0),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Top categories when results were found',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Most Searched Categories'),
                      content: const Text('Top categories when results were found'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
      child: body,
    );
  }

  Widget _buildHeatmapCard(ThemeData theme, List<Map<String, dynamic>> data) {
    final isDashboardDesktop = L2LLayoutScope.isDashboardDesktop(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_on),
                const SizedBox(width: 8),
                Text(
                  'Daily Usage Heatmap (Local time)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Each square is one day. Color = ${_heatmapMetric == 'sessions' ? 'sessions' : 'searches'}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 10),
            // Mobile-friendly controls: avoid Wrap collisions/overlaps by keeping
            // chips horizontally scrollable and the legend on its own line.
            if (isDashboardDesktop)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _heatmapMetricChip(theme, label: 'Searches', value: 'searches'),
                  _heatmapMetricChip(theme, label: 'Sessions', value: 'sessions'),
                  const SizedBox(width: 8),
                  _buildHeatmapLegend(theme),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _heatmapMetricChip(theme, label: 'Searches', value: 'searches'),
                        const SizedBox(width: 8),
                        _heatmapMetricChip(theme, label: 'Sessions', value: 'sessions'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildHeatmapLegend(theme),
              ],
            ),
            const SizedBox(height: 12),
            _buildDailyHeatmap(theme, data),
          ],
        ),
      ),
    );
  }

  Widget _heatmapMetricChip(ThemeData theme, {required String label, required String value}) {
    final selected = _heatmapMetric == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _heatmapMetric = value),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  List<Color> _heatmapColors(ThemeData theme) {
    // Dark-mode-safe: blend from surfaceContainerHighest -> primary at increasing strengths.
    final base = theme.colorScheme.surfaceContainerHighest;
    final p = theme.colorScheme.primary;
    return [
      base,
      Color.lerp(base, p, 0.25)!,
      Color.lerp(base, p, 0.45)!,
      Color.lerp(base, p, 0.65)!,
      Color.lerp(base, p, 0.85)!,
    ];
  }

  Widget _buildHeatmapLegend(ThemeData theme) {
    final colors = _heatmapColors(theme);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Less', style: theme.textTheme.bodySmall),
        const SizedBox(width: 6),
        ...List.generate(colors.length, (i) {
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: colors[i],
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text('More', style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMaintenanceCard(ThemeData theme) {
    final isDashboardDesktop = L2LLayoutScope.isDashboardDesktop(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isDashboardDesktop ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Maintenance',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Manually delete all search analytics data. This action cannot be undone.',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Maintenance'),
                            content: const Text('Manually delete all search analytics data. This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMaintenanceButton(
              theme,
              label: 'Clear All Search Analytics Data',
              icon: Icons.delete_forever,
              onPressed: () => _confirmMaintenanceAction(clearOlderThanYear: false),
            ),
            const SizedBox(height: 12),
            _buildMaintenanceButton(
              theme,
              label: 'Clear Search Data Older Than 365 Days',
              icon: Icons.history_toggle_off,
              onPressed: () => _confirmMaintenanceAction(clearOlderThanYear: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _isClearing ? null : onPressed,
        icon: _isClearing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(_isClearing ? 'Please wait...' : label),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyHeatmap(ThemeData theme, List<Map<String, dynamic>> data) {
    // data item: {date: yyyy-MM-dd, searches: int, sessions: int} (Local day buckets)
    final byDate = <DateTime, Map<String, int>>{};
    int maxValue = 1;

    for (final item in data) {
      final raw = (item['date'] ?? '').toString().trim();
      if (raw.isEmpty || raw.length < 10) continue;
      final y = int.tryParse(raw.substring(0, 4));
      final m = int.tryParse(raw.substring(5, 7));
      final d = int.tryParse(raw.substring(8, 10));
      if (y == null || m == null || d == null) continue;
      final date = DateTime(y, m, d);
      final searches = (item['searches'] is int) ? item['searches'] as int : int.tryParse('${item['searches']}') ?? 0;
      final sessions = (item['sessions'] is int) ? item['sessions'] as int : int.tryParse('${item['sessions']}') ?? 0;
      byDate[date] = {'searches': searches, 'sessions': sessions};

      final v = _heatmapMetric == 'sessions' ? sessions : searches;
      if (v > maxValue) maxValue = v;
    }

    // Show last N days (based on page filter), aligned to week columns.
    final end = DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);
    final startDay = endDay.subtract(Duration(days: _selectedDays - 1));

    // Align to Monday for nice columns (Mon..Sun rows)
    DateTime gridStart = startDay;
    while (gridStart.weekday != DateTime.monday) {
      gridStart = gridStart.subtract(const Duration(days: 1));
    }
    DateTime gridEnd = endDay;
    while (gridEnd.weekday != DateTime.sunday) {
      gridEnd = gridEnd.add(const Duration(days: 1));
    }

    final colors = _heatmapColors(theme);
    final isDashboardDesktop = L2LLayoutScope.isDashboardDesktop(context);
    final gap = 3.0;
    final radius = 4.0;

    String weekdayLabel(int weekday, {required bool compact}) {
      switch (weekday) {
        case DateTime.monday:
          return 'Mon';
        case DateTime.tuesday:
          return compact ? '' : 'Tue';
        case DateTime.wednesday:
          return 'Wed';
        case DateTime.thursday:
          return compact ? '' : 'Thu';
        case DateTime.friday:
          return 'Fri';
        case DateTime.saturday:
          return compact ? '' : 'Sat';
        case DateTime.sunday:
          return compact ? '' : 'Sun';
      }
      return '';
    }

    final dateFmt = DateFormat('MMM d, yyyy');
    final monthFmt = DateFormat('MMM');

    // Build week columns.
    final weeks = <List<DateTime>>[];
    var cursor = gridStart;
    while (!cursor.isAfter(gridEnd)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    Color colorFor(int v) {
      if (v <= 0) return colors[0];
      if (maxValue <= 1) return colors[4];
      // Log scale gives much better visual separation for "small" daily counts.
      final ratio = math.log(v + 1) / math.log(maxValue + 1);
      if (ratio <= 0.20) return colors[1];
      if (ratio <= 0.40) return colors[2];
      if (ratio <= 0.70) return colors[3];
      return colors[4];
    }

    const labelWidth = 34.0;
    const labelGap = 8.0;
    final weekCount = weeks.length;
    const monthRowHeight = 16.0;

    Widget monthLabelCell(double cell, int idx) {
      final weekStart = weeks[idx].first; // Monday
      final prevMonth = idx == 0 ? null : weeks[idx - 1].first.month;
      final show = idx == 0 || weekStart.month != prevMonth;
      return SizedBox(
        width: cell,
        height: monthRowHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: show
              ? OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: cell * 4, // allow month label to flow over next columns (GitHub-style)
                  minHeight: monthRowHeight,
                  maxHeight: monthRowHeight,
                  child: Text(
                    monthFmt.format(weekStart),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isDashboardDesktop ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox(),
        ),
      );
    }

    Widget dayCell(double cell, DateTime day) {
      final inRange = !day.isBefore(startDay) && !day.isAfter(endDay);
      final stats = byDate[day] ?? const {'searches': 0, 'sessions': 0};
      final searches = stats['searches'] ?? 0;
      final sessions = stats['sessions'] ?? 0;
      final v = _heatmapMetric == 'sessions' ? sessions : searches;

      final bg = inRange ? colorFor(v) : Colors.transparent;
      final border = inRange
          ? Border.all(color: theme.dividerColor.withValues(alpha: 0.25))
          : Border.all(color: Colors.transparent);

      final tip = '${searches.toString()} searches\n'
          '${sessions.toString()} sessions\n'
          '${dateFmt.format(day)} (Local)';

      return Tooltip(
        message: tip,
        child: Container(
          width: cell,
          height: cell,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: border,
          ),
        ),
      );
    }

    Widget weekColumn(double cell, List<DateTime> weekDays) {
      return SizedBox(
        width: cell,
      child: Column(
          children: List.generate(7, (row) {
            final day = weekDays[row];
            return Padding(
              padding: EdgeInsets.only(bottom: row == 6 ? 0 : gap),
              child: dayCell(cell, day),
            );
          }),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'pixel9pro-pre',
          'hypothesisId': 'H1',
          'location': 'shared/search_analytics_page.dart:_buildDailyHeatmap.LayoutBuilder',
          'message': 'DUH constraints',
          'data': {
            'maxW': constraints.maxWidth,
            'maxH': constraints.maxHeight,
            'weekCount': weekCount,
            'selectedDays': _selectedDays,
            'isDashboardDesktop': isDashboardDesktop,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion

        // Desktop: try to fit without scrolling (unless needed).
        // Mobile: keep a stable GitHub-like square size + always use horizontal scroll
        // instead of squeezing (prevents "stacked/overlapping" look on small screens).
        final availableGridWidth = constraints.maxWidth - (labelWidth + labelGap);

        final double cell;
        final bool needsScroll;
        final double gridWidth;
        final intrinsicGridWidth = weekCount * (isDashboardDesktop ? 13.0 : 18.0) + (weekCount - 1) * gap;

        if (isDashboardDesktop) {
          final maxCell = 14.0;
          final minCell = 12.0;
          final rawCell =
              weekCount <= 0 ? maxCell : (availableGridWidth - (weekCount - 1) * gap) / weekCount;
          needsScroll = rawCell < minCell;
          cell = needsScroll ? minCell : rawCell.clamp(minCell, maxCell);
          gridWidth = needsScroll ? (weekCount * cell + (weekCount - 1) * gap) : availableGridWidth;
        } else {
          cell = 18.0;
          needsScroll = intrinsicGridWidth > availableGridWidth;
          gridWidth = weekCount * cell + (weekCount - 1) * gap;
        }

        final labelCol = Column(
          children: List.generate(7, (i) {
            final weekday = i + 1; // Mon=1..Sun=7
            return SizedBox(
              width: labelWidth,
              height: cell + gap,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  weekdayLabel(weekday, compact: !isDashboardDesktop),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            );
          }),
        );

        final monthRow = SizedBox(
          width: gridWidth,
          height: monthRowHeight,
          child: Row(
            mainAxisAlignment: needsScroll ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
            children: List.generate(weekCount, (idx) {
              final w = monthLabelCell(cell, idx);
              return needsScroll
                  ? Padding(padding: EdgeInsets.only(right: idx == weekCount - 1 ? 0 : gap), child: w)
                  : w;
            }),
          ),
        );

        final weeksRow = SizedBox(
          width: gridWidth,
          child: Row(
            mainAxisAlignment: needsScroll ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weekCount, (idx) {
              final col = weekColumn(cell, weeks[idx]);
              return needsScroll
                  ? Padding(padding: EdgeInsets.only(right: idx == weekCount - 1 ? 0 : gap), child: col)
                  : col;
            }),
          ),
        );

        final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                const SizedBox(width: labelWidth + labelGap),
                monthRow,
            ],
          ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelCol,
                const SizedBox(width: labelGap),
                weeksRow,
              ],
                ),
          ],
        );

        // Desktop: only scroll when needed.
        // Mobile: always wrap in horizontal scroll so content never gets squished.
        if (!needsScroll && isDashboardDesktop) return content;

        // #region agent log
        AgentLogger.log({
          'sessionId': 'debug-session',
          'runId': 'pixel9pro-pre',
          'hypothesisId': 'H1',
          'location': 'shared/search_analytics_page.dart:_buildDailyHeatmap.scrollWrap',
          'message': 'DUH uses horizontal scroll wrapper',
          'data': {
            'needsScroll': needsScroll,
            'gridWidth': gridWidth,
            'cell': cell,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // #endregion

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: labelWidth + labelGap + gridWidth,
            child: content,
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _prepareSearchList(dynamic rawData) {
    final list = <Map<String, dynamic>>[];
    if (rawData is Iterable) {
      for (final item in rawData) {
        if (item is! Map) continue;
        final term = (item['term'] ?? '').toString();
        if (term.isEmpty) continue;
        final dynamic rawCount = item['count'];
        final count = rawCount is int ? rawCount : int.tryParse(rawCount?.toString() ?? '') ?? 0;
        list.add({'term': term, 'count': count});
      }
    }

    if (_searchSortMode == SearchSortMode.alphabetical) {
      list.sort((a, b) => (a['term'] as String).toLowerCase().compareTo((b['term'] as String).toLowerCase()));
    } else {
      list.sort((a, b) {
        final countCompare = (b['count'] as int).compareTo(a['count'] as int);
        if (countCompare != 0) return countCompare;
        return (a['term'] as String).toLowerCase().compareTo((b['term'] as String).toLowerCase());
      });
    }
    return list;
  }

  List<Map<String, dynamic>> _prepareMissingWords(List<Map<String, dynamic>> rawData) {
    final list = List<Map<String, dynamic>>.from(rawData);
    if (_searchSortMode == SearchSortMode.alphabetical) {
      list.sort((a, b) => (a['term'] ?? '').toString().toLowerCase().compareTo((b['term'] ?? '').toString().toLowerCase()));
    } else {
      list.sort((a, b) {
        final countCompare = ((b['count'] as int? ?? 0)).compareTo(a['count'] as int? ?? 0);
        if (countCompare != 0) return countCompare;
        return (a['term'] ?? '').toString().toLowerCase().compareTo((b['term'] ?? '').toString().toLowerCase());
      });
    }
    return list;
  }

  List<Map<String, dynamic>> _prepareCategoryList(List<Map<String, dynamic>> rawData) {
    final list = List<Map<String, dynamic>>.from(rawData);
    if (_searchSortMode == SearchSortMode.alphabetical) {
      list.sort((a, b) => (a['category'] ?? '').toString().toLowerCase().compareTo((b['category'] ?? '').toString().toLowerCase()));
    } else {
      list.sort((a, b) {
        final countCompare = ((b['count'] as int? ?? 0)).compareTo(a['count'] as int? ?? 0);
        if (countCompare != 0) return countCompare;
        return (a['category'] ?? '').toString().toLowerCase().compareTo((b['category'] ?? '').toString().toLowerCase());
      });
    }
    return list;
  }

  Future<void> _copyMissingWords(List<String> words) async {
    if (words.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: words.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing words copied to clipboard')),
    );
  }

  Future<void> _confirmMaintenanceAction({required bool clearOlderThanYear}) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Search Data'),
            content: const Text('Are you sure you want to delete this data? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Confirm Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isClearing = true);
    try {
      if (clearOlderThanYear) {
        await SearchTrackingService().clearAnalyticsOlderThan(const Duration(days: 365));
      } else {
        await SearchTrackingService().clearAllAnalytics();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(clearOlderThanYear ? 'Deleted entries older than 365 days' : 'All analytics data cleared')),
      );
      setState(_loadData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear analytics data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  Widget _buildAccordionPanel({
    required ThemeData theme,
    required String panelKey,
    required String title,
    required Widget child,
    IconData? icon,
    String? subtitle,
    Widget? titleWidget,
  }) {
    final radius = BorderRadius.circular(12);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: titleWidget ?? Text(title),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: _panelBodyHeightFor(context),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

