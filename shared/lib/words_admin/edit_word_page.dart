// EditWordPage: AddWordPage-style editor for existing words.
// IMPORTANT: This file intentionally mirrors the AddWordPage layout and grouping,
// but DOES NOT modify AddWordPage itself.

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:overlay_support/overlay_support.dart';

import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import '../add_word/style.dart';
import '../tenancy/concept_text.dart';
import '../tenancy/tenant_db.dart';
import '../tenancy/tenant_config.dart';
import '../tenancy/tenant_storage_paths.dart';
import 'words_repository.dart';

class EditWordPage extends StatefulWidget {
  final String wordId;
  final String? userRoleOverride;
  final bool embedded;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;
  final String tenantId;
  final String signLangId;

  const EditWordPage({
    super.key,
    required this.wordId,
    this.userRoleOverride,
    this.embedded = false,
    this.onSaved,
    this.onDeleted,
    this.tenantId = TenantDb.defaultTenantId,
    this.signLangId = TenantDb.defaultSignLangId,
  });

  @override
  State<EditWordPage> createState() => _EditWordPageState();
}

/// A scaffold-less view for desktop split-pane embedding.
class EditWordView extends StatelessWidget {
  final String wordId;
  final String? userRoleOverride;
  final bool embedded;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;
  final String tenantId;
  final String signLangId;

  const EditWordView({
    super.key,
    required this.wordId,
    this.userRoleOverride,
    required this.embedded,
    this.onSaved,
    this.onDeleted,
    this.tenantId = TenantDb.defaultTenantId,
    this.signLangId = TenantDb.defaultSignLangId,
  });

  @override
  Widget build(BuildContext context) {
    return EditWordPage(
      wordId: wordId,
      userRoleOverride: userRoleOverride,
      embedded: embedded,
      onSaved: onSaved,
      onDeleted: onDeleted,
      tenantId: tenantId,
      signLangId: signLangId,
    );
  }
}

class _EditWordPageState extends State<EditWordPage> {
  static const int _maxFileSizeBytes = 1024 * 1024; // 1 MB
  static const Map<String, List<String>> _categoryMap = {
    'Activities & Hobbies': ['Outdoor & Sports', 'Arts & Crafts', 'Music & Dance', 'Games', 'Home & Hobbies'],
    'Adjectives': ['Qualities', 'Flaws & Weaknesses', 'Emotions', 'Condition'],
    'Administration & Public Services': ['Citizen Services & IDs', 'Public Services & Facilities', 'Government Offices & Authorities', 'Documents & Law'],
    'Business & Management': ['Planning & Organizing', 'Money & Economy', 'Deals & Contracts', 'Money & Accounts', 'Operations & Supply', 'Marketing & Sales', 'People & HR'],
    'Culture & Identity': ['Languages', 'Clothes & Dress', 'Food & Cooking', 'Traditions & Festivals', 'Arts & Heritage'],
    'Education & Academia': ['Schools & Colleges', 'Subjects', 'Exams & Grades', 'Classroom & Tools', 'Research & Papers'],
    'Family & Relationships': ['Family Members', 'Marriage & In-Laws', 'Relationships & Status'],
    'Food & Drinks': ['Ingredients', 'Dishes', 'Drinks', 'Cooking & Tools', 'Eating Places'],
    'Geography – Bangladesh': ['Cities & Districts', 'Towns', 'Neighborhoods & Localities', 'Institutions & Facilities'],
    'Geography – International': ['Countries & Regions', 'Cities & Capitals', 'Nature (Land & Water)', 'Landmarks', 'Orgs & Codes'],
    'Health': ['Body', 'Illness & Symptoms', 'Care & Treatment', 'Medicine & Tools', 'Fitness & Diet'],
    'House': ['Rooms', 'Furniture', 'Appliances', 'Tools & Repair', 'Household Items'],
    'Language Basics': ['Alphabet', 'Numbers', 'Personal Pronouns', 'Question Words', 'Time & Dates'],
    'Media & Communication': ['News & TV/Radio', 'Online & Web', 'Social Media', 'Messaging & Calls', 'Media Types', 'Devices'],
    'Nature & Environment': ['Weather & Seasons', 'Animals', 'Plants', 'Places & Habitats', 'Earth & Disasters'],
    'Nouns': ['People', 'Objects', 'Abstract Objects', 'Social Behaviour', 'Habits'],
    'Politics & Society': ['Political System & Elections', 'Ideologies & Movements', 'Conflicts & Wars', 'Governance & Policy Debate', 'Social Issues & Civil Society'],
    'Professions & Occupations': ['Public Service Roles', 'Business Roles', 'Education & Knowledge Roles', 'General Professions', 'Technical Jobs'],
    'Religion': ['Beliefs & Practices', 'People', 'Objects', 'Religious Places', 'Festivals', 'Concepts'],
    'Verbs': ['Communication', 'Cognition', 'Émotion & Attitude', 'Perception', 'Action & Manipulation', 'Movement & Posture', 'State & Change'],
    'Technology & Science': ['Devices & Hardware', 'Software & Data', 'Internet & Networks', 'Engineering & Making', 'New Tech & AI'],
    'Time & Dates': ['Calendar', 'Day & Time', 'Schedules', 'Frequency & Duration'],
    'Transport': ['Vehicles', 'Places', 'Travel & Tickets', 'Road & Traffic'],
    'JW Organisation': ['Responsability', 'Publications & Materials', 'Meetings & Assemblies', 'Manual & Bible Use', 'Service & Ministry'],
    'Biblical Content': ['Locations', 'Bible Characters', 'Historical or Prophetic Events', 'Books of the Bible', 'Bible Teaching', 'Biblical Symbols'],
  };

  // Categories UI state
  List<String> _categories = [];
  Map<String, List<String>> _categoryToSubcategories = {};
  String? _selectedCategory;
  String? _selectedSubcategory;
  final List<Map<String, String>> _selectedCategories = [];

  // --- Multi-locale word fields (EN + tenant locales) ---
  List<String> _uiLocales = const ['en', 'bn'];
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};
  final Map<String, TextEditingController> _synonymsControllers = {};
  final Map<String, TextEditingController> _antonymsControllers = {};
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _videoUrlSDController = TextEditingController();
  final TextEditingController _videoUrlHDController = TextEditingController();
  final TextEditingController _imageFlashcardUrlController = TextEditingController();
  final TextEditingController _videoThumbnailUrlController = TextEditingController();
  final TextEditingController _videoThumbnailSmallUrlController = TextEditingController();

  // Variant controllers (AddWord-style)
  List<Map<String, TextEditingController>> _variantFields = [];

  // Upload toggles + selected files
  bool _addVariant = false;
  bool _isLoading = false;
  bool _isLoadingDoc = true;

  bool _uploadVideo = false;
  PlatformFile? _selectedVideo;
  bool _uploadVideoSD = false;
  PlatformFile? _selectedVideoSD;
  bool _uploadVideoHD = false;
  PlatformFile? _selectedVideoHD;

  bool _uploadVideoThumbnail = false;
  PlatformFile? _selectedVideoThumbnail;

  bool _uploadVideoThumbnailSmall = false;
  PlatformFile? _selectedVideoThumbnailSmall;

  bool _uploadimageFlashcard = false;
  PlatformFile? _selectedimageFlashcard;

  // Per-variant file selections
  List<bool> _uploadVariantVideo = [];
  List<PlatformFile?> _selectedVariantVideos = [];
  List<bool> _uploadVariantVideoSD = [];
  List<PlatformFile?> _selectedVariantVideosSD = [];
  List<bool> _uploadVariantVideoHD = [];
  List<PlatformFile?> _selectedVariantVideosHD = [];
  List<bool> _uploadVariantThumbnail = [];
  List<PlatformFile?> _selectedVariantThumbnails = [];
  List<bool> _uploadVariantThumbnailSmall = [];
  List<PlatformFile?> _selectedVariantThumbnailsSmall = [];

  // Keys to anchor scroll positions (same intent as AddWordPage)
  final GlobalKey _categoryBlockKey = GlobalKey();

  // Storage bucket (canonical)
  // Use the default Storage bucket configured by Firebase.initializeApp(...)
  Reference _storageRoot() => FirebaseStorage.instance.ref();

  late WordsRepository _repo;

  bool get _canDelete {
    final override = widget.userRoleOverride?.toLowerCase().trim();
    // Backward-compat: if no override is provided, keep legacy behavior (allow delete).
    return override == null || override.isEmpty || override == 'admin';
  }

  Future<String> _putBytes({
    required Uint8List bytes,
    required SettableMetadata metadata,
    required String objectPath,
  }) async {
    final ref = _storageRoot().child(objectPath);
    final snapshot = await ref.putData(bytes, metadata);
    return await snapshot.ref.getDownloadURL();
  }

  Future<PlatformFile?> _pickImage({int maxSizeBytes = _maxFileSizeBytes}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > maxSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image smaller than 1 MB')),
          );
          return null;
        }
        return file;
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
    return null;
  }

  Future<PlatformFile?> _pickVideoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > _maxFileSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video smaller than 1 MB')),
          );
          return null;
        }
        return file;
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick video: $e')));
    }
    return null;
  }

  Future<String> _uploadFileToStorage(PlatformFile file, {required String storageDir}) async {
    if (file.bytes == null) {
      throw StateError('Could not read file data for upload.');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final original = file.name;
    final dotIndex = original.lastIndexOf('.');
    final base = dotIndex != -1 ? original.substring(0, dotIndex) : original;
    final ext = dotIndex != -1 ? original.substring(dotIndex) : '';
    final newName = '${base}_$timestamp$ext';
    final objectPath = '$storageDir/$newName';
    final lower = ext.toLowerCase();
    final meta = SettableMetadata(
      contentType: lower.endsWith('.mp4')
          ? 'video/mp4'
          : (lower.endsWith('.webp')
              ? 'image/webp'
              : (lower.endsWith('.png') ? 'image/png' : 'image/jpeg')),
    );
    return await _putBytes(bytes: file.bytes!, metadata: meta, objectPath: objectPath);
  }

  @override
  void initState() {
    super.initState();
    _repo = WordsRepository(tenantId: widget.tenantId, signLangId: widget.signLangId);
    // Prepare sorted categories/subcategories (same as AddWordPage)
    final keys = _categoryMap.keys.toList()..sort((a, b) => a.compareTo(b));
    final map = <String, List<String>>{};
    for (final k in keys) {
      final subs = List<String>.from(_categoryMap[k] ?? const [])..sort((a, b) => a.compareTo(b));
      map[k] = subs;
    }
    _categories = keys;
    _categoryToSubcategories = map;

    // Initialize locale fields (fallback first, then refresh from tenant config).
    _applyUiLocales(_defaultUiLocalesForTenant(widget.tenantId), markLoaded: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTenantUiLocales();
      await _loadExistingWord();
    });
  }

  void _resetTransientSelections() {
    _isLoading = false;

    _uploadVideo = false;
    _selectedVideo = null;
    _uploadVideoSD = false;
    _selectedVideoSD = null;
    _uploadVideoHD = false;
    _selectedVideoHD = null;
    _uploadVideoThumbnail = false;
    _selectedVideoThumbnail = null;
    _uploadVideoThumbnailSmall = false;
    _selectedVideoThumbnailSmall = null;
    _uploadimageFlashcard = false;
    _selectedimageFlashcard = null;

    _selectedCategory = null;
    _selectedSubcategory = null;
  }

  @override
  void didUpdateWidget(covariant EditWordPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final tenantChanged =
        oldWidget.tenantId != widget.tenantId || oldWidget.signLangId != widget.signLangId;
    final wordChanged = oldWidget.wordId != widget.wordId;
    if (!tenantChanged && !wordChanged) return;

    _repo = WordsRepository(tenantId: widget.tenantId, signLangId: widget.signLangId);
    _resetTransientSelections();

    setState(() => _isLoadingDoc = true);

    // Re-load locales if tenant changed, then load the newly selected word.
    Future<void>(() async {
      if (tenantChanged) {
        _applyUiLocales(_defaultUiLocalesForTenant(widget.tenantId), markLoaded: false);
        await _loadTenantUiLocales();
      }
      await _loadExistingWord();
    });
  }

  List<String> _defaultUiLocalesForTenant(String tenantId) {
    if (tenantId == TenantDb.defaultTenantId) return const ['en', 'bn'];
    return const ['en'];
  }

  List<String> _normalizeUiLocales(Iterable<String> raw) {
    final out = <String>[];
    for (final r in raw) {
      final s = r.trim().toLowerCase();
      if (s.isEmpty) continue;
      if (!out.contains(s)) out.add(s);
    }
    if (!out.contains('en')) out.insert(0, 'en');
    return out.isEmpty ? const ['en'] : out;
  }

  void _applyUiLocales(List<String> next, {required bool markLoaded}) {
    final normalized = _normalizeUiLocales(next);

    // Dispose controllers for locales that are being removed.
    final toRemove = _labelControllers.keys.where((k) => !normalized.contains(k)).toList();
    for (final k in toRemove) {
      _labelControllers.remove(k)?.dispose();
      _noteControllers.remove(k)?.dispose();
      _synonymsControllers.remove(k)?.dispose();
      _antonymsControllers.remove(k)?.dispose();
    }

    // Ensure controllers exist for every locale.
    for (final lang in normalized) {
      _labelControllers.putIfAbsent(lang, () => TextEditingController());
      _noteControllers.putIfAbsent(lang, () => TextEditingController());
      _synonymsControllers.putIfAbsent(lang, () => TextEditingController());
      _antonymsControllers.putIfAbsent(lang, () => TextEditingController());
    }

    setState(() {
      _uiLocales = normalized;
    });
  }

  Future<void> _loadTenantUiLocales() async {
    try {
      final snap = await TenantDb.tenantDoc(
        FirebaseFirestore.instance,
        tenantId: widget.tenantId,
      ).get();
      if (!snap.exists) return;
      final cfg = TenantConfigDoc.fromSnapshot(snap);
      final next = cfg.uiLocales.isNotEmpty ? cfg.uiLocales : _defaultUiLocalesForTenant(widget.tenantId);
      if (!mounted) return;
      _applyUiLocales(next, markLoaded: true);
    } catch (_) {
      // non-fatal
    }
  }

  String _langLabel(String lang) {
    switch (lang) {
      case 'en':
        return 'English';
      case 'bn':
        return 'Bengali';
      case 'vi':
        return 'Vietnamese';
      case 'fr':
        return 'French';
      default:
        return lang.toUpperCase();
    }
  }

  @override
  void dispose() {
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    for (final c in _synonymsControllers.values) {
      c.dispose();
    }
    for (final c in _antonymsControllers.values) {
      c.dispose();
    }
    _videoUrlController.dispose();
    _videoUrlSDController.dispose();
    _videoUrlHDController.dispose();
    _imageFlashcardUrlController.dispose();
    _videoThumbnailUrlController.dispose();
    _videoThumbnailSmallUrlController.dispose();
    for (final map in _variantFields) {
      for (final c in map.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _ensureVariantArrays(int len) {
    while (_variantFields.length < len) {
      final i = _variantFields.length;
      _variantFields.add({
        'label': TextEditingController(text: 'Version ${i + 1}'),
        'videoUrl': TextEditingController(),
        'videoUrlSD': TextEditingController(),
        'videoUrlHD': TextEditingController(),
        'thumbnailUrl': TextEditingController(),
        'thumbnailSmallUrl': TextEditingController(),
      });
      _uploadVariantVideo.add(false);
      _selectedVariantVideos.add(null);
      _uploadVariantVideoSD.add(false);
      _selectedVariantVideosSD.add(null);
      _uploadVariantVideoHD.add(false);
      _selectedVariantVideosHD.add(null);
      _uploadVariantThumbnail.add(false);
      _selectedVariantThumbnails.add(null);
      _uploadVariantThumbnailSmall.add(false);
      _selectedVariantThumbnailsSmall.add(null);
    }
  }

  void _migrateSingleToVariant1() {
    _ensureVariantArrays(_variantFields.isEmpty ? 1 : _variantFields.length);
    final v0 = _variantFields[0];
    // Keep label if already set, otherwise force Version 1
    if (v0['label']!.text.trim().isEmpty) {
      v0['label']!.text = 'Version 1';
    }
    v0['videoUrl']!.text = _videoUrlController.text.trim();
    v0['videoUrlSD']!.text = _videoUrlSDController.text.trim();
    v0['videoUrlHD']!.text = _videoUrlHDController.text.trim();
    v0['thumbnailUrl']!.text = _videoThumbnailUrlController.text.trim();
    v0['thumbnailSmallUrl']!.text = _videoThumbnailSmallUrlController.text.trim();
  }

  void _copyVariant1ToSingle() {
    if (_variantFields.isEmpty) return;
    final v0 = _variantFields[0];
    _videoUrlController.text = v0['videoUrl']!.text.trim();
    _videoUrlSDController.text = v0['videoUrlSD']!.text.trim();
    _videoUrlHDController.text = v0['videoUrlHD']!.text.trim();
    _videoThumbnailUrlController.text = v0['thumbnailUrl']!.text.trim();
    _videoThumbnailSmallUrlController.text = v0['thumbnailSmallUrl']!.text.trim();
  }

  void _addNewVariant() {
    _ensureVariantArrays(_variantFields.length + 1);
  }

  Widget _inlineUrlWithFileButton({
    required TextEditingController controller,
    required bool enabled,
    required VoidCallback onPick,
    required String labelText,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasUrl = value.text.trim().isNotEmpty;
        final buttonText = hasUrl ? 'Replace File' : 'Select File';
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: labelText, labelStyle: const TextStyle(fontSize: 12)),
                enabled: enabled,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onPick,
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadExistingWord() async {
    final requestedWordId = widget.wordId;
    final requestedTenantId = widget.tenantId;
    setState(() => _isLoadingDoc = true);
    try {
      final snap = await TenantDb.conceptDoc(
        FirebaseFirestore.instance,
        requestedWordId,
        tenantId: requestedTenantId,
      ).get();
      final data = snap.data() ?? <String, dynamic>{};

      final notesMap = ConceptText.stringMap(data['notes']);
      for (final lang in _uiLocales) {
        _labelControllers[lang]!.text = ConceptText.labelFor(data, lang: lang);
        final fallbackNote = (lang == 'bn')
            ? (data['bengaliNote'] ?? '').toString()
            : (lang == 'en')
                ? (data['englishNote'] ?? '').toString()
                : '';
        _noteControllers[lang]!.text = (notesMap[lang] ?? fallbackNote).toString();
        _synonymsControllers[lang]!.text = ConceptText.synonymsFor(data, lang: lang).join(', ');
        _antonymsControllers[lang]!.text = ConceptText.antonymsFor(data, lang: lang).join(', ');
      }

      _imageFlashcardUrlController.text = (data['imageFlashcard'] ?? '').toString();

      // Categories: prefer new schema
      _selectedCategories.clear();
      final cats = data['categories'];
      if (cats is List) {
        for (final e in cats) {
          if (e is Map) {
            final m = Map<String, dynamic>.from(e);
            _selectedCategories.add({
              'category': (m['category'] ?? '').toString().trim(),
              'subcategory': (m['subcategory'] ?? '').toString().trim(),
            });
          }
        }
      } else {
        final cm = (data['category_main'] ?? '').toString().trim();
        final cs = (data['category_sub'] ?? '').toString().trim();
        if (cm.isNotEmpty) _selectedCategories.add({'category': cm, 'subcategory': cs});
      }

      // Variants: use existing
      final variantsRaw = data['variants'];
      final variants = (variantsRaw is List)
          ? variantsRaw.map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList()
          : <Map<String, dynamic>>[];
      _addVariant = variants.length > 1;

      // Reset variant state
      for (final vf in _variantFields) {
        for (final c in vf.values) {
          c.dispose();
        }
      }
      _variantFields = [];
      _uploadVariantVideo = [];
      _selectedVariantVideos = [];
      _uploadVariantVideoSD = [];
      _selectedVariantVideosSD = [];
      _uploadVariantVideoHD = [];
      _selectedVariantVideosHD = [];
      _uploadVariantThumbnail = [];
      _selectedVariantThumbnails = [];
      _uploadVariantThumbnailSmall = [];
      _selectedVariantThumbnailsSmall = [];

      if (_addVariant) {
        _ensureVariantArrays(variants.length);
        for (int i = 0; i < variants.length; i++) {
          final v = variants[i];
          _variantFields[i]['label']!.text = (v['label'] ?? 'Version ${i + 1}').toString();
          _variantFields[i]['videoUrl']!.text = (v['videos_480'] ?? v['videoUrl'] ?? '').toString();
          _variantFields[i]['videoUrlSD']!.text = (v['videos_360'] ?? v['videoUrlSD'] ?? '').toString();
          _variantFields[i]['videoUrlHD']!.text = (v['videos_720'] ?? v['videoUrlHD'] ?? '').toString();
          _variantFields[i]['thumbnailUrl']!.text = (v['videoThumbnail'] ?? '').toString();
          _variantFields[i]['thumbnailSmallUrl']!.text = (v['videoThumbnailSmall'] ?? '').toString();
        }
      } else {
        // Single-variant fields are represented by first variant where possible
        final first = variants.isNotEmpty ? variants.first : <String, dynamic>{};
        _videoUrlController.text = (first['videos_480'] ?? first['videoUrl'] ?? data['videos_480'] ?? data['videoUrl'] ?? '').toString();
        _videoUrlSDController.text = (first['videos_360'] ?? first['videoUrlSD'] ?? data['videos_360'] ?? data['videoUrlSD'] ?? '').toString();
        _videoUrlHDController.text = (first['videos_720'] ?? first['videoUrlHD'] ?? data['videos_720'] ?? data['videoUrlHD'] ?? '').toString();
        _videoThumbnailUrlController.text =
            (first['videoThumbnail'] ?? data['videoThumbnail'] ?? '').toString();
        _videoThumbnailSmallUrlController.text =
            (first['videoThumbnailSmall'] ?? data['videoThumbnailSmall'] ?? '').toString();
      }

      if (!mounted) return;
      // If user switched selection while loading, ignore stale completion.
      if (widget.wordId != requestedWordId || widget.tenantId != requestedTenantId) return;
      setState(() => _isLoadingDoc = false);
    } catch (e) {
      if (!mounted) return;
      if (widget.wordId != requestedWordId || widget.tenantId != requestedTenantId) return;
      setState(() => _isLoadingDoc = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load word: $e')));
    }
  }

  List<String> _parseCsv(String s) => s
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  List<String> _collectUrlsFromData(Map<String, dynamic> data) {
    final urls = <String>[];
    void push(dynamic v) {
      if (v is String && v.trim().isNotEmpty) urls.add(v.trim());
    }

    push(data['imageFlashcard']);
    push(data['videos_360']);
    push(data['videos_480']);
    push(data['videos_720']);
    push(data['videoUrl']); // legacy
    push(data['videoUrlSD']); // legacy
    push(data['videoUrlHD']); // legacy
    push(data['videoThumbnail']);
    push(data['videoThumbnailSmall']);
    final variants = data['variants'];
    if (variants is List) {
      for (final v in variants) {
        if (v is Map) {
          final m = Map<String, dynamic>.from(v);
          push(m['videos_360']);
          push(m['videos_480']);
          push(m['videos_720']);
          push(m['videoUrl']); // legacy
          push(m['videoUrlSD']); // legacy
          push(m['videoUrlHD']); // legacy
          push(m['videoThumbnail']);
          push(m['videoThumbnailSmall']);
        }
      }
    }
    return urls;
  }

  Future<Map<String, dynamic>> _uploadAllSelectedFiles() async {
    final uploadedUrls = <String, dynamic>{};
    final conceptId = widget.wordId;

    // Main files
    if (_selectedVideo != null) {
      uploadedUrls['videos_480'] =
          await _uploadFileToStorage(_selectedVideo!, storageDir: TenantStoragePaths.videosDir(conceptId: conceptId));
    }
    if (_selectedVideoSD != null) {
      uploadedUrls['videos_360'] =
          await _uploadFileToStorage(_selectedVideoSD!, storageDir: TenantStoragePaths.videosSdDir(conceptId: conceptId));
    }
    if (_selectedVideoHD != null) {
      uploadedUrls['videos_720'] =
          await _uploadFileToStorage(_selectedVideoHD!, storageDir: TenantStoragePaths.videosHdDir(conceptId: conceptId));
    }
    if (_selectedVideoThumbnail != null) {
      uploadedUrls['videoThumbnail'] = await _uploadFileToStorage(
        _selectedVideoThumbnail!,
        storageDir: TenantStoragePaths.thumbnailsDir(conceptId: conceptId),
      );
    }
    if (_selectedVideoThumbnailSmall != null) {
      uploadedUrls['videoThumbnailSmall'] = await _uploadFileToStorage(
        _selectedVideoThumbnailSmall!,
        storageDir: TenantStoragePaths.thumbnailsDir(conceptId: conceptId),
      );
    }
    if (_selectedimageFlashcard != null) {
      uploadedUrls['imageFlashcard'] = await _uploadFileToStorage(
        _selectedimageFlashcard!,
        storageDir: TenantStoragePaths.flashcardsDir(conceptId: conceptId),
      );
    }

    if (_addVariant) {
      final variantVideos = <String>[];
      final variantVideosSD = <String>[];
      final variantVideosHD = <String>[];
      final variantThumbnails = <String>[];
      final variantThumbnailsSmall = <String>[];

      for (int i = 0; i < _variantFields.length; i++) {
        if (_selectedVariantVideos[i] != null) {
          variantVideos.add(await _uploadFileToStorage(_selectedVariantVideos[i]!,
              storageDir: TenantStoragePaths.videosDir(conceptId: conceptId)));
        } else {
          variantVideos.add('');
        }

        if (_selectedVariantVideosSD[i] != null) {
          variantVideosSD.add(await _uploadFileToStorage(_selectedVariantVideosSD[i]!,
              storageDir: TenantStoragePaths.videosSdDir(conceptId: conceptId)));
        } else {
          variantVideosSD.add('');
        }

        if (_selectedVariantVideosHD[i] != null) {
          variantVideosHD.add(await _uploadFileToStorage(_selectedVariantVideosHD[i]!,
              storageDir: TenantStoragePaths.videosHdDir(conceptId: conceptId)));
        } else {
          variantVideosHD.add('');
        }

        if (_selectedVariantThumbnails[i] != null) {
          variantThumbnails.add(await _uploadFileToStorage(_selectedVariantThumbnails[i]!,
              storageDir: TenantStoragePaths.thumbnailsDir(conceptId: conceptId)));
        } else {
          variantThumbnails.add('');
        }

        if (_selectedVariantThumbnailsSmall[i] != null) {
          variantThumbnailsSmall.add(await _uploadFileToStorage(_selectedVariantThumbnailsSmall[i]!,
              storageDir: TenantStoragePaths.thumbnailsDir(conceptId: conceptId)));
        } else {
          variantThumbnailsSmall.add('');
        }
      }

      uploadedUrls['variantVideos'] = variantVideos;
      uploadedUrls['variantVideosSD'] = variantVideosSD;
      uploadedUrls['variantVideosHD'] = variantVideosHD;
      uploadedUrls['variantThumbnails'] = variantThumbnails;
      uploadedUrls['variantThumbnailsSmall'] = variantThumbnailsSmall;
    }

    return uploadedUrls;
  }

  Future<void> _saveAll() async {
    setState(() => _isLoading = true);
    try {
      final beforeSnap = await TenantDb.conceptDoc(
        FirebaseFirestore.instance,
        widget.wordId,
        tenantId: widget.tenantId,
      ).get();
      final beforeData = beforeSnap.data() ?? <String, dynamic>{};
      final oldUrlsAll = _collectUrlsFromData(beforeData);

      final uploadedUrls = await _uploadAllSelectedFiles();

      final labels = <String, String>{};
      final notes = <String, String>{};
      final synonyms = <String, List<String>>{};
      final antonyms = <String, List<String>>{};
      for (final lang in _uiLocales) {
        final label = (_labelControllers[lang]?.text ?? '').trim();
        if (label.isNotEmpty) labels[lang] = label;
        final note = (_noteControllers[lang]?.text ?? '').trim();
        if (note.isNotEmpty) notes[lang] = note;
        final syn = _parseCsv((_synonymsControllers[lang]?.text ?? '').trim());
        if (syn.isNotEmpty) synonyms[lang] = syn;
        final ant = _parseCsv((_antonymsControllers[lang]?.text ?? '').trim());
        if (ant.isNotEmpty) antonyms[lang] = ant;
      }

      final english = (labels['en'] ?? '').trim();
      final bengali = (labels['bn'] ?? '').trim();
      final englishNote = (notes['en'] ?? '').trim();
      final bengaliNote = (notes['bn'] ?? '').trim();

      final categories = _selectedCategories
          .map((m) => {
                'category': (m['category'] ?? '').trim(),
                'subcategory': (m['subcategory'] ?? '').trim(),
              })
          .toList();

      final categoryMain = _selectedCategories.isNotEmpty ? (_selectedCategories.first['category'] ?? '').trim() : '';
      final categorySub = _selectedCategories.isNotEmpty ? (_selectedCategories.first['subcategory'] ?? '').trim() : '';

      final englishWordSynonyms = synonyms['en'] ?? const <String>[];
      final bengaliWordSynonyms = synonyms['bn'] ?? const <String>[];
      final englishWordAntonyms = antonyms['en'] ?? const <String>[];
      final bengaliWordAntonyms = antonyms['bn'] ?? const <String>[];

      final videos480 = uploadedUrls['videos_480'] as String? ?? _videoUrlController.text.trim();
      final videos360 = uploadedUrls['videos_360'] as String? ?? _videoUrlSDController.text.trim();
      final videos720 = uploadedUrls['videos_720'] as String? ?? _videoUrlHDController.text.trim();
      final enteredThumb = _videoThumbnailUrlController.text.trim();
      final videoThumbnailUrl = uploadedUrls['videoThumbnail'] as String? ??
          (enteredThumb.isNotEmpty ? enteredThumb : (beforeData['videoThumbnail'] ?? '').toString());
      final videoThumbnailSmallUrl =
          uploadedUrls['videoThumbnailSmall'] as String? ?? _videoThumbnailSmallUrlController.text.trim();
      final imageFlashcardUrl =
          uploadedUrls['imageFlashcard'] as String? ?? _imageFlashcardUrlController.text.trim();

      // Build variants like AddWordPage
      List<Map<String, String>> variants = [];
      if (!_addVariant) {
        final Map<String, String> firstVariant = {
          'label': 'Version 1',
          // Canonical
          'videos_480': videos480,
          'videos_360': videos360,
          'videos_720': videos720,
          // Legacy mirror (temporary)
          'videoUrl': videos480,
          'videoUrlSD': videos360,
          'videoUrlHD': videos720,
          'videoThumbnail': videoThumbnailUrl,
        };
        if (videoThumbnailSmallUrl.isNotEmpty) {
          firstVariant['videoThumbnailSmall'] = videoThumbnailSmallUrl;
        }
        variants = [firstVariant];
      } else {
        final variantVideos = uploadedUrls['variantVideos'] as List<String>? ?? const [];
        final variantVideosSD = uploadedUrls['variantVideosSD'] as List<String>? ?? const [];
        final variantVideosHD = uploadedUrls['variantVideosHD'] as List<String>? ?? const [];
        final variantThumbnails = uploadedUrls['variantThumbnails'] as List<String>? ?? const [];
        final variantThumbnailsSmall = uploadedUrls['variantThumbnailsSmall'] as List<String>? ?? const [];

        for (int i = 0; i < _variantFields.length; i++) {
          final label = _variantFields[i]['label']!.text.trim();
          final url480 =
              (i < variantVideos.length && variantVideos[i].isNotEmpty) ? variantVideos[i] : _variantFields[i]['videoUrl']!.text.trim();
          final url360 = (i < variantVideosSD.length && variantVideosSD[i].isNotEmpty)
              ? variantVideosSD[i]
              : _variantFields[i]['videoUrlSD']!.text.trim();
          final url720 = (i < variantVideosHD.length && variantVideosHD[i].isNotEmpty)
              ? variantVideosHD[i]
              : _variantFields[i]['videoUrlHD']!.text.trim();
          final thumbnailUrl = (i < variantThumbnails.length && variantThumbnails[i].isNotEmpty)
              ? variantThumbnails[i]
              : (_variantFields[i]['thumbnailUrl']?.text.trim() ?? '');
          final smallThumbUrl = (i < variantThumbnailsSmall.length && variantThumbnailsSmall[i].isNotEmpty)
              ? variantThumbnailsSmall[i]
              : (_variantFields[i]['thumbnailSmallUrl']?.text.trim() ?? '');

          final Map<String, String> v = {
            'label': label.isNotEmpty ? label : 'Version ${i + 1}',
            // Canonical
            'videos_480': url480,
            'videos_360': url360,
            'videos_720': url720,
            // Legacy mirror (temporary)
            'videoUrl': url480,
            'videoUrlSD': url360,
            'videoUrlHD': url720,
            'videoThumbnail': thumbnailUrl,
          };
          if (smallThumbUrl.isNotEmpty) v['videoThumbnailSmall'] = smallThumbUrl;
          variants.add(v);
        }
      }

      final payload = <String, dynamic>{
        'tenantId': widget.tenantId,
        'conceptId': widget.wordId,
        'signLangIds': [widget.signLangId],
        'defaultSignLangId': widget.signLangId,
        'labels': labels,
        'labels_lower': {
          for (final e in labels.entries) e.key: e.value.toLowerCase(),
        },
        if (notes.isNotEmpty) 'notes': notes,
        if (synonyms.isNotEmpty) 'synonyms': synonyms,
        if (antonyms.isNotEmpty) 'antonyms': antonyms,
        'category_main': categoryMain,
        'category_sub': categorySub,
        'categories': categories,
        'variants': variants,
        'imageFlashcard': imageFlashcardUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Legacy mirrors (EN/BN only).
      if (english.isNotEmpty) {
        payload['english'] = english;
        payload['english_lower'] = english.toLowerCase();
      }
      if (bengali.isNotEmpty) {
        payload['bengali'] = bengali;
        payload['bengali_lower'] = bengali.toLowerCase();
      }
      if (englishNote.isNotEmpty) payload['englishNote'] = englishNote;
      if (bengaliNote.isNotEmpty) payload['bengaliNote'] = bengaliNote;
      if (englishWordSynonyms.isNotEmpty) payload['englishWordSynonyms'] = englishWordSynonyms;
      if (bengaliWordSynonyms.isNotEmpty) payload['bengaliWordSynonyms'] = bengaliWordSynonyms;
      if (englishWordAntonyms.isNotEmpty) payload['englishWordAntonyms'] = englishWordAntonyms;
      if (bengaliWordAntonyms.isNotEmpty) payload['bengaliWordAntonyms'] = bengaliWordAntonyms;

      await TenantDb.conceptDoc(
        FirebaseFirestore.instance,
        widget.wordId,
        tenantId: widget.tenantId,
      ).set(payload, SetOptions(merge: true));

      await TenantDb.signDoc(
        FirebaseFirestore.instance,
        tenantId: widget.tenantId,
        conceptId: widget.wordId,
        signLangId: widget.signLangId,
      ).set(
        {
          'tenantId': widget.tenantId,
          'conceptId': widget.wordId,
          'signLangId': widget.signLangId,
          'variants': variants,
          'imageFlashcard': imageFlashcardUrl,
          'status': 'published',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Update controllers to reflect newly uploaded URLs immediately
      if (uploadedUrls['videos_480'] is String) _videoUrlController.text = uploadedUrls['videos_480'] as String;
      if (uploadedUrls['videos_360'] is String) _videoUrlSDController.text = uploadedUrls['videos_360'] as String;
      if (uploadedUrls['videos_720'] is String) _videoUrlHDController.text = uploadedUrls['videos_720'] as String;
      if (uploadedUrls['videoThumbnail'] is String) {
        _videoThumbnailUrlController.text = uploadedUrls['videoThumbnail'] as String;
      }
      if (uploadedUrls['videoThumbnailSmall'] is String) {
        _videoThumbnailSmallUrlController.text = uploadedUrls['videoThumbnailSmall'] as String;
      }
      if (uploadedUrls['imageFlashcard'] is String) _imageFlashcardUrlController.text = uploadedUrls['imageFlashcard'] as String;

      // Delete replaced old media (server-side verification)
      final afterSnap = await TenantDb.conceptDoc(
        FirebaseFirestore.instance,
        widget.wordId,
        tenantId: widget.tenantId,
      ).get();
      final afterData = afterSnap.data() ?? <String, dynamic>{};
      final afterUrls = _collectUrlsFromData(afterData).toSet();
      final candidates = oldUrlsAll.where((u) => !afterUrls.contains(u)).toSet().toList();
      if (candidates.isNotEmpty) {
        await _repo.deleteReplacedWordMedia(wordId: widget.wordId, oldUrls: candidates);
      }

      if (!mounted) return;
      showSimpleNotification(
        Text('Word updated: $english — $bengali', style: const TextStyle(color: Colors.white)),
        background: const Color(0xFF6750a4),
        duration: const Duration(seconds: 4),
      );
      widget.onSaved?.call();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${e.code}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWord() async {
    if (!_canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete is only available for admins.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete word'),
        content: const Text('This will delete the word and all associated media. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _repo.deleteDictionaryEntryCascade(wordId: widget.wordId);
      if (!mounted) return;
      widget.onDeleted?.call();
      if (!widget.embedded) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final body = _isLoadingDoc
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Word',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_canDelete)
                        TextButton.icon(
                          onPressed: _isLoading ? null : _deleteWord,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : theme.colorScheme.error,
                          ),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: Text(
                            'Delete',
                            style: TextStyle(color: isDark ? Colors.white : theme.colorScheme.error),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Labels / notes / synonyms / antonyms (EN + tenant locales)
                  for (final lang in _uiLocales)
                    FieldBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _labelControllers[lang]!,
                            decoration: InputDecoration(
                              labelText: _langLabel(lang),
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextField(
                              controller: _noteControllers[lang]!,
                              decoration: InputDecoration(
                                labelText: '${_langLabel(lang)} Note (optional)',
                                labelStyle: const TextStyle(fontSize: 12),
                                hintText: 'e.g. additional context or usage notes',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextField(
                              controller: _synonymsControllers[lang]!,
                              decoration: InputDecoration(
                                labelText: '${_langLabel(lang)} Synonyms (comma-separated)',
                                labelStyle: const TextStyle(fontSize: 12),
                                hintText: 'e.g. fast, quick, rapid',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextField(
                              controller: _antonymsControllers[lang]!,
                              decoration: InputDecoration(
                                labelText: '${_langLabel(lang)} Antonyms (comma-separated)',
                                labelStyle: const TextStyle(fontSize: 12),
                                hintText: 'e.g. slow, sluggish',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Category picker (exact component)
                  FieldBox(
                    key: _categoryBlockKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CategoryPicker(
                          categories: _categories,
                          categoryToSubcategories: _categoryToSubcategories,
                          selectedCategory: _selectedCategory,
                          selectedSubcategory: _selectedSubcategory,
                          enabled: _categories.isNotEmpty,
                          onOpen: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final ctx = _categoryBlockKey.currentContext;
                              if (ctx != null) {
                                Scrollable.ensureVisible(
                                  ctx,
                                  alignment: 0.0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          },
                          onSelected: (cat, sub) {
                            setState(() {
                              final subSafe = (sub ?? '').trim();
                              final exists = _selectedCategories.any((m) =>
                                  (m['category'] ?? '') == cat && (m['subcategory'] ?? '') == subSafe);
                              if (!exists) {
                                _selectedCategories.add({'category': cat, 'subcategory': subSafe});
                              }
                              _selectedCategory = null;
                              _selectedSubcategory = null;
                            });
                          },
                        ),
                        if (_selectedCategories.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _selectedCategories.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final sel = entry.value;
                                final cat = sel['category'] ?? '';
                                final sub = sel['subcategory'] ?? '';
                                final label = sub.isEmpty ? cat : '$cat  >  $sub';
                                return InputChip(
                                  label: Text(label, style: const TextStyle(fontSize: 12)),
                                  onDeleted: () {
                                    setState(() => _selectedCategories.removeAt(idx));
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Flashcard (URL + Replace File)
                  FieldBox(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _inlineUrlWithFileButton(
                            controller: _imageFlashcardUrlController,
                            enabled: !_uploadimageFlashcard,
                            labelText: 'Flashcard Image URL',
                            onPick: () async {
                              final file = await _pickImage();
                              if (file != null) {
                                setState(() {
                                  _selectedimageFlashcard = file;
                                  _uploadimageFlashcard = true;
                                });
                              }
                            },
                          ),
                          if (_uploadimageFlashcard && _selectedimageFlashcard != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'File selected: ${_selectedimageFlashcard!.name}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _uploadimageFlashcard = false;
                                        _selectedimageFlashcard = null;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Variants toggle & container
                  FieldBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Variants', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                            Switch(
                              value: _addVariant,
                              onChanged: (v) {
                                setState(() {
                                  if (v) {
                                    _addVariant = true;
                                    _migrateSingleToVariant1();
                                  } else {
                                    _copyVariant1ToSingle();
                                    _addVariant = false;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!_addVariant) ...[
                          // Single media (URL + inline Select/Replace)
                          _inlineUrlWithFileButton(
                            controller: _videoUrlController,
                            enabled: !_uploadVideo,
                            labelText: 'Video URL',
                            onPick: () async {
                              final file = await _pickVideoFile();
                              if (file != null) {
                                setState(() {
                                  _selectedVideo = file;
                                  _uploadVideo = true;
                                });
                              }
                            },
                          ),
                          if (_uploadVideo && _selectedVideo != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'File selected: ${_selectedVideo!.name}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _uploadVideo = false;
                                      _selectedVideo = null;
                                    }),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          _inlineUrlWithFileButton(
                            controller: _videoUrlSDController,
                            enabled: !_uploadVideoSD,
                            labelText: 'Video URL (SD)',
                            onPick: () async {
                              final file = await _pickVideoFile();
                              if (file != null) {
                                setState(() {
                                  _selectedVideoSD = file;
                                  _uploadVideoSD = true;
                                });
                              }
                            },
                          ),
                          if (_uploadVideoSD && _selectedVideoSD != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'File selected: ${_selectedVideoSD!.name}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _uploadVideoSD = false;
                                      _selectedVideoSD = null;
                                    }),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          _inlineUrlWithFileButton(
                            controller: _videoUrlHDController,
                            enabled: !_uploadVideoHD,
                            labelText: 'Video URL (HD)',
                            onPick: () async {
                              final file = await _pickVideoFile();
                              if (file != null) {
                                setState(() {
                                  _selectedVideoHD = file;
                                  _uploadVideoHD = true;
                                });
                              }
                            },
                          ),
                          if (_uploadVideoHD && _selectedVideoHD != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'File selected: ${_selectedVideoHD!.name}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _uploadVideoHD = false;
                                      _selectedVideoHD = null;
                                    }),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          _inlineUrlWithFileButton(
                            controller: _videoThumbnailUrlController,
                            enabled: !_uploadVideoThumbnail,
                            labelText: 'Video Thumbnail URL',
                            onPick: () async {
                              final file = await _pickImage();
                              if (file != null) {
                                setState(() {
                                  _selectedVideoThumbnail = file;
                                  _uploadVideoThumbnail = true;
                                });
                              }
                            },
                          ),
                          if (_uploadVideoThumbnail && _selectedVideoThumbnail != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'File selected: ${_selectedVideoThumbnail!.name}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _uploadVideoThumbnail = false;
                                      _selectedVideoThumbnail = null;
                                    }),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          _inlineUrlWithFileButton(
                            controller: _videoThumbnailSmallUrlController,
                            enabled: !_uploadVideoThumbnailSmall,
                            labelText: 'Video Thumbnail Small URL',
                            onPick: () async {
                              final file = await _pickImage();
                              if (file != null) {
                                setState(() {
                                  _selectedVideoThumbnailSmall = file;
                                  _uploadVideoThumbnailSmall = true;
                                });
                              }
                            },
                          ),
                          if (_uploadVideoThumbnailSmall && _selectedVideoThumbnailSmall != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'File selected: ${_selectedVideoThumbnailSmall!.name}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _uploadVideoThumbnailSmall = false;
                                      _selectedVideoThumbnailSmall = null;
                                    }),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ),
                        ] else ...[
                          // Variants list (Variant 1, Variant 2...) with Add new variant
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => setState(_addNewVariant),
                                icon: const Icon(Icons.add),
                                label: const Text('Add new variant'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < _variantFields.length; i++)
                            FieldBox(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Variant ${i + 1}', style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _variantFields[i]['label'],
                                    decoration: const InputDecoration(labelText: 'Label', labelStyle: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(height: 8),
                                  _inlineUrlWithFileButton(
                                    controller: _variantFields[i]['videoUrl']!,
                                    enabled: !_uploadVariantVideo[i],
                                    labelText: 'Video URL',
                                    onPick: () async {
                                      final file = await _pickVideoFile();
                                      if (file != null) {
                                        setState(() {
                                          _selectedVariantVideos[i] = file;
                                          _uploadVariantVideo[i] = true;
                                        });
                                      }
                                    },
                                  ),
                                  if (_uploadVariantVideo[i] && _selectedVariantVideos[i] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'File selected: ${_selectedVariantVideos[i]!.name}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => setState(() {
                                              _uploadVariantVideo[i] = false;
                                              _selectedVariantVideos[i] = null;
                                            }),
                                            child: const Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  _inlineUrlWithFileButton(
                                    controller: _variantFields[i]['videoUrlSD']!,
                                    enabled: !_uploadVariantVideoSD[i],
                                    labelText: 'Video URL (SD)',
                                    onPick: () async {
                                      final file = await _pickVideoFile();
                                      if (file != null) {
                                        setState(() {
                                          _selectedVariantVideosSD[i] = file;
                                          _uploadVariantVideoSD[i] = true;
                                        });
                                      }
                                    },
                                  ),
                                  if (_uploadVariantVideoSD[i] && _selectedVariantVideosSD[i] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'File selected: ${_selectedVariantVideosSD[i]!.name}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => setState(() {
                                              _uploadVariantVideoSD[i] = false;
                                              _selectedVariantVideosSD[i] = null;
                                            }),
                                            child: const Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  _inlineUrlWithFileButton(
                                    controller: _variantFields[i]['videoUrlHD']!,
                                    enabled: !_uploadVariantVideoHD[i],
                                    labelText: 'Video URL (HD)',
                                    onPick: () async {
                                      final file = await _pickVideoFile();
                                      if (file != null) {
                                        setState(() {
                                          _selectedVariantVideosHD[i] = file;
                                          _uploadVariantVideoHD[i] = true;
                                        });
                                      }
                                    },
                                  ),
                                  if (_uploadVariantVideoHD[i] && _selectedVariantVideosHD[i] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'File selected: ${_selectedVariantVideosHD[i]!.name}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => setState(() {
                                              _uploadVariantVideoHD[i] = false;
                                              _selectedVariantVideosHD[i] = null;
                                            }),
                                            child: const Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  _inlineUrlWithFileButton(
                                    controller: _variantFields[i]['thumbnailUrl']!,
                                    enabled: !_uploadVariantThumbnail[i],
                                    labelText: 'Thumbnail URL',
                                    onPick: () async {
                                      final file = await _pickImage();
                                      if (file != null) {
                                        setState(() {
                                          _selectedVariantThumbnails[i] = file;
                                          _uploadVariantThumbnail[i] = true;
                                        });
                                      }
                                    },
                                  ),
                                  if (_uploadVariantThumbnail[i] && _selectedVariantThumbnails[i] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'File selected: ${_selectedVariantThumbnails[i]!.name}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => setState(() {
                                              _uploadVariantThumbnail[i] = false;
                                              _selectedVariantThumbnails[i] = null;
                                            }),
                                            child: const Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  _inlineUrlWithFileButton(
                                    controller: _variantFields[i]['thumbnailSmallUrl']!,
                                    enabled: !_uploadVariantThumbnailSmall[i],
                                    labelText: 'Thumbnail Small URL',
                                    onPick: () async {
                                      final file = await _pickImage();
                                      if (file != null) {
                                        setState(() {
                                          _selectedVariantThumbnailsSmall[i] = file;
                                          _uploadVariantThumbnailSmall[i] = true;
                                        });
                                      }
                                    },
                                  ),
                                  if (_uploadVariantThumbnailSmall[i] && _selectedVariantThumbnailsSmall[i] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'File selected: ${_selectedVariantThumbnailsSmall[i]!.name}',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => setState(() {
                                              _uploadVariantThumbnailSmall[i] = false;
                                              _selectedVariantThumbnailsSmall[i] = null;
                                            }),
                                            child: const Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveAll,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                  if (!widget.embedded) const SizedBox(height: 24),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.05),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );

    final content = L2LLayoutScope.dashboard(child: body);

    if (widget.embedded) return content;

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit Word'),
      ),
      body: content,
    );
  }
}


