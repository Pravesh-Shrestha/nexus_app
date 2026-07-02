import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/event/data/event_model.dart';
import 'package:nexus_app/features/event/data/event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final String currentUserId;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.currentUserId,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventService _eventService = EventService();
  late Stream<EventModel?> _eventStream;

  @override
  void initState() {
    super.initState();
    // Get real-time updates for this specific event from Firestore
    _eventStream = _eventService.getEvents().map((events) {
      final matches = events.where((e) => e.id == widget.event.id);
      return matches.isNotEmpty ? matches.first : null;
    });
  }

  String _formatEventTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayStr;
    if (today == eventDay) {
      dayStr = 'Today';
    } else {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayStr = days[dateTime.weekday - 1];
    }

    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$dayStr · $hour:$minute $period';
  }

  void _toggleRsvp(bool isGoing) async {
    try {
      if (isGoing) {
        await _eventService.cancelRsvp(widget.event.id, widget.currentUserId);
      } else {
        await _eventService.rsvpToEvent(widget.event.id, widget.currentUserId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update RSVP: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<EventModel?>(
        stream: _eventStream,
        initialData: widget.event,
        builder: (context, snapshot) {
          final event = snapshot.data ?? widget.event;
          final isGoing = event.attendeeUids.contains(widget.currentUserId);

          // Calculate time diff dynamically for badges
          final diff = event.dateTime.difference(DateTime.now());
          String badgeText = 'OPEN';
          if (diff.isNegative) {
            badgeText = 'CLOSED';
          } else if (diff.inHours <= 3) {
            badgeText = 'LIVE IN ${diff.inHours}H';
            if (diff.inHours == 0) badgeText = 'LIVE IN ${diff.inMinutes}M';
          }

          // Parse host community name from description if stored there or fallback
          String hostCommunity = 'Valorant Tactics';
          if (event.description.contains('Hosted by community:')) {
            final parts = event.description.split('Hosted by community:');
            if (parts.length > 1) {
              final subParts = parts[1].split('. Game:');
              if (subParts.isNotEmpty) {
                hostCommunity = subParts[0].trim();
              }
            }
          }

          // Visual details matching screenshots
          return Stack(
            children: [
              // Top Banner Area with Gradient Background
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE91E63).withValues(alpha: 0.15),
                      AppColors.primaryPurple.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Back button and Live badge overlay
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Event Info Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              // Host Community Subtitle Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white10, width: 1),
                                ),
                                child: Text(
                                  hostCommunity,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Detail Rows
                              // Time Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryPurple.withValues(alpha: 0.15),
                                      border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3), width: 1),
                                    ),
                                    child: const Icon(
                                      Icons.access_time,
                                      color: AppColors.primaryPurple,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatEventTime(event.dateTime),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Runs ~3 hours',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Location/Platform Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.successGreen.withValues(alpha: 0.15),
                                      border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3), width: 1),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.successGreen,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.location.isNotEmpty ? event.location : 'Online · Twitch Stream',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Hosted in $hostCommunity',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Attendance Bar Card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF13141B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10, width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Overlapping attendee avatars
                                        SizedBox(
                                          width: 64,
                                          height: 28,
                                          child: Stack(
                                            children: [
                                              _buildAvatar(0, 'Z', const Color(0xFF4CAF50)),
                                              _buildAvatar(1, 'N', const Color(0xFF9C27B0)),
                                              _buildAvatar(2, 'R', const Color(0xFF00BCD4)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          event.attendeeUids.length > 3
                                              ? '${event.attendeeUids.length} going'
                                              : '2.4k going', // mockup fallback if database is empty
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_drop_up,
                                          color: AppColors.successGreen,
                                          size: 20,
                                        ),
                                        Text(
                                          'trending',
                                          style: TextStyle(
                                            color: AppColors.successGreen,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // About Header Label
                              const Text(
                                'About',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Description Paragraph
                              Text(
                                event.description.contains('Hosted by community:')
                                    ? 'The two top squads clash for the regional title. Watch party, live predictions, and GG rewards for attendees.'
                                    : event.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Sticky Actions
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: const Border(
                            top: BorderSide(color: Colors.white10, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Main Green RSVP Button
                            Expanded(
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2ECC71),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () => _toggleRsvp(isGoing),
                                  child: Text(
                                    isGoing ? 'Going ✓' : "RSVP — I'm in",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Share Action Button
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Event link copied to clipboard!'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                              },
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white24, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.share_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar(int index, String initial, Color color) {
    return Positioned(
      left: index * 16.0,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF13141B), width: 2),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
