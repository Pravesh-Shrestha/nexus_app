import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:nexus_app/core/theme/app_sizes.dart';
import 'package:nexus_app/features/chat/data/chat_service.dart';
import 'package:nexus_app/features/chat/data/message_model.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:nexus_app/features/chat/presentation/widgets/chat_input_field.dart';

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
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  StreamSubscription<DocumentSnapshot>? _chatRoomSubscription;
  Map<String, dynamic> _unreadCounts = {};
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _subscribeToChatRoom();
    _markAsRead();
  }

  void _subscribeToChatRoom() {
    _chatRoomSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        if (data != null) {
          setState(() {
            final map = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
            data.forEach((key, value) {
              if (key.startsWith('unreadCounts.')) {
                final uid = key.replaceFirst('unreadCounts.', '');
                map[uid] = value;
              }
            });
            _unreadCounts = map;
          });
        }
      }
    });
  }

  void _markAsRead() {
    _chatService.markChatAsRead(widget.chatId, _currentUserId);
  }

  void _sendMessage(String text) async {
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

  void _sendImage(String imageUrl) async {
    try {
      await _chatService.sendMessage(
        widget.chatId,
        _currentUserId,
        'Sent a photo',
        type: 'image',
        imageUrl: imageUrl,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
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

  Set<String> _calculateReadMessageIds(List<MessageModel> messages) {
    final Set<String> readIds = {};
    final recipientVal = _unreadCounts[widget.recipient.uid];
    final recipientUnreadCount = recipientVal is num ? recipientVal.toInt() : 0;
    
    int mySentCount = 0;
    for (var message in messages) {
      if (message.senderId == _currentUserId) {
        mySentCount++;
        if (mySentCount > recipientUnreadCount) {
          readIds.add(message.id);
        }
      }
    }
    return readIds;
  }

  Widget _buildUploadingBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(4),
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4B39EF),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Uploading photo...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              'Sending...',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
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

  @override
  void dispose() {
    _chatRoomSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
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
                color: Color(0xFF58A6FF),
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
                  
                  if (messages.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markAsRead();
                    });
                  }

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
                  final readMessageIds = _calculateReadMessageIds(messages);

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 8),
                    itemCount: groupedItems.length + (_isUploading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isUploading && index == 0) {
                        return _buildUploadingBubble();
                      }
                      
                      final itemIndex = _isUploading ? index - 1 : index;
                      final item = groupedItems[itemIndex];
                      if (item is DateTime) {
                        return _buildDateDivider(item);
                      }
                      final message = item as MessageModel;
                      final isMe = message.senderId == _currentUserId;
                      return ChatBubble(
                        message: message,
                        isMe: isMe,
                        isRead: readMessageIds.contains(message.id),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Bottom chat input field
            ChatInputField(
              onSendMessage: _sendMessage,
              onImageSent: _sendImage,
              onUploadStateChanged: (uploading) {
                setState(() {
                  _isUploading = uploading;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
