import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';
import 'package:nexus_app/features/chat/data/chat_service.dart';
import 'package:nexus_app/features/chat/presentation/chat_screen.dart';

class FindAllyRadarScreen extends StatefulWidget {
  const FindAllyRadarScreen({super.key});

  @override
  State<FindAllyRadarScreen> createState() => _FindAllyRadarScreenState();
}

class _FindAllyRadarScreenState extends State<FindAllyRadarScreen>
    with SingleTickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  late AnimationController _radarController;
  List<UserModel> _friends = [];
  UserModel? _currentUserModel;
  bool _isLoading = true;
  bool _isEventsTab = false; // False = Friends, True = Events

  UserModel? _selectedFriend;
  bool _gpsUpdating = false;

  // Custom mock tags & roles for tactical display
  final List<String> _tacticalRoles = [
    'ELITE SNIPER',
    'FRAGGER PRO',
    'SUPPORT TACTICAL',
    'MOBA CHAMPION',
    'RPG EXPLORER',
  ];

  final List<List<String>> _tacticalTags = [
    ['FPS', 'Competitive', 'Lvl 45'],
    ['MOBA', 'Streamer', 'Lvl 38'],
    ['Co-op', 'Casual', 'Lvl 52'],
    ['Sandbox', 'PRO', 'Lvl 29'],
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _loadData();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_currentUserId.isEmpty) return;
    try {
      final friendsList = await _friendsService.getFriendsProfiles(_currentUserId);
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      UserModel? currentUser;
      if (doc.exists && doc.data() != null) {
        currentUser = UserModel.fromJson(doc.data()!);
      }

      if (mounted) {
        setState(() {
          _friends = friendsList;
          _currentUserModel = currentUser;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Simulate updating current user's location
  Future<void> _requestAndPostLocation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: AppColors.primaryCyan),
            SizedBox(width: 10),
            Text('Tac-GPS Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Allow Nexus to calibrate your GPS locator coordinates and publish them to regional ally grids?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _performLocationUpdate();
            },
            child: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLocationUpdate() async {
    setState(() => _gpsUpdating = true);
    
    // Simulate slight delay for GPS signal lock
    await Future.delayed(const Duration(milliseconds: 1200));

    // Simulated coordinates (Kathmandu regional server center with slight random offsets)
    final math.Random random = math.Random();
    final double simulatedLat = 27.7172 + (random.nextDouble() - 0.5) * 0.005;
    final double simulatedLng = 85.3240 + (random.nextDouble() - 0.5) * 0.005;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
        'latitude': simulatedLat,
        'longitude': simulatedLng,
        'location': 'Kathmandu Grid Sector',
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tactical grid successfully synchronized! Location updated.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Sync Failed: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _gpsUpdating = false);
      }
    }
  }

  // Calculate distance between points in meters
  int _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lng2 - lng1) * p)) / 2;
    return (12742 * math.asin(math.sqrt(a)) * 1000).round();
  }

  Widget _buildAvatarImage(String imageUrl, String seed, {double size = 38}) {
    if (imageUrl.startsWith('data:image') || !imageUrl.startsWith('http')) {
      try {
        final cleanBase64 = imageUrl.contains(',') ? imageUrl.split(',')[1] : imageUrl;
        final decodedBytes = base64Decode(cleanBase64);
        return ClipOval(
          child: Image.memory(
            decodedBytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        // Fallback
      }
    }
    return ClipOval(
      child: Image.network(
        imageUrl.isNotEmpty ? imageUrl : 'https://api.dicebear.com/7.x/adventurer/png?seed=$seed',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.network(
          'https://api.dicebear.com/7.x/adventurer/png?seed=$seed',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<void> _startChatWithUser(UserModel otherUser) async {
    if (_currentUserId.isEmpty) return;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // User GPS reference center coordinates
    final double userLat = _currentUserModel?.latitude ?? 27.7172;
    final double userLng = _currentUserModel?.longitude ?? 85.3240;

    return Scaffold(
      backgroundColor: Colors.black, // Midnight Tactical Black
      body: Stack(
        children: [
          // ── Tactical Canvas Map Background ────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RadarPainter(
                    sweepAngle: _radarController.value * 2 * math.pi,
                  ),
                );
              },
            ),
          ),

          // ── Top Header Section ──────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF13141B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),

                      // Pill Switcher: Friends / Events
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13141B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isEventsTab = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !_isEventsTab ? AppColors.surfaceHighlight : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Friends',
                                  style: TextStyle(
                                    color: !_isEventsTab ? Colors.white : Colors.white38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isEventsTab = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isEventsTab ? AppColors.primaryCyan : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Events',
                                  style: TextStyle(
                                    color: _isEventsTab ? Colors.black : Colors.white38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 40), // Spacer balancing the back button
                    ],
                  ),
                ),

                // Find Your Ally Informational Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: screenWidth * 0.58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13141B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find Your Ally',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _gpsUpdating ? 'Syncing coordinates...' : 'Connecting to regional servers...',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── GPS Coordinates Blips Layer ──────────────────────────────────
          if (!_isLoading)
            ..._friends.asMap().entries.map((entry) {
              final idx = entry.key;
              final friend = entry.value;

              // Extract or mock offsets
              double latOffset = 0.0;
              double lngOffset = 0.0;
              if (friend.latitude != null && friend.longitude != null) {
                latOffset = friend.latitude! - userLat;
                lngOffset = friend.longitude! - userLng;
              } else {
                // Generate a deterministic mock offset based on UID hash
                latOffset = ((friend.uid.hashCode % 100) - 50) * 0.00008;
                lngOffset = ((friend.uid.hashCode % 80) - 40) * 0.0001;
              }

              // Map coordinates to pixel offset relative to center of radar (screenCenter)
              final double centerX = screenWidth / 2;
              final double centerY = screenHeight / 2 - 40;

              // Coordinates multipliers to fit screen limits nicely
              final double xPos = centerX + (lngOffset * 900000);
              final double yPos = centerY - (latOffset * 900000);

              // Skip rendering if offset falls outside visible area
              if (xPos < 20 || xPos > screenWidth - 20 || yPos < 120 || yPos > screenHeight - 180) {
                return const SizedBox.shrink();
              }

              final isSelected = _selectedFriend?.uid == friend.uid;

              return Positioned(
                left: xPos - 20,
                top: yPos - 20,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFriend = friend;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Active Glow Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 48 : 40,
                        height: isSelected ? 48 : 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryCyan : AppColors.primaryPurple,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? AppColors.primaryCyan : AppColors.primaryPurple)
                                  .withValues(alpha: isSelected ? 0.6 : 0.2),
                              blurRadius: isSelected ? 12 : 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),

                      // Profile Pic Node
                      _buildAvatarImage(friend.profileImageUrl, friend.username, size: isSelected ? 40 : 34),

                      // Optional Live Status indicator matching mockup
                      if (idx == 0)
                        Positioned(
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

          // ── Central User Pulsing Pulse ──────────────────────────────────
          Positioned(
            left: screenWidth / 2 - 24,
            top: screenHeight / 2 - 64,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Target Pulsing Rings
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryCyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    _buildAvatarImage(
                      _currentUserModel?.profileImageUrl ?? '',
                      _currentUserModel?.username ?? 'You',
                      size: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Searching for Allies...',
                    style: TextStyle(color: AppColors.primaryCyan, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Vertical Toolbar Panel (Right side) ─────────────────────────
          Positioned(
            right: 16,
            top: screenHeight * 0.24,
            child: Column(
              children: [
                // Filter Button
                _buildToolbarButton(Icons.filter_list),
                const SizedBox(height: 12),
                // Groups Button
                _buildToolbarButton(Icons.people_outline),
                const SizedBox(height: 12),
                // Calendar Button
                _buildToolbarButton(Icons.calendar_today_outlined),
                const SizedBox(height: 12),
                // GPS Target/Update Location Button
                _buildToolbarButton(
                  Icons.my_location,
                  iconColor: AppColors.primaryCyan,
                  onTap: _requestAndPostLocation,
                ),
              ],
            ),
          ),

          // ── Bottom Detail Overlay Card (Dynamic Allies PageView) ────────
          if (_selectedFriend != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildAllyDetailCard(_selectedFriend!),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, {Color iconColor = Colors.white, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF13141B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _buildAllyDetailCard(UserModel ally) {
    // Generate deterministic index metrics for nice visual display
    final int idx = ally.uid.hashCode;
    final String role = _tacticalRoles[idx % _tacticalRoles.length];
    final List<String> tags = _tacticalTags[idx % _tacticalTags.length];
    
    // Distance display logic
    final double userLat = _currentUserModel?.latitude ?? 27.7172;
    final double userLng = _currentUserModel?.longitude ?? 85.3240;
    final int distanceMeters = ally.latitude != null && ally.longitude != null
        ? _calculateDistance(userLat, userLng, ally.latitude!, ally.longitude!)
        : (100 + (ally.uid.hashCode % 1200));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13141B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: _buildAvatarImage(ally.profileImageUrl, ally.username, size: 48),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ally.fullName.isNotEmpty ? ally.fullName : ally.username,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$role • ${distanceMeters}M AWAY',
                      style: const TextStyle(color: AppColors.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Close "X" Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFriend = null;
                  });
                },
                child: const Icon(Icons.close, color: Colors.white60, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              // View Profile Button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewFriendScreen(userModel: ally),
                        ),
                      );
                    },
                    child: const Text('View Friend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Chat Action Button
              GestureDetector(
                onTap: () => _startChatWithUser(ally),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF262A34),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter drawing the sweeping futuristic tactical HUD Radar Map grid
class RadarPainter extends CustomPainter {
  final double sweepAngle;

  RadarPainter({required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2 - 40;
    final double maxRadius = math.min(size.width, size.height) * 0.46;

    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint accentPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw concentric circles
    canvas.drawCircle(Offset(centerX, centerY), maxRadius * 0.25, linePaint);
    canvas.drawCircle(Offset(centerX, centerY), maxRadius * 0.55, linePaint);
    canvas.drawCircle(Offset(centerX, centerY), maxRadius * 0.85, linePaint);
    canvas.drawCircle(Offset(centerX, centerY), maxRadius, accentPaint);

    // Draw axis lines
    canvas.drawLine(
      Offset(centerX - maxRadius, centerY),
      Offset(centerX + maxRadius, centerY),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - maxRadius),
      Offset(centerX, centerY + maxRadius),
      linePaint,
    );

    // Draw angled sub-lines
    final double angle45 = math.pi / 4;
    canvas.drawLine(
      Offset(centerX - maxRadius * math.cos(angle45), centerY - maxRadius * math.sin(angle45)),
      Offset(centerX + maxRadius * math.cos(angle45), centerY + maxRadius * math.sin(angle45)),
      linePaint,
    );
    canvas.drawLine(
      Offset(centerX - maxRadius * math.cos(angle45), centerY + maxRadius * math.sin(angle45)),
      Offset(centerX + maxRadius * math.cos(angle45), centerY - maxRadius * math.sin(angle45)),
      linePaint,
    );

    // Draw futuristic HUD corner brackets
    final Paint bracketPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double bracketOffset = 24.0;
    const double bracketLen = 16.0;

    // Top-Left bracket
    canvas.drawPath(
      Path()
        ..moveTo(bracketOffset, bracketOffset + bracketLen)
        ..lineTo(bracketOffset, bracketOffset)
        ..lineTo(bracketOffset + bracketLen, bracketOffset),
      bracketPaint,
    );
    // Top-Right bracket
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketOffset, bracketOffset + bracketLen)
        ..lineTo(size.width - bracketOffset, bracketOffset)
        ..lineTo(size.width - bracketOffset - bracketLen, bracketOffset),
      bracketPaint,
    );
    // Bottom-Left bracket
    canvas.drawPath(
      Path()
        ..moveTo(bracketOffset, size.height - bracketOffset - bracketLen)
        ..lineTo(bracketOffset, size.height - bracketOffset)
        ..lineTo(bracketOffset + bracketLen, size.height - bracketOffset),
      bracketPaint,
    );
    // Bottom-Right bracket
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketOffset, size.height - bracketOffset - bracketLen)
        ..lineTo(size.width - bracketOffset, size.height - bracketOffset)
        ..lineTo(size.width - bracketOffset - bracketLen, size.height - bracketOffset),
      bracketPaint,
    );

    // Draw the active scanning sweep line gradient
    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), maxRadius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}
