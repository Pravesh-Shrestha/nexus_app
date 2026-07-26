import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/chat/presentation/chat_screen.dart';
import 'package:nexus_app/features/chat/data/chat_service.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/widgets/custom_snackbar.dart';
import 'package:nexus_app/features/friends/presentation/user_lists_screen.dart';

class ViewFriendScreen extends StatefulWidget {
  final Map<String, dynamic>? allyData;
  final UserModel? userModel;

  const ViewFriendScreen({
    super.key,
    this.allyData,
    this.userModel,
  });

  @override
  State<ViewFriendScreen> createState() => _ViewFriendScreenState();
}

class _ViewFriendScreenState extends State<ViewFriendScreen> {
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService();
  
  String _friendshipStatus = 'none'; // 'friends' | 'pending_sent' | 'pending_received' | 'none'
  bool _isLoading = true;
  String _currentUserId = '';
  String _currentUserUsername = 'User';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndStatus();
  }

  Future<void> _loadCurrentUserAndStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      try {
        // Load current user username to send in friend request notifications
        final currentProfile = await AuthService().getUserData(user.uid);
        if (currentProfile != null) {
          _currentUserUsername = currentProfile.username;
        }

        final targetId = _getTargetUserId();
        if (targetId.isNotEmpty) {
          final status = await _friendsService.getFriendshipStatus(user.uid, targetId);
          if (mounted) {
            setState(() {
              _friendshipStatus = status;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        // Fallback
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTargetUserId() {
    if (widget.userModel != null) {
      return widget.userModel!.uid;
    }
    if (widget.allyData != null && widget.allyData!['uid'] != null) {
      return widget.allyData!['uid'] as String;
    }
    // Mock user ID if none exists for mockup data
    return widget.allyData?['name'] ?? 'mock_user_id';
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

  void _sendFriendRequest() async {
    final targetId = _getTargetUserId();
    if (targetId.isEmpty || _currentUserId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _friendsService.sendFriendRequest(_currentUserId, _currentUserUsername, targetId);
      if (mounted) {
        CustomSnackBar.showSuccessSnackBar(
          context,
          title: 'Request Sent',
          message: 'Friend request sent!',
        );
        _loadCurrentUserAndStatus();
      }
    } on AppException catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(context, e);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Request Failed',
            message: 'Failed to send request.',
            actionText: 'Retry',
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _acceptFriendRequest() async {
    final targetId = _getTargetUserId();
    if (targetId.isEmpty || _currentUserId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Direct accept (since we are on profile, search notification automatically)
      await _friendsService.acceptFriendRequest(targetId, _currentUserId);
      if (mounted) {
        CustomSnackBar.showSuccessSnackBar(
          context,
          title: 'Accepted',
          message: 'Friend request accepted!',
        );
        _loadCurrentUserAndStatus();
      }
    } on AppException catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(context, e);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Action Failed',
            message: 'Failed to accept request.',
            actionText: 'Retry',
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _declineFriendRequest() async {
    final targetId = _getTargetUserId();
    if (targetId.isEmpty || _currentUserId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _friendsService.declineFriendRequest(targetId, _currentUserId);
      if (mounted) {
        CustomSnackBar.showSuccessSnackBar(
          context,
          title: 'Declined',
          message: 'Friend request declined.',
        );
        _loadCurrentUserAndStatus();
      }
    } on AppException catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(context, e);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Action Failed',
            message: 'Failed to decline request.',
            actionText: 'Retry',
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startChat() async {
    final targetId = _getTargetUserId();
    if (targetId.isEmpty || _currentUserId.isEmpty) return;

    // Check if they are friends
    if (_friendshipStatus != 'friends') {
      CustomSnackBar.showErrorSnackBar(
        context,
        AppException(
          title: 'Cannot Message',
          message: 'You must be mutual friends to send a message.',
          actionText: 'Okay',
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final chatId = await _chatService.getOrCreateChatRoom(_currentUserId, targetId);
      
      // Get recipient model
      UserModel recipientModel;
      if (widget.userModel != null) {
        recipientModel = widget.userModel!;
      } else {
        recipientModel = UserModel(
          uid: targetId,
          email: '',
          fullName: widget.allyData?['name'] ?? 'Player',
          username: widget.allyData?['name'] ?? 'Player',
          dob: '',
          gender: '',
          profileImageUrl: '',
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              recipient: recipientModel,
            ),
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(context, e);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Chat Failed',
            message: 'Failed to start chat.',
            actionText: 'Retry',
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine data source
    final String name = widget.userModel != null
        ? (widget.userModel!.fullName.isNotEmpty ? widget.userModel!.fullName : widget.userModel!.username)
        : (widget.allyData?['name'] ?? 'Player');

    final String username = widget.userModel != null
        ? widget.userModel!.username
        : (widget.allyData?['name'] ?? 'Player');

    final String avatar = username.isNotEmpty ? username[0].toUpperCase() : 'P';
    
    final Color avatarColor = widget.userModel != null
        ? _getAvatarColor(widget.userModel!.uid)
        : (widget.allyData?['avatarColor'] as Color? ?? Colors.purple);

    final bool isOnline = widget.userModel != null ? true : (widget.allyData?['isOnline'] ?? false);

    final String bio = widget.userModel != null
        ? (widget.userModel!.bio.isNotEmpty ? widget.userModel!.bio : 'Active gamer · down to squad up')
        : (widget.allyData?['bio'] ?? 'IGL · looking for competitive team play');

    final String friendsCount = widget.allyData?['friendsCount'] ?? '150';
    final String communitiesCount = widget.allyData?['communitiesCount'] ?? '8';

    final String game = widget.userModel != null
        ? (widget.userModel!.favoriteGames.isNotEmpty ? widget.userModel!.favoriteGames.join(', ') : 'Valorant')
        : (widget.allyData?['game'] ?? 'Valorant');

    final String rank = widget.userModel != null
        ? (widget.userModel!.skillLevel.isNotEmpty ? widget.userModel!.skillLevel : 'Pro')
        : (widget.allyData?['rank'] ?? 'Diamond 2');

    final List<String> gameBadges = widget.userModel != null
        ? [widget.userModel!.role, widget.userModel!.playstyle, ...widget.userModel!.favoriteGames]
            .where((e) => e.isNotEmpty)
            .toList()
        : List<String>.from(widget.allyData?['gameBadges'] ?? ['TACTICAL', 'SNIPER', 'Aggressive']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  
                  // Large Avatar Stack
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatarColor.withValues(alpha: 0.15),
                            border: Border.all(
                              color: avatarColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avatar,
                              style: TextStyle(
                                color: avatarColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 48,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 4,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? AppColors.statusOnline : Colors.grey,
                              border: Border.all(color: AppColors.background, width: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name & League/Level Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.statusOnline.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'PRO LEAGUE',
                          style: TextStyle(
                            color: AppColors.statusOnline,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bio
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats grid (Friends & Communities cards side-by-side)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserListsScreen(
                                  userId: _getTargetUserId(),
                                  userName: name,
                                  initialShowCommunities: false,
                                ),
                              ),
                            );
                          },
                          child: _buildStatCard('Friends', friendsCount),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserListsScreen(
                                  userId: _getTargetUserId(),
                                  userName: name,
                                  initialShowCommunities: true,
                                ),
                              ),
                            );
                          },
                          child: _buildStatCard('Communities', communitiesCount),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Actions Row
                  _buildActionsRow(),
                  
                  const SizedBox(height: 32),

                  // Gaming DNA card section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GAMING DNA',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Game and Rank Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                game,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              rank,
                              style: const TextStyle(
                                color: AppColors.statusOnline,
                                fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 28),

                          // Badges wrap
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: gameBadges
                                .map((badge) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceHighlight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                      ),
                                      child: Text(
                                        badge,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow() {
    // If not logged in or looking at ourselves
    if (_currentUserId.isEmpty || _currentUserId == _getTargetUserId()) {
      return const SizedBox.shrink();
    }

    if (_friendshipStatus == 'friends') {
      return Row(
        children: [
          // Friend Status indicator
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
                color: AppColors.surface,
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.statusOnline, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Mutual Friends',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Chat / Message button
          Expanded(
            child: GestureDetector(
              onTap: _startChat,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.authButtonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_friendshipStatus == 'pending_sent') {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
                color: AppColors.surface,
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Colors.amberAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Request Pending',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Disabled Message button (with prompt on click)
          Expanded(
            child: GestureDetector(
              onTap: () {
                CustomSnackBar.showErrorSnackBar(
                  context,
                  AppException(
                    title: 'Cannot Message',
                    message: 'You cannot message until they accept your friend request.',
                    actionText: 'Okay',
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white24, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Message',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_friendshipStatus == 'pending_received') {
      return Column(
        children: [
          const Text(
            'This user sent you a friend request!',
            style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _acceptFriendRequest,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: AppColors.authButtonGradient,
                    ),
                    child: const Center(
                      child: Text(
                        'Accept Request',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _declineFriendRequest,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surface,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: Text(
                        'Decline',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // 'none' - No request or connection yet
      return Row(
        children: [
          // Add Friend Button
          Expanded(
            child: GestureDetector(
              onTap: _sendFriendRequest,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.authButtonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Add Friend',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Disabled Message Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                CustomSnackBar.showErrorSnackBar(
                  context,
                  AppException(
                    title: 'Cannot Message',
                    message: 'You must add them as a friend before you can send a message.',
                    actionText: 'Okay',
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white24, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Message',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
