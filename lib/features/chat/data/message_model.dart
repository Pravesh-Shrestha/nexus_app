import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String type; // 'text' | 'image'
  final String imageUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = 'text',
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'imageUrl': imageUrl,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final Timestamp ts = json['timestamp'] as Timestamp? ?? Timestamp.now();
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: ts.toDate(),
      type: json['type'] ?? 'text',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
