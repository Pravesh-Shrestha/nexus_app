import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/friends/data/friends_model.dart';
import 'package:nexus_app/features/friends/data/friend_request_model.dart';
import 'package:nexus_app/features/home/data/notification_model.dart';
import 'package:nexus_app/features/home/data/notification_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';

/// Pairs a UserModel with the associated FriendRequestModel.
class FriendRequestEntry {
  final UserModel user;
  final FriendRequestModel request;

  const FriendRequestEntry({required this.user, required this.request});
}

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ── Friends CRUD ───────────────────────────────────────────────────────────

  Stream<FriendsModel> getFriendsList(String uid) {
    return _firestore.collection('friends').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return FriendsModel.fromJson(doc.data()!);
      }
      return FriendsModel(uid: uid);
    });
  }

  Future<FriendsModel> getFriendsListFuture(String uid) async {
    final doc = await _firestore.collection('friends').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return FriendsModel.fromJson(doc.data()!);
    }
    return FriendsModel(uid: uid);
  }

  Future<void> addFriend(String uid, String friendUid) async {
    try {
      await _firestore.collection('friends').doc(uid).set({
        'friendUids': FieldValue.arrayUnion([friendUid]),
      }, SetOptions(merge: true));
      await _firestore.collection('friends').doc(friendUid).set({
        'friendUids': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to add friend: $e';
    }
  }

  Future<void> removeFriend(String uid, String friendUid) async {
    try {
      await _firestore.collection('friends').doc(uid).set({
        'friendUids': FieldValue.arrayRemove([friendUid]),
      }, SetOptions(merge: true));
      await _firestore.collection('friends').doc(friendUid).set({
        'friendUids': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to remove friend: $e';
    }
  }

  // ── Friend Requests ────────────────────────────────────────────────────────

  Future<void> sendFriendRequest(
      String senderId, String senderUsername, String receiverId) async {
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
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .set(request.toJson());

      final notificationId = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .doc()
          .id;
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

  Future<void> acceptFriendRequest(String senderId, String receiverId,
      [String? notificationId]) async {
    try {
      final requestId = '${senderId}_$receiverId';
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted'});
      await addFriend(senderId, receiverId);

      if (notificationId != null && notificationId.isNotEmpty) {
        await _notificationService.updateNotificationStatus(
            receiverId, notificationId, 'accepted');
      } else {
        final notifs = await _firestore
            .collection('users')
            .doc(receiverId)
            .collection('notifications')
            .where('type', isEqualTo: 'friend_request')
            .where('relatedId', isEqualTo: senderId)
            .get();
        for (var doc in notifs.docs) {
          await _notificationService.updateNotificationStatus(
              receiverId, doc.id, 'accepted');
        }
      }
    } catch (e) {
      throw 'Failed to accept friend request: $e';
    }
  }

  Future<void> declineFriendRequest(String senderId, String receiverId,
      [String? notificationId]) async {
    try {
      final requestId = '${senderId}_$receiverId';
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'declined'});

      if (notificationId != null && notificationId.isNotEmpty) {
        await _notificationService.updateNotificationStatus(
            receiverId, notificationId, 'declined');
      } else {
        final notifs = await _firestore
            .collection('users')
            .doc(receiverId)
            .collection('notifications')
            .where('type', isEqualTo: 'friend_request')
            .where('relatedId', isEqualTo: senderId)
            .get();
        for (var doc in notifs.docs) {
          await _notificationService.updateNotificationStatus(
              receiverId, doc.id, 'declined');
        }
      }
    } catch (e) {
      throw 'Failed to decline friend request: $e';
    }
  }

  /// Withdraw / cancel a friend request that the current user sent.
  Future<void> cancelFriendRequest(
      String senderId, String receiverId) async {
    try {
      final requestId = '${senderId}_$receiverId';
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      // Mark the receiver's notification as declined so it disappears
      final notifs = await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .where('type', isEqualTo: 'friend_request')
          .where('relatedId', isEqualTo: senderId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (var doc in notifs.docs) {
        await _notificationService.updateNotificationStatus(
            receiverId, doc.id, 'cancelled');
      }
    } catch (e) {
      throw 'Failed to cancel friend request: $e';
    }
  }

  // ── Status Check ───────────────────────────────────────────────────────────

  /// Returns: 'friends' | 'pending_sent' | 'pending_received' | 'none'
  Future<String> getFriendshipStatus(
      String currentUserId, String otherUserId) async {
    try {
      final friendsDoc =
          await _firestore.collection('friends').doc(currentUserId).get();
      if (friendsDoc.exists && friendsDoc.data() != null) {
        final friendsModel = FriendsModel.fromJson(friendsDoc.data()!);
        if (friendsModel.friendUids.contains(otherUserId)) return 'friends';
      }

      final sentRequestDoc = await _firestore
          .collection('friend_requests')
          .doc('${currentUserId}_$otherUserId')
          .get();
      if (sentRequestDoc.exists && sentRequestDoc.data() != null) {
        final request = FriendRequestModel.fromJson(sentRequestDoc.data()!);
        if (request.status == 'pending' &&
            request.expireAt.isAfter(DateTime.now())) {
          return 'pending_sent';
        }
      }

      final receivedRequestDoc = await _firestore
          .collection('friend_requests')
          .doc('${otherUserId}_$currentUserId')
          .get();
      if (receivedRequestDoc.exists && receivedRequestDoc.data() != null) {
        final request =
            FriendRequestModel.fromJson(receivedRequestDoc.data()!);
        if (request.status == 'pending' &&
            request.expireAt.isAfter(DateTime.now())) {
          return 'pending_received';
        }
      }

      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  // ── Profile Loaders ────────────────────────────────────────────────────────

  /// Fetch all profiles for user's friends list.
  Future<List<UserModel>> getFriendsProfiles(String currentUserId) async {
    try {
      final friendsModel = await getFriendsListFuture(currentUserId);
      if (friendsModel.friendUids.isEmpty) return [];

      final List<UserModel> friends = [];
      for (var uid in friendsModel.friendUids.take(30)) {
        final userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          friends.add(UserModel.fromJson(userDoc.data()!));
        }
      }
      return friends;
    } catch (e) {
      throw 'Failed to load friends profiles: $e';
    }
  }

  /// Fetch all received pending friend requests with the sender's profile.
  Future<List<FriendRequestEntry>> getReceivedRequestsWithProfiles(
      String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      final results = <FriendRequestEntry>[];
      for (final doc in snapshot.docs) {
        final request = FriendRequestModel.fromJson(doc.data());
        if (request.expireAt.isAfter(DateTime.now())) {
          final userDoc = await _firestore
              .collection('users')
              .doc(request.senderId)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            results.add(FriendRequestEntry(
              request: request,
              user: UserModel.fromJson(userDoc.data()!),
            ));
          }
        }
      }
      return results;
    } catch (e) {
      throw 'Failed to load received requests: $e';
    }
  }

  /// Fetch all sent pending friend requests with the receiver's profile.
  Future<List<FriendRequestEntry>> getSentRequestsWithProfiles(
      String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      final results = <FriendRequestEntry>[];
      for (final doc in snapshot.docs) {
        final request = FriendRequestModel.fromJson(doc.data());
        if (request.expireAt.isAfter(DateTime.now())) {
          final userDoc = await _firestore
              .collection('users')
              .doc(request.receiverId)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            results.add(FriendRequestEntry(
              request: request,
              user: UserModel.fromJson(userDoc.data()!),
            ));
          }
        }
      }
      return results;
    } catch (e) {
      throw 'Failed to load sent requests: $e';
    }
  }

  /// Recommended players: users who are NOT friends AND have no pending
  /// request (sent or received) with the current user.
  Future<List<UserModel>> getRecommendedPlayers(String currentUserId) async {
    try {
      // 1. Collect all excluded UIDs: friends + self
      final friendsModel = await getFriendsListFuture(currentUserId);
      final Set<String> excluded =
          Set<String>.from(friendsModel.friendUids)..add(currentUserId);

      // 2. Exclude users with a pending sent request
      final sentSnap = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (final doc in sentSnap.docs) {
        final req = FriendRequestModel.fromJson(doc.data());
        if (req.expireAt.isAfter(DateTime.now())) {
          excluded.add(req.receiverId);
        }
      }

      // 3. Exclude users with a pending received request
      final receivedSnap = await _firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (final doc in receivedSnap.docs) {
        final req = FriendRequestModel.fromJson(doc.data());
        if (req.expireAt.isAfter(DateTime.now())) {
          excluded.add(req.senderId);
        }
      }

      // 4. Fetch users and filter
      final querySnapshot =
          await _firestore.collection('users').limit(50).get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) => !excluded.contains(user.uid))
          .toList();
    } catch (e) {
      throw 'Failed to load recommended players: $e';
    }
  }
}
