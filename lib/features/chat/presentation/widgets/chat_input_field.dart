import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/services/cloudinary_service.dart';
import 'emoji_picker_sheet.dart';

class ChatInputField extends StatefulWidget {
  final ValueChanged<String> onSendMessage;
  final ValueChanged<String> onImageSent;
  final ValueChanged<bool> onUploadStateChanged;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    required this.onImageSent,
    required this.onUploadStateChanged,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  Future<void> _pickAndSendImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryCyan),
                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryCyan),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        widget.onUploadStateChanged(true);

        final cloudinaryUrl = await CloudinaryService().uploadImage(File(pickedFile.path));
        
        if (cloudinaryUrl != null) {
          widget.onImageSent(cloudinaryUrl);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      widget.onUploadStateChanged(false);
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EmojiPickerSheet(
        onEmojiSelected: (emoji) {
          final text = _controller.text;
          final selection = _controller.selection;
          
          if (selection.isValid) {
            final newText = text.replaceRange(selection.start, selection.end, emoji);
            _controller.value = _controller.value.copyWith(
              text: newText,
              selection: TextSelection.collapsed(offset: selection.start + emoji.length),
            );
          } else {
            _controller.text = text + emoji;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Camera button replacing paperclip with 40x40 bounds
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white54, size: 22),
            onPressed: _pickAndSendImage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
          const SizedBox(width: 4),
          
          // Text input container with cyan glow outline and stacked emoji button
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 40,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryCyan.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 40, top: 2, bottom: 2),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 0,
                    top: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.white54, size: 22),
                        onPressed: _showEmojiPicker,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Blue paper airplane send button matching design (40x40)
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6C8CFF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C8CFF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
