import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final String content;
  final String imageUrl;
  final List<String> tags;
  final List<String> likedUserIds;
  final DateTime timestamp;

  PostModel({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.imageUrl = '',
    this.tags = const [],
    this.likedUserIds = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'imageUrl': imageUrl,
      'tags': tags,
      'likedUserIds': likedUserIds,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final Timestamp ts = json['timestamp'] as Timestamp? ?? Timestamp.now();
    return PostModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      likedUserIds: List<String>.from(json['likedUserIds'] ?? []),
      timestamp: ts.toDate(),
    );
  }
}
