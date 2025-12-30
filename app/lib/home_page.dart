import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/dynamic_l10n.dart';
import 'locale_provider.dart';
import 'tenancy/tenant_scope.dart';
import 'widgets/main_app_bar.dart';
import 'widgets/app_language_setup.dart';
import 'widgets/main_btm_nav_bar.dart';
import 'widgets/main_drawer.dart';

import 'widgets/review_sessions_row.dart';
import 'dictionary_page.dart';
import 'game_master.dart';
import 'theme.dart';
import 'video_viewer_page.dart';
import 'donation.dart';
import 'settings_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'services/favorites_repository.dart';
import 'services/share_utils.dart';
import 'services/spaced_repetition_service.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;


class HomePage extends StatefulWidget {
  final String? countryCode;
  const HomePage({
    super.key,
    this.countryCode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _handledInitialIndex = false;
  bool _consumedPendingNotification = false;
  bool _pendingOpenQuizOptions = false;

  DateTime? _lastDay;

  // ReviewBox sorting: false = Chronologique (date), true = Par volume
  bool _reviewSortByVolume = false;
  final Map<DateTime, List<String>> reviewBoxWordsByDay = {}; // TODO: Replace with actual review data source

  Future<void> _openUrl(Uri uri) async {
    bool launched = false;

    // Try external app (preferred)
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    // Fallback to in‑app browser view for http/https
    if (!launched && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        launched = false;
      }
    }

    // Last‑chance fallback
    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        launched = false;
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open link. Please check your browser.'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  Future<void> _openEmail(Uri emailUri) async {
    bool launched = false;

    // Prefer external mail app (shows chooser if multiple)
    try {
      launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    // Fallback to platform default
    if (!launched) {
      try {
        launched = await launchUrl(emailUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        launched = false;
      }
    }

    if (!launched && mounted) {
      // Likely no mail app installed (common in emulators)
      await Clipboard.setData(ClipboardData(text: emailUri.path));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No email app found. Address copied to clipboard.'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  Future<void> _loadReviewSessionsData() async {
    try {
      final mapped = await SpacedRepetitionService().getWordsGroupedByDay();
      if (!mounted) return;
      setState(() {
        reviewBoxWordsByDay
          ..clear()
          ..addAll(mapped);
      });
    } catch (e) {
      debugPrint('Failed to load review sessions: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastDay = DateTime.now();
    _loadReviewSortPreference();
    _loadReviewSessionsData();
    // Consume any pending notification payload saved during cold start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_consumedPendingNotification) return;
      final prefs = await SharedPreferences.getInstance();
      final payload = prefs.getString('pendingNotificationPayload');
      if (payload != null && payload.trim().startsWith('{')) {
        try {
          final data = jsonDecode(payload);
          final String? route = data['route'] as String?;
          final Map<String, dynamic>? args = (data['args'] as Map?)?.cast<String, dynamic>();
          if (route != null && args != null) {
            _consumedPendingNotification = true;
            await prefs.remove('pendingNotificationPayload');
            if (!mounted) return;
            Navigator.of(context).pushNamed(route, arguments: args);
          }
        } catch (_) {
          // ignore bad payload
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastDay == null || now.year != _lastDay!.year || now.month != _lastDay!.month || now.day != _lastDay!.day) {
        _loadReviewSessionsData();
      }
      _lastDay = now;
    }
  }

  void _loadReviewSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reviewSortByVolume = prefs.getBool('reviewSortByVolume') ?? false;
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
      // Already on DictionaryPage
        break;
      case 1:
        _navigateWithoutTransition(
          context,
          DictionaryPage(

            countryCode: widget.countryCode,
          ),
        );
        break;
      case 2:
        final bool openQuizOptions = _pendingOpenQuizOptions;
        _pendingOpenQuizOptions = false;
        _navigateWithoutTransition(
          context,
          GameMasterPage(

            countryCode: widget.countryCode,
            showQuizOptionsOnStart: openQuizOptions,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // One-time handling of initial tab index passed via route arguments (e.g., {'initialIndex': 2})
    if (!_handledInitialIndex) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final int? idx = args['initialIndex'] is int ? args['initialIndex'] as int : null;
        if (args['openQuizOptions'] == true) {
          _pendingOpenQuizOptions = true;
        }
        _handledInitialIndex = true;
        if (idx != null && idx != _currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onTabSelected(idx);
          });
        }
      } else {
        _handledInitialIndex = true;
      }
    }
    final locale = Provider.of<LocaleProvider>(context).locale;
    final tenantId = context.watch<TenantScope>().tenantId;
    final bool showDonationIcon =
        (widget.countryCode != 'BD') &&
        (locale.languageCode != 'bn') &&
        (locale.countryCode != 'BD');
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final bool isLoggedIn = snapshot.hasData;
        final String userRole = 'editor'; // Placeholder, à remplacer par ta logique
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: MainAppBar(
              title: S.of(context)!.tabHome,
              countryCode: widget.countryCode,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLanguageSetup(),
                  SizedBox(width: 12),
                  SettingsButton(),
                ],
              ),
            ),
          ),
          endDrawer: MainDrawerWidget(
            countryCode: widget.countryCode ?? '',
            checkedLocation: true,
            isLoggedIn: isLoggedIn,
            userRole: userRole,
            deviceLanguageCode: locale.languageCode,
            deviceRegionCode: locale.countryCode,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0), // Adjust if you want global horizontal padding
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          Text(
                             S.of(context)!.welcomeTitle,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8), // Some space between the lines
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/l2l-logo-foreground.png',
                                width: 30,
                                height: 30,
                              ),
                              SizedBox(width: 8),
                              Text(
                                 S.of(context)!.headlineTitle, // <--- New line
                                style: Theme.of(context).textTheme.headlineMedium, // Or another style if you prefer
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Section title
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 10, top: 20, bottom: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context)!.favoritesVideos,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          tooltip: 'Info',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(S.of(context)!.howToReorderFavorites),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(S.of(context)!.longPressThumbnail),
                                      SizedBox(height: 6),
                                      Text(S.of(context)!.dragLeftRight),
                                      SizedBox(height: 6),
                                      Text(S.of(context)!.releaseToDrop),
                                      SizedBox(height: 6),
                                      Text(S.of(context)!.newFavoritesAdded),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(S.of(context)!.gotIt),
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
                  // Slider of favorites (refactored)
                  SizedBox(
                    height: 125,
                    child: Consumer<FavoritesRepository>(
                      builder: (context, repo, _) {
                        final ids = repo.value;
                        if (ids.isEmpty) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              // 3 tiles (70) + gaps (5,5) + side paddings (15,15) = 250
                              width: 250,
                              child: Stack(
                                children: [
                                  // Three placeholder videos with 50% opacity
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: List.generate(3, (index) {
                                      return Container(
                                        width: 70,
                                        margin: EdgeInsets.only(left: index == 0 ? 15 : 5, right: index == 2 ? 15 : 0),
                                        child: Opacity(
                                          opacity: 0.5,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(3),
                                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: Image.asset(
                                                    'assets/videoLoadingPlaceholder.webp',
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.only(top: 3.0),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Container(
                                                        height: 10,
                                                        width: 50,
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                                          borderRadius: BorderRadius.circular(2),
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
                                    }),
                                  ),
                                  // Text centered over the three placeholders
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        S.of(context)!.noFavorites,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return StreamBuilder(
                          stream: TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
                            .where(FieldPath.documentId, whereIn: ids.take(10).toList())
                            .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                            final docs = snapshot.data!.docs
                              .where((doc) => ids.contains(doc.id))
                              .toList()
                              ..sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
                            if (docs.isEmpty) {
                              return Center(child: Text(S.of(context)!.noFavorites));
                            }
                            return ReorderableListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              buildDefaultDragHandles: false, // we'll start drag on long‑press of the card
                              itemCount: docs.length,
                              proxyDecorator: (child, index, animation) {
                                final data = docs[index].data();
                                final english = data['english'] ?? '';
                                final bengali = data['bengali'] ?? '';

                                // Build a drag-optimized thumbnail: only the image (or placeholder) + texts, no bg, no shadows
                                final variants = data['variants'] as List?;
                                String? thumbnailUrl;
                                if (variants != null && variants.isNotEmpty) {
                                  final map = variants[0] as Map<String, dynamic>;
                                  final small = (map['videoThumbnailSmall'] ?? '').toString();
                                  final original = (map['videoThumbnail'] ?? '').toString();
                                  thumbnailUrl = small.isNotEmpty ? small : (original.isNotEmpty ? original : null);
                                }

                                Widget thumb;
                                if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
                                  thumb = Image.network(
                                    thumbnailUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  );
                                } else {
                                  // Fallback to the same asset but without any colored container
                                  thumb = Image.asset(
                                    'assets/videoLoadingPlaceholder.webp',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  );
                                }

                                return Material(
                                  type: MaterialType.transparency, // no white card, no elevation
                                  child: SizedBox(
                                    width: 70,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        // No shadow, no bg, only the miniature
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(3),
                                          child: thumb,
                                        ),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(top: 3.0),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                            child: _FavoriteWordLabels(
                                              english: _formatEnglishLabel(english),
                                              bengali: bengali,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              onReorder: (oldIndex, newIndex) {
                                // Standard fix for Flutter's newIndex semantics
                                if (newIndex > oldIndex) newIndex -= 1;

                                final repo = context.read<FavoritesRepository>();
                                final currentIds = List<String>.from(repo.value);

                                // Get the ID being moved
                                final movedId = docs[oldIndex].id;

                                // Simply remove and insert at the new position in the current list
                                final fromIndex = currentIds.indexOf(movedId);
                                if (fromIndex == -1) return; // safety check

                                currentIds.removeAt(fromIndex);
                                currentIds.insert(newIndex, movedId);

                                // Update the repository with the new order
                                repo.clear(); // Clear all
                                for (final id in currentIds) {
                                  repo.add(id); // Add in new order
                                }
                              },
                              itemBuilder: (context, i) {
                                final data = docs[i].data();
                                final english = data['english'] ?? '';
                                final bengali = data['bengali'] ?? '';
                                final englishLabel = _formatEnglishLabel(english);

                                // --- Begin thumbnail logic (unchanged) ---
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
                                        width: 70,
                                        height: 70,
                                        color: Colors.transparent,
                                        child: Image.asset('assets/videoLoadingPlaceholder.webp', width: 70, height: 70, fit: BoxFit.cover),
                                      ),
                                      Image.network(
                                        thumbnailUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                      ),
                                    ],
                                  );
                                } else {
                                  thumbnailWidget = Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.transparent,
                                    child: Image.asset('assets/videoLoadingPlaceholder.webp', width: 70, height: 70, fit: BoxFit.cover),
                                  );
                                }
                                // --- End thumbnail logic ---

                                // Wrap the original tile in a ReorderableDelayedDragStartListener to start drag on long‑press
                                final tile = Padding(
                                  key: ValueKey(docs[i].id),
                                  padding: EdgeInsets.only(left: i == 0 ? 15 : 5, right: i == docs.length - 1 ? 15 : 0),
                                  child: ReorderableDelayedDragStartListener(
                                    index: i,
                                    child: SizedBox(
                                      width: 70,
                                      child: Stack(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => VideoViewerPage(
                                                    wordId: docs[i].id,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(3),
                                                    // Keep shadow only when NOT dragging (drag feedback handled by proxyDecorator)
                                                    boxShadow: const [],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(3),
                                                    child: thumbnailWidget,
                                                  ),
                                                ),
                                                Container(
                                                  alignment: Alignment.centerLeft,
                                                  padding: const EdgeInsets.only(top: 3.0),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                    child: _FavoriteWordLabels(
                                                      english: englishLabel,
                                                      bengali: bengali,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Three-dot menu remains tappable without starting drag (long-press starts drag)
                                          Positioned(
                                            top: -10,
                                            right: -15,
                                            child: _MiniatureMenu(
                                              wordId: docs[i].id,
                                              english: english,
                                              bengali: bengali,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                return tile;
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ReviewBox Section (Refactored)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ReviewSessionsRow(
                      reviewBoxWordsByDay: reviewBoxWordsByDay,
                      reviewSortByVolume: _reviewSortByVolume,
                      onToggleSort: (value) async {
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool('reviewSortByVolume', value);
                        setState(() => _reviewSortByVolume = value);
                      },
                      onDeleteSession: (date) async {
                        await SpacedRepetitionService().deleteWordsForDate(date);
                        await _loadReviewSessionsData();
                      },
                      // Refresh the Review Box after returning from Flashcards
                      onAfterReview: () async {
                        await _loadReviewSessionsData();
                      },
                    ),
                  ),
                  
                  // "What's New" Section Title
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                         S.of(context)!.whatsNew,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  // Slider of latest videos
                  SizedBox(
                    height: 125,
                    child: StreamBuilder(
                      stream: TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
                          .orderBy('addedAt', descending: true)
                          .limit(15)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs;
                        
                        // Get user roles for filtering restricted content
                        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
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
                        
                        // Filter out restricted videos
                        final filteredDocs = docs.where((doc) => !shouldFilterVideo(doc)).toList();
                        
                        if (filteredDocs.isEmpty) {
                           return Center(child: Text(S.of(context)!.noNewVideos));
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, i) {
                            final data = filteredDocs[i].data();
                            final english = data['english'] ?? '';
                            final bengali = data['bengali'] ?? '';
                            // --- Begin thumbnail logic ---
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
                                    width: 70,
                                    height: 70,
                                    color: Theme.of(context).colorScheme.surface3,
                                    child: Image.asset('assets/videoLoadingPlaceholder.webp', width: 70, height: 70, fit: BoxFit.cover),
                                  ),
                                  Image.network(
                                    thumbnailUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ],
                              );
                            } else {
                              thumbnailWidget = Container(
                                width: 70,
                                height: 70,
                                color: Theme.of(context).colorScheme.surface3,
                                child: Image.asset('assets/videoLoadingPlaceholder.webp', width: 70, height: 70, fit: BoxFit.cover),
                              );
                            }
                            // --- End thumbnail logic ---
                            return Container(
                              width: 70,
                              margin: EdgeInsets.only(left: i == 0 ? 15 : 5, right: i == filteredDocs.length - 1 ? 15 : 0),
                              child: Stack(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VideoViewerPage(
                                            wordId: filteredDocs[i].id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.12),
                                                spreadRadius: 0,
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(3),
                                            child: thumbnailWidget,
                                          ),
                                        ),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(top: 3.0),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final locale = Localizations.localeOf(context).languageCode;
                                                    // Capitalize first letter of English word
                                                    final englishCapitalized = english.isNotEmpty
                                                        ? english[0].toUpperCase() +
                                                            (english.length > 1 ? english.substring(1) : '')
                                                        : english;
                                                    final topText = locale == 'bn' ? bengali : englishCapitalized;
                                                    final bottomText = locale == 'bn' ? englishCapitalized : bengali;

                                                    final textTheme = Theme.of(context).textTheme;
                                                    final topStyle = (locale == 'bn'
                                                            ? textTheme.bodyMedium
                                                            : textTheme.bodySmall)
                                                        ?.copyWith(fontWeight: FontWeight.bold);

                                                    return Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          topText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: topStyle,
                                                        ),
                                                        Text(
                                                          bottomText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: textTheme.bodySmall,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: -10,
                                    right: -15,
                                    child: _MiniatureMenu(
                                      wordId: filteredDocs[i].id,
                                      english: english,
                                      bengali: bengali,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // --- Online Section ---
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                         S.of(context)!.online,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OnlineBox(
                              iconWidget: Image.asset('assets/icons/Net-creative-logo-white-noshadow.png', width: 45, height: 45),
                               label: S.of(context)!.website,
                              color: Theme.of(context).colorScheme.onSurface2,
                              onTap: () async {
                                await _openUrl(Uri.parse('https://netcreative-swas.net'));
                              },
                            ),
                            
                            SizedBox(width: 8),
                            _OnlineBox(
                              iconWidget: Icon(FontAwesomeIcons.facebook, size: 38, color: Theme.of(context).colorScheme.onSurface2),
                               label: S.of(context)!.facebook,
                              color: Theme.of(context).colorScheme.onSurface2,
                              onTap: () async {
                                await _openUrl(Uri.parse('https://www.facebook.com/profile.php?id=61579770276676'));
                              },
                            ),
                            if (showDonationIcon) ...[
                              SizedBox(width: 8),
                              _OnlineBox(
                                iconWidget: Icon(FontAwesomeIcons.gift, size: 34, color: Theme.of(context).colorScheme.onSurface2),
                                 label: S.of(context)!.donation,
                                color: Theme.of(context).colorScheme.onSurface2,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DonationPage()),
                                  );
                                },
                              ),
                            ],
                            SizedBox(width: 8),
                            _OnlineBox(
                              iconWidget: Icon(IconlyLight.message, size: 38, color: Theme.of(context).colorScheme.onSurface2),
                               label: S.of(context)!.contactUs,
                              color: Theme.of(context).colorScheme.onSurface2,
                              onTap: () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'info@netcreative-swas.net',
                                  query: Uri(
                                    queryParameters: <String, String>{
                                      'subject': 'Sending from Love to Learn Sign app',
                                      'body': 'Hello Luke, I want some information regarding....',
                                    },
                                  ).query,
                                );
                                await _openEmail(emailUri);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // You can add more widgets below for your home page content
                ],
              ),
            ),
          ),
          bottomNavigationBar: MainBtmNavBar(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
          ),
        );
      },
    );
  }
}

class _OnlineBox extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _OnlineBox({
    required this.iconWidget,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Theme.of(context).colorScheme.surface3,
              ),
              child: Center(
                child: iconWidget,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.settings),
      tooltip: S.of(context)!.settings,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
      },
    );
  }
}

bool _isBengaliLocale(BuildContext context) =>
    Localizations.localeOf(context).languageCode.toLowerCase() == 'bn';

String _formatEnglishLabel(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

class _FavoriteWordLabels extends StatelessWidget {
  const _FavoriteWordLabels({
    required this.english,
    required this.bengali,
  });

  final String english;
  final String bengali;

  @override
  Widget build(BuildContext context) {
    final isBn = _isBengaliLocale(context);
    final topText = isBn ? bengali : english;
    final bottomText = isBn ? english : bengali;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          topText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (isBn ? Theme.of(context).textTheme.bodyMedium : Theme.of(context).textTheme.bodySmall)?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          bottomText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MiniatureMenu extends StatelessWidget {
  final String wordId;
  final String english;
  final String bengali;
  const _MiniatureMenu({
    required this.wordId,
    required this.english,
    required this.bengali,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MiniAction>(
      padding: EdgeInsets.zero,
      tooltip: '',
      // Open the menu more tightly aligned to the icon (closer)
      offset: const Offset(-20, 30),
      color: Theme.of(context).scaffoldBackgroundColor,
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 210),
      icon: const _ThreeDotsIcon(),
      onSelected: (value) async {
        switch (value) {
          case _MiniAction.share:
            final scope = context.read<TenantScope>();
            final uiLocale = context.read<LocaleProvider>().locale.languageCode;
            await ShareService.shareVideo(
              wordId,
              english: english,
              bengali: bengali,
              tenantId: scope.tenantId,
              signLangId: scope.signLangId,
              uiLocale: uiLocale,
            );
            break;
          case _MiniAction.toggleFavorite:
            final repo = context.read<FavoritesRepository>();
            final isFav = repo.contains(wordId);
            if (isFav) {
              repo.remove(wordId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context)!.removedFromFavorites)),
              );
            } else {
              repo.add(wordId);
            }
            break;
        }
      },
      itemBuilder: (context) {
        final isFav = context.read<FavoritesRepository>().contains(wordId);
        return [
          PopupMenuItem(
            value: _MiniAction.share,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.share, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                  S.of(context)!.share,
                    softWrap: true,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: _MiniAction.toggleFavorite,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isFav ? IconlyBold.heart : IconlyLight.heart,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                  isFav ? S.of(context)!.unfavorite : S.of(context)!.favorite,
                    softWrap: true,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }
}

enum _MiniAction { share, toggleFavorite }

class _ThreeDotsIcon extends StatelessWidget {
  const _ThreeDotsIcon();
  @override
  Widget build(BuildContext context) {
    final List<Widget> dots = List.generate(3, (index) {
      return Container(
        width: 4,
        height: 4,
        margin: EdgeInsets.only(top: index == 0 ? 0 : 3),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 2,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
      );
    });
    return Column(mainAxisSize: MainAxisSize.min, children: dots);
  }
}
