import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/features/chat/data/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isRead;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isRead,
  });

  String _formatMessageTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
    return '$hour:$minute $period';
  }

  bool _isFileMessage(String text) {
    return text.toLowerCase().endsWith('.docx') ||
        text.toLowerCase().endsWith('.pdf') ||
        text.toLowerCase().endsWith('.xlsx') ||
        text.toLowerCase().endsWith('.pptx');
  }

  Widget _buildMessageText(String text) {
    String cleanText = text;
    bool isItalic = false;

    // Support basic *italic* or _italic_ formatting
    if ((text.startsWith('_') && text.endsWith('_')) ||
        (text.startsWith('*') && text.endsWith('*'))) {
      cleanText = text.substring(1, text.length - 1);
      isItalic = true;
    }

    return Text(
      cleanText,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        height: 1.4,
      ),
    );
  }

  Widget _buildFileBubble(String filename) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B39EF), // Indigo border matching the design
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.primaryCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  '487 KB',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(BuildContext context, String imageUrl, bool isMe) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageScreen(imageUrl: imageUrl),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          maxHeight: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.surface : const Color(0xFF1B1C22),
          borderRadius: BorderRadius.circular(16),
          border: isMe
              ? Border.all(
                  color: const Color(0xFF4B39EF),
                  width: 1.2,
                )
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                width: 150,
                color: Colors.black26,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryCyan,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(12),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.errorRed),
                    SizedBox(width: 8),
                    Text('Failed to load image', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFile = _isFileMessage(message.text);
    final isImage = message.type == 'image';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isFile)
            _buildFileBubble(message.text)
          else if (isImage)
            _buildImageBubble(context, message.imageUrl, isMe)
          else if (isMe)
            // Sent bubble with solid background and thin purple/indigo outline
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface, // Solid dark grey matching the design
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4B39EF), // Solid indigo border
                  width: 1.2,
                ),
              ),
              child: _buildMessageText(message.text),
            )
          else
            // Received bubble (solid dark background, no border)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1C22), // Solid dark grey matching the design
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildMessageText(message.text),
            ),
          
          // Time representation below the bubble
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: isMe
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        color: isRead ? AppColors.statusOnline : Colors.white24,
                        size: 14,
                      ),
                    ],
                  )
                : Text(
                    _formatMessageTime(message.timestamp),
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
