import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/community/data/post_model.dart';
import 'package:nexus_app/features/community/data/comment_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of posts in a community
  Stream<List<PostModel>> getPosts(String communityId) {
    return _firestore
        .collection('posts')
        .where('communityId', isEqualTo: communityId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Create a new post
  Future<void> createPost({
    required String communityId,
    required String authorId,
    required String authorName,
    required String content,
    String imageUrl = '',
    List<String> tags = const [],
  }) async {
    try {
      final docRef = _firestore.collection('posts').doc();
      final post = PostModel(
        id: docRef.id,
        communityId: communityId,
        authorId: authorId,
        authorName: authorName,
        content: content,
        imageUrl: imageUrl,
        tags: tags,
        likedUserIds: const [],
        timestamp: DateTime.now(),
      );

      await docRef.set(post.toJson());
    } catch (e) {
      throw 'Failed to create post: $e';
    }
  }

  // Like or unlike a post
  Future<void> likePost(String postId, String userId) async {
    try {
      final docRef = _firestore.collection('posts').doc(postId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final post = PostModel.fromJson(doc.data()!);
      if (post.likedUserIds.contains(userId)) {
        await docRef.update({
          'likedUserIds': FieldValue.arrayRemove([userId]),
        });
      } else {
        await docRef.update({
          'likedUserIds': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw 'Failed to like post: $e';
    }
  }

  // Get comments stream
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommentModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    try {
      final commentsRef = _firestore.collection('posts').doc(postId).collection('comments');
      final docRef = commentsRef.doc();
      final comment = CommentModel(
        id: docRef.id,
        authorId: authorId,
        authorName: authorName,
        content: content,
        timestamp: DateTime.now(),
      );

      await docRef.set(comment.toJson());
    } catch (e) {
      throw 'Failed to add comment: $e';
    }
  }
}
