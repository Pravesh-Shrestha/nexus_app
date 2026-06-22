import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/home/data/notification_model.dart';
import 'package:nexus_app/features/home/data/notification_service.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FriendsService _friendsService = FriendsService();
  
  List<NotificationModel> _dbNotifications = [];
  bool _isLoading = true;
  String _currentUserId = '';

  // Local mockup fallback if DB is empty
  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 'mock_1',
      'type': 'friend_request',
      'title': 'Phantom_Ace sent you a friend request',
      'time': '12m ago',
      'isRead': false,
      'status': 'pending',
      'section': 'TODAY',
      'relatedId': 'phantom_ace_mock_uid',
    },
    {
      'id': 'mock_2',
      'type': 'gg',
      'title': 'Nova_Strike and 88 others GG\'d your clutch VOD',
      'time': '1h ago',
      'isRead': false,
      'section': 'TODAY',
    },
    {
      'id': 'mock_3',
      'type': 'rsvp',
      'title': 'Grand Finals starts in 2 hours — you RSVP\'d',
      'time': '2h ago',
      'isRead': true,
      'section': 'TODAY',
    },
    {
      'id': 'mock_4',
      'type': 'invite',
      'title': 'Valorant Tactics invited you to join the community',
      'time': 'Yesterday',
      'isRead': true,
      'section': 'EARLIER',
    },
    {
      'id': 'mock_5',
      'type': 'mention',
      'title': 'Pixel_Queen mentioned you in Elite Setups',
      'time': 'Yesterday',
      'isRead': true,
      'section': 'EARLIER',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      try {
        final list = await _notificationService.getNotifications(user.uid);
        if (mounted) {
          setState(() {
            _dbNotifications = list;
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

  Future<void> _markAllAsRead() async {
    if (_currentUserId.isEmpty) return;
    
    // If we are using the DB list
    if (_dbNotifications.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _notificationService.markAllAsRead(_currentUserId);
        await _loadNotifications();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error marking read: $e'), backgroundColor: Colors.redAccent),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Local mockup mark read
      setState(() {
        for (var notif in _mockNotifications) {
          notif['isRead'] = true;
        }
      });
    }
  }

  Future<void> _handleFriendRequest(String id, String relatedId, String newStatus) async {
    final isMock = id.startsWith('mock_');

    if (isMock) {
      setState(() {
        final index = _mockNotifications.indexWhere((element) => element['id'] == id);
        if (index != -1) {
          _mockNotifications[index]['status'] = newStatus;
          _mockNotifications[index]['isRead'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mock request ${newStatus == 'accepted' ? 'accepted' : 'declined'} (Offline Demo)'),
          backgroundColor: AppColors.statusOnline,
        ),
      );
      return;
    }

    if (_currentUserId.isEmpty || relatedId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (newStatus == 'accepted') {
        await _friendsService.acceptFriendRequest(relatedId, _currentUserId, id);
      } else {
        await _friendsService.declineFriendRequest(relatedId, _currentUserId, id);
      }
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request ${newStatus == 'accepted' ? 'accepted' : 'declined'}.'),
            backgroundColor: AppColors.statusOnline,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update request: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() {
          _isLoading = false;
        });
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

  String _getSection(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      return 'TODAY';
    }
    return 'EARLIER';
  }

  @override
  Widget build(BuildContext context) {
    // Determine which data to show: DB notifications if any, fallback to mocks
    final hasDb = _dbNotifications.isNotEmpty;
    
    final List<Map<String, dynamic>> itemsToShow = hasDb
        ? _dbNotifications.map((n) => {
              'id': n.id,
              'type': n.type,
              'title': n.title,
              'time': _formatTimeAgo(n.createdAt),
              'isRead': n.isRead,
              'status': n.status,
              'section': _getSection(n.createdAt),
              'relatedId': n.relatedId,
            }).toList()
        : _mockNotifications;

    final todayNotifications = itemsToShow.where((item) => item['section'] == 'TODAY').toList();
    final earlierNotifications = itemsToShow.where((item) => item['section'] == 'EARLIER').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Mark All Read
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _markAllAsRead,
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(
                              color: AppColors.primaryCyan,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Empty State or List
                  Expanded(
                    child: itemsToShow.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.notifications_off_outlined, color: Colors.white12, size: 64),
                                SizedBox(height: 16),
                                Text(
                                  'All caught up!',
                                  style: TextStyle(color: Colors.white24, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!hasDb)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16, left: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
                                      ),
                                      child: const Text(
                                        'Offline Demo Mode (Firestore notifications empty)',
                                        style: TextStyle(color: AppColors.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                if (todayNotifications.isNotEmpty) ...[
                                  _buildSectionHeader('TODAY'),
                                  ...todayNotifications.map((item) => _buildNotificationCard(item)),
                                  const SizedBox(height: 24),
                                ],
                                if (earlierNotifications.isNotEmpty) ...[
                                  _buildSectionHeader('EARLIER'),
                                  ...earlierNotifications.map((item) => _buildNotificationCard(item)),
                                ],
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final String type = item['type'] ?? '';
    final bool isFriendRequest = type == 'friend_request';
    final String status = item['status'] ?? '';
    final bool isRead = item['isRead'] ?? false;
    final String id = item['id'] ?? '';
    final String relatedId = item['relatedId'] ?? '';

    // Map UI properties based on type
    IconData icon = Icons.notifications_none;
    String? iconText;
    Color iconBgColor = const Color(0xFF1E1736);
    Color iconColor = Colors.white;

    switch (type) {
      case 'friend_request':
        icon = Icons.person_add_alt_1_outlined;
        iconBgColor = const Color(0xFF1E1736);
        iconColor = const Color(0xFFB08CFF);
        break;
      case 'gg':
        iconText = 'GG';
        iconBgColor = const Color(0xFF152A20);
        iconColor = const Color(0xFF00FF87);
        break;
      case 'rsvp':
        icon = Icons.access_time_filled_outlined;
        iconBgColor = const Color(0xFF331525);
        iconColor = const Color(0xFFFF4081);
        break;
      case 'invite':
        icon = Icons.group_outlined;
        iconBgColor = const Color(0xFF132B30);
        iconColor = const Color(0xFF00E5FF);
        break;
      case 'mention':
        icon = Icons.alternate_email_outlined;
        iconBgColor = const Color(0xFF1E1736);
        iconColor = const Color(0xFF8A2BE2);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: iconText != null
                        ? Text(
                            iconText,
                            style: TextStyle(
                              color: iconColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : Icon(
                            icon,
                            color: iconColor,
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                
                // Content text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['time'] as String,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Unread Blue Dot
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            
            // Action buttons if it is a pending friend request
            if (isFriendRequest) ...[
              if (status == 'pending') ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 58),
                  child: Row(
                    children: [
                      // Accept Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusOnline,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _handleFriendRequest(id, relatedId, 'accepted'),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Decline Button
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white12),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _handleFriendRequest(id, relatedId, 'declined'),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 58),
                  child: Text(
                    status == 'accepted' ? 'Request Accepted' : 'Request Declined',
                    style: TextStyle(
                      color: status == 'accepted' ? AppColors.statusOnline : Colors.white30,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
