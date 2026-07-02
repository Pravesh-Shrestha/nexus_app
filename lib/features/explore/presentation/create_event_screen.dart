import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/event/data/event_service.dart';
import 'package:nexus_app/features/community/data/community_service.dart';
import 'package:nexus_app/features/community/data/community_model.dart';

class CreateEventScreen extends StatefulWidget {
  final String currentUserId;
  const CreateEventScreen({super.key, required this.currentUserId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final EventService _eventService = EventService();
  final CommunityService _communityService = CommunityService();

  String _selectedGame = 'Valorant';
  final List<String> _games = ['Valorant', 'League of Legends', 'Apex Legends', 'Fortnite', 'Minecraft', 'CS:GO'];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isOnline = true; // True = Online, False = Local meetup
  String? _selectedHostCommunityId;
  List<CommunityModel> _myCommunities = [];
  bool _isLoadingCommunities = true;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadMyCommunities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _loadMyCommunities() {
    _communityService.getCommunities().first.then((communities) {
      if (mounted) {
        setState(() {
          _myCommunities = communities.where((c) {
            return c.creatorId == widget.currentUserId || c.memberUids.contains(widget.currentUserId);
          }).toList();
          if (_myCommunities.isNotEmpty) {
            _selectedHostCommunityId = _myCommunities.first.id;
          }
          _isLoadingCommunities = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _isLoadingCommunities = false);
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
        _selectedTime = time;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date and time'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final hostCommunityName = _myCommunities.firstWhere(
        (c) => c.id == _selectedHostCommunityId,
        orElse: () => CommunityModel(id: '', name: 'General', description: '', creatorId: ''),
      ).name;

      await _eventService.createEvent(
        title: _titleController.text.trim(),
        description: 'Hosted by community: $hostCommunityName. Game: $_selectedGame.',
        organizerId: widget.currentUserId,
        dateTime: combinedDateTime,
        location: _isOnline ? 'Online' : 'Local meetup',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event published successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _isOnline ? const Color(0xFF6C8CFF) : const Color(0xFFAB47BC);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header matching screenshots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
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
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Create Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Title
                      const Text(
                        'Event title',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'e.g. Friday Night Scrims',
                          hintStyle: const TextStyle(color: Colors.white24),
                          fillColor: const Color(0xFF13141B),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accentColor, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Event title is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Game Dropdown
                      const Text(
                        'Game',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13141B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGame,
                            dropdownColor: const Color(0xFF13141B),
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                            isExpanded: true,
                            items: _games.map((game) {
                              return DropdownMenuItem<String>(
                                value: game,
                                child: Text(game),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGame = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date / Time split columns
                      const Text(
                        'Date / Time',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF13141B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10, width: 1),
                                ),
                                child: Text(
                                  _formatDate(_selectedDate),
                                  style: TextStyle(
                                    color: _selectedDate == null ? Colors.white24 : Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF13141B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10, width: 1),
                                ),
                                child: Text(
                                  _formatTime(_selectedTime),
                                  style: TextStyle(
                                    color: _selectedTime == null ? Colors.white24 : Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Type segmented controls
                      const Text(
                        'Type',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13141B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isOnline = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isOnline ? const Color(0xFF6C8CFF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Online',
                                      style: TextStyle(
                                        color: _isOnline ? Colors.black : Colors.white60,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isOnline = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isOnline ? const Color(0xFFAB47BC) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Local meetup',
                                      style: TextStyle(
                                        color: !_isOnline ? Colors.white : Colors.white60,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Capacity
                      const Text(
                        'Capacity',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _capacityController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Max attendees',
                          hintStyle: const TextStyle(color: Colors.white24),
                          fillColor: const Color(0xFF13141B),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accentColor, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Host community
                      const Text(
                        'Host community',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingCommunities
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF13141B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10, width: 1),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedHostCommunityId,
                                  dropdownColor: const Color(0xFF13141B),
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                  isExpanded: true,
                                  hint: const Text('Select a community', style: TextStyle(color: Colors.white24)),
                                  items: _myCommunities.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedHostCommunityId = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                      const SizedBox(height: 40),

                      // Publish Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: _isOnline ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isPublishing ? null : _submit,
                          child: _isPublishing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Publish Event',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
