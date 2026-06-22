import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';

class FindAllyScreen extends StatefulWidget {
  const FindAllyScreen({super.key});

  @override
  State<FindAllyScreen> createState() => _FindAllyScreenState();
}

class _FindAllyScreenState extends State<FindAllyScreen> {
  final FriendsService _friendsService = FriendsService();
  bool _isFriendsTab = true;
  bool _isLoading = true;
  
  List<UserModel> _friends = [];
  List<UserModel> _feedPlayers = [];
  int _pendingRequestsCount = 0;

  // Premium mock allies fallback if DB query is empty
  final List<Map<String, dynamic>> _mockAllies = [
    {
      'name': 'Persona 1',
      'avatar': 'Z',
      'avatarColor': Colors.green,
      'isOnline': true,
      'badges': ['TACTICAL', 'SNIPER'],
      'bio': 'Tactical IGL · always down to queue',
      'rank': 'Immortal 2',
      'game': 'Valorant',
      'friendsCount': '1.2k',
      'communitiesCount': '42',
      'gameBadges': ['TACTICAL', 'SNIPER', 'Methodical', 'Shotcaller'],
    },
    {
      'name': 'Nova_Strike',
      'avatar': 'N',
      'avatarColor': Colors.purple,
      'isOnline': true,
      'badges': ['SUPPORT', 'CASUAL'],
      'bio': 'Support player looking for competitive team play',
      'rank': 'Diamond 1',
      'game': 'Apex Legends',
      'friendsCount': '482',
      'communitiesCount': '15',
      'gameBadges': ['SUPPORT', 'CASUAL', 'Team-player'],
    },
    {
      'name': 'Rift_Walker',
      'avatar': 'R',
      'avatarColor': Colors.teal,
      'isOnline': false,
      'lastSeen': 'Last seen 3h ago',
      'badges': ['ENTRY', 'COMPETITIVE'],
      'bio': 'Entry fragger looking for an active squad',
      'rank': 'Gold 3',
      'game': 'Valorant',
      'friendsCount': '210',
      'communitiesCount': '8',
      'gameBadges': ['ENTRY', 'COMPETITIVE', 'Aggressive'],
    },
    {
      'name': 'Pixel_Queen',
      'avatar': 'P',
      'avatarColor': Colors.pink,
      'isOnline': false,
      'lastSeen': 'Last seen 1d ago',
      'badges': ['CREATIVE', 'CASUAL'],
      'bio': 'Cozy gamer, mostly playing for fun and chill sessions',
      'rank': 'Silver 2',
      'game': 'Minecraft',
      'friendsCount': '850',
      'communitiesCount': '24',
      'gameBadges': ['CREATIVE', 'CASUAL', 'Builder'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      try {
        // 1. Fetch friends list profiles
        final friendsList = await _friendsService.getFriendsProfiles(user.uid);
        
        // 2. Fetch recommended feed profiles
        final recommendedList = await _friendsService.getRecommendedPlayers(user.uid);

        // 3. Fetch count of pending requests from notifications subcollection
        final requestsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('type', isEqualTo: 'friend_request')
            .where('status', isEqualTo: 'pending')
            .get();
        
        if (mounted) {
          setState(() {
            _friends = friendsList;
            _feedPlayers = recommendedList;
            _pendingRequestsCount = requestsSnap.docs.length;
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
    // Decide whether to show DB players or fallback to mocks
    final bool showDbFeed = _feedPlayers.isNotEmpty;
    final bool showDbFriends = _friends.isNotEmpty;

    // Filter which list to render based on active tab
    final List<dynamic> activeList = _isFriendsTab
        ? (showDbFriends ? _friends : _mockAllies.take(2).toList())
        : (showDbFeed ? _feedPlayers : _mockAllies);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button & Explore circular indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceHighlight,
                      border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.15), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.explore_outlined, color: AppColors.primaryCyan, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title Header
              const Text(
                'Find Your Ally',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Discover elite players matching your DNA.',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Toggle Tab & Request Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tab Switch
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isFriendsTab = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isFriendsTab ? AppColors.surfaceHighlight : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Friends',
                              style: TextStyle(
                                color: _isFriendsTab ? Colors.white : Colors.white30,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isFriendsTab = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isFriendsTab ? AppColors.surfaceHighlight : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Feed',
                              style: TextStyle(
                                color: !_isFriendsTab ? Colors.white : Colors.white30,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Requests count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Text(
                      'Requests · ${_pendingRequestsCount > 0 ? _pendingRequestsCount : (showDbFeed ? 0 : 4)}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Demo mode warning if Firestore is empty
              if (!_isLoading && _isFriendsTab && !showDbFriends)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppColors.primaryPurple, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing offline demo allies (no mutual friends in database yet).',
                            style: TextStyle(color: AppColors.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isLoading && !_isFriendsTab && !showDbFeed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppColors.primaryPurple, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing offline demo players (no recommended users in database yet).',
                            style: TextStyle(color: AppColors.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Allies list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                    : ListView.builder(
                        itemCount: activeList.length,
                        itemBuilder: (context, index) {
                          final item = activeList[index];
                          return _buildAllyListItem(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllyListItem(dynamic item) {
    final bool isUserModel = item is UserModel;
    
    final String name = isUserModel
        ? (item.fullName.isNotEmpty ? item.fullName : item.username)
        : (item['name'] as String);

    final String username = isUserModel
        ? item.username
        : (item['name'] as String);

    final String avatar = username.isNotEmpty ? username[0].toUpperCase() : 'A';
    
    final Color avatarColor = isUserModel
        ? _getAvatarColor(item.uid)
        : (item['avatarColor'] as Color? ?? Colors.purple);

    final bool isOnline = isUserModel ? true : (item['isOnline'] as bool? ?? false);
    
    final List<String> badges = isUserModel
        ? [item.role, item.playstyle].where((b) => b.isNotEmpty).toList()
        : List<String>.from(item['badges'] ?? ['TACTICAL', 'SNIPER']);

    if (badges.isEmpty) {
      badges.addAll(['TACTICAL', 'SNIPER']);
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => isUserModel
                ? ViewFriendScreen(userModel: item)
                : ViewFriendScreen(allyData: item),
          ),
        ).then((_) => _loadData()); // Reload when coming back
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar Stack with Online status
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarColor.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        avatar,
                        style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppColors.statusOnline : Colors.grey,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Title and Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Badges row
                    Row(
                      children: badges
                          .map((badge) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // Action Msg button (Right Arrow or Msg)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOnline
                        ? AppColors.statusOnline.withValues(alpha: 0.5)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFriendsTab ? Icons.chat_bubble_outline : Icons.arrow_forward_ios,
                      color: isOnline ? AppColors.statusOnline : Colors.white30,
                      size: 14,
                    ),
                    if (_isFriendsTab) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Msg',
                        style: TextStyle(
                          color: isOnline ? AppColors.statusOnline : Colors.white30,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
