import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/community/data/community_model.dart';
import 'package:nexus_app/features/community/data/community_service.dart';
import 'package:nexus_app/features/explore/presentation/community_details_screen.dart';
import 'package:nexus_app/features/friends/presentation/widgets/friendship_status_button.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserListsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final bool initialShowCommunities;

  const UserListsScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialShowCommunities = false,
  });

  @override
  State<UserListsScreen> createState() => _UserListsScreenState();
}

class _UserListsScreenState extends State<UserListsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();
  final CommunityService _communityService = CommunityService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialShowCommunities ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final String title = widget.userId == _currentUserId ? 'My Hub' : "${widget.userName}'s Hub";
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Communities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildCommunitiesTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return FutureBuilder<List<UserModel>>(
      future: _friendsService.getFriendsProfiles(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(
            child: Text(
              'No friends connected.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.p24),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final name = friend.username.isNotEmpty ? friend.username : friend.fullName;
            final role = friend.role.isNotEmpty ? '${friend.role} · ${friend.playstyle}' : 'Member';
            final avatarColor = _getAvatarColor(name);

            return GestureDetector(
              onTap: () {
                if (friend.uid == _currentUserId) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewFriendScreen(userModel: friend),
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
                          backgroundColor: avatarColor,
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
                    if (friend.uid != _currentUserId)
                      FriendshipStatusButton(
                        currentUserId: _currentUserId,
                        otherUserId: friend.uid,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommunitiesTab() {
    return StreamBuilder<List<CommunityModel>>(
      stream: _communityService.getJoinedCommunities(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'No joined communities.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.p24),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final community = list[index];
            final isCreator = community.creatorId == widget.userId;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityDetailsScreen(community: community),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            community.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCreator
                            ? AppColors.primaryPurple.withValues(alpha: 0.15)
                            : AppColors.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCreator ? AppColors.primaryPurple : AppColors.primaryCyan,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isCreator ? 'OWNER' : 'MEMBER',
                        style: TextStyle(
                          color: isCreator ? AppColors.primaryPurple : AppColors.primaryCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
