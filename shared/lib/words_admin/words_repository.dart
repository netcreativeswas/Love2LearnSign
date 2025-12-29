import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../tenancy/tenant_db.dart';

class WordsRepository {
  static const String functionsRegion = 'us-central1';

  final FirebaseFirestore _db;
  final String tenantId;
  final String signLangId;

  WordsRepository({
    FirebaseFirestore? firestore,
    this.tenantId = TenantDb.defaultTenantId,
    this.signLangId = TenantDb.defaultSignLangId,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => TenantDb.concepts(_db, tenantId: tenantId);

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamWord(String wordId) {
    return _col.doc(wordId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getWord(String wordId) {
    return _col.doc(wordId).get();
  }

  Future<int?> countWords() async {
    try {
      final agg = await _col.count().get();
      return agg.count;
    } catch (_) {
      return null;
    }
  }

  Query<Map<String, dynamic>> _baseListQuery({required String orderByField}) => _col.orderBy(orderByField);

  Query<Map<String, dynamic>> buildPrefixSearchQuery({
    required bool bengali,
    required String prefixLower,
  }) {
    final field = bengali ? 'bengali_lower' : 'english_lower';
    final q = prefixLower.trim();
    final end = '$q\uf8ff';
    return _baseListQuery(orderByField: field).startAt([q]).endAt([end]);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchSearchPage({
    required bool bengali,
    required String queryLower,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = buildPrefixSearchQuery(bengali: bengali, prefixLower: queryLower);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.limit(limit).get();
  }

  Future<void> updateFields(String wordId, Map<String, dynamic> fields) {
    return _col.doc(wordId).update(fields);
  }

  Future<void> setFieldsMerge(String wordId, Map<String, dynamic> fields) {
    return _col.doc(wordId).set(fields, SetOptions(merge: true));
  }

  Future<void> updateEnglish(String wordId, String english) async {
    final trimmed = english.trim();
    await updateFields(wordId, {
      'english': trimmed,
      'english_lower': trimmed.toLowerCase(),
    });
  }

  Future<void> updateBengali(String wordId, String bengali) async {
    final trimmed = bengali.trim();
    await updateFields(wordId, {
      'bengali': trimmed,
      'bengali_lower': trimmed.toLowerCase(),
    });
  }

  Future<void> updateVariantsTransaction({
    required String wordId,
    required List<Map<String, dynamic>> Function(List<Map<String, dynamic>> current) mutate,
  }) async {
    final ref = _col.doc(wordId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final raw = data['variants'];
      final current = (raw is List)
          ? raw.map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList()
          : <Map<String, dynamic>>[];

      final next = mutate(current);
      tx.update(ref, {'variants': next});
    });
  }

  Future<void> updateVariantAtIndex({
    required String wordId,
    required int index,
    required Map<String, dynamic> Function(Map<String, dynamic> current) mutateVariant,
  }) async {
    await updateVariantsTransaction(
      wordId: wordId,
      mutate: (current) {
        if (index < 0 || index >= current.length) return current;
        final v = Map<String, dynamic>.from(current[index]);
        current[index] = mutateVariant(v);
        return current;
      },
    );
  }

  Future<Map<String, dynamic>> deleteDictionaryEntryCascade({
    required String wordId,
  }) async {
    final fn = FirebaseFunctions.instanceFor(region: functionsRegion).httpsCallable('deleteDictionaryEntry');
    final res = await fn.call(<String, dynamic>{
      'tenantId': tenantId,
      'conceptId': wordId,
      'signLangId': signLangId,
    });
    final data = res.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{'raw': data};
  }

  Future<Map<String, dynamic>> backfillWordLowerFields({int limit = 500, String? startAfterDocId}) async {
    final fn = FirebaseFunctions.instanceFor(region: functionsRegion).httpsCallable('backfillWordLowerFields');
    final payload = <String, dynamic>{
      'tenantId': tenantId,
      'limit': limit,
    };
    if (startAfterDocId != null && startAfterDocId.trim().isNotEmpty) {
      payload['startAfterDocId'] = startAfterDocId.trim();
    }
    final res = await fn.call(payload);
    final data = res.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{'raw': data};
  }

  Future<Map<String, dynamic>> deleteReplacedWordMedia({
    required String wordId,
    required List<String> oldUrls,
  }) async {
    final fn = FirebaseFunctions.instanceFor(region: functionsRegion).httpsCallable('deleteReplacedWordMedia');
    final res = await fn.call(<String, dynamic>{
      'tenantId': tenantId,
      'conceptId': wordId,
      'signLangId': signLangId,
      'oldUrls': oldUrls,
    });
    final data = res.data;
    return (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{'raw': data};
  }
}


