import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/auth/data/auth_service.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/friends/presentation/view_friend_screen.dart';
import 'package:nexus_app/features/event/data/event_model.dart';
import 'package:nexus_app/features/event/data/event_service.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/widgets/custom_snackbar.dart';

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
    } on AppException catch (e) {
      if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'RSVP Failed',
            message: 'Failed to update RSVP status.',
            actionText: 'Retry',
          ),
        );
      }
    }
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

  void _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHighlight,
        title: const Text('Delete Event', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this event permanently?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('events').doc(widget.event.id).delete();
        if (mounted) {
          Navigator.pop(context); // pop organizer menu / details screen
          CustomSnackBar.showSuccessSnackBar(
            context,
            title: 'Success',
            message: 'Event deleted successfully!',
          );
        }
      } on AppException catch (e) {
        if (mounted) CustomSnackBar.showErrorSnackBar(context, e);
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showErrorSnackBar(
            context,
            AppException(
              title: 'Delete Failed',
              message: 'Failed to delete event. Please try again.',
              actionText: 'Retry',
            ),
          );
        }
      }
    }
  }

  void _editEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditEventSheet(
        event: widget.event,
      ),
    );
  }

  void _showOrganizerMenu() {
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
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primaryCyan),
              title: const Text('Edit Event', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editEvent();
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.errorRed),
              title: const Text('Delete Event', style: TextStyle(color: AppColors.errorRed)),
              onTap: () {
                Navigator.pop(context);
                _deleteEvent();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendeesSheet(List<String> attendeeUids) {
    if (attendeeUids.isEmpty) return;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ATTENDEES',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: attendeeUids.length,
                itemBuilder: (context, index) {
                  final uid = attendeeUids[index];
                  return FutureBuilder<UserModel?>(
                    future: AuthService().getUserData(uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox();
                      }
                      final user = snapshot.data!;
                      final name = user.username.isNotEmpty ? user.username : user.fullName;
                      final role = user.role.isNotEmpty ? '${user.role} · ${user.playstyle}' : 'Gamer';
                      final color = _getAvatarColor(name);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(role, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          if (uid == widget.currentUserId) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewFriendScreen(userModel: user),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicAvatar(int index, String uid) {
    return Positioned(
      left: index * 16.0,
      child: FutureBuilder<UserModel?>(
        future: AuthService().getUserData(uid),
        builder: (context, snapshot) {
          final initial = snapshot.data != null && snapshot.data!.username.isNotEmpty
              ? snapshot.data!.username[0].toUpperCase()
              : 'G';
          final name = snapshot.data?.username ?? 'Gamer';
          final color = _getAvatarColor(name);
          return Container(
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
          );
        },
      ),
    );
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

          // Parse host community name from description
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
                      Row(
                        children: [
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
                          if (event.organizerId == widget.currentUserId) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _showOrganizerMenu,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                child: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                                        event.latitude != null
                                            ? 'Hosted in $hostCommunity (${event.latitude!.toStringAsFixed(4)}, ${event.longitude!.toStringAsFixed(4)})'
                                            : 'Hosted in $hostCommunity',
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
                                child: InkWell(
                                  onTap: () => _showAttendeesSheet(event.attendeeUids),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (event.attendeeUids.isNotEmpty) ...[
                                            SizedBox(
                                              width: (event.attendeeUids.length.clamp(1, 3) * 16.0) + 12,
                                              height: 28,
                                              child: Stack(
                                                children: List.generate(
                                                  event.attendeeUids.length.clamp(0, 3),
                                                  (i) => _buildDynamicAvatar(i, event.attendeeUids[i]),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ] else ...[
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
                                          ],
                                          Text(
                                            event.attendeeUids.isNotEmpty
                                                ? '${event.attendeeUids.length} going'
                                                : '2.4k going',
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
                                    backgroundColor: event.organizerId == widget.currentUserId
                                        ? AppColors.primaryCyan.withValues(alpha: 0.2)
                                        : const Color(0xFF2ECC71),
                                    foregroundColor: event.organizerId == widget.currentUserId
                                        ? AppColors.primaryCyan
                                        : Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: event.organizerId == widget.currentUserId
                                          ? const BorderSide(color: AppColors.primaryCyan, width: 1)
                                          : BorderSide.none,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (event.organizerId == widget.currentUserId) {
                                      CustomSnackBar.showErrorSnackBar(
                                        context,
                                        AppException(
                                          title: 'Cannot RSVP',
                                          message: 'As the organizer, you are always attending this event.',
                                          actionText: 'Okay',
                                        ),
                                      );
                                      return;
                                    }
                                    _toggleRsvp(isGoing);
                                  },
                                  child: Text(
                                    event.organizerId == widget.currentUserId
                                        ? 'Organizer'
                                        : (isGoing ? 'Going ✓' : "RSVP — I'm in"),
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
                                Clipboard.setData(ClipboardData(text: 'https://nexusapp.com/event/${event.id}'));
                                CustomSnackBar.showSuccessSnackBar(
                                  context,
                                  title: 'Copied',
                                  message: 'Event link copied to clipboard!',
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

class _EditEventSheet extends StatefulWidget {
  final EventModel event;
  const _EditEventSheet({required this.event});

  @override
  State<_EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<_EditEventSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location);
    _descController = TextEditingController(text: widget.event.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.event.id).update({
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccessSnackBar(
          context,
          title: 'Success',
          message: 'Event updated successfully!',
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomSnackBar.showErrorSnackBar(context, e);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomSnackBar.showErrorSnackBar(
          context,
          AppException(
            title: 'Update Failed',
            message: 'Failed to update event. Please try again.',
            actionText: 'Retry',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EDIT EVENT', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.white60)),
              validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Location/Platform', labelStyle: TextStyle(color: Colors.white60)),
              validator: (val) => val == null || val.trim().isEmpty ? 'Location is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white60)),
              validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C8CFF)),
                onPressed: _isSaving ? null : _save,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Save Changes', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
