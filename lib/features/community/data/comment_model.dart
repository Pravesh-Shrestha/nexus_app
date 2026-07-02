import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final Timestamp ts = json['timestamp'] as Timestamp? ?? Timestamp.now();
    return CommentModel(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      content: json['content'] ?? '',
      timestamp: ts.toDate(),
    );
  }
}
