import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/chat/data/chat_service.dart';
import 'package:nexus_app/features/chat/presentation/chat_screen.dart';
import 'package:nexus_app/features/friends/presentation/find_ally_radar_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  List<UserModel> _friends = [];
  bool _isLoadingFriends = true;
  String _searchQuery = '';
  final Set<String> _startingChatIds = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    if (_currentUserId.isEmpty) return;
    try {
      final list = await _friendsService.getFriendsProfiles(_currentUserId);
      if (mounted) {
        setState(() {
          _friends = list;
          _isLoadingFriends = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFriends = false;
        });
      }
    }
  }

  Future<void> _startChatWithUser(UserModel otherUser) async {
    if (_currentUserId.isEmpty) return;
    
    setState(() => _startingChatIds.add(otherUser.uid));
    
    try {
      final chatId = await _chatService.getOrCreateChatRoom(_currentUserId, otherUser.uid);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatId: chatId, recipient: otherUser),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _startingChatIds.remove(otherUser.uid));
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  Color _getRandomGlowColor(int index) {
    final colors = [
      AppColors.primaryCyan,
      AppColors.primaryPurple,
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00FF87), // Bright Green
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Section ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Hollow logo circle matching the design
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryCyan,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'NEXUS',
                            style: TextStyle(
                              color: AppColors.primaryCyan,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.explore_outlined, color: Colors.white, size: 24),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FindAllyRadarScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Top Horizontal Friends Avatars ──────────────────────────────
            if (_isLoadingFriends)
              const SizedBox(
                height: 100,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              )
            else if (_friends.isEmpty)
              const SizedBox.shrink()
            else
              SizedBox(
                height: 105,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final isStarting = _startingChatIds.contains(friend.uid);
                    final glowColor = _getRandomGlowColor(index);

                    return GestureDetector(
                      onTap: isStarting ? null : () => _startChatWithUser(friend),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing color border ring
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: glowColor,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: glowColor.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                // Avatar circle image
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor: AppColors.surfaceHighlight,
                                  backgroundImage: friend.profileImageUrl.isNotEmpty
                                      ? NetworkImage(friend.profileImageUrl)
                                      : null,
                                  child: friend.profileImageUrl.isEmpty
                                      ? Text(
                                          friend.username.isNotEmpty
                                              ? friend.username[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: glowColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                ),
                                if (isStarting)
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 62,
                              child: Text(
                                friend.fullName.isNotEmpty ? friend.fullName.split(' ')[0] : friend.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── Search Conversations Bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white30, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Conversations List Section ──────────────────────────────────
            Expanded(
              child: StreamBuilder<List<ChatRoom>>(
                stream: _chatService.getChatRooms(_currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading chats: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white30),
                      ),
                    );
                  }

                  final rooms = snapshot.data ?? [];
                  
                  // Filter based on search query
                  final filteredRooms = rooms.where((room) {
                    final name = (room.recipient.fullName).toLowerCase();
                    final username = (room.recipient.username).toLowerCase();
                    return name.contains(_searchQuery) || username.contains(_searchQuery);
                  }).toList();

                  if (filteredRooms.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white12,
                              size: 48,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No conversation matches your search.'
                                  : 'No active conversations yet.\nTap a friend above to start messaging!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, 100),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      final isStarting = _startingChatIds.contains(room.recipient.uid);

                      return GestureDetector(
                        onTap: isStarting ? null : () => _startChatWithUser(room.recipient),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar with online status dot indicator
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.surfaceHighlight,
                                    backgroundImage: room.recipient.profileImageUrl.isNotEmpty
                                        ? NetworkImage(room.recipient.profileImageUrl)
                                        : null,
                                    child: room.recipient.profileImageUrl.isEmpty
                                        ? Text(
                                            room.recipient.username.isNotEmpty
                                                ? room.recipient.username[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: AppColors.primaryPurple,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          )
                                        : null,
                                  ),
                                  // Online status indicator dot
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.statusOnline,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.surface,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              
                              // Middle details (Name and last message)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.recipient.fullName.isNotEmpty
                                          ? room.recipient.fullName
                                          : room.recipient.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      room.lastMessage.isNotEmpty
                                          ? room.lastMessage
                                          : 'Tap to send a message...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Right details (Timestamp + Badge placeholder if needed)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTimeAgo(room.lastMessageTime),
                                    style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (room.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryCyan,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${room.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.black,
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
