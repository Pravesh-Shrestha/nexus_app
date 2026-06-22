import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'friend_request',
      'title': 'Phantom_Ace sent you a friend request',
      'time': '12m ago',
      'isRead': false,
      'icon': Icons.person_add_alt_1_outlined,
      'iconBgColor': Color(0xFF1E1736),
      'iconColor': Color(0xFFB08CFF),
      'status': 'pending', // 'pending', 'accepted', 'declined'
      'section': 'TODAY',
    },
    {
      'id': '2',
      'type': 'gg',
      'title': 'Nova_Strike and 88 others GG\'d your clutch VOD',
      'time': '1h ago',
      'isRead': false,
      'iconText': 'GG',
      'iconBgColor': Color(0xFF152A20),
      'iconColor': Color(0xFF00FF87),
      'section': 'TODAY',
    },
    {
      'id': '3',
      'type': 'rsvp',
      'title': 'Grand Finals starts in 2 hours — you RSVP\'d',
      'time': '2h ago',
      'isRead': true,
      'icon': Icons.access_time_filled_outlined,
      'iconBgColor': Color(0xFF331525),
      'iconColor': Color(0xFFFF4081),
      'section': 'TODAY',
    },
    {
      'id': '4',
      'type': 'invite',
      'title': 'Valorant Tactics invited you to join the community',
      'time': 'Yesterday',
      'isRead': true,
      'icon': Icons.group_outlined,
      'iconBgColor': Color(0xFF132B30),
      'iconColor': Color(0xFF00E5FF),
      'section': 'EARLIER',
    },
    {
      'id': '5',
      'type': 'mention',
      'title': 'Pixel_Queen mentioned you in Elite Setups',
      'time': 'Yesterday',
      'isRead': true,
      'icon': Icons.alternate_email_outlined,
      'iconBgColor': Color(0xFF1E1736),
      'iconColor': Color(0xFF8A2BE2),
      'section': 'EARLIER',
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _handleFriendRequest(String id, String newStatus) {
    setState(() {
      final index = _notifications.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        _notifications[index]['status'] = newStatus;
        _notifications[index]['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayNotifications = _notifications.where((item) => item['section'] == 'TODAY').toList();
    final earlierNotifications = _notifications.where((item) => item['section'] == 'EARLIER').toList();

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
        child: Column(
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
            
            // Notification Items List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
    final bool isFriendRequest = item['type'] == 'friend_request';
    final String status = item['status'] ?? '';
    final bool isRead = item['isRead'] ?? false;

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
                    color: item['iconBgColor'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: item['iconText'] != null
                        ? Text(
                            item['iconText'] as String,
                            style: TextStyle(
                              color: item['iconColor'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : Icon(
                            item['icon'] as IconData,
                            color: item['iconColor'] as Color,
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
                        onPressed: () => _handleFriendRequest(item['id'] as String, 'accepted'),
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
                        onPressed: () => _handleFriendRequest(item['id'] as String, 'declined'),
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
