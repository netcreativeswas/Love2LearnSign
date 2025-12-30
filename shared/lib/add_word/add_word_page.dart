// ignore_for_file: unused_import, unnecessary_import, unused_field, unused_element, unused_local_variable
// Only import dart:io if not on web, for Platform checks and File usage
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:l2l_shared/layout/l2l_layout_scope.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'package:l2l_shared/tenancy/tenant_config.dart';
import 'package:l2l_shared/tenancy/tenant_storage_paths.dart';
import 'style.dart';


class AddWordPage extends StatefulWidget {
  final String tenantId;
  final String signLangId;

  const AddWordPage({
    super.key,
    this.tenantId = TenantDb.defaultTenantId,
    this.signLangId = TenantDb.defaultSignLangId,
  });

  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  static const int _maxFileSizeBytes = 1024 * 1024; // 1 MB
  // Static master map of categories/subcategories (sorted at render time)
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
  List<String> _categories = [];
  Map<String, List<String>> _categoryToSubcategories = {};
  String? _selectedCategory;
  String? _selectedSubcategory;
  // Multiple category selections (list of {category, subcategory})
  final List<Map<String, String>> _selectedCategories = [];
  double _uploadProgress = 0.0;
  List<double> _variantUploadProgress = [];
  // --- Multi-locale word fields (EN + tenant locales) ---
  List<String> _uiLocales = const ['en', 'bn'];
  bool _uiLocalesLoaded = false;
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};
  final Map<String, TextEditingController> _synonymsControllers = {};
  final Map<String, TextEditingController> _antonymsControllers = {};
  final TextEditingController _videoUrlController = TextEditingController();
  // SD video (main/single)
  final TextEditingController _videoUrlSDController = TextEditingController();
  // HD video (main/single)
  final TextEditingController _videoUrlHDController = TextEditingController();
  // Image flashcard controller
  final TextEditingController _imageFlashcardUrlController = TextEditingController();

  // For variant fields in addVariants mode
  // Each variant: label, videoUrl, thumbnailUrl
  List<Map<String, TextEditingController>> _variantFields = [];

  List<bool> _uploadVariantVideo = [];
  List<PlatformFile?> _selectedVariantVideos = [];
  List<String?> _uploadedVariantVideoUrls = [];
  // Variant SD video state
  List<bool> _uploadVariantVideoSD = [];
  List<PlatformFile?> _selectedVariantVideosSD = [];
  List<String?> _uploadedVariantVideoUrlsSD = [];
  List<double> _variantUploadProgressSD = [];
  // Variant HD video state
  List<bool> _uploadVariantVideoHD = [];
  List<PlatformFile?> _selectedVariantVideosHD = [];
  List<String?> _uploadedVariantVideoUrlsHD = [];
  List<double> _variantUploadProgressHD = [];
  // For video thumbnails (main and variants)
  bool _uploadVideoThumbnail = false;
  PlatformFile? _selectedVideoThumbnail;
  String? _uploadedVideoThumbnailUrl;
  double _videoThumbnailUploadProgress = 0.0;
  // Small thumbnail (optional) for the first/main variant
  final TextEditingController _videoThumbnailSmallUrlController = TextEditingController();
  bool _uploadVideoThumbnailSmall = false;
  PlatformFile? _selectedVideoThumbnailSmall;
  String? _uploadedVideoThumbnailSmallUrl;
  double _videoThumbnailSmallUploadProgress = 0.0;
  // Per-variant thumbnail state
  List<bool> _uploadVariantThumbnail = [];
  List<PlatformFile?> _selectedVariantThumbnails = [];
  List<String?> _uploadedVariantThumbnailUrls = [];
  List<double> _variantThumbnailUploadProgress = [];
  // Per-variant small thumbnail state
  List<bool> _uploadVariantThumbnailSmall = [];
  List<PlatformFile?> _selectedVariantThumbnailsSmall = [];
  List<String?> _uploadedVariantThumbnailSmallUrls = [];
  List<double> _variantThumbnailSmallUploadProgress = [];
  // Variant item keys for scrolling to the newly added/last item
  final List<GlobalKey> _variantItemKeys = [];

  bool _addVariant = false;
  bool _isLoading = false;

  bool _uploadVideo = false;
  PlatformFile? _selectedVideo;
  String? _uploadedVideoUrl;
  // SD video (main/single)
  bool _uploadVideoSD = false;
  PlatformFile? _selectedVideoSD;
  String? _uploadedVideoUrlSD;
  double _uploadProgressSD = 0.0;
  // HD video (main/single)
  bool _uploadVideoHD = false;
  PlatformFile? _selectedVideoHD;
  String? _uploadedVideoUrlHD;
  double _uploadProgressHD = 0.0;
  // Image flashcard state
  bool _uploadimageFlashcard = false;
  PlatformFile? _selectedimageFlashcard;
  String? _uploadedimageFlashcardUrl;
  double _imageFlashcardUploadProgress = 0.0;
  // Keys to anchor scroll positions
  final GlobalKey _singleBlockKey = GlobalKey();
  final GlobalKey _variantsStartKey = GlobalKey();
  final GlobalKey _categoryBlockKey = GlobalKey();
  // Use the default Storage bucket configured by Firebase.initializeApp(...)
  // (prevents hard-coding a legacy bucket and keeps multi-project setups working).
  Reference _storageRoot() => FirebaseStorage.instance.ref();
  Future<String> _putBytes({
    required Uint8List bytes,
    required SettableMetadata metadata,
    required String objectPath,
  }) async {
    final ref = _storageRoot().child(objectPath);
    // debug: bucket/path
    final snapshot = await ref.putData(bytes, metadata);
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }
  Future<String> _putString({
    required String data,
    required SettableMetadata metadata,
    required String objectPath,
  }) async {
    final ref = _storageRoot().child(objectPath);
    // debug: bucket/path
    final snapshot = await ref.putString(data, format: PutStringFormat.raw, metadata: metadata);
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        // ignore; UI will still try upload and show precise error
      }
    }
    // debug auth uid (optional)
  }
  // Use default Storage instance/bucket configured by Firebase.initializeApp
  @override
  void initState() {
    super.initState();
    // Prepare sorted categories and subcategories from static map
    final keys = _categoryMap.keys.toList()..sort((a,b)=>a.compareTo(b));
    final map = <String, List<String>>{};
    for (final k in keys) {
      final subs = List<String>.from(_categoryMap[k] ?? const [])..sort((a,b)=>a.compareTo(b));
      map[k] = subs;
    }
    _categories = keys;
    _categoryToSubcategories = map;

    // Initialize locale fields (fallback first, then refresh from tenant config).
    _applyUiLocales(_defaultUiLocalesForTenant(widget.tenantId), markLoaded: false);
    _loadTenantUiLocales();
  }

  List<String> _defaultUiLocalesForTenant(String tenantId) {
    // Backward-compatible default: Bengali tenant shows EN+BN unless overridden by Firestore.
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
      if (markLoaded) _uiLocalesLoaded = true;
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
      // non-fatal: keep defaults
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

  List<String> _parseCsvList(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return const <String>[];
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  // Helper for picking image files (jpg/png) - stores file, no upload
  Future<PlatformFile?> _pickImage({
    int maxSizeBytes = _maxFileSizeBytes,
  }) async {
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

  // Helper for picking and uploading image files (jpg/png) to a given path - DEPRECATED, kept for compatibility
  Future<void> _pickAndUploadImage({
    required String storageDir,
    required Function(String) onComplete,
    required Function(double) onProgress,
    Function()? onStart,
    Function()? onError,
    Function()? onCancel,
    void Function()? onFilePicked,
    int maxSizeBytes = _maxFileSizeBytes,
  }) async {
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
            const SnackBar(content: Text('Please select an image smaller than 1 MB')),
          );
          if (onCancel != null) onCancel();
          return;
        }
        if (onFilePicked != null) onFilePicked();
        if (onStart != null) onStart();
        // Build file name: base_timestamp.ext (like video naming pattern)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final original = file.name;
        final dotIndex = original.lastIndexOf('.');
        final base = dotIndex != -1 ? original.substring(0, dotIndex) : original;
        final ext = dotIndex != -1 ? original.substring(dotIndex) : '';
        final newName = '${base}_$timestamp$ext';
        await _ensureSignedIn();
        final objectPath = '$storageDir/$newName';
        // debug path
        final lower = ext.toLowerCase();
        final meta = SettableMetadata(
          contentType: lower.endsWith('.webp')
              ? 'image/webp'
              : (lower.endsWith('.png') ? 'image/png' : 'image/jpeg'),
        );
        final url = await _putBytes(
          bytes: file.bytes!,
          metadata: meta,
          objectPath: objectPath,
        );
        onComplete(url);
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      if (onError != null) onError();
    }
  }

  Future<void> _uploadFile(
    PlatformFile file,
    Function(String) onComplete,
    Function(double) onProgress, {
    required String storageDir,
  }) async {
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file data for upload. Try a different browser or check file permissions.')),
      );
      return;
    }
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final original = file.name;
      final dotIndex = original.lastIndexOf('.');
      final base = dotIndex != -1 ? original.substring(0, dotIndex) : original;
      final ext = dotIndex != -1 ? original.substring(dotIndex) : '';
      final newName = '${base}_$timestamp$ext';

      await _ensureSignedIn();
      final objectPath = '$storageDir/$newName';
        // debug path
      final meta = SettableMetadata(
        contentType: ext.toLowerCase().endsWith('.mp4') ? 'video/mp4' : 'application/octet-stream',
      );
      try {
      final url = await _putBytes(
          bytes: file.bytes!,
          metadata: meta,
          objectPath: objectPath,
        );
        onComplete(url);
        // debug upload URL
      } on FirebaseException catch (e) {
        // debug storage error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.code}')),
        );
      }
    } catch (e) {
      // debug upload error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video upload failed: $e')),
      );
    }
  }

  Future<void> _testStorageUpload() async {
    try {
      await _ensureSignedIn();
      final objectPath = 'tenants/${widget.tenantId}/test_probe.txt';
      final meta = SettableMetadata(contentType: 'text/plain');
      final url = await _putString(
        data: 'hello',
        metadata: meta,
        objectPath: objectPath,
      );
      // debug test OK
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test upload OK')));
      }
    } on FirebaseException catch (e) {
      // debug test error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test upload failed: ${e.code}')));
      }
    } catch (e) {
      // debug test error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test upload failed: $e')));
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // Debug log selected file
        // debug pick video
        // File size
        if (file.size > _maxFileSizeBytes) {
          // debug too large
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a portrait video 3/4 (ratio 1:1.33) smaller than 1 MB')),
          );
          return;
        }
        setState(() {
          _selectedVideo = file;
          _uploadVideo = true;
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick video: $e')));
    }
  }

  // SD video pick (500 KB limit) - single
  Future<void> _pickVideoSD() async {
    const int maxSizeBytesSD = 500 * 1024;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > maxSizeBytesSD) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video smaller than 500 KB')),
          );
          return;
        }
            setState(() {
          _selectedVideoSD = file;
          _uploadVideoSD = true;
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick SD video: $e')));
    }
  }

  Future<void> _pickVideoHD() async {
    const int maxSizeBytesHD = 2 * 1024 * 1024;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > maxSizeBytesHD) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video smaller than 2 MB')),
          );
          return;
        }
            setState(() {
          _selectedVideoHD = file;
          _uploadVideoHD = true;
            });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick HD video: $e')));
    }
  }

  Future<void> _pickVariantVideo(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // debug pick variant video
        if (file.size > _maxFileSizeBytes) {
          // debug too large
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a portrait video 3/4 (ratio 1:1.33) smaller than 1 MB')),
          );
          return;
        }
        setState(() {
          _selectedVariantVideos[index] = file;
          _uploadVariantVideo[index] = true;
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick variant video: $e')));
    }
  }

  // SD video pick (500 KB limit) - variant
  Future<void> _pickVariantVideoSD(int index) async {
    const int maxSizeBytesSD = 500 * 1024;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > maxSizeBytesSD) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video smaller than 500 KB')),
          );
          return;
        }
            setState(() {
          _selectedVariantVideosSD[index] = file;
          _uploadVariantVideoSD[index] = true;
        });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick variant SD video: $e')));
    }
  }

  // HD video pick (2 MB limit) - variant
  Future<void> _pickVariantVideoHD(int index) async {
    const int maxSizeBytesHD = 2 * 1024 * 1024;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > maxSizeBytesHD) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video smaller than 2 MB')),
          );
          return;
        }
            setState(() {
          _selectedVariantVideosHD[index] = file;
          _uploadVariantVideoHD[index] = true;
            });
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick variant HD video: $e')));
    }
  }

  void _addVariantField() {
    setState(() {
      _variantFields.add({
        'label': TextEditingController(),
        'videoUrl': TextEditingController(),
        'videoUrlSD': TextEditingController(),
        'videoUrlHD': TextEditingController(),
        'thumbnailUrl': TextEditingController(),
        'thumbnailSmallUrl': TextEditingController(),
      });
      _uploadVariantVideo.add(false);
      _selectedVariantVideos.add(null);
      _uploadedVariantVideoUrls.add(null);
      _variantUploadProgress.add(0.0);
      // SD video init
      _uploadVariantVideoSD.add(false);
      _selectedVariantVideosSD.add(null);
      _uploadedVariantVideoUrlsSD.add(null);
      _variantUploadProgressSD.add(0.0);
      // HD video init
      _uploadVariantVideoHD.add(false);
      _selectedVariantVideosHD.add(null);
      _uploadedVariantVideoUrlsHD.add(null);
      _variantUploadProgressHD.add(0.0);
      // For thumbnail
      _uploadVariantThumbnail.add(false);
      _selectedVariantThumbnails.add(null);
      _uploadedVariantThumbnailUrls.add(null);
      _variantThumbnailUploadProgress.add(0.0);
      // For small thumbnail
      _uploadVariantThumbnailSmall.add(false);
      _selectedVariantThumbnailsSmall.add(null);
      _uploadedVariantThumbnailSmallUrls.add(null);
      _variantThumbnailSmallUploadProgress.add(0.0);
      _variantItemKeys.add(GlobalKey());
    });
  }

  void _removeVariantField(int index) {
    setState(() {
      _variantFields[index]['label']!.dispose();
      _variantFields[index]['videoUrl']!.dispose();
      _variantFields[index]['videoUrlSD']!.dispose();
      _variantFields[index]['videoUrlHD']!.dispose();
      _variantFields[index]['thumbnailUrl']?.dispose();
      _variantFields[index]['thumbnailSmallUrl']?.dispose();
      _variantFields.removeAt(index);
      _uploadVariantVideo.removeAt(index);
      _selectedVariantVideos.removeAt(index);
      _uploadedVariantVideoUrls.removeAt(index);
      _variantUploadProgress.removeAt(index);
      _uploadVariantVideoSD.removeAt(index);
      _selectedVariantVideosSD.removeAt(index);
      _uploadedVariantVideoUrlsSD.removeAt(index);
      _variantUploadProgressSD.removeAt(index);
      _uploadVariantVideoHD.removeAt(index);
      _selectedVariantVideosHD.removeAt(index);
      _uploadedVariantVideoUrlsHD.removeAt(index);
      _variantUploadProgressHD.removeAt(index);
      _uploadVariantThumbnail.removeAt(index);
      _selectedVariantThumbnails.removeAt(index);
      _uploadedVariantThumbnailUrls.removeAt(index);
      _variantThumbnailUploadProgress.removeAt(index);
      _uploadVariantThumbnailSmall.removeAt(index);
      _selectedVariantThumbnailsSmall.removeAt(index);
      _uploadedVariantThumbnailSmallUrls.removeAt(index);
      _variantThumbnailSmallUploadProgress.removeAt(index);
      _variantItemKeys.removeAt(index);
    });
  }

  // Upload file and return URL directly (wrapper for _uploadFile)
  Future<String> _uploadFileAndGetUrl(PlatformFile file, {required String storageDir}) async {
    String? resultUrl;
    await _uploadFile(
      file,
      (url) {
        resultUrl = url;
      },
      (progress) {},
      storageDir: storageDir,
    );
    return resultUrl ?? '';
  }

  // Batch upload all selected files and return URLs
  Future<Map<String, dynamic>> _uploadAllSelectedFiles({required String conceptId}) async {
    final Map<String, dynamic> uploadedUrls = {
      'videoUrl': '',
      'videoUrlSD': '',
      'videoUrlHD': '',
      'videoThumbnail': '',
      'videoThumbnailSmall': '',
      'imageFlashcard': '',
      'variantVideos': <String>[],
      'variantVideosSD': <String>[],
      'variantVideosHD': <String>[],
      'variantThumbnails': <String>[],
      'variantThumbnailsSmall': <String>[],
    };

    await _ensureSignedIn();

    // Upload main video files
    if (_selectedVideo != null) {
      uploadedUrls['videoUrl'] = await _uploadFileAndGetUrl(
        _selectedVideo!,
        storageDir: TenantStoragePaths.videosDir(
          tenantId: widget.tenantId,
          signLangId: widget.signLangId,
          conceptId: conceptId,
        ),
      );
    }

    if (_selectedVideoSD != null) {
      uploadedUrls['videoUrlSD'] = await _uploadFileAndGetUrl(
        _selectedVideoSD!,
        storageDir: TenantStoragePaths.videosSdDir(
          tenantId: widget.tenantId,
          signLangId: widget.signLangId,
          conceptId: conceptId,
        ),
      );
    }

    if (_selectedVideoHD != null) {
      uploadedUrls['videoUrlHD'] = await _uploadFileAndGetUrl(
        _selectedVideoHD!,
        storageDir: TenantStoragePaths.videosHdDir(
          tenantId: widget.tenantId,
          signLangId: widget.signLangId,
          conceptId: conceptId,
        ),
      );
    }

    // Upload main thumbnails
    if (_selectedVideoThumbnail != null) {
      uploadedUrls['videoThumbnail'] = await _uploadImageFile(
        _selectedVideoThumbnail!,
        storageDir: TenantStoragePaths.thumbnailsDir(
          tenantId: widget.tenantId,
          signLangId: widget.signLangId,
          conceptId: conceptId,
        ),
      );
    }

    if (_selectedVideoThumbnailSmall != null) {
      uploadedUrls['videoThumbnailSmall'] = await _uploadImageFile(
        _selectedVideoThumbnailSmall!,
        storageDir: TenantStoragePaths.thumbnailsDir(
          tenantId: widget.tenantId,
          signLangId: widget.signLangId,
          conceptId: conceptId,
        ),
      );
    }

    // Upload flashcard image
    if (_selectedimageFlashcard != null) {
      uploadedUrls['imageFlashcard'] = await _uploadImageFile(
        _selectedimageFlashcard!,
        storageDir: TenantStoragePaths.flashcardsDir(
          tenantId: widget.tenantId,
          signLangId: widget.signLangId,
          conceptId: conceptId,
        ),
      );
    }

    // Upload variant files
    for (int i = 0; i < _variantFields.length; i++) {
      // Variant videos
      if (_selectedVariantVideos[i] != null) {
        final url = await _uploadFileAndGetUrl(
          _selectedVariantVideos[i]!,
          storageDir: TenantStoragePaths.videosDir(
            tenantId: widget.tenantId,
            signLangId: widget.signLangId,
            conceptId: conceptId,
          ),
        );
        uploadedUrls['variantVideos'].add(url);
      } else {
        uploadedUrls['variantVideos'].add('');
      }

      if (_selectedVariantVideosSD[i] != null) {
        final url = await _uploadFileAndGetUrl(
          _selectedVariantVideosSD[i]!,
          storageDir: TenantStoragePaths.videosSdDir(
            tenantId: widget.tenantId,
            signLangId: widget.signLangId,
            conceptId: conceptId,
          ),
        );
        uploadedUrls['variantVideosSD'].add(url);
      } else {
        uploadedUrls['variantVideosSD'].add('');
      }

      if (_selectedVariantVideosHD[i] != null) {
        final url = await _uploadFileAndGetUrl(
          _selectedVariantVideosHD[i]!,
          storageDir: TenantStoragePaths.videosHdDir(
            tenantId: widget.tenantId,
            signLangId: widget.signLangId,
            conceptId: conceptId,
          ),
        );
        uploadedUrls['variantVideosHD'].add(url);
      } else {
        uploadedUrls['variantVideosHD'].add('');
      }

      // Variant thumbnails
      if (_selectedVariantThumbnails[i] != null) {
        final url = await _uploadImageFile(
          _selectedVariantThumbnails[i]!,
          storageDir: TenantStoragePaths.thumbnailsDir(
            tenantId: widget.tenantId,
            signLangId: widget.signLangId,
            conceptId: conceptId,
          ),
        );
        uploadedUrls['variantThumbnails'].add(url);
      } else {
        uploadedUrls['variantThumbnails'].add('');
      }

      if (_selectedVariantThumbnailsSmall[i] != null) {
        final url = await _uploadImageFile(
          _selectedVariantThumbnailsSmall[i]!,
          storageDir: TenantStoragePaths.thumbnailsDir(
            tenantId: widget.tenantId,
            signLangId: widget.signLangId,
            conceptId: conceptId,
          ),
        );
        uploadedUrls['variantThumbnailsSmall'].add(url);
      } else {
        uploadedUrls['variantThumbnailsSmall'].add('');
      }
    }

    return uploadedUrls;
  }

  // Helper to upload image file
  Future<String> _uploadImageFile(PlatformFile file, {required String storageDir}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final original = file.name;
    final dotIndex = original.lastIndexOf('.');
    final base = dotIndex != -1 ? original.substring(0, dotIndex) : original;
    final ext = dotIndex != -1 ? original.substring(dotIndex) : '';
    final newName = '${base}_$timestamp$ext';
    final objectPath = '$storageDir/$newName';
    final lower = ext.toLowerCase();
    final meta = SettableMetadata(
      contentType: lower.endsWith('.webp')
          ? 'image/webp'
          : (lower.endsWith('.png') ? 'image/png' : 'image/jpeg'),
    );
    return await _putBytes(
      bytes: file.bytes!,
      metadata: meta,
      objectPath: objectPath,
    );
  }

  Future<void> _saveWord() async {
    setState(() => _isLoading = true);

    final labels = <String, String>{};
    for (final lang in _uiLocales) {
      final v = (_labelControllers[lang]?.text ?? '').trim();
      if (v.isNotEmpty) labels[lang] = v;
    }
    final english = (labels['en'] ?? '').trim();

    final conceptId = english.isEmpty
        ? 'concept-${DateTime.now().millisecondsSinceEpoch}'
        : english.replaceAll(' ', '_').toLowerCase();

    // Upload all selected files first
    Map<String, dynamic> uploadedUrls;
    try {
      uploadedUrls = await _uploadAllSelectedFiles(conceptId: conceptId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      setState(() => _isLoading = false);
      return;
    }

    final tenantId = widget.tenantId;
    final signLangId = widget.signLangId;
    // For backward compatibility, expose first selected as legacy fields
    final categoryMain = _selectedCategories.isNotEmpty ? (_selectedCategories.first['category'] ?? '').trim() : '';
    final categorySub = _selectedCategories.isNotEmpty ? (_selectedCategories.first['subcategory'] ?? '').trim() : '';
    // Full categories list for new schema
    final List<Map<String, String>> categories = _selectedCategories
        .map((m) => {
              'category': (m['category'] ?? '').trim(),
              'subcategory': (m['subcategory'] ?? '').trim(),
            })
        .toList();
    // Use uploaded URLs if files were selected, otherwise use manual URLs
    final videoUrl = uploadedUrls['videoUrl'] as String? ?? _videoUrlController.text.trim();
    final videoUrlSD = uploadedUrls['videoUrlSD'] as String? ?? _videoUrlSDController.text.trim();
    final videoUrlHD = uploadedUrls['videoUrlHD'] as String? ?? _videoUrlHDController.text.trim();
    final videoThumbnailUrl = uploadedUrls['videoThumbnail'] as String? ?? '';
    final videoThumbnailSmallUrl = uploadedUrls['videoThumbnailSmall'] as String? ?? _videoThumbnailSmallUrlController.text.trim();
    final imageFlashcardUrl = uploadedUrls['imageFlashcard'] as String? ?? _imageFlashcardUrlController.text.trim();

    // Notes/synonyms/antonyms (per locale).
    final notes = <String, String>{};
    final synonyms = <String, List<String>>{};
    final antonyms = <String, List<String>>{};
    for (final lang in _uiLocales) {
      final note = (_noteControllers[lang]?.text ?? '').trim();
      if (note.isNotEmpty) notes[lang] = note;
      final syn = _parseCsvList(_synonymsControllers[lang]?.text ?? '');
      if (syn.isNotEmpty) synonyms[lang] = syn;
      final ant = _parseCsvList(_antonymsControllers[lang]?.text ?? '');
      if (ant.isNotEmpty) antonyms[lang] = ant;
    }

    // Legacy field mirrors (EN + BN only).
    final englishNote = (notes['en'] ?? '').trim();
    final bengali = (labels['bn'] ?? '').trim();
    final bengaliNote = (notes['bn'] ?? '').trim();
    final List<String> englishWordSynonyms = synonyms['en'] ?? const <String>[];
    final List<String> bengaliWordSynonyms = synonyms['bn'] ?? const <String>[];
    final List<String> englishWordAntonyms = antonyms['en'] ?? const <String>[];
    final List<String> bengaliWordAntonyms = antonyms['bn'] ?? const <String>[];

    // No required fields: allow saving with whatever is provided

    List<Map<String, String>> variants = [];

    if (!_addVariant) {
      // Single variant (video is optional)
      final Map<String, String> firstVariant = {
        'label': 'Version 1',
        'videoUrl': videoUrl,
        'videoUrlSD': videoUrlSD,
        'videoUrlHD': videoUrlHD,
        'videoThumbnail': videoThumbnailUrl,
      };
      if (videoThumbnailSmallUrl.isNotEmpty) {
        firstVariant['videoThumbnailSmall'] = videoThumbnailSmallUrl;
      }
      variants = [ firstVariant ];
    } else {
      // addVariants: collect all variant fields (video optional)
      variants = [];
      final variantVideos = uploadedUrls['variantVideos'] as List<String>;
      final variantVideosSD = uploadedUrls['variantVideosSD'] as List<String>;
      final variantVideosHD = uploadedUrls['variantVideosHD'] as List<String>;
      final variantThumbnails = uploadedUrls['variantThumbnails'] as List<String>;
      final variantThumbnailsSmall = uploadedUrls['variantThumbnailsSmall'] as List<String>;
      for (int i = 0; i < _variantFields.length; i++) {
        final label = _variantFields[i]['label']!.text.trim();
        final url = (i < variantVideos.length && variantVideos[i].isNotEmpty) ? variantVideos[i] : _variantFields[i]['videoUrl']!.text.trim();
        final urlSD = (i < variantVideosSD.length && variantVideosSD[i].isNotEmpty) ? variantVideosSD[i] : _variantFields[i]['videoUrlSD']!.text.trim();
        final urlHD = (i < variantVideosHD.length && variantVideosHD[i].isNotEmpty) ? variantVideosHD[i] : _variantFields[i]['videoUrlHD']!.text.trim();
        final thumbnailUrl = (i < variantThumbnails.length && variantThumbnails[i].isNotEmpty) ? variantThumbnails[i] : (_variantFields[i]['thumbnailUrl']?.text.trim() ?? '');
        final smallThumbUrl = (i < variantThumbnailsSmall.length && variantThumbnailsSmall[i].isNotEmpty) ? variantThumbnailsSmall[i] : (_variantFields[i]['thumbnailSmallUrl']?.text.trim() ?? '');
        final Map<String, String> v = {
          'label': label.isNotEmpty ? label : 'Version ${i + 1}',
          'videoUrl': url,
          'videoUrlSD': urlSD,
          'videoUrlHD': urlHD,
          'videoThumbnail': thumbnailUrl,
        };
        if (smallThumbUrl.isNotEmpty) v['videoThumbnailSmall'] = smallThumbUrl;
        variants.add(v);
      }
    }

    final docId = conceptId;

    // Print what will be saved
    // debug payload summary

    try {
      final Map<String, dynamic> payload = {
        // Multi-tenant core
        'tenantId': tenantId,
        'conceptId': docId,
        'status': 'published',
        'visibility': 'public',
        'signLangIds': [signLangId],
        'defaultSignLangId': signLangId,
        // Multi-language schema
        // - labels: { "en": "...", "vi": "..." }
        // - labels_lower: derived
        // - notes/synonyms/antonyms: per-locale maps
        'labels': labels,
        'labels_lower': {
          for (final e in labels.entries) e.key: e.value.toLowerCase(),
        },
        if (notes.isNotEmpty) 'notes': notes,
        if (synonyms.isNotEmpty) 'synonyms': synonyms,
        if (antonyms.isNotEmpty) 'antonyms': antonyms,
        // New schema
        'category_main': categoryMain,
        'category_sub': categorySub.isEmpty ? '' : categorySub,
        'categories': categories, // New schema: list of selections
        'variants': variants,
        'imageFlashcard': imageFlashcardUrl,
        'addedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Legacy mirrors (keep existing clients working; only EN/BN).
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
      await TenantDb.conceptDoc(FirebaseFirestore.instance, docId, tenantId: tenantId).set(payload);
      await TenantDb.signDoc(
        FirebaseFirestore.instance,
        tenantId: tenantId,
        conceptId: docId,
        signLangId: signLangId,
      ).set(
        {
          'tenantId': tenantId,
          'conceptId': docId,
          'signLangId': signLangId,
          'variants': variants,
          'imageFlashcard': imageFlashcardUrl,
          'status': 'published',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      // debug firestore error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${e.code}')));
      setState(() => _isLoading = false);
      return;
    } catch (e) {
      // debug generic error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      setState(() => _isLoading = false);
      return;
    }

    // Show in-app banner
    showSimpleNotification(
      Text(
        'New word added: $english ---- $bengali',
        style: TextStyle(color: Colors.white),
      ),
        background: const Color(0xFF6750a4),
      duration: Duration(seconds: 5),
    );

    setState(() => _isLoading = false);

    // Show confirmation dialog
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Word saved'),
        content: const Text('Word saved in the database. You can add another word.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Reset form fields
    setState(() {
      for (final c in _labelControllers.values) {
        c.clear();
      }
      _videoUrlController.clear();
      _videoUrlSDController.clear();
      _videoUrlHDController.clear();
      for (final c in _noteControllers.values) {
        c.clear();
      }
      for (final c in _synonymsControllers.values) {
        c.clear();
      }
      for (final c in _antonymsControllers.values) {
        c.clear();
      }
      _imageFlashcardUrlController.clear();
      _videoThumbnailSmallUrlController.clear();
      _selectedCategory = null;
      _selectedSubcategory = null;
      _selectedCategories.clear();
      _addVariant = false;
      _uploadVideo = false;
      _selectedVideo = null;
      _uploadedVideoUrl = null;
      _uploadProgress = 0.0;
      _uploadVideoSD = false;
      _selectedVideoSD = null;
      _uploadedVideoUrlSD = null;
      _uploadProgressSD = 0.0;
      _uploadVideoHD = false;
      _selectedVideoHD = null;
      _uploadedVideoUrlHD = null;
      _uploadProgressHD = 0.0;
      _uploadVideoThumbnail = false;
      _selectedVideoThumbnail = null;
      _uploadedVideoThumbnailUrl = null;
      _videoThumbnailUploadProgress = 0.0;
      _uploadVideoThumbnailSmall = false;
      _selectedVideoThumbnailSmall = null;
      _uploadedVideoThumbnailSmallUrl = null;
      _videoThumbnailSmallUploadProgress = 0.0;
      _uploadimageFlashcard = false;
      _selectedimageFlashcard = null;
      _uploadedimageFlashcardUrl = null;
      _imageFlashcardUploadProgress = 0.0;
      for (var map in _variantFields) {
        map['label']!.clear();
        map['videoUrl']!.clear();
        map['videoUrlSD']!.clear();
        map['videoUrlHD']!.clear();
        map['thumbnailUrl']?.clear();
      }
      _variantFields.clear();
      _uploadVariantVideo.clear();
      _selectedVariantVideos.clear();
      _uploadedVariantVideoUrls.clear();
      _variantUploadProgress.clear();
      _uploadVariantVideoSD.clear();
      _selectedVariantVideosSD.clear();
      _uploadedVariantVideoUrlsSD.clear();
      _variantUploadProgressSD.clear();
      _uploadVariantVideoHD.clear();
      _selectedVariantVideosHD.clear();
      _uploadedVariantVideoUrlsHD.clear();
      _variantUploadProgressHD.clear();
      _uploadVariantThumbnail.clear();
      _selectedVariantThumbnails.clear();
      _uploadedVariantThumbnailUrls.clear();
      _variantThumbnailUploadProgress.clear();
      _uploadVariantThumbnailSmall.clear();
      _selectedVariantThumbnailsSmall.clear();
      _uploadedVariantThumbnailSmallUrls.clear();
      _variantThumbnailSmallUploadProgress.clear();
      _variantItemKeys.clear();
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ready to add a new word')));
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
    _videoThumbnailSmallUrlController.dispose();
    // Clear any dynamic controllers in variants
    for (var map in _variantFields) {
      map['label']!.dispose();
      map['videoUrl']!.dispose();
      map['videoUrlSD']!.dispose();
      map['videoUrlHD']!.dispose();
      map['thumbnailUrl']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDashboard = L2LLayoutScope.maybeOf(context)?.isDashboard ?? false;
    return Scaffold(
      appBar: isDashboard
          ? null
          : AppBar(
              title: const Text('Add New Word'),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDashboard ? 400 : double.infinity),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Checkbox for variants (no auto-scroll per request)
                  Row(
                    children: [
                      Checkbox(
                        value: _addVariant,
                        onChanged: (v) {
                          setState(() {
                            _addVariant = v ?? false;
                            if (_addVariant && _variantFields.isEmpty) {
                              _addVariantField();
                            }
                          });
                        },
                      ),
                      const Text('This word has some variations'),
                    ],
                  ),
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
                  // Single Category picker with attached sub-dropdown
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
                        // When opening dropdown, ensure it is positioned at top of the viewport
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
                              final String subSafe = (sub ?? '').trim();
                              final bool exists = _selectedCategories.any((m) =>
                                  (m['category'] ?? '') == cat && (m['subcategory'] ?? '') == subSafe);
                              if (!exists) {
                                _selectedCategories.add({'category': cat, 'subcategory': subSafe});
                              }
                              // Reset current picker selection to allow adding more
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
                                final int idx = entry.key;
                                final Map<String, String> sel = entry.value;
                                final String cat = sel['category'] ?? '';
                                final String sub = sel['subcategory'] ?? '';
                                final String label = sub.isEmpty ? cat : '$cat  >  $sub';
                                return InputChip(
                                  label: Text(label, style: const TextStyle(fontSize: 12)),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedCategories.removeAt(idx);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Upload Flashcard Image section wrapped in FieldBox (no extra Padding)
                  FieldBox(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _imageFlashcardUrlController,
                                  decoration: InputDecoration(
                                    labelText: 'Flashcard Image URL',
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                  enabled: !_uploadimageFlashcard,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final file = await _pickImage();
                                  if (file != null) {
                                            setState(() {
                                      _selectedimageFlashcard = file;
                                              _uploadimageFlashcard = true;
                                    });
                                  }
                                },
                                child: const Text('Choose File'),
                              ),
                            ],
                          ),
                          if (_uploadimageFlashcard && _selectedimageFlashcard != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Text('File selected: ${_selectedimageFlashcard!.name}'),
                                  const SizedBox(width: 8),
                                  TextButton(
                                onPressed: () {
                                  setState(() {
                                    _uploadimageFlashcard = false;
                                    _selectedimageFlashcard = null;
                                  });
                                },
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Non-variant block
                  if (!_addVariant) ...[
                    FieldBox(
                      key: _singleBlockKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // SD Video upload (360p) for main video - FIRST
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _videoUrlSDController,
                                    decoration: const InputDecoration(
                                      labelText: 'Video URL (SD 360p)',
                                      labelStyle: TextStyle(fontSize: 12),
                                      hintText: 'e.g. https://... (SD)',
                                    ),
                                    enabled: !_uploadVideoSD,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _pickVideoSD(),
                                  child: const Text('Choose File'),
                                ),
                              ],
                            ),
                          ),
                          if (_uploadVideoSD && _selectedVideoSD != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Text('File selected: ${_selectedVideoSD!.name}'),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _uploadVideoSD = false;
                                        _selectedVideoSD = null;
                                      });
                                    },
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8.0),
                          // SD Video upload (480p) for main video - SECOND
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _videoUrlController,
                                  decoration: InputDecoration(
                                    labelText: 'Video URL (SD 480p)',
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                  enabled: !_uploadVideo,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _pickVideo(),
                                child: const Text('Choose File'),
                              ),
                            ],
                          ),
                          if (_uploadVideo && _selectedVideo != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Text('File selected: ${_selectedVideo!.name}'),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _uploadVideo = false;
                                        _selectedVideo = null;
                                      });
                                    },
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
                          // HD Video upload (720p) for main video - THIRD
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _videoUrlHDController,
                                    decoration: const InputDecoration(
                                      labelText: 'Video URL (HD 720p)',
                                      labelStyle: TextStyle(fontSize: 12),
                                      hintText: 'e.g. https://... (HD)',
                                    ),
                                    enabled: !_uploadVideoHD,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _pickVideoHD(),
                                  child: const Text('Choose File'),
                                ),
                              ],
                            ),
                          ),
                          if (_uploadVideoHD && _selectedVideoHD != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Text('File selected: ${_selectedVideoHD!.name}'),
                                  const SizedBox(width: 8),
                                  TextButton(
                                onPressed: () {
                                  setState(() {
                                        _uploadVideoHD = false;
                                        _selectedVideoHD = null;
                                  });
                                },
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
                          // Video Thumbnail upload for main video
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(text: _uploadedVideoThumbnailUrl ?? ''),
                                        decoration: InputDecoration(
                                          labelText: 'Video Thumbnail URL',
                                          labelStyle: const TextStyle(fontSize: 12),
                                        ),
                                        enabled: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final file = await _pickImage();
                                        if (file != null) {
                                                  setState(() {
                                            _selectedVideoThumbnail = file;
                                                    _uploadVideoThumbnail = true;
                                          });
                                        }
                                      },
                                      child: const Text('Choose File'),
                                    ),
                                  ],
                                ),
                                if (_uploadVideoThumbnail && _selectedVideoThumbnail != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Text('File selected: ${_selectedVideoThumbnail!.name}'),
                                        const SizedBox(width: 8),
                                        TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _uploadVideoThumbnail = false;
                                          _selectedVideoThumbnail = null;
                                        });
                                      },
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Small thumbnail URL (optional) for the first/main variant
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _videoThumbnailSmallUrlController,
                                        decoration: const InputDecoration(
                                          labelText: 'Video Thumbnail Small URL (optional)',
                                          labelStyle: TextStyle(fontSize: 12),
                                          hintText: 'e.g. small WebP thumbnail URL',
                                        ),
                                        enabled: !_uploadVideoThumbnailSmall,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final file = await _pickImage();
                                        if (file != null) {
                                                  setState(() {
                                            _selectedVideoThumbnailSmall = file;
                                                    _uploadVideoThumbnailSmall = true;
                                          });
                                        }
                                      },
                                      child: const Text('Choose File'),
                                    ),
                                  ],
                                ),
                                if (_uploadVideoThumbnailSmall && _selectedVideoThumbnailSmall != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Text('File selected: ${_selectedVideoThumbnailSmall!.name}'),
                                        const SizedBox(width: 8),
                                        TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _uploadVideoThumbnailSmall = false;
                                              _selectedVideoThumbnailSmall = null;
                                        });
                                      },
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Variant block
                  if (_addVariant) ...[
                    // Invisible anchor to ensure we can scroll to the last variant item easily
                    SizedBox(key: _variantsStartKey, height: 0),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _variantFields.length,
                      itemBuilder: (context, index) {
                        return FieldBox(
                            key: _variantItemKeys[index],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _variantFields[index]['label'],
                                        decoration: InputDecoration(
                                          labelText: 'Variant Label #${index + 1}',
                                          labelStyle: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeVariantField(index),
                                    ),
                                  ],
                                ),
                                // SD video upload (360p) for this variant - FIRST
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _variantFields[index]['videoUrlSD'],
                                          decoration: const InputDecoration(
                                            labelText: 'Video URL (SD 360p)',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          enabled: !_uploadVariantVideoSD[index],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _pickVariantVideoSD(index),
                                        child: const Text('Choose File'),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_uploadVariantVideoSD[index] && _selectedVariantVideosSD[index] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Text('File selected: ${_selectedVariantVideosSD[index]!.name}'),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _uploadVariantVideoSD[index] = false;
                                              _selectedVariantVideosSD[index] = null;
                                            });
                                          },
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 8.0),
                                // SD video upload (480p) for this variant - SECOND
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _variantFields[index]['videoUrl'],
                                        decoration: InputDecoration(
                                          labelText: 'Video URL (SD 480p)',
                                          labelStyle: const TextStyle(fontSize: 12),
                                        ),
                                        enabled: !_uploadVariantVideo[index],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _pickVariantVideo(index),
                                      child: const Text('Choose File'),
                                    ),
                                  ],
                                ),
                                if (_uploadVariantVideo[index] && _selectedVariantVideos[index] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Text('File selected: ${_selectedVariantVideos[index]!.name}'),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _uploadVariantVideo[index] = false;
                                              _selectedVariantVideos[index] = null;
                                            });
                                          },
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ),
                                // HD video upload (720p) for this variant - THIRD
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _variantFields[index]['videoUrlHD'],
                                          decoration: const InputDecoration(
                                            labelText: 'Video URL (HD 720p)',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          enabled: !_uploadVariantVideoHD[index],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _pickVariantVideoHD(index),
                                        child: const Text('Choose File'),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_uploadVariantVideoHD[index] && _selectedVariantVideosHD[index] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Text('File selected: ${_selectedVariantVideosHD[index]!.name}'),
                                        const SizedBox(width: 8),
                                        TextButton(
                                      onPressed: () {
                                        setState(() {
                                              _uploadVariantVideoHD[index] = false;
                                              _selectedVariantVideosHD[index] = null;
                                        });
                                      },
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Video Thumbnail upload for this variant
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _variantFields[index]['thumbnailUrl'],
                                              decoration: InputDecoration(
                                                labelText: 'Video Thumbnail URL',
                                                labelStyle: const TextStyle(fontSize: 12),
                                              ),
                                              enabled: !_uploadVariantThumbnail[index],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final file = await _pickImage();
                                              if (file != null) {
                                                        setState(() {
                                                  _selectedVariantThumbnails[index] = file;
                                                          _uploadVariantThumbnail[index] = true;
                                                });
                                              }
                                            },
                                            child: const Text('Choose File'),
                                          ),
                                        ],
                                      ),
                                      if (_uploadVariantThumbnail[index] && _selectedVariantThumbnails[index] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            children: [
                                              Text('File selected: ${_selectedVariantThumbnails[index]!.name}'),
                                              const SizedBox(width: 8),
                                              TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _uploadVariantThumbnail[index] = false;
                                                _selectedVariantThumbnails[index] = null;
                                              });
                                            },
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Small thumbnail upload for this variant (optional)
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _variantFields[index]['thumbnailSmallUrl'],
                                              decoration: const InputDecoration(
                                                labelText: 'Video Thumbnail Small URL (optional)',
                                                labelStyle: TextStyle(fontSize: 12),
                                              ),
                                              enabled: !_uploadVariantThumbnailSmall[index],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final file = await _pickImage();
                                              if (file != null) {
                                                        setState(() {
                                                  _selectedVariantThumbnailsSmall[index] = file;
                                                          _uploadVariantThumbnailSmall[index] = true;
                                                });
                                              }
                                            },
                                            child: const Text('Choose File'),
                                          ),
                                        ],
                                      ),
                                      if (_uploadVariantThumbnailSmall[index] && _selectedVariantThumbnailsSmall[index] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            children: [
                                              Text('File selected: ${_selectedVariantThumbnailsSmall[index]!.name}'),
                                              const SizedBox(width: 8),
                                              TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _uploadVariantThumbnailSmall[index] = false;
                                                _selectedVariantThumbnailsSmall[index] = null;
                                              });
                                            },
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _addVariantField();
                        // Scroll to last variant block after it is inserted
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_variantItemKeys.isNotEmpty) {
                            final ctx = _variantItemKeys.last.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                alignment: 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          }
                        });
                      },
                      child: const Text('Add Variant'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(onPressed: _saveWord, child: const Text('Save')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
