import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:l2l_shared/tenancy/tenant_config.dart';

class TenantConfigLoader {
  static const int _whereInLimit = 10;

  static Iterable<List<String>> _chunks(List<String> ids, {int size = _whereInLimit}) sync* {
    for (int i = 0; i < ids.length; i += size) {
      final end = (i + size < ids.length) ? i + size : ids.length;
      yield ids.sublist(i, end);
    }
  }

  /// Best-effort bulk load of tenant config docs by document id.
  ///
  /// - Uses whereIn(FieldPath.documentId) in chunks of 10
  /// - Falls back to per-doc reads if whereIn fails (rules/index/etc.)
  static Future<Map<String, TenantConfigDoc>> fetchByIds(
    FirebaseFirestore db,
    Iterable<String> tenantIds,
  ) async {
    final ids = tenantIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final out = <String, TenantConfigDoc>{};
    if (ids.isEmpty) return out;

    for (final chunk in _chunks(ids)) {
      try {
        final snap = await db
            .collection('tenants')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in snap.docs) {
          out[d.id] = TenantConfigDoc.fromSnapshot(d);
        }
      } catch (_) {
        // Fallback to per-doc get when whereIn is unavailable (rules or query errors).
        for (final id in chunk) {
          try {
            final d = await db.collection('tenants').doc(id).get();
            if (d.exists) out[d.id] = TenantConfigDoc.fromSnapshot(d);
          } catch (_) {}
        }
      }
    }

    return out;
  }
}


