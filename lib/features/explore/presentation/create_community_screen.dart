import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/services/cloudinary_service.dart';
import 'package:nexus_app/features/community/data/community_service.dart';

class CreateCommunityScreen extends StatefulWidget {
  final String currentUserId;
  const CreateCommunityScreen({super.key, required this.currentUserId});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final CommunityService _communityService = CommunityService();

  File? _imageFile;
  String _uploadedImageUrl = '';
  bool _isUploadingImage = false;
  bool _isCreating = false;
  bool _isPrivate = false;

  final List<String> _tags = ['#FPS', '#COMPETITIVE'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUploadingImage = true;
        });

        final cloudinaryUrl = await CloudinaryService().uploadImage(_imageFile!);
        setState(() {
          _isUploadingImage = false;
          if (cloudinaryUrl != null) {
            _uploadedImageUrl = cloudinaryUrl;
          }
        });
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController tagController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surfaceHighlight,
          title: const Text('Add Tag', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: tagController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. RPG',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPurple)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final text = tagController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    final formatted = text.startsWith('#') ? text : '#$text';
                    if (!_tags.contains(formatted)) {
                      _tags.add(formatted);
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: AppColors.primaryCyan)),
            ),
          ],
        );
      },
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // In firestore community service, createCommunity creates the community.
      // We will also store the private flag or tags in the community document, or pass imageUrl.
      // Let's pass the uploaded image url (or a dummy if empty).
      await _communityService.createCommunity(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        creatorId: widget.currentUserId,
        imageUrl: _uploadedImageUrl.isNotEmpty 
            ? _uploadedImageUrl 
            : 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community created successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
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
                    'Create Community',
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
                      // Upload Cover Artwork Area
                      GestureDetector(
                        onTap: _pickImage,
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: Colors.white24,
                            strokeWidth: 1.5,
                            gap: 6.0,
                            dash: 6.0,
                            borderRadius: 16.0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              color: const Color(0xFF13141B),
                              child: _isUploadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryPurple,
                                      ),
                                    )
                                  : _uploadedImageUrl.isNotEmpty
                                      ? Image.network(
                                          _uploadedImageUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.add_photo_alternate_outlined,
                                              color: Colors.grey,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Upload cover artwork',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.4),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Community Name Label
                      const Text(
                        'Community name',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'e.g. Valorant Tactics',
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
                            borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Community name is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Description Label
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "What's this community about?",
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
                            borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Tags Label
                      const Text(
                        'Tags',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3), width: 1.5),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )),
                          GestureDetector(
                            onTap: _addTag,
                            child: CustomPaint(
                              painter: DashedBorderPainter(
                                color: Colors.white30,
                                strokeWidth: 1.2,
                                gap: 3.0,
                                dash: 3.0,
                                borderRadius: 20.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: Colors.grey, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Private Community Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13141B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Private community',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Invite-only, hidden from explore',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPrivate,
                              onChanged: (val) => setState(() => _isPrivate = val),
                              activeTrackColor: AppColors.primaryPurple,
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C8CFF),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isCreating ? null : _submit,
                          child: _isCreating
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text(
                                  'Create Community',
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

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dash = 5.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.borderRadius != borderRadius;
  }
}
