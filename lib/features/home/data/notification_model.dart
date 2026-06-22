import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String type; // 'friend_request' | 'gg' | 'rsvp' | 'invite' | 'mention'
  final bool isRead;
  final DateTime createdAt;
  final DateTime expireAt;
  final String? relatedId; // e.g., senderId for friend request, or roomId
  final String? status; // 'pending' | 'accepted' | 'declined' (for friend_request type)

  NotificationModel({
    required this.id,
    required this.title,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    required this.expireAt,
    this.relatedId,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'expireAt': Timestamp.fromDate(expireAt),
      'relatedId': relatedId,
      'status': status,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expireAt: (json['expireAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 20)),
      relatedId: json['relatedId'],
      status: json['status'],
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expireAt,
    String? relatedId,
    String? status,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expireAt: expireAt ?? this.expireAt,
      relatedId: relatedId ?? this.relatedId,
      status: status ?? this.status,
    );
  }
}
