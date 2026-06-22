import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/community/data/community_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all communities
  Stream<List<CommunityModel>> getCommunities() {
    return _firestore.collection('communities').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Create a community
  Future<void> createCommunity({
    required String name,
    required String description,
    required String creatorId,
    String imageUrl = '',
  }) async {
    try {
      final docRef = _firestore.collection('communities').doc();
      final community = CommunityModel(
        id: docRef.id,
        name: name,
        description: description,
        creatorId: creatorId,
        imageUrl: imageUrl,
        memberUids: [creatorId], // Creator is the first member
      );

      await docRef.set(community.toJson());
    } catch (e) {
      throw 'Failed to create community: $e';
    }
  }

  // Join a community
  Future<void> joinCommunity(String communityId, String uid) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'memberUids': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      throw 'Failed to join community: $e';
    }
  }

  // Leave a community
  Future<void> leaveCommunity(String communityId, String uid) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'memberUids': FieldValue.arrayRemove([uid]),
      });
    } catch (e) {
      throw 'Failed to leave community: $e';
    }
  }
}
