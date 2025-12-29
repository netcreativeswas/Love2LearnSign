import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'l10n/dynamic_l10n.dart';
import 'locale_provider.dart';
import 'package:l2l_shared/auth/auth_provider.dart' as app_auth;
import 'services/notification_permission_service.dart';
import 'main.dart' show scheduleDailyTasks;
import 'theme_provider.dart';
import 'widgets/cupertino_sheet_container.dart';
import 'services/cache_service.dart';
import 'services/android_intent_helper.dart';
import 'services/ios_settings_helper.dart';
import 'l10n/dynamic_l10n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'pages/premium_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  int get _learnWordHour12 {
    final h = _learnWordHour % 12;
    return h == 0 ? 12 : h;
  }
  bool? _precacheEnabled;
  bool _loaded = false;
  int _maxCacheSizeMb = 200;
  bool _wifiOnly = false;
  bool _notifyNewWords = true;
  bool _notifyLearnWord = true;
  bool _notifyFlashcardReview = true;
  bool _notificationPermissionGranted = false;
  bool _notificationPermissionChecked = false;
  int? _currentCacheMb;
  int _learnWordHour = 10;
  int _learnWordMinute = 0;
  int _flashReviewHour = 12;
  int _flashReviewMinute = 0;
  List<String> _categories = ['Random'];
  String _selectedCategory = 'Random';
  bool _refreshingCache = false;
  String _appVersion = 'Loading...';
  
  String _prettyCategoryLabel(BuildContext context, String value) {
    if (value == 'Random') {
      return S.of(context)!.randomAllCategories;
    }
    final String locale = Localizations.localeOf(context).languageCode;
    return locale == 'bn' ? translateCategory(context, value) : value;
  }

  @override
  void initState() {
    super.initState();
    NotificationPermissionService.areNotificationsEnabled().then((granted) {
      setState(() {
        _notificationPermissionGranted = granted;
        _notificationPermissionChecked = true;
      });
    });
    _loadPreferences().then((_) {
      _fetchCategories();
    });
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _precacheEnabled = prefs.getBool('precacheEnabled') ?? true;
      _maxCacheSizeMb = prefs.getInt('maxCacheSizeMb') ?? 200;
      _wifiOnly = prefs.getBool('wifiOnly') ?? false;
      _notifyNewWords = prefs.getBool('notifyNewWords') ?? true;
      _notifyLearnWord = prefs.getBool('notifyLearnWord') ?? true;
      _notifyFlashcardReview = prefs.getBool('notifyFlashcardReview') ?? true;
      _learnWordHour = prefs.getInt('learnWordHour') ?? 10;
      _learnWordMinute = prefs.getInt('learnWordMinute') ?? 0;
      _flashReviewHour = prefs.getInt('flashReviewHour') ?? 12;
      _flashReviewMinute = prefs.getInt('flashReviewMinute') ?? 0;
      _selectedCategory = prefs.getString('notificationCategory') ?? 'Random';
      _loaded = true;
    });
    // Fetch cache size after preferences load
    final bytes = await CacheService.instance.getApproxCacheSizeBytes();
    if (mounted) setState(() => _currentCacheMb = (bytes / (1024 * 1024)).round());
  }
  Future<void> _updateNotifyFlashcardReview(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyFlashcardReview', value);
    setState(() => _notifyFlashcardReview = value);
  }

  Future<void> _updateFlashReviewTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flashReviewHour', hour);
    await prefs.setInt('flashReviewMinute', minute);
    setState(() {
      _flashReviewHour = hour;
      _flashReviewMinute = minute;
    });
  }

  Future<void> _fetchCategories() async {
    final snapshot = await TenantDb.concepts(FirebaseFirestore.instance).get();
    final Set<String> catSet = {};
    for (final d in snapshot.docs) {
      final data = d.data();
      final String main = (data['category_main'] ?? '').toString().trim();
      if (main.isNotEmpty) catSet.add(main);
    }
    var cats = catSet.toList()..sort();
    // Filter out restricted JW categories if user lacks 'jw' role
    final roles = context.read<app_auth.AuthProvider>().userRoles;
    final hasJW = roles.contains('jw');
    if (!hasJW) {
      final restricted = {
        'JW Organisation',
        'JW Organization',
        'Biblical Content',
      };
      cats = cats.where((c) => !restricted.contains(c)).toList();
    }
    setState(() {
      _categories = ['Random', ...cats];
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Random';
      }
    });
  }

  Future<void> _updateCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationCategory', category);
    setState(() {
      _selectedCategory = category;
    });
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(200);
    await scheduleDailyTasks(plugin);
  }

  Future<void> _updateLearnWordHour(int hour) async {
    await _updateLearnWordTime(hour, _learnWordMinute);
  }

  Future<void> _updateLearnWordTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('learnWordHour', hour);
    await prefs.setInt('learnWordMinute', minute);
    setState(() {
      _learnWordHour = hour;
      _learnWordMinute = minute;
    });
    final plugin = FlutterLocalNotificationsPlugin();
    // Cancel existing and reschedule
    await plugin.cancel(200);
    await scheduleDailyTasks(plugin);
  }

  Future<void> _updatePrecachePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('precacheEnabled', value);
    setState(() {
      _precacheEnabled = value;
    });
  }

  Future<void> _updateMaxCacheSize(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxCacheSizeMb', value);
    setState(() {
      _maxCacheSizeMb = value;
    });
  }

  Future<void> _updateWifiOnlyPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifiOnly', value);
    setState(() {
      _wifiOnly = value;
    });
  }

  Future<void> _updateNotifyNewWords(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    bool granted = _notificationPermissionGranted;
    if (value && !_notificationPermissionGranted) {
      granted = await NotificationPermissionService.requestPermission();
      setState(() {
        _notificationPermissionGranted = granted;
      });
      // Removed notification permission denied snackbar for Android as per instructions
    }
    await prefs.setBool('notifyNewWords', value);
    setState(() {
      _notifyNewWords = value;
    });
    final plugin = FlutterLocalNotificationsPlugin();
    if (!value) {
      await plugin.cancel(100);
    }
  }

  Future<void> _updateNotifyLearnWord(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    bool granted = _notificationPermissionGranted;
    if (value && !_notificationPermissionGranted) {
      granted = await NotificationPermissionService.requestPermission();
      setState(() {
        _notificationPermissionGranted = granted;
      });
      // Removed notification permission denied snackbar for Android as per instructions
    }
    await prefs.setBool('notifyLearnWord', value);
    setState(() {
      _notifyLearnWord = value;
    });
    if (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
    final plugin = FlutterLocalNotificationsPlugin();
    if (!value) {
      // Cancel the learn-word reminder when disabled
      await plugin.cancel(200);
    } else {
      // When enabled, cancel any existing and reschedule
      await plugin.cancel(200);
      await scheduleDailyTasks(plugin);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        title: Text(
          S.of(context)!.settings,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          const Divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              S.of(context)!.general,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            title: Text(
              S.of(context)!.settingsLanguage,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.settingsLanguageSubtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: GestureDetector(
              onTap: () async {
                final current = Provider.of<LocaleProvider>(context, listen: false).locale;
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (ctx) {
                    return CupertinoSheetContainer(
                      height: 200,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: current.languageCode == 'bn' ? 1 : 0,
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (idx) {
                          final newLocale = idx == 0 ? const Locale('en') : const Locale('bn');
                          Provider.of<LocaleProvider>(ctx, listen: false).setLocale(newLocale);
                          Navigator.of(ctx).pop();
                        },
                        children: const [
                          Center(child: Text('English', style: TextStyle())),
                          Center(child: Text('বাংলা', style: TextStyle())),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Provider.of<LocaleProvider>(context).locale.languageCode == 'bn'
                        ? S.of(context)!.bengali
                        : S.of(context)!.english,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: Text(
              S.of(context)!.darkMode,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.darkMode,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            value: context.watch<ThemeProvider>().mode == ThemeMode.dark,
            onChanged: (value) {
              context.read<ThemeProvider>().setMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
            activeTrackColor: Theme.of(context).colorScheme.secondary,
          ),
          const Divider(),
          // Premium Section
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              S.of(context)!.premiumSectionTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              S.of(context)!.upgradeToPremium,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.removeAdsUnlimitedAccess,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PremiumSettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              S.of(context)!.settingsSectionCachingOptions,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          SwitchListTile(
            title: Text(
              S.of(context)!.preloadVideosTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.preloadVideosSubtitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            value: _precacheEnabled ?? true,
            onChanged: (value) => _updatePrecachePreference(value),
            activeTrackColor: Theme.of(context).colorScheme.secondary,
          ),
          ListTile(
            title: Text(
              S.of(context)!.clearCachedVideosTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.clearCachedVideosSubtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: const Icon(Icons.delete),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    S.of(context)!.dialogClearCacheTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  content: Text(
                    S.of(context)!.dialogClearCacheContent,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Clear',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await CacheService.instance.emptyCache();

                // Refresh current cache size display
                final bytes = await CacheService.instance.getApproxCacheSizeBytes();
                if (!mounted) return;
                setState(() => _currentCacheMb = (bytes / (1024 * 1024)).round());

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      S.of(context)!.snackbarCacheCleared,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF6750A4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )
                );
              }
            },
          ),
          ListTile(
            title: Text(
              S.of(context)!.maxCacheSizeTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.maxCacheSizeSubtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: GestureDetector(
              onTap: () async {
                int temp = _maxCacheSizeMb;
                final result = await showModalBottomSheet<int>(
                  context: context,
                  builder: (ctx) {
                    return CupertinoSheetContainer(
                      height: 200,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: [50, 100, 200, 300, 400, 500].indexOf(temp),
                        ),
                        itemExtent: 32,
                        onSelectedItemChanged: (idx) {
                          temp = [50, 100, 200, 300, 400, 500][idx];
                        },
                        children: [50, 100, 200, 300, 400, 500]
                            .map((s) => Center(
                          child: Text(
                            '$s MB',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        ))
                            .toList(),
                      ),
                    );
                  },
                );
                // Always apply the last-selected temp value on dismiss or selection
                final selectedSize = result ?? temp;
                _updateMaxCacheSize(selectedSize);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_maxCacheSizeMb MB',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: Text(
              S.of(context)!.cacheWifiTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.cacheWifiSubtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            value: _wifiOnly,
            onChanged: (value) => _updateWifiOnlyPreference(value),
            activeTrackColor: Theme.of(context).colorScheme.secondary,
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              S.of(context)!.storageSectionTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          // Storage section reinserted here per new order
          ListTile(
            title: Text(
              S.of(context)!.currentCacheTitle('${_currentCacheMb ?? 0}'),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.currentCacheSubtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: SizedBox(
              width: 40,
              child: Center(
                child: _refreshingCache
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          setState(() => _refreshingCache = true);
                          final bytes = await CacheService.instance.getApproxCacheSizeBytes();
                          if (!mounted) return;
                          setState(() {
                            _currentCacheMb = (bytes / (1024 * 1024)).round();
                            _refreshingCache = false;
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cache size updated')),
                          );
                        },
                      ),
              ),
            ),
          ),

          ListTile(
            title: Text(
              S.of(context)!.openSystemStorageSettings,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.openSystemStorageSettings,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final platform = Theme.of(context).platform;
              try {
                if (platform == TargetPlatform.android) {
                  await AndroidIntentHelper.openAppDetails();
                } else if (platform == TargetPlatform.iOS) {
                  await IOSSettingsHelper.openAppSettings();
                }
              } catch (_) {}
            },
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              S.of(context)!.settingsSectionNotifications,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          _notificationPermissionChecked
              ? SwitchListTile(
                  title: Text(
                    S.of(context)!.notificationNewWordsTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  value: _notifyNewWords,
                  onChanged: (value) => _updateNotifyNewWords(value),
                  activeTrackColor: Theme.of(context).colorScheme.secondary,
                )
              : ListTile(
                  title: Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  subtitle: Center(child: CircularProgressIndicator()),
                ),
          _notificationPermissionChecked
              ? Column(
                  children: [
                    // Flashcard review reminders
                    SwitchListTile(
                      dense: true,
                      title: Text(
                        S.of(context)!.flashcardReminderTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                      value: _notifyFlashcardReview,
                      onChanged: (v) => _updateNotifyFlashcardReview(v),
                      activeTrackColor: Theme.of(context).colorScheme.secondary,
                    ),
                    if (_notifyFlashcardReview)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.only(left: 26.0, right: 16.0),
                        title: Text(
                          S.of(context)!.flashcardReminderTime,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.normal),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_flashReviewHour % 12 == 0 ? 12 : _flashReviewHour % 12).toString()}:${_flashReviewMinute.toString().padLeft(2, '0')} ${_flashReviewHour < 12 ? 'AM' : 'PM'}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: _flashReviewHour, minute: _flashReviewMinute),
                          );
                          if (picked != null) {
                            _updateFlashReviewTime(picked.hour, picked.minute);
                          }
                        },
                      ),
                    SwitchListTile(
                      dense: true,
                      visualDensity: VisualDensity(vertical: -4, horizontal: 0),
                      title: Text(
                         S.of(context)!.notificationLearnWordTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                      value: _notifyLearnWord,
                      onChanged: (value) => _updateNotifyLearnWord(value),
                      activeTrackColor: Theme.of(context).colorScheme.secondary,
                    ),
                    if (_notifyLearnWord)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                S.of(context)!.notificationLearnWordHelp,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_notificationPermissionChecked && _notifyLearnWord)
                      ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0.0),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -4, horizontal: 0),
                            contentPadding: EdgeInsets.only(left: 26.0, right: 16.0),
                            title: Text(
                              S.of(context)!.notificationLearnWordTimeTitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final displayHour12 = _learnWordHour12;
                                    final period = _learnWordHour < 12 ? 'AM' : 'PM';
                                    final minutePadded = _learnWordMinute.toString().padLeft(2, '0');
                                    return Text(
                                      '$displayHour12:$minutePadded $period',
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(color: Theme.of(context).colorScheme.primary),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: _learnWordHour, minute: _learnWordMinute),
                              );
                              if (picked != null) {
                                _updateLearnWordTime(picked.hour, picked.minute);
                              }
                            },
                          ),
                        ),
                        // Category selector with reduced top margin and CupertinoPicker
                        Container(
                          margin: const EdgeInsets.only(top: 0.0),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity(vertical: -4, horizontal: 0),
                            contentPadding: EdgeInsets.only(left: 26.0, right: 16.0),
                            title: Text(
                              S.of(context)!.notificationCategoryTitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _prettyCategoryLabel(context, _selectedCategory),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                            onTap: () async {
                              int tempIndex = _categories.indexOf(_selectedCategory);
                              await showModalBottomSheet<void>(
                                context: context,
                                builder: (ctx) {
                                  return CupertinoSheetContainer(
                                    height: 250,
                                    child: CupertinoPicker(
                                      scrollController: FixedExtentScrollController(initialItem: tempIndex),
                                      itemExtent: 32,
                                      onSelectedItemChanged: (idx) => tempIndex = idx,
                                      children: _categories
                                          .map((cat) => Center(
                                                child: Text(
                                                  _prettyCategoryLabel(context, cat),
                                                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  );
                                },
                              );
                              // After sheet closes, update with last-selected value
                              if (tempIndex >= 0 && tempIndex < _categories.length) {
                                _updateCategory(_categories[tempIndex]);
                              }
                            },
                          ),
                        ),
                      ],
                  ],
                )
              : SizedBox.shrink(),
          
          // Privacy Policy Section
          const Divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              S.of(context)!.privacySectionTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            title: Text(
              S.of(context)!.privacyPolicyTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              S.of(context)!.privacyPolicySubtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: const Icon(Icons.privacy_tip_outlined),
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),
          // About Section
          const Divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text(
              S.of(context)!.aboutSectionTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              S.of(context)!.appVersionTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _appVersion,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            isThreeLine: false,
          ),
          const SizedBox(height: 16), // Extra spacing at the bottom
        ],
      ),
    );
  }
  
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            S.of(context)!.privacyPolicyTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context)!.privacyDialogIntro,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context)!.privacyDialogDataUsageTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointPersonalized),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointAccount),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointPremium),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointAds),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointReminders),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointCaching),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointTracking),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointSearchAnalytics),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointDemographic),
                _buildPolicyPoint(S.of(context)!.privacyDialogPointImprove),
                const SizedBox(height: 16),
                Text(
                  S.of(context)!.privacyDialogThirdPartyTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPolicyPoint(S.of(context)!.privacyDialogThirdPartyFirebase),
                _buildPolicyPoint(S.of(context)!.privacyDialogThirdPartyAdmob),
                _buildPolicyPoint(S.of(context)!.privacyDialogThirdPartyStores),
                const SizedBox(height: 16),
                Text(
                  S.of(context)!.privacyDialogRightsTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPolicyPoint(S.of(context)!.privacyDialogRightsAccess),
                _buildPolicyPoint(S.of(context)!.privacyDialogRightsCancel),
                _buildPolicyPoint(S.of(context)!.privacyDialogRightsAds),
                _buildPolicyPoint(S.of(context)!.privacyDialogRightsDelete),
                const SizedBox(height: 16),
                Text(
                  S.of(context)!.privacyDialogPremiumTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPolicyPoint(S.of(context)!.privacyDialogPremiumNoAds),
                _buildPolicyPoint(S.of(context)!.privacyDialogPremiumPayment),
                _buildPolicyPoint(S.of(context)!.privacyDialogPremiumNoCard),
                const SizedBox(height: 16),
                Text(
                  S.of(context)!.privacyDialogFullPolicy,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('https://love2learnsign.com/privacy');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Text(
                    'https://love2learnsign.com/privacy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('mailto:info@netcreative-swas.net');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Text(
                    S.of(context)!.privacyDialogContact,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                S.of(context)!.close,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPolicyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
    );
  }
}
Future<int> _getDirectorySize(Directory dir) async {
  int total = 0;
  if (await dir.exists()) {
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
  }
  return total;
}