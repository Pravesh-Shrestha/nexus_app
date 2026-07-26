import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/home/presentation/notifications_screen.dart';
import 'package:nexus_app/features/friends/presentation/find_ally_screen.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';
import 'package:nexus_app/features/community/data/community_model.dart';
import 'package:nexus_app/features/community/data/community_service.dart';
import 'package:nexus_app/features/event/data/event_model.dart';
import 'package:nexus_app/features/event/data/event_service.dart';
import 'package:nexus_app/features/explore/presentation/community_details_screen.dart';
import 'package:nexus_app/features/explore/presentation/event_details_screen.dart';
import 'package:nexus_app/features/home/presentation/main_layout.dart';
import 'package:nexus_app/core/services/push_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  final FriendsService _friendsService = FriendsService();
  final CommunityService _communityService = CommunityService();
  final EventService _eventService = EventService();
  
  UserModel? _userModel;
  List<UserModel> _friends = [];
  List<UserModel> _recommended = [];
  bool _isLoading = true;
  String _currentUserId = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      // Setup push notification tokens and permissions asynchronously
      PushNotificationService.requestPermissions().then((_) {
        PushNotificationService.getAndSaveToken(user.uid);
      });
      try {
        final results = await Future.wait([
          _authService.getUserData(user.uid),
          _friendsService.getFriendsProfiles(user.uid),
          _friendsService.getRecommendedPlayers(user.uid),
        ]);
        final data = results[0] as UserModel?;
        final friendsList = results[1] as List<UserModel>;
        final recommendedList = results[2] as List<UserModel>;
        
        if (mounted) {
          setState(() {
            _userModel = data;
            _friends = friendsList;
            _recommended = recommendedList;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPlayerAvatarUrl(UserModel user) {
    if (user.profileImageUrl.isNotEmpty && user.profileImageUrl.startsWith('http')) {
      return user.profileImageUrl;
    }
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=${user.username}';
  }

  Widget _buildAvatarImage(String imageUrl, String seed) {
    if (imageUrl.startsWith('data:image') || !imageUrl.startsWith('http')) {
      try {
        final cleanBase64 = imageUrl.contains(',') ? imageUrl.split(',')[1] : imageUrl;
        final decodedBytes = base64Decode(cleanBase64);
        return Image.memory(
          decodedBytes,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Fallback
      }
    }
    return Image.network(
      imageUrl.isNotEmpty ? imageUrl : 'https://api.dicebear.com/7.x/adventurer/png?seed=$seed',
      width: 36,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.network(
        'https://api.dicebear.com/7.x/adventurer/png?seed=$seed',
        width: 36,
        height: 36,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final model = _userModel;
    final String fullName = model?.fullName.isNotEmpty == true ? model!.fullName : 'Gamer';
    final String username = model?.username.isNotEmpty == true ? model!.username : 'User';
    final String imageUrl = model?.profileImageUrl ?? '';
    final String firstName = fullName.split(' ')[0];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
            : RefreshIndicator(
                color: AppColors.primaryPurple,
                onRefresh: _loadHomeData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120), // Padding for bottom nav
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top App Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    'assets/images/splash/Frame.png',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nexus',
                                  style: TextStyle(
                                    color: AppColors.primaryPurple,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    ).then((_) => _loadHomeData());
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceHighlight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: _buildAvatarImage(imageUrl, username),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Greeting Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $firstName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ready to RollOut !!',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Friends Section
                      _buildSectionHeader(
                        'Friends',
                        'Find Allies',
                        onTapAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FindAllyScreen(),
                            ),
                          ).then((_) => _loadHomeData());
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_friends.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                            itemCount: _friends.length,
                            itemBuilder: (context, index) {
                              final friend = _friends[index];
                              final name = friend.fullName.isNotEmpty ? friend.fullName.split(' ')[0] : friend.username;
                              final avatarUrl = _getPlayerAvatarUrl(friend);
                              return _buildPlayerAvatar(
                                name,
                                avatarUrl,
                                true,
                                AppColors.primaryCyan,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ViewFriendScreen(userModel: friend),
                                    ),
                                  ).then((_) => _loadHomeData());
                                },
                              );
                            },
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSizes.r16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'No friends yet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Discover players to build your squad!',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const FindAllyScreen(),
                                      ),
                                    ).then((_) => _loadHomeData());
                                  },
                                  child: const Text('Find Allies'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Recommended Players Section
                      if (_recommended.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Recommended Players',
                          'View More',
                          onTapAction: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FindAllyScreen(),
                              ),
                            ).then((_) => _loadHomeData());
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                            itemCount: _recommended.length,
                            itemBuilder: (context, index) {
                              final player = _recommended[index];
                              final name = player.fullName.isNotEmpty ? player.fullName.split(' ')[0] : player.username;
                              final avatarUrl = _getPlayerAvatarUrl(player);
                              return _buildPlayerAvatar(
                                name,
                                avatarUrl,
                                false,
                                Colors.grey,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ViewFriendScreen(userModel: player),
                                    ),
                                  ).then((_) => _loadHomeData());
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Trending Communities Section
                      _buildSectionHeader(
                        'Trending Communities',
                        'Explore All',
                        onTapAction: () {
                          TabNavigationController.exploreEventsTab.value = false;
                          TabNavigationController.activeTab.value = 1;
                        },
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                        child: StreamBuilder<List<CommunityModel>>(
                          stream: _communityService.getCommunities(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                            }
                            final list = snapshot.data ?? [];
                            if (list.isEmpty) {
                              return const Center(
                                child: Text('No communities found.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                              );
                            }
                            // Sort by membership count descending to show "trending"
                            final sorted = List<CommunityModel>.from(list)
                              ..sort((a, b) => b.memberUids.length.compareTo(a.memberUids.length));
                            final trending = sorted.take(2).toList();

                            return Column(
                              children: trending.map((community) {
                                final isJoined = community.memberUids.contains(_currentUserId);
                                final badge = community.memberUids.length >= 3 ? 'HOT' : 'GLOBAL';
                                final badgeColor = community.memberUids.length >= 3 ? AppColors.statusOnline : AppColors.primaryPurple;
                                final imgUrl = community.imageUrl.isNotEmpty
                                    ? community.imageUrl
                                    : 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200&auto=format&fit=crop';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildCommunityCard(
                                    community: community,
                                    isJoined: isJoined,
                                    badge: badge,
                                    badgeColor: badgeColor,
                                    imageUrl: imgUrl,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Upcoming Events Section
                      _buildSectionHeader(
                        'Upcoming Events',
                        'Explore All',
                        onTapAction: () {
                          TabNavigationController.exploreEventsTab.value = true;
                          TabNavigationController.activeTab.value = 1;
                        },
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                        child: StreamBuilder<List<EventModel>>(
                          stream: _eventService.getEvents(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                            }
                            final list = snapshot.data ?? [];
                            // Filter for upcoming events
                            final upcoming = list.where((e) => e.dateTime.isAfter(DateTime.now())).toList();

                            if (upcoming.isEmpty) {
                              return const Center(
                                child: Text('No upcoming events.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                              );
                            }
                            
                            // Render the single closest upcoming event
                            final event = upcoming.first;
                            final diff = event.dateTime.difference(DateTime.now());
                            String liveBadge = 'LIVE IN ${diff.inHours}H';
                            if (diff.inHours == 0) {
                              liveBadge = 'LIVE IN ${diff.inMinutes}M';
                            } else if (diff.inDays > 0) {
                              liveBadge = 'IN ${diff.inDays} DAYS';
                            }

                            // Host Community name parse
                            String hostCommunity = 'Valorant Tactics';
                            if (event.description.contains('Hosted by community:')) {
                              final parts = event.description.split('Hosted by community:');
                              if (parts.length > 1) {
                                final subParts = parts[1].split('. Game:');
                                if (subParts.isNotEmpty) {
                                  hostCommunity = subParts[0].trim();
                                }
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailsScreen(event: event, currentUserId: _currentUserId),
                                  ),
                                );
                              },
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppSizes.r24),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=800&auto=format&fit=crop'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppSizes.r24),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        AppColors.secondaryPurple.withValues(alpha: 0.9),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(AppSizes.p20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryPurple.withValues(alpha: 0.8),
                                              borderRadius: BorderRadius.circular(AppSizes.r16),
                                            ),
                                            child: Text(
                                              liveBadge,
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceHighlight.withValues(alpha: 0.8),
                                              borderRadius: BorderRadius.circular(AppSizes.r16),
                                              border: Border.all(color: Colors.white24),
                                            ),
                                            child: Text(
                                              hostCommunity,
                                              style: const TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, {VoidCallback? onTapAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onTapAction,
            child: Text(
              action,
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(String name, String imageUrl, bool isOnline, Color glowColor, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.p20),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: glowColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF00), // Online green
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard({
    required CommunityModel community,
    required bool isJoined,
    required String badge,
    required Color badgeColor,
    required String imageUrl,
  }) {
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
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.r16),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(color: badgeColor, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    community.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, color: AppColors.textMuted, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${community.memberUids.length} Active',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                      if (community.creatorId == _currentUserId || isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: community.creatorId == _currentUserId
                                ? AppColors.primaryPurple.withValues(alpha: 0.15)
                                : AppColors.primaryCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: community.creatorId == _currentUserId
                                  ? AppColors.primaryPurple
                                  : AppColors.primaryCyan,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            community.creatorId == _currentUserId ? 'OWNER' : 'MEMBER',
                            style: TextStyle(
                              color: community.creatorId == _currentUserId
                                  ? AppColors.primaryPurple
                                  : AppColors.primaryCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
