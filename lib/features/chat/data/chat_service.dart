import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/chat/data/message_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FriendsService _friendsService = FriendsService();

  // Stream of messages for a specific chat room
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Get or create a chat room between two users
  Future<String> getOrCreateChatRoom(String currentUserId, String otherUserId) async {
    try {
      // 1. Enforce friend check
      final friendshipStatus = await _friendsService.getFriendshipStatus(currentUserId, otherUserId);
      if (friendshipStatus != 'friends') {
        throw AppException(
          title: 'Action Denied',
          message: 'You must be mutual friends to send a message.',
          actionText: 'Find Allies',
        );
      }

      // 2. Generate a deterministic chat ID by sorting UIDs alphabetically
      final list = [currentUserId, otherUserId]..sort();
      final chatId = '${list[0]}_${list[1]}';

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'id': chatId,
          'participants': list,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return chatId;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        title: 'Chat Failed',
        message: 'Failed to start chat. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String text, {String type = 'text', String imageUrl = ''}) async {
    try {
      // Check if participants of this chat are still friends
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw AppException(
          title: 'Chat Error',
          message: 'Chat room does not exist.',
          actionText: 'Go Back',
        );
      }
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
      final otherUserId = participants.firstWhere((id) => id != senderId, orElse: () => '');
      
      if (otherUserId.isNotEmpty) {
        final friendshipStatus = await _friendsService.getFriendshipStatus(senderId, otherUserId);
        if (friendshipStatus != 'friends') {
          throw AppException(
            title: 'Message Blocked',
            message: 'You cannot send messages to users who are not in your friends list.',
            actionText: 'Understood',
          );
        }
      }

      final docRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        id: docRef.id,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        type: type,
        imageUrl: imageUrl,
      );

      await docRef.set(message.toJson());
      
      // Update chat room's last message time, lastMessage, and increment recipient's unread count
      final Map<String, dynamic> updateData = {
        'lastMessage': type == 'image' ? 'Sent a photo' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };
      
      if (otherUserId.isNotEmpty) {
        updateData['unreadCounts.$otherUserId'] = FieldValue.increment(1);
      }

      await _firestore.collection('chats').doc(chatId).update(updateData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        title: 'Send Failed',
        message: 'Failed to send message. Please check your connection.',
        actionText: 'Retry',
      );
    }
  }

  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$currentUserId': 0,
      });
    } catch (_) {}
  }

  // Get active conversations list for current user
  Stream<List<ChatRoom>> getChatRooms(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<ChatRoom> rooms = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          try {
            final userDoc = await _firestore.collection('users').doc(otherUserId).get();
            if (userDoc.exists && userDoc.data() != null) {
              final recipient = UserModel.fromJson(userDoc.data()!);
              final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
              
              // Also merge any flat keys (e.g. unreadCounts.UID) that might exist
              data.forEach((key, value) {
                if (key.startsWith('unreadCounts.')) {
                  final uid = key.replaceFirst('unreadCounts.', '');
                  unreadCounts[uid] = value;
                }
              });

              final unreadCount = unreadCounts[currentUserId] as int? ?? 0;

              rooms.add(ChatRoom(
                id: doc.id,
                lastMessage: data['lastMessage'] ?? '',
                lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                recipient: recipient,
                unreadCount: unreadCount,
              ));
            }
          } catch (_) {}
        }
      }
      // Sort by lastMessageTime descending
      rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return rooms;
    });
  }
}

class ChatRoom {
  final String id;
  final String lastMessage;
  final DateTime lastMessageTime;
  final UserModel recipient;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.recipient,
    required this.unreadCount,
  });
}

