import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/chat/data/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
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
}
