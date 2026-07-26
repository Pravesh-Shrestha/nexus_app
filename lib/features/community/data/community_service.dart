import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/community/data/community_model.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';

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

  // Stream of communities joined by user
  Stream<List<CommunityModel>> getJoinedCommunities(String uid) {
    return _firestore
        .collection('communities')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
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
      throw AppException(
        title: 'Creation Failed',
        message: 'Failed to create community. Please check your internet connection and try again.',
        actionText: 'Retry',
      );
    }
  }

  // Join a community
  Future<void> joinCommunity(String communityId, String uid) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'memberUids': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      throw AppException(
        title: 'Join Failed',
        message: 'Failed to join community. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // Leave a community
  Future<void> leaveCommunity(String communityId, String uid) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'memberUids': FieldValue.arrayRemove([uid]),
      });
    } catch (e) {
      throw AppException(
        title: 'Leave Failed',
        message: 'Failed to leave community. Please try again.',
        actionText: 'Retry',
      );
    }
  }
}
