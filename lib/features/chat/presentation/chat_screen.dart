import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/chat/data/chat_service.dart';
import 'package:nexus_app/features/chat/data/message_model.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel recipient;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipient,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      await _chatService.sendMessage(widget.chatId, _currentUserId, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  List<dynamic> _groupMessages(List<MessageModel> messages) {
    final List<dynamic> items = [];
    for (int i = 0; i < messages.length; i++) {
      items.add(messages[i]);
      
      final currentMsg = messages[i];
      final hasNext = i + 1 < messages.length;
      
      if (!hasNext) {
        items.add(currentMsg.timestamp);
      } else {
        final nextMsg = messages[i + 1];
        if (!_isSameDay(currentMsg.timestamp, nextMsg.timestamp)) {
          items.add(currentMsg.timestamp);
        }
      }
    }
    return items;
  }

  String _formatMessageTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceHighlight,
                  backgroundImage: widget.recipient.profileImageUrl.isNotEmpty
                      ? NetworkImage(widget.recipient.profileImageUrl)
                      : null,
                  child: widget.recipient.profileImageUrl.isEmpty
                      ? Text(
                          widget.recipient.username.isNotEmpty
                              ? widget.recipient.username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.primaryCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.statusOnline,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              widget.recipient.fullName.isNotEmpty ? widget.recipient.fullName : widget.recipient.username,
              style: const TextStyle(
                color: Color(0xFF58A6FF), // Cyan/Blue shade matching the design
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages Stream
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Colors.white12, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Say GG to start the conversation!',
                            style: TextStyle(color: Colors.white24, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  final groupedItems = _groupMessages(messages);

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 8),
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final item = groupedItems[index];
                      if (item is DateTime) {
                        return _buildDateDivider(item);
                      }
                      final message = item as MessageModel;
                      final isMe = message.senderId == _currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            
            // Redesigned Custom Input Field Container
            Container(
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
                children: [
                  // Paperclip attachment button
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: Colors.white54, size: 22),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  
                  // Text input container with cyan glow outline
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.white54, size: 22),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Blue paper airplane send button matching design
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C8CFF), // Indigo/Blue from design
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C8CFF).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    String dateStr = '';
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      dateStr = 'TODAY';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      dateStr = 'YESTERDAY';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateStr,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
        ],
      ),
    );
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

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final isFile = _isFileMessage(message.text);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isFile)
            _buildFileBubble(message.text)
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
                      const Icon(
                        Icons.done_all_rounded,
                        color: AppColors.statusOnline, // Green checkmarks
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

