import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/community/data/post_model.dart';
import 'package:nexus_app/features/community/data/comment_model.dart';
import 'package:nexus_app/features/community/data/post_service.dart';

class PostDetailsScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';

  late Stream<List<CommentModel>> _commentsStream;
  late Stream<PostModel?> _postStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = _postService.getComments(widget.post.id);
    _postStream = _postService.getPosts(widget.post.communityId).map((posts) {
      final matches = posts.where((p) => p.id == widget.post.id);
      return matches.isNotEmpty ? matches.first : null;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      await _postService.addComment(
        postId: widget.post.id,
        authorId: _currentUserId,
        authorName: _currentUserName.isNotEmpty ? _currentUserName : 'Gamer',
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<PostModel?>(
          stream: _postStream,
          initialData: widget.post,
          builder: (context, snapshot) {
            final post = snapshot.data ?? widget.post;
            final isLiked = post.likedUserIds.contains(_currentUserId);

            return Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Post Content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryPurple,
                                    child: Text(
                                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'P',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Valorant Tactics · ${_formatTimeAgo(post.timestamp)}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Text Content
                              Text(
                                post.content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Image (If any)
                              if (post.imageUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    post.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Tags Row
                              if (post.tags.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: post.tags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white10, width: 0.8),
                                      ),
                                      child: Text(
                                        tag.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Stats Footer Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Like Button
                                      GestureDetector(
                                        onTap: () => _postService.likePost(post.id, _currentUserId),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                                              color: isLiked ? AppColors.primaryCyan : Colors.white38,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${post.likedUserIds.length}',
                                              style: TextStyle(
                                                color: isLiked ? AppColors.primaryCyan : Colors.white38,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),

                                      // Comments Icon
                                      const Icon(Icons.comment_outlined, color: Colors.white38, size: 16),
                                      const SizedBox(width: 6),
                                      StreamBuilder<List<CommentModel>>(
                                        stream: _commentsStream,
                                        builder: (context, snapshot) {
                                          final commentCount = snapshot.data?.length ?? 0;
                                          return Text(
                                            '$commentCount',
                                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 20),

                                      // GG/Views Points Icon
                                      const Icon(Icons.flash_on_outlined, color: Colors.white38, size: 16),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '312',
                                        style: TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.share_outlined, color: Colors.white38, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),

                        // Comments Section Header
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            'Comments',
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // Comments Thread Stream
                        StreamBuilder<List<CommentModel>>(
                          stream: _commentsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                            }
                            final comments = snapshot.data ?? [];
                            if (comments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'No comments yet. Start the conversation!',
                                    style: TextStyle(color: Colors.white24, fontSize: 13),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                final initial = comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'C';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: const Color(0xFF6C8CFF),
                                        child: Text(
                                          initial,
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  comment.authorName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '· ${_formatTimeAgo(comment.timestamp)}',
                                                  style: const TextStyle(
                                                    color: Colors.white30,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment.content,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 13.5,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Composer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF13141B),
                    border: Border(top: BorderSide(color: Colors.white10, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white24),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _submitComment,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
