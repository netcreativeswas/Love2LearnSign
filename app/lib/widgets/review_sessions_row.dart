import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:love_to_learn_sign/video_viewer_page.dart';
import 'package:love_to_learn_sign/services/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:love_to_learn_sign/l10n/dynamic_l10n.dart';
import 'package:provider/provider.dart';
import 'package:love_to_learn_sign/services/favorites_repository.dart';
import 'package:love_to_learn_sign/flashcard_page.dart';
import 'package:love_to_learn_sign/theme.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:love_to_learn_sign/tenancy/tenant_scope.dart';


/// Row of upcoming review sessions with an integrated bottom drawer that lists words.
///
/// Props:
///  - [reviewBoxWordsByDay]: map of date -> list of wordIds to review
///  - [reviewSortByVolume]: current sort mode flag (true = by volume, false = by date)
///  - [onToggleSort]: callback to request toggling sort mode. Receives the next value.
///  - [onDeleteSession]: callback to delete a review session for a specific date.
///  - [favoritesRepository]: optional. If null, will be taken from Provider.
class ReviewSessionsRow extends StatefulWidget {
  final Map<DateTime, List<String>> reviewBoxWordsByDay;
  final bool reviewSortByVolume;
  final Future<void> Function(bool nextValue) onToggleSort;
  final Future<void> Function(DateTime date)? onDeleteSession;
  final FavoritesRepository? favoritesRepository;
  final VoidCallback? onAfterReview;

  const ReviewSessionsRow({
    Key? key,
    required this.reviewBoxWordsByDay,
    required this.reviewSortByVolume,
    required this.onToggleSort,
    this.onDeleteSession,
    this.favoritesRepository,
    this.onAfterReview,
  }) : super(key: key);

  @override
  State<ReviewSessionsRow> createState() => _ReviewSessionsRowState();
}

class _ReviewSessionsRowState extends State<ReviewSessionsRow> {
  DateTime? _selectedDay;
  List<String> _selectedDayWords = const [];

  FavoritesRepository get _favRepo =>
      widget.favoritesRepository ?? context.read<FavoritesRepository>();

  List<MapEntry<DateTime, List<String>>> _sortedEntries() {
    final entries = widget.reviewBoxWordsByDay.entries.toList();

    // Normalize "today" to midnight for accurate whole-day comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Remove items that are more than 10 days overdue
    entries.removeWhere((e) {
      final d = DateTime(e.key.year, e.key.month, e.key.day);
      final diff = d.difference(today).inDays; // negative = overdue
      return diff < -2; // drop anything overdue by more than 10 days
    });

    if (widget.reviewSortByVolume) {
      entries.sort((a, b) => b.value.length.compareTo(a.value.length));
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }
    return entries;
  }

  void _openDrawerFor(DateTime day, List<String> words) {
    setState(() {
      _selectedDay = day;
      _selectedDayWords = List<String>.from(words);
    });
    _showDraggableDrawer();
  }

  Widget _buildThumbnail(String? thumbnailUrl, BuildContext context, {double size = 56}) {
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              color: Theme.of(context).colorScheme.surface3,
              child: Image.asset(
                'assets/videoLoadingPlaceholder.webp',
                width: size,
                height: size,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Image.network(
              thumbnailUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.asset(
          'assets/videoLoadingPlaceholder.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      );
    }
  }

  void _showDraggableDrawer() {
    if (!mounted || _selectedDay == null) return;
    final day = _selectedDay!;
    final words = _selectedDayWords;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final tenantId = context.read<TenantScope>().tenantId;
            Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchDocs(List<String> allIds) async {
              final chunks = <List<String>>[];
              for (int i = 0; i < allIds.length; i += 10) {
                chunks.add(allIds.sublist(i, (i + 10 > allIds.length) ? allIds.length : i + 10));
              }
              final snaps = await Future.wait(chunks.map((chunk) =>
                  TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
                      .where(FieldPath.documentId, whereIn: chunk)
                      .get()));
              final docs = snaps.expand((s) => s.docs).toList();
              // Preserve original order
              docs.sort((a, b) => words.indexOf(a.id).compareTo(words.indexOf(b.id)));
              return docs;
            }

            String _dayLabel(DateTime d) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final onlyDay = DateTime(d.year, d.month, d.day);
              final diff = onlyDay.difference(today).inDays;
              if (diff == 0) return S.of(context)!.today;
              if (diff > 0) return S.of(context)!.inDays(diff);
              return S.of(context)!.overdue;
            }

            return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future: _fetchDocs(words),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final docs = snap.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              S.of(context)!.signsToReview(docs.length, _dayLabel(day)),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        itemBuilder: (context, i) {
                          final d = docs[i];
                          final data = d.data();
                          final english = (data['english'] ?? '').toString();
                          final bengali = (data['bengali'] ?? '').toString();

                          // thumbnail extraction
                          String? thumbnailUrl;
                          final variants = data['variants'] as List?;
                          if (variants != null && variants.isNotEmpty) {
                            final v0 = variants[0] as Map<String, dynamic>;
                            final small = (v0['videoThumbnailSmall'] ?? '').toString();
                            final original = (v0['videoThumbnail'] ?? '').toString();
                            thumbnailUrl = small.isNotEmpty ? small : (original.isNotEmpty ? original : null);
                          }

                          final leading = _buildThumbnail(thumbnailUrl, context, size: 45);

                          final isFav = _favRepo.contains(d.id);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: leading,
                            title: Text(
                              english,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              bengali,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 30,
                                  tooltip: S.of(context)!.play,
                                  icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => VideoViewerPage(wordId: d.id)),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: isFav ? S.of(context)!.unfavorite : S.of(context)!.favorite,
                                  icon: Icon(
                                    isFav ? IconlyBold.heart : IconlyLight.heart,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    setState(() { _favRepo.toggle(d.id); });
                                  },
                                ),
                                IconButton(
                                  tooltip: S.of(context)!.share,
                                  icon: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                                  onPressed: () async {
                                    final scope = context.read<TenantScope>();
                                    await ShareService.shareVideo(
                                      d.id,
                                      english: english,
                                      bengali: bengali,
                                      tenantId: scope.tenantId,
                                      signLangId: scope.signLangId,
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => VideoViewerPage(wordId: d.id)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      // reset local selection when sheet closes
      if (mounted) {
        setState(() {
          _selectedDay = null;
          _selectedDayWords = const [];
        });
      }
    });
  }

  Future<void> _navigateToFlashcardPage(BuildContext context, DateTime date, List<String> words) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardPage(
          numCards: words.length,
          contentChoice: 'review_existing',
          startingPoint: false,
          reviewWordIds: List<String>.from(words),
        ),
      ),
    );
    if (!mounted) return;
    // Ask parent to refresh its data (it will requery the service/FutureBuilder)
    widget.onAfterReview?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviewBoxWordsByDay.isEmpty) return const SizedBox.shrink();

    final entries = _sortedEntries();
    
    // Hide the entire section if there are no entries after filtering
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context)!.reviewBox,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<bool>(
                  tooltip: '',
                  initialValue: widget.reviewSortByVolume,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  onSelected: (value) async {
                    await widget.onToggleSort(value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: false,
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(S.of(context)!.sortByDate, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: true,
                      child: Row(
                        children: [
                          Icon(Icons.format_list_numbered,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(S.of(context)!.sortByVolume, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.surfaceVariant),
                      color: Theme.of(context)
                          .scaffoldBackgroundColor, // requested background
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          widget.reviewSortByVolume ? S.of(context)!.sortByVolume : S.of(context)!.sortByDate,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final day = entry.key;
              final words = entry.value;
              // Calculate days difference and display string
              String getDayLabel(DateTime day) {
                final now = DateTime.now();
                // Remove time part for comparison
                final today = DateTime(now.year, now.month, now.day);
                final entryDay = DateTime(day.year, day.month, day.day);
                final diff = entryDay.difference(today).inDays;
                if (diff == 0) {
                  return S.of(context)!.today;
                } else                 if (diff > 0) {
                  return S.of(context)!.inDays(diff);
                } else {
                  return S.of(context)!.overdue;
                }
              }
              bool isUrgent(DateTime d) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final entryDay = DateTime(d.year, d.month, d.day);
                final diff = entryDay.difference(today).inDays;
                return diff <= 0; // today or overdue
              }
              return SizedBox(
                width: 110,
                child: GestureDetector(
                  onTap: () => _openDrawerFor(day, words),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Overlay menu in top right - positioned at the edge
                        Positioned(
                          top: -10,
                          right: -20, // Compensate for Container's horizontal padding of 10px
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(), // Remove default button constraints
                            icon: Icon(Icons.more_vert, size: 20, color: Colors.grey),
                            color: Theme.of(context).scaffoldBackgroundColor,
                            onSelected: (value) async {
                              if (value == 'delete' && widget.onDeleteSession != null) {
                                await widget.onDeleteSession!(day);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      S.of(context)!.delete,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Main content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(
                              builder: (context) {
                                final dayLabel = getDayLabel(day);
                                final isOverdue = dayLabel == S.of(context)!.overdue;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOverdue
                                        ? Colors.red  // Red for overdue
                                        : Theme.of(context).colorScheme.secondary,  // Orange for today/future
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    dayLabel,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: isOverdue
                                              ? Colors.white  // White text on red background
                                              : Theme.of(context).colorScheme.onSecondary,  // White text on orange background
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${words.length}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  S.of(context)!.signCount(words.length),
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: GestureDetector(
                                onTap: () => _navigateToFlashcardPage(context, day, words),
                                child: isUrgent(day)
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondary, // orange-like
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          S.of(context)!.reviewNow,
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSecondary, // white text on colored bg
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent, // no background
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          S.of(context)!.reviewNow,
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.primary, // primary text
                                                decoration: TextDecoration.underline, // underlined
                                              ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}