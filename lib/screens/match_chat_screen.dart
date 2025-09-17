import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../providers/auth_provider.dart';
import '../services/matching_service.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  WebSocketChannel? _channel;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMessages();
    _connectToSocket();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadMessages() async {
    final messages = await MatchingService.getMatchMessages(widget.matchId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _connectToSocket() {
    try {
      _channel = IOWebSocketChannel.connect('ws://localhost:3000');
      
      // Join the match room
      _channel!.sink.add(json.encode({
        'type': 'join_match',
        'matchId': widget.matchId,
      }));

      // Listen for messages
      _channel!.stream.listen(
        (data) {
          final message = json.decode(data);
          if (message['type'] == 'new_message') {
            setState(() {
              _messages.add(message['data']);
            });
            _scrollToBottom();
          } else if (message['type'] == 'typing') {
            setState(() {
              _isTyping = message['isTyping'];
            });
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    // Send to Supabase
    final success = await MatchingService.sendMessage(
      widget.matchId,
      currentUser['id'],
      text,
    );

    if (success) {
      // Send via WebSocket for real-time delivery
      _channel?.sink.add(json.encode({
        'type': 'send_message',
        'matchId': widget.matchId,
        'senderId': currentUser['id'],
        'content': text,
      }));

      _messageController.clear();
    }
  }

  void _onTyping() {
    _channel?.sink.add(json.encode({
      'type': 'typing',
      'matchId': widget.matchId,
      'isTyping': true,
    }));

    // Stop typing after 2 seconds of inactivity
    Timer(const Duration(seconds: 2), () {
      _channel?.sink.add(json.encode({
        'type': 'typing',
        'matchId': widget.matchId,
        'isTyping': false,
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
              child: Text(
                widget.otherUser['full_name']?[0]?.toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser['full_name'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(
                        _getMoodIcon(widget.otherUser['mood'] ?? 'Happy'),
                        size: 14,
                        color: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Feeling ${widget.otherUser['mood'] ?? 'Happy'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getMoodColor(widget.otherUser['mood'] ?? 'Happy').withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Match info banner
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getMoodColor(widget.otherUser['mood'] ?? 'Happy').withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getMoodColor(widget.otherUser['mood'] ?? 'Happy').withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You both are feeling ${widget.otherUser['mood'] ?? 'Happy'} - Perfect match!',
                      style: TextStyle(
                        color: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Messages list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['sender']['id'] == currentUser?['id'];
                          
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
                    ),
            ),
            
            // Typing indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
                      child: Text(
                        widget.otherUser['full_name']?[0]?.toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypingDot(0),
                          const SizedBox(width: 4),
                          _buildTypingDot(1),
                          const SizedBox(width: 4),
                          _buildTypingDot(2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) => _onTyping(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getMoodColor(widget.otherUser['mood'] ?? 'Happy'),
              child: Text(
                message['sender']['full_name']?[0]?.toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? _getMoodColor(widget.otherUser['mood'] ?? 'Happy')
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['content'],
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(DateTime.parse(message['sent_at'])),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_animationController.value + delay) % 1.0;
        final opacity = (math.sin(animationValue * 2 * math.pi) + 1) / 2;
        
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade600.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Sad':
        return Icons.sentiment_very_dissatisfied;
      case 'Excited':
        return Icons.celebration;
      case 'Calm':
        return Icons.spa;
      case 'Anxious':
        return Icons.psychology;
      case 'Romantic':
        return Icons.favorite;
      case 'Adventurous':
        return Icons.explore;
      case 'Peaceful':
        return Icons.self_improvement;
      default:
        return Icons.mood;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.yellow.shade700;
      case 'Sad':
        return Colors.blue.shade600;
      case 'Excited':
        return Colors.orange.shade600;
      case 'Calm':
        return Colors.green.shade600;
      case 'Anxious':
        return Colors.purple.shade600;
      case 'Romantic':
        return Colors.pink.shade600;
      case 'Adventurous':
        return Colors.red.shade600;
      case 'Peaceful':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
