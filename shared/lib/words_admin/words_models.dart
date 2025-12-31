import 'package:cloud_firestore/cloud_firestore.dart';

import '../tenancy/concept_text.dart';

class DictionaryVariant {
  final String label;
  /// Canonical video URLs (new schema): prefer `videos_360/480/720`.
  /// Legacy fallback: `videoUrlSD/videoUrl/videoUrlHD`.
  final String videos360;
  final String videos480;
  final String videos720;
  final String videoThumbnail;
  final String videoThumbnailSmall;

  const DictionaryVariant({
    required this.label,
    required this.videos360,
    required this.videos480,
    required this.videos720,
    required this.videoThumbnail,
    required this.videoThumbnailSmall,
  });

  factory DictionaryVariant.fromMap(Map<String, dynamic> map) {
    String pickString(dynamic v) => (v ?? '').toString();
    return DictionaryVariant(
      label: (map['label'] ?? '').toString(),
      // New schema first, then legacy fallback.
      videos360: pickString(map['videos_360']).isNotEmpty ? pickString(map['videos_360']) : pickString(map['videoUrlSD']),
      videos480: pickString(map['videos_480']).isNotEmpty ? pickString(map['videos_480']) : pickString(map['videoUrl']),
      videos720: pickString(map['videos_720']).isNotEmpty ? pickString(map['videos_720']) : pickString(map['videoUrlHD']),
      videoThumbnail: (map['videoThumbnail'] ?? '').toString(),
      videoThumbnailSmall: (map['videoThumbnailSmall'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'label': label,
      // New schema only.
      'videos_360': videos360,
      'videos_480': videos480,
      'videos_720': videos720,
      'videoThumbnail': videoThumbnail,
    };
    if (videoThumbnailSmall.isNotEmpty) {
      m['videoThumbnailSmall'] = videoThumbnailSmall;
    }
    return m;
  }
}

class DictionaryWordDoc {
  final String id;
  final Map<String, dynamic> data;
  final DocumentReference<Map<String, dynamic>> ref;

  DictionaryWordDoc({
    required this.id,
    required this.data,
    required this.ref,
  });

  factory DictionaryWordDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    return DictionaryWordDoc(
      id: snap.id,
      data: snap.data() ?? <String, dynamic>{},
      ref: snap.reference,
    );
  }

  /// New schema (preferred): labels map, with legacy fallback.
  Map<String, String> get labels => ConceptText.stringMap(data['labels']);

  /// Convenience: get a label for a given language code.
  /// Falls back to English then legacy fields.
  String labelFor(String lang, {String fallbackLang = 'en'}) =>
      ConceptText.labelFor(data, lang: lang, fallbackLang: fallbackLang);

  String get english => (data['english'] ?? '').toString();
  String get bengali => (data['bengali'] ?? '').toString();
  String get englishNote => (data['englishNote'] ?? '').toString();
  String get bengaliNote => (data['bengaliNote'] ?? '').toString();
  String get categoryMain => (data['category_main'] ?? '').toString();
  String get categorySub => (data['category_sub'] ?? '').toString();
  String get imageFlashcard => (data['imageFlashcard'] ?? '').toString();

  List<String> get englishWordSynonyms =>
      (data['englishWordSynonyms'] is List) ? List<String>.from(data['englishWordSynonyms']) : const <String>[];
  List<String> get bengaliWordSynonyms =>
      (data['bengaliWordSynonyms'] is List) ? List<String>.from(data['bengaliWordSynonyms']) : const <String>[];
  List<String> get englishWordAntonyms =>
      (data['englishWordAntonyms'] is List) ? List<String>.from(data['englishWordAntonyms']) : const <String>[];
  List<String> get bengaliWordAntonyms =>
      (data['bengaliWordAntonyms'] is List) ? List<String>.from(data['bengaliWordAntonyms']) : const <String>[];

  /// New schema: synonyms/antonyms per language, with legacy fallback.
  List<String> synonymsFor(String lang) => ConceptText.synonymsFor(data, lang: lang);
  List<String> antonymsFor(String lang) => ConceptText.antonymsFor(data, lang: lang);

  List<Map<String, dynamic>> get categories {
    final raw = data['categories'];
    if (raw is List) {
      return raw.map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  List<DictionaryVariant> get variants {
    final raw = data['variants'];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? DictionaryVariant.fromMap(Map<String, dynamic>.from(e)) : null)
          .whereType<DictionaryVariant>()
          .toList();
    }
    return const <DictionaryVariant>[];
  }
}


