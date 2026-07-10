import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/services/cloudinary_service.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';
import 'package:nexus_app/features/community/data/community_model.dart';
import 'package:nexus_app/features/community/data/community_service.dart';
import 'package:nexus_app/features/community/data/post_model.dart';
import 'package:nexus_app/features/community/data/comment_model.dart';
import 'package:nexus_app/features/community/data/post_service.dart';
import 'package:nexus_app/features/explore/presentation/post_details_screen.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/widgets/custom_snackbar.dart';

class CommunityDetailsScreen extends StatefulWidget {
  final CommunityModel community;
  const CommunityDetailsScreen({super.key, required this.community});

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen> with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  final PostService _postService = PostService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'Gamer';

  late TabController _tabController;
  late Stream<CommunityModel?> _communityStream;
  late Stream<List<PostModel>> _postsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Live update stream for community info
    _communityStream = _communityService.getCommunities().map((list) {
      final matches = list.where((c) => c.id == widget.community.id);
      return matches.isNotEmpty ? matches.first : null;
    });

    _postsStream = _postService.getPosts(widget.community.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleJoin(bool isMember) async {
    try {
      if (isMember) {
        await _communityService.leaveCommunity(widget.community.id, _currentUserId);
      } else {
        await _communityService.joinCommunity(widget.community.id, _currentUserId);
      }
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Action Failed',
            message: 'Could not perform community action.',
            actionText: 'Retry',
          ),
        );
      }
    }
  }

  void _deleteCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        title: const Text('Delete Community', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this community permanently?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('communities').doc(widget.community.id).delete();
        if (mounted) {
          Navigator.pop(context); // pop creator menu / details screen
          CustomSnackBar.showSuccessSnackBar(
            context,
            title: 'Success',
            message: 'Community deleted successfully!',
          );
        }
      } on AppException catch (e) {
        if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showErrorSnackBar(
            context,
            AppException(
              title: 'Delete Failed',
              message: 'Failed to delete community. Please try again.',
              actionText: 'Retry',
            ),
          );
        }
      }
    }
  }

  void _editCommunity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCommunitySheet(
        community: widget.community,
      ),
    );
  }

  void _showCreatorMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primaryCyan),
              title: const Text('Edit Community', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editCommunity();
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.errorRed),
              title: const Text('Delete Community', style: TextStyle(color: AppColors.errorRed)),
              onTap: () {
                Navigator.pop(context);
                _deleteCommunity();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(
        communityId: widget.community.id,
        authorId: _currentUserId,
        authorName: _currentUserName.isNotEmpty ? _currentUserName : 'Gamer',
        postService: _postService,
      ),
    );
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
    return StreamBuilder<CommunityModel?>(
      stream: _communityStream,
      initialData: widget.community,
      builder: (context, snapshot) {
        final community = snapshot.data ?? widget.community;
        final isMember = community.memberUids.contains(_currentUserId);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Banner Area
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: community.imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(community.imageUrl), fit: BoxFit.cover)
                      : null,
                  gradient: community.imageUrl.isEmpty
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryPurple.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                ),
              ),
              // Dark gradient overlay on banner
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Back button & Status Pill Overlay
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.4), width: 1),
                            ),
                            child: const Text(
                              'HOT',
                              style: TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (community.creatorId == _currentUserId) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showCreatorMenu,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Main Details Content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Title block and join button row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  community.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${community.memberUids.length} members · 1.1k online',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                           // Join / Joined Button
                           ElevatedButton(
                             style: ElevatedButton.styleFrom(
                               backgroundColor: community.creatorId == _currentUserId
                                   ? AppColors.primaryPurple.withValues(alpha: 0.2)
                                   : const Color(0xFF6C8CFF),
                               foregroundColor: community.creatorId == _currentUserId
                                   ? AppColors.primaryPurple
                                   : Colors.black,
                               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(20),
                                 side: community.creatorId == _currentUserId
                                     ? const BorderSide(color: AppColors.primaryPurple, width: 1)
                                     : BorderSide.none,
                               ),
                               elevation: 0,
                             ),
                             onPressed: () {
                               if (community.creatorId == _currentUserId) {
                                 CustomSnackBar.showErrorSnackBar(
                                   context,
                                   AppException(
                                     title: 'Cannot Leave Community',
                                     message: 'As the creator, you cannot leave this community.',
                                     actionText: 'Okay',
                                   ),
                                 );
                                 return;
                               }
                               _toggleJoin(isMember);
                             },
                             child: Text(
                               community.creatorId == _currentUserId
                                   ? 'Creator'
                                   : (isMember ? 'Joined' : 'Join'),
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                             ),
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom Tabs selector bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryCyan,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primaryCyan,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Feed'),
                          Tab(text: 'Members'),
                          Tab(text: 'Media'),
                        ],
                      ),
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Feed tab
                          _buildFeedTab(),
                          // Members tab
                          _buildMembersTab(community),
                          // Media tab
                          _buildMediaTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreatePostSheet,
            backgroundColor: const Color(0xFF2ECC71),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.black, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildFeedTab() {
    return StreamBuilder<List<PostModel>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }
        final posts = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Share box composer trigger card
            GestureDetector(
              onTap: _showCreatePostSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF13141B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Text(
                        _currentUserName.isNotEmpty ? _currentUserName[0].toUpperCase() : 'G',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Share something with the squad...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'No posts yet. Be the first to share!',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
              )
            else
              ...posts.map((post) => _buildPostCard(post)),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    final isLiked = post.likedUserIds.contains(_currentUserId);
    final isDisliked = post.dislikedUserIds.contains(_currentUserId);
    final initial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'G';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13141B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryPurple,
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Valorant Tactics · ${_formatTimeAgo(post.timestamp)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Content
            Text(
              post.content,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
            ),
            const SizedBox(height: 12),

            // Image
            if (post.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tags
            if (post.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white10, width: 0.8),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Engagement footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: () => _postService.likePost(post.id, _currentUserId),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                            color: isLiked ? AppColors.primaryCyan : Colors.white38,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likedUserIds.length}',
                            style: TextStyle(
                              color: isLiked ? AppColors.primaryCyan : Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Dislike button
                    GestureDetector(
                      onTap: () => _postService.dislikePost(post.id, _currentUserId),
                      child: Row(
                        children: [
                          Icon(
                            isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined,
                            color: isDisliked ? const Color(0xFFFF6B6B) : Colors.white38,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.dislikedUserIds.length}',
                            style: TextStyle(
                              color: isDisliked ? const Color(0xFFFF6B6B) : Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Comments button/icon
                    const Icon(Icons.comment_outlined, color: Colors.white38, size: 15),
                    const SizedBox(width: 6),
                    StreamBuilder<List<CommentModel>>(
                      stream: _postService.getComments(post.id),
                      builder: (context, snapshot) {
                        final commentsLength = snapshot.data?.length ?? 0;
                        return Text(
                          '$commentsLength',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    // GG point icon
                    const Icon(Icons.flash_on_outlined, color: Colors.white38, size: 15),
                    const SizedBox(width: 6),
                    const Text('312', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: 'https://nexusapp.com/post/${post.id}'));
                    CustomSnackBar.showSuccessSnackBar(
                      context,
                      title: 'Copied',
                      message: 'Post link copied to clipboard!',
                    );
                  },
                  child: const Icon(Icons.share_outlined, color: Colors.white38, size: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(CommunityModel community) {
    final memberList = List<String>.from(community.memberUids);
    
    if (memberList.isEmpty) {
      return const Center(
        child: Text('No members yet.', style: TextStyle(color: Colors.white38, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: memberList.length,
      itemBuilder: (context, index) {
        final uid = memberList[index];
        final isCreator = uid == community.creatorId;
        // Mock compatibility score
        final matchPercent = isCreator ? '92%' : (index == 1 ? '80%' : (index == 2 ? '71%' : '64%'));

        return MemberRow(
          uid: uid,
          isCreator: isCreator,
          currentUserId: _currentUserId,
          matchPercent: matchPercent,
        );
      },
    );
  }

  Widget _buildMediaTab() {
    return StreamBuilder<List<PostModel>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }
        final posts = snapshot.data ?? [];
        final mediaUrls = posts
            .where((p) => p.imageUrl.isNotEmpty)
            .map((p) => p.imageUrl)
            .toList();

        if (mediaUrls.isEmpty) {
          return const Center(
            child: Text(
              'No media uploaded in this community.',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: mediaUrls.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                mediaUrls[index],
                fit: BoxFit.cover,
              ),
            );
          },
        );
      },
    );
  }
}

class MemberRow extends StatelessWidget {
  final String uid;
  final bool isCreator;
  final String currentUserId;
  final String matchPercent;

  const MemberRow({
    super.key,
    required this.uid,
    required this.isCreator,
    required this.currentUserId,
    required this.matchPercent,
  });

  Color _getAvatarColor(String seed) {
    final colors = [
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.blue,
      Colors.orange,
      Colors.indigo
    ];
    final hash = seed.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService().getUserData(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        final user = snapshot.data!;
        final name = user.username.isNotEmpty ? user.username : user.fullName;
        final role = user.role.isNotEmpty ? '${user.role} · ${user.playstyle}' : 'Member';
        final color = _getAvatarColor(name);

        return GestureDetector(
          onTap: () {
            if (uid == currentUserId) return; // Don't view yourself
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewFriendScreen(userModel: user),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF13141B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color,
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (isCreator) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CREATOR',
                                  style: TextStyle(color: AppColors.primaryPurple, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          role,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  matchPercent,
                  style: const TextStyle(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditCommunitySheet extends StatefulWidget {
  final CommunityModel community;
  const _EditCommunitySheet({required this.community});

  @override
  State<_EditCommunitySheet> createState() => _EditCommunitySheetState();
}

class _EditCommunitySheetState extends State<_EditCommunitySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.community.name);
    _descController = TextEditingController(text: widget.community.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('communities').doc(widget.community.id).update({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccessSnackBar(
          context,
          title: 'Success',
          message: 'Community updated successfully!',
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomSnackBar.showErrorSnackBar(context, e);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Update Failed',
            message: 'Failed to update community.',
            actionText: 'Retry',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EDIT COMMUNITY', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white60)),
              validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white60)),
              validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C8CFF)),
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Save Changes', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final String communityId;
  final String authorId;
  final String authorName;
  final PostService postService;

  const _CreatePostSheet({
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.postService,
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  File? _imageFile;
  String _uploadedImageUrl = '';
  bool _isUploadingImage = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUploadingImage = true;
        });

        final cloudinaryUrl = await CloudinaryService().uploadImage(_imageFile!);
        setState(() {
          _isUploadingImage = false;
          if (cloudinaryUrl != null) {
            _uploadedImageUrl = cloudinaryUrl;
          }
        });
      }
    } on AppException catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Image Selection Failed',
            message: 'Failed to pick image.',
            actionText: 'Retry',
          ),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPublishing = true);

    try {
      // Split tags
      final tagList = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .map((t) => t.startsWith('#') ? t : '#$t')
          .toList();

      await widget.postService.createPost(
        communityId: widget.communityId,
        authorId: widget.authorId,
        authorName: widget.authorName,
        content: _contentController.text.trim(),
        imageUrl: _uploadedImageUrl,
        tags: tagList,
      );

      if (mounted) {
        CustomSnackBar.showSuccessSnackBar(
          context,
          title: 'Success',
          message: 'Post shared successfully!',
        );
        Navigator.pop(context);
      }
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Post Failed',
            message: 'Failed to share post.',
            actionText: 'Retry',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CREATE POST',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Content text field (Minimal Styling)
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPurple)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please type some content' : null,
              ),
              const SizedBox(height: 16),

              // Tags text field (Minimal Styling)
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tags (comma separated, e.g. competitive, ace)',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPurple)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 16),

              // Closeable Image Preview
              if (_uploadedImageUrl.isNotEmpty) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _uploadedImageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _uploadedImageUrl = '';
                            _imageFile = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Minimal Image Attachment and Publish Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _uploadedImageUrl.isNotEmpty ? AppColors.successGreen : Colors.white60,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isUploadingImage
                              ? 'Uploading...'
                              : (_uploadedImageUrl.isNotEmpty ? 'Change Image' : 'Add Image'),
                          style: TextStyle(
                            color: _uploadedImageUrl.isNotEmpty ? AppColors.successGreen : Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C8CFF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        elevation: 0,
                      ),
                      onPressed: _isPublishing ? null : _submit,
                      child: _isPublishing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
