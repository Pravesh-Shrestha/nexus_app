import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/services/cloudinary_service.dart';
import 'package:nexus_app/features/community/data/community_model.dart';
import 'package:nexus_app/features/community/data/community_service.dart';
import 'package:nexus_app/features/community/data/post_model.dart';
import 'package:nexus_app/features/community/data/comment_model.dart';
import 'package:nexus_app/features/community/data/post_service.dart';
import 'package:nexus_app/features/explore/presentation/post_details_screen.dart';

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
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
                              backgroundColor: const Color(0xFF6C8CFF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            onPressed: () => _toggleJoin(isMember),
                            child: Text(
                              isMember ? 'Joined' : 'Join',
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
                const Icon(Icons.share_outlined, color: Colors.white38, size: 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(CommunityModel community) {
    // Generate simple list of members starting with creator
    final memberList = List<String>.from(community.memberUids);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: memberList.length,
      itemBuilder: (context, index) {
        final uid = memberList[index];
        final isCreator = uid == community.creatorId;
        final name = isCreator ? 'Zenith_Pro' : (index == 1 ? 'Nova_Strike' : (index == 2 ? 'Rift_Walker' : 'Pixel_Queen'));
        final role = isCreator ? 'Immortal 2 · TACTICAL' : (index == 1 ? 'Diamond 1 · SUPPORT' : (index == 2 ? 'Platinum 1 · ENTRY' : 'Diamond 1 · FLEX'));
        final matchPercent = isCreator ? '92%' : (index == 1 ? '80%' : (index == 2 ? '71%' : '64%'));
        final color = isCreator ? Colors.green : (index == 1 ? Colors.purple : (index == 2 ? Colors.cyan : Colors.pink));

        return Container(
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
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppColors.errorRed),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!'), backgroundColor: AppColors.successGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share post: $e'), backgroundColor: AppColors.errorRed),
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
              const SizedBox(height: 20),

              // Content text field
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: const TextStyle(color: Colors.white24),
                  fillColor: const Color(0xFF13141B),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please type some content' : null,
              ),
              const SizedBox(height: 16),

              // Tags text field
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tags (comma separated, e.g. competitive, ace)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  fillColor: const Color(0xFF13141B),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // Image attachment upload
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13141B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: Center(
                    child: _isUploadingImage
                        ? const CircularProgressIndicator(color: AppColors.primaryPurple)
                        : _uploadedImageUrl.isNotEmpty
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                                  SizedBox(width: 8),
                                  Text('Image Attached', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 20),
                                  SizedBox(width: 8),
                                  Text('Attach Image', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Publish button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C8CFF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isPublishing ? null : _submit,
                  child: _isPublishing
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Publish Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
