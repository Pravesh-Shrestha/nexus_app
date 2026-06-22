import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';

class FindAllyScreen extends StatefulWidget {
  const FindAllyScreen({super.key});

  @override
  State<FindAllyScreen> createState() => _FindAllyScreenState();
}

class _FindAllyScreenState extends State<FindAllyScreen> {
  bool _isFriendsTab = true;

  final List<Map<String, dynamic>> _allies = [
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
  Widget build(BuildContext context) {
    final onlineAllies = _allies.where((item) => item['isOnline']).toList();
    final offlineAllies = _allies.where((item) => !item['isOnline']).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button & Search Circular Radar
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

              // Toggle & Request badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tab switches
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
                    child: const Text(
                      'Requests · 4',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Allies list
              Expanded(
                child: ListView(
                  children: [
                    if (onlineAllies.isNotEmpty) ...[
                      _buildHeaderLabel('ONLINE — ${onlineAllies.length}', AppColors.statusOnline),
                      ...onlineAllies.map((item) => _buildAllyCard(item)),
                      const SizedBox(height: 20),
                    ],
                    if (offlineAllies.isNotEmpty) ...[
                      _buildHeaderLabel('OFFLINE — ${offlineAllies.length}', Colors.white24),
                      ...offlineAllies.map((item) => _buildAllyCard(item)),
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

  Widget _buildHeaderLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAllyCard(Map<String, dynamic> ally) {
    final bool isOnline = ally['isOnline'];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ViewFriendScreen(allyData: ally),
          ),
        );
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
                      color: (ally['avatarColor'] as Color).withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        ally['avatar'] as String,
                        style: TextStyle(
                          color: ally['avatarColor'] as Color,
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
                      ally['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badges row
                    Row(
                      children: (ally['badges'] as List<String>)
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

              // Action Msg button
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
                      Icons.chat_bubble_outline,
                      color: isOnline ? AppColors.statusOnline : Colors.white30,
                      size: 14,
                    ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
