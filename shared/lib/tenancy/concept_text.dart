/// Helpers for the multi-language concept schema.
///
/// New schema (recommended):
/// - labels: { "en": "...", "vi": "..." }
/// - labels_lower: { "en": "...", "vi": "..." } (derived, for search/orderBy)
/// - synonyms: { "en": ["..."], "vi": ["..."] }
/// - antonyms: { "en": ["..."], "vi": ["..."] }
///
/// Legacy schema (current app):
/// - english, bengali
/// - english_lower, bengali_lower
/// - englishWordSynonyms, bengaliWordSynonyms
/// - englishWordAntonyms, bengaliWordAntonyms
class ConceptText {
  /// Extract a string map from Firestore doc data.
  static Map<String, String> stringMap(dynamic raw) {
    if (raw is Map) {
      final out = <String, String>{};
      raw.forEach((k, v) {
        final key = k.toString().trim();
        if (key.isEmpty) return;
        final val = (v ?? '').toString();
        if (val.trim().isEmpty) return;
        out[key] = val;
      });
      return out;
    }
    return const <String, String>{};
  }

  static Map<String, List<String>> stringListMap(dynamic raw) {
    if (raw is Map) {
      final out = <String, List<String>>{};
      raw.forEach((k, v) {
        final key = k.toString().trim();
        if (key.isEmpty) return;
        if (v is List) {
          final list = v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
          if (list.isNotEmpty) out[key] = list;
        }
      });
      return out;
    }
    return const <String, List<String>>{};
  }

  /// Get label for a language code, with fallback rules.
  static String labelFor(
    Map<String, dynamic> data, {
    required String lang,
    String fallbackLang = 'en',
  }) {
    final labels = stringMap(data['labels']);
    if (labels.containsKey(lang)) return labels[lang]!;
    if (fallbackLang.isNotEmpty && labels.containsKey(fallbackLang)) return labels[fallbackLang]!;

    // Legacy fallback: en->english, bn->bengali
    if (lang == 'bn') {
      final bn = (data['bengali'] ?? '').toString();
      if (bn.trim().isNotEmpty) return bn;
    }
    final en = (data['english'] ?? '').toString();
    if (en.trim().isNotEmpty) return en;

    // Last fallback: any label
    if (labels.isNotEmpty) return labels.values.first;
    return '';
  }

  static String labelLowerFor(
    Map<String, dynamic> data, {
    required String lang,
    String fallbackLang = 'en',
  }) {
    final labelsLower = stringMap(data['labels_lower']);
    if (labelsLower.containsKey(lang)) return labelsLower[lang]!;
    if (fallbackLang.isNotEmpty && labelsLower.containsKey(fallbackLang)) return labelsLower[fallbackLang]!;

    // Legacy fallback
    if (lang == 'bn') {
      final bn = (data['bengali_lower'] ?? '').toString();
      if (bn.trim().isNotEmpty) return bn;
    }
    final en = (data['english_lower'] ?? '').toString();
    if (en.trim().isNotEmpty) return en;

    // Derive from label
    final raw = labelFor(data, lang: lang, fallbackLang: fallbackLang);
    return raw.toLowerCase();
  }

  static List<String> synonymsFor(
    Map<String, dynamic> data, {
    required String lang,
  }) {
    final map = stringListMap(data['synonyms']);
    if (map.containsKey(lang)) return map[lang]!;

    // Legacy fallback
    if (lang == 'bn') {
      final raw = data['bengaliWordSynonyms'];
      if (raw is List) return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    final raw = data['englishWordSynonyms'];
    if (raw is List) return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    return const <String>[];
  }

  static List<String> antonymsFor(
    Map<String, dynamic> data, {
    required String lang,
  }) {
    final map = stringListMap(data['antonyms']);
    if (map.containsKey(lang)) return map[lang]!;

    // Legacy fallback
    if (lang == 'bn') {
      final raw = data['bengaliWordAntonyms'];
      if (raw is List) return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    final raw = data['englishWordAntonyms'];
    if (raw is List) return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    return const <String>[];
  }
}


