import 'package:cloud_firestore/cloud_firestore.dart';

bool forceServerFetch = false;

extension FirestoreCacheExtension<T> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> getCacheFirst() async {
    if (forceServerFetch) {
      return await get(const GetOptions(source: Source.server));
    }
    try {
      final doc = await get(const GetOptions(source: Source.cache));
      if (doc.exists) {
        return doc;
      }
    } catch (_) {}
    return await get();
  }
}

extension FirestoreQueryCacheExtension<T> on Query<T> {
  Future<QuerySnapshot<T>> getCacheFirst() async {
    if (forceServerFetch) {
      return await get(const GetOptions(source: Source.server));
    }
    try {
      final qs = await get(const GetOptions(source: Source.cache));
      if (qs.docs.isNotEmpty) {
        return qs;
      }
    } catch (_) {}
    return await get();
  }
}
