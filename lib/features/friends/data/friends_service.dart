import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/friends/data/friends_model.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream user's friends list
  Stream<FriendsModel> getFriendsList(String uid) {
    return _firestore.collection('friends').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return FriendsModel.fromJson(doc.data()!);
      }
      return FriendsModel(uid: uid);
    });
  }

  // Add a friend
  Future<void> addFriend(String uid, String friendUid) async {
    try {
      // Add friendUid to uid's list
      await _firestore.collection('friends').doc(uid).set({
        'friendUids': FieldValue.arrayUnion([friendUid]),
      }, SetOptions(merge: true));

      // Dual bind: Add uid to friendUid's list
      await _firestore.collection('friends').doc(friendUid).set({
        'friendUids': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to add friend: $e';
    }
  }

  // Remove a friend
  Future<void> removeFriend(String uid, String friendUid) async {
    try {
      // Remove friendUid from uid's list
      await _firestore.collection('friends').doc(uid).set({
        'friendUids': FieldValue.arrayRemove([friendUid]),
      }, SetOptions(merge: true));

      // Dual bind: Remove uid from friendUid's list
      await _firestore.collection('friends').doc(friendUid).set({
        'friendUids': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to remove friend: $e';
    }
  }
}
