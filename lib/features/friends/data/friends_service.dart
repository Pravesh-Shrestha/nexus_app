import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/friends/data/friends_model.dart';
import 'package:nexus_app/features/friends/data/friend_request_model.dart';
import 'package:nexus_app/features/home/data/notification_model.dart';
import 'package:nexus_app/features/home/data/notification_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Stream user's friends list
  Stream<FriendsModel> getFriendsList(String uid) {
    return _firestore.collection('friends').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return FriendsModel.fromJson(doc.data()!);
      }
      return FriendsModel(uid: uid);
    });
  }

  // Future user's friends list
  Future<FriendsModel> getFriendsListFuture(String uid) async {
    final doc = await _firestore.collection('friends').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return FriendsModel.fromJson(doc.data()!);
    }
    return FriendsModel(uid: uid);
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

  // Send a Friend Request
  Future<void> sendFriendRequest(String senderId, String senderUsername, String receiverId) async {
    try {
      final requestId = '${senderId}_$receiverId';
      final request = FriendRequestModel(
        id: requestId,
        senderId: senderId,
        receiverId: receiverId,
        status: 'pending',
        createdAt: DateTime.now(),
        expireAt: DateTime.now().add(const Duration(days: 21)),
      );

      // 1. Write the FriendRequest document
      await _firestore.collection('friend_requests').doc(requestId).set(request.toJson());

      // 2. Send the Notification to the receiver
      final notificationId = _firestore.collection('users').doc(receiverId).collection('notifications').doc().id;
      final notification = NotificationModel(
        id: notificationId,
        title: '$senderUsername sent you a friend request',
        type: 'friend_request',
        isRead: false,
        createdAt: DateTime.now(),
        expireAt: DateTime.now().add(const Duration(days: 21)),
        relatedId: senderId,
        status: 'pending',
      );

      await _notificationService.sendNotification(receiverId, notification);
    } catch (e) {
      throw 'Failed to send friend request: $e';
    }
  }

  // Accept a Friend Request
  Future<void> acceptFriendRequest(String senderId, String receiverId, [String? notificationId]) async {
    try {
      final requestId = '${senderId}_$receiverId';

      // 1. Update friend request status to accepted
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'accepted',
      });

      // 2. Add to mutual friends list
      await addFriend(senderId, receiverId);

      // 3. Update the receiver's notification status
      if (notificationId != null && notificationId.isNotEmpty) {
        await _notificationService.updateNotificationStatus(receiverId, notificationId, 'accepted');
      } else {
        // Query to find matching notifications if not provided
        final notifs = await _firestore
            .collection('users')
            .doc(receiverId)
            .collection('notifications')
            .where('type', isEqualTo: 'friend_request')
            .where('relatedId', isEqualTo: senderId)
            .get();
        for (var doc in notifs.docs) {
          await _notificationService.updateNotificationStatus(receiverId, doc.id, 'accepted');
        }
      }
    } catch (e) {
      throw 'Failed to accept friend request: $e';
    }
  }

  // Decline a Friend Request
  Future<void> declineFriendRequest(String senderId, String receiverId, [String? notificationId]) async {
    try {
      final requestId = '${senderId}_$receiverId';

      // 1. Update friend request status to declined
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'declined',
      });

      // 2. Update the receiver's notification status
      if (notificationId != null && notificationId.isNotEmpty) {
        await _notificationService.updateNotificationStatus(receiverId, notificationId, 'declined');
      } else {
        // Query to find matching notifications if not provided
        final notifs = await _firestore
            .collection('users')
            .doc(receiverId)
            .collection('notifications')
            .where('type', isEqualTo: 'friend_request')
            .where('relatedId', isEqualTo: senderId)
            .get();
        for (var doc in notifs.docs) {
          await _notificationService.updateNotificationStatus(receiverId, doc.id, 'declined');
        }
      }
    } catch (e) {
      throw 'Failed to decline friend request: $e';
    }
  }

  // Check Friendship/Request Status between current user and another user
  // Returns: 'friends' | 'pending_sent' | 'pending_received' | 'none'
  Future<String> getFriendshipStatus(String currentUserId, String otherUserId) async {
    try {
      // 1. Check if they are friends already
      final friendsDoc = await _firestore.collection('friends').doc(currentUserId).get();
      if (friendsDoc.exists && friendsDoc.data() != null) {
        final friendsModel = FriendsModel.fromJson(friendsDoc.data()!);
        if (friendsModel.friendUids.contains(otherUserId)) {
          return 'friends';
        }
      }

      // 2. Check if a request was sent by current user
      final sentRequestDoc = await _firestore.collection('friend_requests').doc('${currentUserId}_$otherUserId').get();
      if (sentRequestDoc.exists && sentRequestDoc.data() != null) {
        final request = FriendRequestModel.fromJson(sentRequestDoc.data()!);
        if (request.status == 'pending' && request.expireAt.isAfter(DateTime.now())) {
          return 'pending_sent';
        }
      }

      // 3. Check if a request was received from other user
      final receivedRequestDoc = await _firestore.collection('friend_requests').doc('${otherUserId}_$currentUserId').get();
      if (receivedRequestDoc.exists && receivedRequestDoc.data() != null) {
        final request = FriendRequestModel.fromJson(receivedRequestDoc.data()!);
        if (request.status == 'pending' && request.expireAt.isAfter(DateTime.now())) {
          return 'pending_received';
        }
      }

      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  // Fetch Recommended Players: Users who are NOT friends and NOT the current user
  Future<List<UserModel>> getRecommendedPlayers(String currentUserId) async {
    try {
      // 1. Fetch current friends
      final friendsModel = await getFriendsListFuture(currentUserId);
      final Set<String> friendsAndSelf = Set<String>.from(friendsModel.friendUids)..add(currentUserId);

      // 2. Fetch some users
      final querySnapshot = await _firestore.collection('users').limit(30).get();

      // 3. Filter out friends & self
      final list = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) => !friendsAndSelf.contains(user.uid))
          .toList();

      return list;
    } catch (e) {
      throw 'Failed to load recommended players: $e';
    }
  }

  // Fetch Friends: Load user profiles of all friends
  Future<List<UserModel>> getFriendsProfiles(String currentUserId) async {
    try {
      final friendsModel = await getFriendsListFuture(currentUserId);
      if (friendsModel.friendUids.isEmpty) return [];

      final List<UserModel> friends = [];
      // Fetch user profile for each friend (limit to 30 for safety)
      for (var uid in friendsModel.friendUids.take(30)) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          friends.add(UserModel.fromJson(userDoc.data()!));
        }
      }
      return friends;
    } catch (e) {
      throw 'Failed to load friends profiles: $e';
    }
  }
}

