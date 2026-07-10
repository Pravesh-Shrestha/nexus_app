import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/widgets/custom_snackbar.dart';

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
  int _selectedTabIndex = 0; // 0: People, 1: Requested, 2: Requests

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
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      _showError(AppException(
        title: 'Action Failed',
        message: 'Failed to accept request.',
        actionText: 'Retry',
      ));
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
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      _showError(AppException(
        title: 'Action Failed',
        message: 'Failed to decline request.',
        actionText: 'Retry',
      ));
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
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      _showError(AppException(
        title: 'Action Failed',
        message: 'Failed to cancel request.',
        actionText: 'Retry',
      ));
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
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      _showError(AppException(
        title: 'Action Failed',
        message: 'Failed to send request.',
        actionText: 'Retry',
      ));
    } finally {
      if (mounted) setState(() => _processingIds.remove(player.uid));
    }
  }

  void _showError(AppException exception) {
    if (!mounted) return;
    CustomSnackBar.showErrorSnackBar(context, exception);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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

  Widget _avatar(UserModel u, Color fallbackColor) {
    final hasImage = u.profileImageUrl.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: fallbackColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: fallbackColor.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                u.profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallbackAvatarWidget(u, fallbackColor),
              )
            : _fallbackAvatarWidget(u, fallbackColor),
      ),
    );
  }

  Widget _fallbackAvatarWidget(UserModel u, Color color) {
    return Container(
      color: color.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        _initials(u),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _buildHorizontalSelector() {
    final options = [
      {'title': 'People', 'count': _discoverPlayers.length},
      {'title': 'Requested', 'count': _sentRequests.length},
      {'title': 'Requests', 'count': _receivedRequests.length},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final opt = options[index];
          final title = opt['title'] as String;
          final count = opt['count'] as int;
          final isSelected = _selectedTabIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          AppColors.primaryPurple,
                          AppColors.primaryCyan,
                        ],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryPurple.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white30
                              : Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.primaryCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedTabIndex) {
      case 0: // People (Discover)
        return _buildTabContent(
          onRefresh: _loadData,
          isEmpty: _discoverPlayers.isEmpty,
          emptyWidget: _emptyState(
            icon: Icons.people_outline_rounded,
            message: 'No new players to discover yet.',
          ),
          itemCount: _discoverPlayers.length,
          itemBuilder: (context, index) => _discoverCard(_discoverPlayers[index]),
        );
      case 1: // Requested (Sent)
        return _buildTabContent(
          onRefresh: _loadData,
          isEmpty: _sentRequests.isEmpty,
          emptyWidget: _emptyState(
            icon: Icons.hourglass_empty_rounded,
            message: 'You haven\'t sent any requests.',
          ),
          itemCount: _sentRequests.length,
          itemBuilder: (context, index) => _sentCard(_sentRequests[index]),
        );
      case 2: // Requests (Received)
        return _buildTabContent(
          onRefresh: _loadData,
          isEmpty: _receivedRequests.isEmpty,
          emptyWidget: _emptyState(
            icon: Icons.inbox_rounded,
            message: 'No incoming friend requests right now.',
          ),
          itemCount: _receivedRequests.length,
          itemBuilder: (context, index) => _receivedCard(_receivedRequests[index]),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.p24),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceHighlight,
                  border: Border.all(
                      color: AppColors.primaryCyan.withValues(alpha: 0.2),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.group_outlined,
                    color: AppColors.primaryCyan, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Find Your Ally',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connect with players. Build your squad.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Horizontal Selector
            _buildHorizontalSelector(),
            const SizedBox(height: 20),

            // Selected View Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryPurple))
                  : _buildSelectedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required Future<void> Function() onRefresh,
    required bool isEmpty,
    required Widget emptyWidget,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    if (isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  child: emptyWidget,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, 40),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatar(player, color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(player),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: badges
                          .map((b) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Text(
                                  b.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryCyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ] else
                    Text(
                      '@${player.username}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add button
            if (processing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryPurple,
                ),
              )
            else
              GestureDetector(
                onTap: () => _sendRequest(player),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.primaryCyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryCyan.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCyan.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatar(u, color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(u),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${u.username}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (processing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryPurple,
                ),
              )
            else
              Row(
                children: [
                  // Decline Button
                  GestureDetector(
                    onTap: () => _declineRequest(entry),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.errorRed.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.errorRed,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept Button
                  GestureDetector(
                    onTap: () => _acceptRequest(entry),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.statusOnline.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.statusOnline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusOnline.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.statusOnline,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatar(u, color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(u),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${u.username}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (processing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryPurple,
                ),
              )
            else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryCyan.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _cancelRequest(entry),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _emptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white24,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

