import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime createdAt;
  final DateTime expireAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.expireAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expireAt': Timestamp.fromDate(expireAt),
    };
  }

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expireAt: (json['expireAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 21)),
    );
  }
}
