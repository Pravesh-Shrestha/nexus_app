import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';

class FriendshipStatusButton extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  const FriendshipStatusButton({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<FriendshipStatusButton> createState() => _FriendshipStatusButtonState();
}

class _FriendshipStatusButtonState extends State<FriendshipStatusButton> {
  final FriendsService _friendsService = FriendsService();
  String _status = 'none';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final status = await _friendsService.getFriendshipStatus(
      widget.currentUserId,
      widget.otherUserId,
    );
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final currentUserProfile = await AuthService().getUserData(widget.currentUserId);
      final senderUsername = currentUserProfile?.username ?? 'Agent';
      await _friendsService.sendFriendRequest(
        widget.currentUserId,
        senderUsername,
        widget.otherUserId,
      );
      if (mounted) {
        setState(() {
          _status = 'pending_sent';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUserId == widget.otherUserId) return const SizedBox();
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryCyan),
      );
    }

    if (_status == 'friends') {
      return const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryCyan, size: 18);
    } else if (_status == 'pending_sent') {
      return const Icon(Icons.hourglass_empty_rounded, color: Colors.white30, size: 18);
    } else if (_status == 'pending_received') {
      return GestureDetector(
        onTap: () async {
          setState(() => _isLoading = true);
          try {
            await _friendsService.acceptFriendRequest(widget.otherUserId, widget.currentUserId);
            if (mounted) {
              setState(() {
                _status = 'friends';
                _isLoading = false;
              });
            }
          } catch (e) {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        child: const Icon(Icons.person_add_disabled_outlined, color: AppColors.successGreen, size: 18),
      );
    } else {
      return GestureDetector(
        onTap: _sendRequest,
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white70, size: 18),
      );
    }
  }
}
