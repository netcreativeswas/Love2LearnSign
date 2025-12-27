import 'package:cloud_firestore/cloud_firestore.dart';

class DictionaryVariant {
  final String label;
  final String videoUrl;
  final String videoUrlSD;
  final String videoUrlHD;
  final String videoThumbnail;
  final String videoThumbnailSmall;

  const DictionaryVariant({
    required this.label,
    required this.videoUrl,
    required this.videoUrlSD,
    required this.videoUrlHD,
    required this.videoThumbnail,
    required this.videoThumbnailSmall,
  });

  factory DictionaryVariant.fromMap(Map<String, dynamic> map) {
    return DictionaryVariant(
      label: (map['label'] ?? '').toString(),
      videoUrl: (map['videoUrl'] ?? '').toString(),
      videoUrlSD: (map['videoUrlSD'] ?? '').toString(),
      videoUrlHD: (map['videoUrlHD'] ?? '').toString(),
      videoThumbnail: (map['videoThumbnail'] ?? '').toString(),
      videoThumbnailSmall: (map['videoThumbnailSmall'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'label': label,
      'videoUrl': videoUrl,
      'videoUrlSD': videoUrlSD,
      'videoUrlHD': videoUrlHD,
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


