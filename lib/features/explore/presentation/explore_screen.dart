import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/community/data/community_model.dart';
import 'package:nexus_app/features/community/data/community_service.dart';
import 'package:nexus_app/features/event/data/event_model.dart';
import 'package:nexus_app/features/event/data/event_service.dart';
import 'package:nexus_app/features/explore/presentation/create_community_screen.dart';
import 'package:nexus_app/features/explore/presentation/create_event_screen.dart';
import 'package:nexus_app/features/explore/presentation/event_details_screen.dart';
import 'package:nexus_app/features/explore/presentation/community_details_screen.dart';
import 'package:nexus_app/features/home/presentation/main_layout.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final CommunityService _communityService = CommunityService();
  final EventService _eventService = EventService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isEventsTab = false; // False = Communities, True = Events
  String _searchQuery = '';
  String _selectedTag = '';

  @override
  void initState() {
    super.initState();
    _isEventsTab = TabNavigationController.exploreEventsTab.value;
    TabNavigationController.exploreEventsTab.addListener(_onExploreTabChanged);
  }

  @override
  void dispose() {
    TabNavigationController.exploreEventsTab.removeListener(_onExploreTabChanged);
    super.dispose();
  }

  void _onExploreTabChanged() {
    if (mounted) {
      setState(() {
        _isEventsTab = TabNavigationController.exploreEventsTab.value;
      });
    }
  }

  final List<String> _tags = ['#LFG', '#COMPETITIVE', '#RPG', '#SQUAD'];

  Color _getRandomGlowColor(int index) {
    final colors = [
      AppColors.primaryCyan,
      AppColors.primaryPurple,
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00FF87), // Bright Green
    ];
    return colors[index % colors.length];
  }

  String _formatEventTime(DateTime dateTime) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayStr = days[dateTime.weekday - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$dayStr • $hour:$minute $period';
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CREATE SPACE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.group_outlined, color: Color(0xFF6C8CFF)),
              title: const Text('New Community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Create an invite-only or public community', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCommunityScreen(currentUserId: _currentUserId),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.event_outlined, color: AppColors.primaryPurple),
              title: const Text('New Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Publish an online or offline meetup event', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEventScreen(currentUserId: _currentUserId),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
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
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // ── Sub-header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Space',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Communities and events matched to your DNA',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search & Add Row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Row(
                children: [
                  Expanded(
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
                                hintText: 'Search games, squads, tags',
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
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showCreateBottomSheet,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C8CFF), AppColors.primaryPurple],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Horizontal Tag List ─────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  final isSelected = _selectedTag == tag;
                  final glowColor = _getRandomGlowColor(index);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTag = isSelected ? '' : tag;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? glowColor.withValues(alpha: 0.15) : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? glowColor : Colors.white.withValues(alpha: 0.08),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: isSelected ? glowColor : Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Tab Switcher: Communities vs Events ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isEventsTab = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isEventsTab ? const Color(0xFF6C8CFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Communities',
                            style: TextStyle(
                              color: !_isEventsTab ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isEventsTab = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isEventsTab ? AppColors.primaryPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Events',
                            style: TextStyle(
                              color: _isEventsTab ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Main Tab Contents ───────────────────────────────────────────
            Expanded(
              child: !_isEventsTab ? _buildCommunitiesTab() : _buildEventsTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitiesTab() {
    return StreamBuilder<List<CommunityModel>>(
      stream: _communityService.getCommunities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white38)));
        }

        final list = snapshot.data ?? [];
        
        // Search and tag query filters
        final filteredList = list.where((item) {
          final queryMatch = item.name.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery);
          final tagMatch = _selectedTag.isEmpty ||
              item.description.toLowerCase().contains(_selectedTag.substring(1).toLowerCase()) ||
              item.name.toLowerCase().contains(_selectedTag.substring(1).toLowerCase());
          return queryMatch && tagMatch;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Text(
              'No communities found.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final community = filteredList[index];
            final isJoined = community.memberUids.contains(_currentUserId);
            
            // Assign badges based on index and member count dynamically
            String badge = 'GLOBAL';
            Color badgeColor = AppColors.primaryPurple;
            if (community.memberUids.length >= 3) {
              badge = 'HOT';
              badgeColor = AppColors.statusOnline;
            } else if (index == 0 || community.memberUids.length <= 1) {
              badge = 'NEW';
              badgeColor = AppColors.primaryCyan;
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityDetailsScreen(community: community),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gradient Card Header with Badge
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          colors: [
                            badgeColor.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor, width: 1),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),

                    // Card Content Details
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                community.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${community.memberUids.length} active',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            community.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: community.creatorId == _currentUserId
                                        ? AppColors.primaryPurple.withValues(alpha: 0.2)
                                        : (isJoined ? AppColors.surfaceHighlight : AppColors.successGreen),
                                    foregroundColor: community.creatorId == _currentUserId
                                        ? AppColors.primaryPurple
                                        : (isJoined ? Colors.white60 : Colors.black),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: community.creatorId == _currentUserId
                                          ? const BorderSide(color: AppColors.primaryPurple, width: 1)
                                          : (isJoined ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    if (community.creatorId == _currentUserId) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('As the creator, you cannot leave this community.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    if (isJoined) {
                                      _communityService.leaveCommunity(community.id, _currentUserId);
                                    } else {
                                      _communityService.joinCommunity(community.id, _currentUserId);
                                    }
                                  },
                                  child: Text(
                                    community.creatorId == _currentUserId
                                        ? 'Creator'
                                        : (isJoined ? 'Leave Comm' : 'Join Comm'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceHighlight,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommunityDetailsScreen(community: community),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.share_outlined, color: Colors.white60, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Community link copied to clipboard!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white38)));
        }

        final list = snapshot.data ?? [];

        // Search and tag query filters
        final filteredList = list.where((item) {
          final queryMatch = item.title.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery) ||
              item.location.toLowerCase().contains(_searchQuery);
          final tagMatch = _selectedTag.isEmpty ||
              item.description.toLowerCase().contains(_selectedTag.substring(1).toLowerCase()) ||
              item.title.toLowerCase().contains(_selectedTag.substring(1).toLowerCase());
          return queryMatch && tagMatch;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Text(
              'No events scheduled.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final event = filteredList[index];
            final isGoing = event.attendeeUids.contains(_currentUserId);
            
            // Calculate time diff dynamically for badges
            final diff = event.dateTime.difference(DateTime.now());
            String badge = 'OPEN';
            Color badgeColor = AppColors.successGreen;
            
            if (diff.isNegative) {
              badge = 'CLOSED';
              badgeColor = Colors.white24;
            } else if (diff.inHours <= 3) {
              badge = 'LIVE IN ${diff.inHours}H';
              if (diff.inHours == 0) badge = 'LIVE IN ${diff.inMinutes}M';
              badgeColor = const Color(0xFFE91E63); // Pink live badge
            } else if (index == 0 || diff.inDays == 0) {
              badge = 'NEARBY';
              badgeColor = AppColors.primaryCyan;
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailsScreen(
                      event: event,
                      currentUserId: _currentUserId,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGoing ? AppColors.primaryPurple.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                    width: isGoing ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Calendar/Image Box Left
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            badgeColor.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Middle Details Block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
                                ),
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatEventTime(event.dateTime),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${event.attendeeUids.length} going',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // RSVP Interactive Checkbox
                    IconButton(
                      icon: Icon(
                        event.organizerId == _currentUserId
                            ? Icons.stars_rounded // Stars icon for organizer
                            : (isGoing ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded),
                        color: event.organizerId == _currentUserId
                            ? AppColors.primaryCyan
                            : (isGoing ? AppColors.primaryPurple : Colors.white38),
                        size: 26,
                      ),
                      onPressed: () {
                        if (event.organizerId == _currentUserId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('As the organizer, you are always attending this event.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        if (isGoing) {
                          _eventService.cancelRsvp(event.id, _currentUserId);
                        } else {
                          _eventService.rsvpToEvent(event.id, _currentUserId);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CreateSpaceSheet extends StatefulWidget {
  final String currentUserId;
  final CommunityService communityService;
  final EventService eventService;

  const _CreateSpaceSheet({
    required this.currentUserId,
    required this.communityService,
    required this.eventService,
  });

  @override
  State<_CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends State<_CreateSpaceSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isEventForm = false; // False = Community, True = Event

  // Form Fields
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDateTime;

  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: AppColors.surfaceHighlight,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    if (mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 20, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryPurple,
                onSurface: Colors.white,
                surface: AppColors.surfaceHighlight,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isEventForm && _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time for the event')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      if (!_isEventForm) {
        // Create Community
        await widget.communityService.createCommunity(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          creatorId: widget.currentUserId,
        );
      } else {
        // Create Event
        await widget.eventService.createEvent(
          title: _nameController.text.trim(),
          description: _descController.text.trim(),
          organizerId: widget.currentUserId,
          dateTime: _selectedDateTime!,
          location: _locationController.text.trim(),
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEventForm ? 'Event created successfully!' : 'Community created successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CREATE SPACE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Community', style: TextStyle(fontSize: 11)),
                        selected: !_isEventForm,
                        onSelected: (val) => setState(() => _isEventForm = false),
                        selectedColor: const Color(0xFF6C8CFF),
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(color: !_isEventForm ? Colors.black : Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Event', style: TextStyle(fontSize: 11)),
                        selected: _isEventForm,
                        onSelected: (val) => setState(() => _isEventForm = true),
                        selectedColor: AppColors.primaryPurple,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(color: _isEventForm ? Colors.black : Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title / Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _isEventForm ? 'Event Title' : 'Community Name',
                  hintStyle: const TextStyle(color: Colors.white24),
                  fillColor: AppColors.surface,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Description',
                  hintStyle: const TextStyle(color: Colors.white24),
                  fillColor: AppColors.surface,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Event Specific Fields
              if (_isEventForm) ...[
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Location (Optional)',
                    hintStyle: const TextStyle(color: Colors.white24),
                    fillColor: AppColors.surface,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDateTime == null
                              ? 'Pick Event Date & Time'
                              : 'Selected: ${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} at ${_selectedDateTime!.hour}:${_selectedDateTime!.minute}',
                          style: TextStyle(
                            color: _selectedDateTime == null ? Colors.white24 : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.calendar_month, color: Colors.white54, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEventForm ? AppColors.primaryPurple : const Color(0xFF6C8CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isCreating ? null : _submit,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('CREATE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
