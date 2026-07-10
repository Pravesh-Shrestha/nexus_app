import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/data/friends_service.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';
import 'package:nexus_app/features/chat/data/chat_service.dart';
import 'package:nexus_app/features/chat/presentation/chat_screen.dart';
import 'package:nexus_app/features/event/data/event_model.dart';
import 'package:nexus_app/features/event/data/event_service.dart';
import 'package:nexus_app/features/explore/presentation/event_details_screen.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/widgets/custom_snackbar.dart';

class FindAllyRadarScreen extends StatefulWidget {
  const FindAllyRadarScreen({super.key});

  @override
  State<FindAllyRadarScreen> createState() => _FindAllyRadarScreenState();
}

class _FindAllyRadarScreenState extends State<FindAllyRadarScreen> {
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService();
  final EventService _eventService = EventService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final MapController _mapController = MapController();

  List<UserModel> _friends = [];
  List<EventModel> _eventsList = [];
  UserModel? _currentUserModel;
  bool _isLoading = true;
  bool _isEventsTab = false; // False = Friends, True = Events

  UserModel? _selectedFriend;
  EventModel? _selectedEvent;
  bool _gpsUpdating = false;

  double _userLat = 27.7172;
  double _userLng = 85.3240;

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
    _loadData().then((_) {
      _initAndRequestLocation();
    });
  }

  Future<void> _loadData() async {
    if (_currentUserId.isEmpty) return;
    try {
      final friendsList = await _friendsService.getFriendsProfiles(_currentUserId);
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      UserModel? currentUser;
      if (doc.exists && doc.data() != null) {
        currentUser = UserModel.fromJson(doc.data()!);
        if (currentUser.latitude != null && currentUser.longitude != null) {
          _userLat = currentUser.latitude!;
          _userLng = currentUser.longitude!;
        }
      }

      // Fetch upcoming events
      final events = await _eventService.getEvents().first;

      if (mounted) {
        setState(() {
          _friends = friendsList;
          _currentUserModel = currentUser;
          _eventsList = events;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initAndRequestLocation() async {
    setState(() => _gpsUpdating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        // Give a prompt so they know they need to turn it on
        throw AppException(
          title: 'GPS Disabled',
          message: 'Location services are disabled. We have opened your device settings so you can enable GPS.',
          actionText: 'Retry',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      
      if (_currentUserId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'location': 'User GPS Sector',
        });
      }

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _gpsUpdating = false;
      });

      _mapController.move(LatLng(_userLat, _userLng), 14.0);
      await _loadData();
    } catch (e) {
      setState(() => _gpsUpdating = false);
      if (mounted) {
        if (e is AppException) {
           CustomSnackBar.showErrorSnackBar(context, e);
        } else {
           CustomSnackBar.showErrorSnackBar(
             context,
             AppException(
               title: 'GPS Error',
               message: '$e. Make sure location permission is granted and GPS is on.',
               actionText: 'Retry',
             ),
           );
        }
      }
      _mapController.move(LatLng(_userLat, _userLng), 14.0);
      await _loadData();
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
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Chat Error',
            message: 'Failed to start chat.',
            actionText: 'Retry',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final LatLng centerLatLng = LatLng(_userLat, _userLng);

    // Build markers
    final List<Marker> mapMarkers = [];

    // 1. Current user (You)
    mapMarkers.add(
      Marker(
        point: centerLatLng,
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryCyan, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            _buildAvatarImage(
              _currentUserModel?.profileImageUrl ?? '',
              _currentUserModel?.username ?? 'You',
              size: 44,
            ),
          ],
        ),
      ),
    );

    // 2. Friends or Events markers (Skip rendering if no real coordinates exist)
    if (!_isEventsTab) {
      for (final friend in _friends) {
        if (friend.latitude == null || friend.longitude == null || (friend.latitude == 0.0 && friend.longitude == 0.0)) {
          continue; // Skip friends without valid GPS coordinates
        }

        final double fLat = friend.latitude!;
        final double fLng = friend.longitude!;
        final isSelected = _selectedFriend?.uid == friend.uid;

        mapMarkers.add(
          Marker(
            point: LatLng(fLat, fLng),
            width: 54,
            height: 54,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFriend = friend;
                  _selectedEvent = null;
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
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
                        ),
                      ],
                    ),
                  ),
                  _buildAvatarImage(friend.profileImageUrl, friend.username, size: isSelected ? 40 : 34),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      // Events Layer
      for (final ev in _eventsList) {
        if (ev.latitude == null || ev.longitude == null || (ev.latitude == 0.0 && ev.longitude == 0.0)) {
          continue; // Skip events without valid GPS coordinates
        }

        final double eLat = ev.latitude!;
        final double eLng = ev.longitude!;
        final isSelected = _selectedEvent?.id == ev.id;

        mapMarkers.add(
          Marker(
            point: LatLng(eLat, eLng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEvent = ev;
                  _selectedFriend = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 46 : 38,
                height: isSelected ? 46 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF16171D),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryCyan : AppColors.successGreen,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? AppColors.primaryCyan : AppColors.successGreen)
                          .withValues(alpha: isSelected ? 0.6 : 0.3),
                      blurRadius: isSelected ? 12 : 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events,
                    color: isSelected ? AppColors.primaryCyan : AppColors.successGreen,
                    size: isSelected ? 22 : 18,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── FlutterMap Dark Theme Streets Layer ────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: 14.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedFriend = null;
                    _selectedEvent = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.nexus.nexusapp',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(markers: mapMarkers),
              ],
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
                              onTap: () => setState(() {
                                _isEventsTab = false;
                                _selectedFriend = null;
                                _selectedEvent = null;
                              }),
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
                              onTap: () => setState(() {
                                _isEventsTab = true;
                                _selectedFriend = null;
                                _selectedEvent = null;
                              }),
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

                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Map HUD Banner
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
                        Text(
                          _isEventsTab ? 'Tactical Events' : 'Find Your Ally',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _gpsUpdating ? 'Calibrating GPS...' : 'GPS Lock Engaged',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom-Right My Location Centering Button ──────────────────────
          Positioned(
            right: 20,
            bottom: (_selectedFriend != null || _selectedEvent != null) ? 190 : 30,
            child: GestureDetector(
              onTap: _initAndRequestLocation,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF13141B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.my_location, color: AppColors.primaryCyan, size: 24),
              ),
            ),
          ),

          // ── Bottom Detail Overlay Card (Dynamic Allies or Events PageView) ─
          if (_selectedFriend != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildAllyDetailCard(_selectedFriend!),
            )
          else if (_selectedEvent != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildEventDetailCard(_selectedEvent!),
            ),
        ],
      ),
    );
  }

  Widget _buildAllyDetailCard(UserModel ally) {
    final int idx = ally.uid.hashCode;
    final String role = _tacticalRoles[idx % _tacticalRoles.length];
    final List<String> tags = _tacticalTags[idx % _tacticalTags.length];
    
    final int distanceMeters = ally.latitude != null && ally.longitude != null
        ? _calculateDistance(_userLat, _userLng, ally.latitude!, ally.longitude!)
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
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: _buildAvatarImage(ally.profileImageUrl, ally.username, size: 48),
              ),
              const SizedBox(width: 16),
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
          Row(
            children: [
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

  Widget _buildEventDetailCard(EventModel event) {
    final int distanceMeters = event.latitude != null && event.longitude != null
        ? _calculateDistance(_userLat, _userLng, event.latitude!, event.longitude!)
        : (200 + (event.id.hashCode % 1500));

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: AppColors.successGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.location} • ${distanceMeters}M AWAY',
                      style: const TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEvent = null;
                  });
                },
                child: const Icon(Icons.close, color: Colors.white60, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailsScreen(event: event, currentUserId: _currentUserId),
                  ),
                );
              },
              child: const Text('View Event Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
