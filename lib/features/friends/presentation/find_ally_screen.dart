import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool _isLoading = true;
  List<FriendRequestEntry> _receivedRequests = [];
  List<FriendRequestEntry> _sentRequests = [];
  List<UserModel> _discoverPlayers = [];

  // Track which cards are processing an action
  final Set<String> _processingIds = {};

  String? _currentUserId;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _currentUsername = user.displayName ?? user.email ?? 'User';
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_currentUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        _friendsService.getReceivedRequestsWithProfiles(_currentUserId!),
        _friendsService.getSentRequestsWithProfiles(_currentUserId!),
        _friendsService.getRecommendedPlayers(_currentUserId!),
      ]);

      if (mounted) {
        setState(() {
          _receivedRequests = results[0] as List<FriendRequestEntry>;
          _sentRequests = results[1] as List<FriendRequestEntry>;
          _discoverPlayers = results[2] as List<UserModel>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _acceptRequest(FriendRequestEntry entry) async {
    setState(() => _processingIds.add(entry.request.id));
    try {
      await _friendsService.acceptFriendRequest(
        entry.request.senderId,
        _currentUserId!,
      );
      await _loadData();
    } catch (e) {
      _showError('Failed to accept request');
    } finally {
      if (mounted) setState(() => _processingIds.remove(entry.request.id));
    }
  }

  Future<void> _declineRequest(FriendRequestEntry entry) async {
    setState(() => _processingIds.add(entry.request.id));
    try {
      await _friendsService.declineFriendRequest(
        entry.request.senderId,
        _currentUserId!,
      );
      await _loadData();
    } catch (e) {
      _showError('Failed to decline request');
    } finally {
      if (mounted) setState(() => _processingIds.remove(entry.request.id));
    }
  }

  Future<void> _cancelRequest(FriendRequestEntry entry) async {
    setState(() => _processingIds.add(entry.request.id));
    try {
      await _friendsService.cancelFriendRequest(
        _currentUserId!,
        entry.request.receiverId,
      );
      await _loadData();
    } catch (e) {
      _showError('Failed to cancel request');
    } finally {
      if (mounted) setState(() => _processingIds.remove(entry.request.id));
    }
  }

  Future<void> _sendRequest(UserModel player) async {
    setState(() => _processingIds.add(player.uid));
    try {
      await _friendsService.sendFriendRequest(
        _currentUserId!,
        _currentUsername!,
        player.uid,
      );
      await _loadData();
    } catch (e) {
      _showError('Failed to send request');
    } finally {
      if (mounted) setState(() => _processingIds.remove(player.uid));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  Color _avatarColor(String uid) {
    const colors = [
      Color(0xFF6C63FF),
      Color(0xFF00BCD4),
      Color(0xFF4CAF50),
      Color(0xFFFF7043),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFFFF9800),
    ];
    return colors[uid.hashCode.abs() % colors.length];
  }

  String _initials(UserModel u) {
    if (u.fullName.isNotEmpty) return u.fullName[0].toUpperCase();
    if (u.username.isNotEmpty) return u.username[0].toUpperCase();
    return '?';
  }

  String _displayName(UserModel u) =>
      u.fullName.isNotEmpty ? u.fullName : u.username;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.p24, 12, AppSizes.p24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceHighlight,
                      border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.2),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withValues(alpha: 0.2),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.group_outlined,
                        color: AppColors.primaryCyan, size: 20),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.p24, 20, AppSizes.p24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Find Your Ally',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connect with players. Build your squad.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryPurple))
                  : RefreshIndicator(
                      color: AppColors.primaryPurple,
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          // 1 — Received Requests
                          _buildSection(
                            icon: Icons.person_add_alt_1_rounded,
                            iconColor: const Color(0xFF00E5AA),
                            title: 'Friend Requests',
                            subtitle: 'People who want to connect with you',
                            count: _receivedRequests.length,
                            child: _receivedRequests.isEmpty
                                ? _emptyState(
                                    icon: Icons.inbox_rounded,
                                    message:
                                        'No incoming friend requests right now.',
                                  )
                                : Column(
                                    children: _receivedRequests
                                        .map((e) =>
                                            _receivedCard(e))
                                        .toList(),
                                  ),
                          ),

                          // 2 — Sent Requests
                          _buildSection(
                            icon: Icons.send_rounded,
                            iconColor: AppColors.primaryCyan,
                            title: 'Requests Sent',
                            subtitle: 'Waiting for their response',
                            count: _sentRequests.length,
                            child: _sentRequests.isEmpty
                                ? _emptyState(
                                    icon: Icons.hourglass_empty_rounded,
                                    message: 'You haven\'t sent any requests.',
                                  )
                                : Column(
                                    children: _sentRequests
                                        .map((e) => _sentCard(e))
                                        .toList(),
                                  ),
                          ),

                          // 3 — Discover Players
                          _buildSection(
                            icon: Icons.explore_rounded,
                            iconColor: AppColors.primaryPurple,
                            title: 'Discover Players',
                            subtitle: 'New people you can connect with',
                            count: _discoverPlayers.length,
                            child: _discoverPlayers.isEmpty
                                ? _emptyState(
                                    icon: Icons.people_outline_rounded,
                                    message:
                                        'No new players to discover yet.',
                                  )
                                : Column(
                                    children: _discoverPlayers
                                        .map((p) => _discoverCard(p))
                                        .toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int count,
    required Widget child,
  }) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Received request card ─────────────────────────────────────────────────

  Widget _receivedCard(FriendRequestEntry entry) {
    final u = entry.user;
    final color = _avatarColor(u.uid);
    final processing = _processingIds.contains(entry.request.id);

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => ViewFriendScreen(userModel: u)))
            .then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00E5AA).withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            _avatar(u, color),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName(u),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  if (u.username.isNotEmpty)
                    Text('@${u.username}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            // Buttons
            if (processing)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple))
            else
              Row(
                children: [
                  // Decline
                  GestureDetector(
                    onTap: () => _declineRequest(entry),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.redAccent, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accept
                  GestureDetector(
                    onTap: () => _acceptRequest(entry),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5AA)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF00E5AA)
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Color(0xFF00E5AA), size: 18),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Sent request card ─────────────────────────────────────────────────────

  Widget _sentCard(FriendRequestEntry entry) {
    final u = entry.user;
    final color = _avatarColor(u.uid);
    final processing = _processingIds.contains(entry.request.id);

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => ViewFriendScreen(userModel: u)))
            .then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            _avatar(u, color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName(u),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  if (u.username.isNotEmpty)
                    Text('@${u.username}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            // Pending chip + Cancel
            if (processing)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple))
            else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _cancelRequest(entry),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white38, size: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Discover card ─────────────────────────────────────────────────────────

  Widget _discoverCard(UserModel player) {
    final color = _avatarColor(player.uid);
    final processing = _processingIds.contains(player.uid);

    final List<String> badges = [player.role, player.playstyle]
        .where((b) => b.isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => ViewFriendScreen(userModel: player)))
            .then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            _avatar(player, color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName(player),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      children: badges
                          .map((b) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.white10),
                                ),
                                child: Text(b,
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                    ),
                  ] else
                    Text('@${player.username}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            // Add button
            if (processing)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple))
            else
              GestureDetector(
                onTap: () => _sendRequest(player),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.primaryCyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Shared avatar widget ──────────────────────────────────────────────────

  Widget _avatar(UserModel u, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Center(
        child: Text(
          _initials(u),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white12, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
