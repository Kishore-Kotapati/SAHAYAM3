import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';

// Import your existing database service
// import 'firebase_database_service.dart';

class FirebaseChatService {
  static final FirebaseChatService _instance = FirebaseChatService._internal();
  factory FirebaseChatService() => _instance;
  FirebaseChatService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Database references
  DatabaseReference get _chatsRef => _database.ref('chats');
  DatabaseReference get _messagesRef => _database.ref('messages');
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _chatParticipantsRef => _database.ref('chatParticipants');

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Stream subscriptions for cleanup
  final Map<String, StreamSubscription> _subscriptions = {};

  // Chat room management
  Future<String> createChatRoom({
    required String name,
    required List<String> participantIds,
    String? description,
    String? chatType = 'group', // 'group', 'direct', 'mood_match'
    String? matchId,
    String? sharedMood,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final chatRef = _chatsRef.push();
      final chatId = chatRef.key!;
      
      final chatData = {
        'id': chatId,
        'name': name,
        'description': description,
        'type': chatType,
        'createdBy': currentUserId,
        'createdAt': ServerValue.timestamp,
        'lastActivity': ServerValue.timestamp,
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSender': null,
        'messageCount': 0,
        'participantCount': participantIds.length,
        'isActive': true,
        'matchId': matchId,
        'sharedMood': sharedMood,
        'metadata': metadata,
      };
      
      await chatRef.set(chatData);
      
      // Add participants
      await addParticipantsToChat(chatId, participantIds);
      
      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<void> addParticipantsToChat(String chatId, List<String> participantIds) async {
    try {
      final batch = <String, dynamic>{};
      final joinTime = ServerValue.timestamp;
      
      for (final participantId in participantIds) {
        // Add to chat participants
        batch['$chatId/$participantId'] = {
          'userId': participantId,
          'joinedAt': joinTime,
          'role': 'member',
          'isActive': true,
          'lastRead': null,
          'unreadCount': 0,
        };
        
        // Add chat to user's chat list
        await _usersRef.child(participantId).child('chats').child(chatId).set({
          'chatId': chatId,
          'joinedAt': joinTime,
          'isActive': true,
          'isPinned': false,
          'isMuted': false,
        });
      }
      
      await _chatParticipantsRef.update(batch);
      
      // Update participant count
      await _chatsRef.child(chatId).update({
        'participantCount': participantIds.length,
      });
    } catch (e) {
      throw Exception('Failed to add participants: $e');
    }
  }

  Future<void> removeParticipantFromChat(String chatId, String participantId) async {
    try {
      // Remove from chat participants
      await _chatParticipantsRef.child(chatId).child(participantId).update({
        'isActive': false,
        'leftAt': ServerValue.timestamp,
      });
      
      // Remove chat from user's chat list
      await _usersRef.child(participantId).child('chats').child(chatId).update({
        'isActive': false,
        'leftAt': ServerValue.timestamp,
      });
      
      // Update participant count
      final participantsSnapshot = await _chatParticipantsRef.child(chatId).get();
      if (participantsSnapshot.exists) {
        final participants = Map<String, dynamic>.from(participantsSnapshot.value as Map);
        final activeCount = participants.values
            .where((p) => (p as Map)['isActive'] == true)
            .length;
        
        await _chatsRef.child(chatId).update({
          'participantCount': activeCount,
        });
      }
    } catch (e) {
      throw Exception('Failed to remove participant: $e');
    }
  }

  Future<void> updateChatInfo({
    required String chatId,
    String? name,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': ServerValue.timestamp,
      };
      
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (metadata != null) updates['metadata'] = metadata;
      
      await _chatsRef.child(chatId).update(updates);
    } catch (e) {
      throw Exception('Failed to update chat info: $e');
    }
  }

  // Message management
  Future<String> sendMessage({
    required String chatId,
    required String text,
    String messageType = 'text',
    String? replyToMessageId,
    String? mood,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final messageRef = _messagesRef.child(chatId).push();
      final messageId = messageRef.key!;
      
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': currentUserId,
        'text': text,
        'type': messageType,
        'timestamp': ServerValue.timestamp,
        'edited': false,
        'deleted': false,
        'replyTo': replyToMessageId,
        'mood': mood,
        'attachments': attachments,
        'reactions': {},
        'metadata': metadata,
      };
      
      await messageRef.set(messageData);
      
      // Update chat with last message info
      await _chatsRef.child(chatId).update({
        'lastMessage': text,
        'lastMessageTime': ServerValue.timestamp,
        'lastMessageSender': currentUserId,
        'lastActivity': ServerValue.timestamp,
        'messageCount': ServerValue.increment(1),
      });
      
      // Update unread counts for other participants
      await _updateUnreadCounts(chatId, currentUserId);
      
      return messageId;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> _updateUnreadCounts(String chatId, String senderId) async {
    try {
      final participantsSnapshot = await _chatParticipantsRef.child(chatId).get();
      if (participantsSnapshot.exists) {
        final participants = Map<String, dynamic>.from(participantsSnapshot.value as Map);
        
        final batch = <String, dynamic>{};
        for (final entry in participants.entries) {
          final participantId = entry.key;
          final participantData = Map<String, dynamic>.from(entry.value as Map);
          
          if (participantId != senderId && participantData['isActive'] == true) {
            batch['$chatId/$participantId/unreadCount'] = ServerValue.increment(1);
          }
        }
        
        if (batch.isNotEmpty) {
          await _chatParticipantsRef.update(batch);
        }
      }
    } catch (e) {
      print('Error updating unread counts: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) return;

      await _chatParticipantsRef.child(chatId).child(currentUserId).update({
        'lastRead': ServerValue.timestamp,
        'unreadCount': 0,
      });
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Verify user owns the message
      final messageSnapshot = await _messagesRef.child(chatId).child(messageId).get();
      if (!messageSnapshot.exists) throw Exception('Message not found');
      
      final messageData = Map<String, dynamic>.from(messageSnapshot.value as Map);
      if (messageData['senderId'] != currentUserId) {
        throw Exception('Permission denied: Cannot edit other user\'s message');
      }
      
      await _messagesRef.child(chatId).child(messageId).update({
        'text': newText,
        'edited': true,
        'editedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final messageSnapshot = await _messagesRef.child(chatId).child(messageId).get();
      if (!messageSnapshot.exists) throw Exception('Message not found');
      
      final messageData = Map<String, dynamic>.from(messageSnapshot.value as Map);
      
      if (deleteForEveryone) {
        // Check if user has permission (sender or chat admin)
        if (messageData['senderId'] != currentUserId) {
          final chatParticipant = await _chatParticipantsRef
              .child(chatId)
              .child(currentUserId)
              .get();
          
          if (!chatParticipant.exists || 
              (chatParticipant.value as Map)['role'] != 'admin') {
            throw Exception('Permission denied: Cannot delete message for everyone');
          }
        }
        
        await _messagesRef.child(chatId).child(messageId).update({
          'deleted': true,
          'text': 'This message was deleted',
          'deletedAt': ServerValue.timestamp,
          'deletedBy': currentUserId,
        });
      } else {
        // Delete for self only - add to user's deleted messages list
        await _usersRef
            .child(currentUserId)
            .child('deletedMessages')
            .child(messageId)
            .set(true);
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> reactToMessage({
    required String chatId,
    required String messageId,
    required String reaction,
  }) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      final reactionRef = _messagesRef
          .child(chatId)
          .child(messageId)
          .child('reactions')
          .child(reaction)
          .child(currentUserId);
      
      // Toggle reaction
      final reactionSnapshot = await reactionRef.get();
      if (reactionSnapshot.exists) {
        await reactionRef.remove();
      } else {
        await reactionRef.set(ServerValue.timestamp);
      }
    } catch (e) {
      throw Exception('Failed to react to message: $e');
    }
  }

  // Real-time streams
  Stream<List<ChatMessage>> getChatMessagesStream(String chatId, {int limit = 50}) {
    return _messagesRef
        .child(chatId)
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .asyncMap((event) async {
      final messages = <ChatMessage>[];
      final currentUserId = currentUser?.uid;
      
      if (event.snapshot.exists) {
        final messagesMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Get user's deleted messages
        Set<String> deletedMessageIds = {};
        if (currentUserId != null) {
          final deletedSnapshot = await _usersRef
              .child(currentUserId)
              .child('deletedMessages')
              .get();
          if (deletedSnapshot.exists) {
            deletedMessageIds = Set<String>.from(
              (deletedSnapshot.value as Map).keys
            );
          }
        }
        
        for (final entry in messagesMap.entries) {
          final messageId = entry.key;
          
          // Skip if user deleted this message for themselves
          if (deletedMessageIds.contains(messageId)) continue;
          
          final messageData = Map<String, dynamic>.from(entry.value as Map);
          messageData['id'] = messageId;
          
          messages.add(ChatMessage.fromMap(messageData));
        }
        
        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      
      return messages;
    });
  }

  Stream<List<ChatRoom>> getUserChatsStream() {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _usersRef
        .child(currentUserId)
        .child('chats')
        .onValue
        .asyncMap((event) async {
      final chatRooms = <ChatRoom>[];
      
      if (event.snapshot.exists) {
        final userChats = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        for (final entry in userChats.entries) {
          final chatId = entry.key;
          final userChatData = Map<String, dynamic>.from(entry.value as Map);
          
          // Skip inactive chats
          if (userChatData['isActive'] != true) continue;
          
          final chatSnapshot = await _chatsRef.child(chatId).get();
          if (chatSnapshot.exists) {
            final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
            
            // Get unread count
            final participantSnapshot = await _chatParticipantsRef
                .child(chatId)
                .child(currentUserId)
                .get();
            
            int unreadCount = 0;
            if (participantSnapshot.exists) {
              final participantData = Map<String, dynamic>.from(
                participantSnapshot.value as Map
              );
              unreadCount = participantData['unreadCount'] ?? 0;
            }
            
            chatRooms.add(ChatRoom.fromMap({
              ...chatData,
              'unreadCount': unreadCount,
              'isPinned': userChatData['isPinned'] ?? false,
              'isMuted': userChatData['isMuted'] ?? false,
            }));
          }
        }
        
        // Sort by last activity and pinned status
        chatRooms.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.lastActivity.compareTo(a.lastActivity);
        });
      }
      
      return chatRooms;
    });
  }

  Stream<Map<String, bool>> getTypingIndicators(String chatId) {
    return _chatsRef.child(chatId).child('typing').onValue.map((event) {
      final typingUsers = <String, bool>{};
      
      if (event.snapshot.exists) {
        final typingData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final now = DateTime.now().millisecondsSinceEpoch;
        
        for (final entry in typingData.entries) {
          final lastTyping = entry.value as int? ?? 0;
          typingUsers[entry.key] = (now - lastTyping) < 3000;
        }
      }
      
      return typingUsers;
    });
  }

  // Typing indicators
  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) return;

      final typingRef = _chatsRef.child(chatId).child('typing').child(currentUserId);
      
      if (isTyping) {
        await typingRef.set(ServerValue.timestamp);
        typingRef.onDisconnect().remove();
      } else {
        await typingRef.remove();
      }
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }

  // Chat preferences
  Future<void> pinChat(String chatId, bool isPinned) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) return;

      await _usersRef
          .child(currentUserId)
          .child('chats')
          .child(chatId)
          .update({'isPinned': isPinned});
    } catch (e) {
      throw Exception('Failed to pin/unpin chat: $e');
    }
  }

  Future<void> muteChat(String chatId, bool isMuted) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) return;

      await _usersRef
          .child(currentUserId)
          .child('chats')
          .child(chatId)
          .update({'isMuted': isMuted});
    } catch (e) {
      throw Exception('Failed to mute/unmute chat: $e');
    }
  }

  // Search messages
  Future<List<ChatMessage>> searchMessages({
    required String chatId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final messagesSnapshot = await _messagesRef
          .child(chatId)
          .orderByChild('timestamp')
          .limitToLast(1000) // Search in recent messages
          .get();
      
      final messages = <ChatMessage>[];
      
      if (messagesSnapshot.exists) {
        final messagesMap = Map<String, dynamic>.from(messagesSnapshot.value as Map);
        final queryLower = query.toLowerCase();
        
        for (final entry in messagesMap.entries) {
          final messageData = Map<String, dynamic>.from(entry.value as Map);
          final text = (messageData['text'] as String? ?? '').toLowerCase();
          
          if (text.contains(queryLower)) {
            messageData['id'] = entry.key;
            messages.add(ChatMessage.fromMap(messageData));
          }
        }
        
        // Sort by relevance and timestamp
        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        if (messages.length > limit) {
          return messages.take(limit).toList();
        }
      }
      
      return messages;
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Cleanup and dispose
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}

// Data models
class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String type;
  final String createdBy;
  final DateTime createdAt;
  final DateTime lastActivity;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;
  final int messageCount;
  final int participantCount;
  final bool isActive;
  final String? matchId;
  final String? sharedMood;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final Map<String, dynamic>? metadata;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.lastActivity,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    this.messageCount = 0,
    this.participantCount = 0,
    this.isActive = true,
    this.matchId,
    this.sharedMood,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.metadata,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      type: map['type'] ?? 'group',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastActivity: DateTime.fromMillisecondsSinceEpoch(map['lastActivity'] ?? 0),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSender: map['lastMessageSender'],
      messageCount: map['messageCount'] ?? 0,
      participantCount: map['participantCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      matchId: map['matchId'],
      sharedMood: map['sharedMood'],
      unreadCount: map['unreadCount'] ?? 0,
      isPinned: map['isPinned'] ?? false,
      isMuted: map['isMuted'] ?? false,
      metadata: map['metadata'],
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String type;
  final DateTime timestamp;
  final bool edited;
  final DateTime? editedAt;
  final bool deleted;
  final String? replyTo;
  final String? mood;
  final List<String>? attachments;
  final Map<String, Map<String, int>>? reactions;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = 'text',
    required this.timestamp,
    this.edited = false,
    this.editedAt,
    this.deleted = false,
    this.replyTo,
    this.mood,
    this.attachments,
    this.reactions,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      edited: map['edited'] ?? false,
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
      deleted: map['deleted'] ?? false,
      replyTo: map['replyTo'],
      mood: map['mood'],
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      reactions: map['reactions'] != null
          ? Map<String, Map<String, int>>.from(
              (map['reactions'] as Map).map((k, v) =>
                  MapEntry(k.toString(), Map<String, int>.from(v as Map))))
          : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'edited': edited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'deleted': deleted,
      'replyTo': replyTo,
      'mood': mood,
      'attachments': attachments,
      'reactions': reactions,
      'metadata': metadata,
    };
  }
}

class ChatParticipant {
  final String userId;
  final String chatId;
  final DateTime joinedAt;
  final String role;
  final bool isActive;
  final DateTime? lastRead;
  final int unreadCount;

  ChatParticipant({
    required this.userId,
    required this.chatId,
    required this.joinedAt,
    this.role = 'member',
    this.isActive = true,
    this.lastRead,
    this.unreadCount = 0,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      userId: map['userId'] ?? '',
      chatId: map['chatId'] ?? '',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] ?? 0),
      role: map['role'] ?? 'member',
      isActive: map['isActive'] ?? true,
      lastRead: map['lastRead'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastRead'])
          : null,
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}