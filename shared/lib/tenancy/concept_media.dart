class ConceptMedia {
  /// Returns the playback URL for the 480p rendition (canonical),
  /// with fallback to legacy fields for older documents.
  static String video480FromVariant(Map<String, dynamic> v) {
    final canonical = (v['videos_480'] ?? '').toString().trim();
    if (canonical.isNotEmpty) return canonical;
    final legacy = (v['videoUrl'] ?? '').toString().trim();
    if (legacy.isNotEmpty) return legacy;
    // Last-resort: sometimes older docs stored under a different key.
    return (v['videos_480_url'] ?? '').toString().trim();
  }

  /// Returns the first variant map from a concept document.
  static Map<String, dynamic>? firstVariant(Map<String, dynamic> concept) {
    final variants = concept['variants'];
    if (variants is List && variants.isNotEmpty) {
      final first = variants.first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  /// Returns the 480p URL from a concept document (first variant), with legacy fallback.
  static String video480FromConcept(Map<String, dynamic> concept) {
    final v = firstVariant(concept);
    if (v != null) return video480FromVariant(v);
    // Root-level legacy fallback
    final legacy = (concept['videoUrl'] ?? '').toString().trim();
    if (legacy.isNotEmpty) return legacy;
    return (concept['videos_480'] ?? '').toString().trim();
  }
}


