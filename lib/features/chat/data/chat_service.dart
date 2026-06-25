import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/chat/data/message_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';

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
        throw 'You must be mutual friends to send a message.';
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
    } catch (e) {
      throw 'Failed to start chat: $e';
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      // Check if participants of this chat are still friends
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw 'Chat room does not exist.';
      }
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
      final otherUserId = participants.firstWhere((id) => id != senderId, orElse: () => '');
      
      if (otherUserId.isNotEmpty) {
        final friendshipStatus = await _friendsService.getFriendshipStatus(senderId, otherUserId);
        if (friendshipStatus != 'friends') {
          throw 'You cannot send messages to users who are not in your friends list.';
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
      );

      await docRef.set(message.toJson());
      
      // Update chat room's last message time and metadata
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to send message: $e';
    }
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
              rooms.add(ChatRoom(
                id: doc.id,
                lastMessage: data['lastMessage'] ?? '',
                lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
                recipient: recipient,
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

  ChatRoom({
    required this.id,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.recipient,
  });
}

