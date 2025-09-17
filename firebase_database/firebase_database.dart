import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Database references
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _chatsRef => _database.ref('chats');
  DatabaseReference get _messagesRef => _database.ref('messages');
  DatabaseReference get _matchesRef => _database.ref('matches');
  DatabaseReference get _moodsRef => _database.ref('moods');

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Initialize database with proper security rules
  Future<void> initializeDatabase() async {
    try {
      // Set database persistence
      _database.setPersistenceEnabled(true);
      _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache
      
      // Keep sync for active connections
      _database.ref('.info/connected').onValue.listen((event) {
        if (event.snapshot.value == true) {
          print('Connected to Firebase Database');
        } else {
          print('Disconnected from Firebase Database');
        }
      });
    } catch (e) {
      print('Error initializing Firebase Database: $e');
    }
  }

  // User management
  Future<void> createUser({
    required String userId,
    required String username,
    required String email,
    String? profilePicture,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _usersRef.child(userId).set({
        'id': userId,
        'username': username,
        'email': email,
        'profilePicture': profilePicture,
        'createdAt': ServerValue.timestamp,
        'lastSeen': ServerValue.timestamp,
        'isOnline': true,
        'currentMood': 'neutral',
        ...?additionalData,
      });
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _usersRef.child(userId).update({
        ...updates,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> setUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _usersRef.child(userId).update({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      });
      
      // Set up offline presence
      if (isOnline) {
        _usersRef.child(userId).child('isOnline').onDisconnect().set(false);
        _usersRef.child(userId).child('lastSeen').onDisconnect().set(ServerValue.timestamp);
      }
    } catch (e) {
      throw Exception('Failed to set online status: $e');
    }
  }

  // Mood management
  Future<void> updateUserMood(String userId, String mood) async {
    try {
      await _usersRef.child(userId).update({
        'currentMood': mood,
        'moodUpdatedAt': ServerValue.timestamp,
      });

      // Also store in moods collection for analytics
      await _moodsRef.child(userId).push().set({
        'mood': mood,
        'timestamp': ServerValue.timestamp,
        'userId': userId,
      });
    } catch (e) {
      throw Exception('Failed to update mood: $e');
    }
  }

  Stream<String?> getUserMoodStream(String userId) {
    return _usersRef.child(userId).child('currentMood').onValue.map((event) {
      return event.snapshot.value as String?;
    });
  }

  // Match management
  Future<String> createMatch({
    required String user1Id,
    required String user2Id,
    required String sharedMood,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final matchRef = _matchesRef.push();
      final matchId = matchRef.key!;
      
      final matchData = {
        'id': matchId,
        'user1Id': user1Id,
        'user2Id': user2Id,
        'sharedMood': sharedMood,
        'createdAt': ServerValue.timestamp,
        'status': 'active',
        'lastActivity': ServerValue.timestamp,
        ...?additionalData,
      };
      
      await matchRef.set(matchData);
      
      // Update users' matches
      await _usersRef.child(user1Id).child('matches').child(matchId).set(true);
      await _usersRef.child(user2Id).child('matches').child(matchId).set(true);
      
      return matchId;
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  Future<Map<String, dynamic>?> getMatch(String matchId) async {
    try {
      final snapshot = await _matchesRef.child(matchId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get match: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserMatches(String userId) {
    return _usersRef.child(userId).child('matches').onValue.asyncMap((event) async {
      final matches = <Map<String, dynamic>>[];
      
      if (event.snapshot.exists) {
        final matchIds = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        for (final matchId in matchIds.keys) {
          final matchData = await getMatch(matchId);
          if (matchData != null) {
            matches.add(matchData);
          }
        }
      }
      
      return matches;
    });
  }

  // Chat room management
  Future<String> createChatRoom({
    required String matchId,
    required List<String> participants,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final chatRef = _chatsRef.push();
      final chatId = chatRef.key!;
      
      final chatData = {
        'id': chatId,
        'matchId': matchId,
        'participants': participants,
        'createdAt': ServerValue.timestamp,
        'lastMessage': null,
        'lastMessageTime': null,
        'messageCount': 0,
        ...?additionalData,
      };
      
      await chatRef.set(chatData);
      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<Map<String, dynamic>?> getChatRoom(String chatId) async {
    try {
      final snapshot = await _chatsRef.child(chatId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get chat room: $e');
    }
  }

  // Message management
  Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? mood,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageRef = _messagesRef.child(chatId).push();
      final messageId = messageRef.key!;
      
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'type': messageType,
        'mood': mood,
        'timestamp': ServerValue.timestamp,
        'edited': false,
        'metadata': metadata,
      };
      
      // Send message
      await messageRef.set(messageData);
      
      // Update chat room with last message info
      await _chatsRef.child(chatId).update({
        'lastMessage': text,
        'lastMessageTime': ServerValue.timestamp,
        'lastMessageSender': senderId,
        'messageCount': ServerValue.increment(1),
      });
      
      // Update match activity
      final chatRoom = await getChatRoom(chatId);
      if (chatRoom != null && chatRoom['matchId'] != null) {
        await _matchesRef.child(chatRoom['matchId']).update({
          'lastActivity': ServerValue.timestamp,
        });
      }
      
      return messageId;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId, {int limit = 50}) {
    return _messagesRef
        .child(chatId)
        .orderByChild('timestamp')
        .limitToLast(limit)
        .onValue
        .map((event) {
      final messages = <Map<String, dynamic>>[];
      
      if (event.snapshot.exists) {
        final messagesMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        for (final entry in messagesMap.entries) {
          final messageData = Map<String, dynamic>.from(entry.value as Map);
          messageData['id'] = entry.key;
          messages.add(messageData);
        }
        
        // Sort by timestamp
        messages.sort((a, b) {
          final aTime = a['timestamp'] as int? ?? 0;
          final bTime = b['timestamp'] as int? ?? 0;
          return aTime.compareTo(bTime);
        });
      }
      
      return messages;
    });
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _messagesRef.child(chatId).child(messageId).remove();
      
      // Update message count
      await _chatsRef.child(chatId).update({
        'messageCount': ServerValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    try {
      await _messagesRef.child(chatId).child(messageId).update({
        'text': newText,
        'edited': true,
        'editedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // Typing indicator
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      final typingRef = _chatsRef.child(chatId).child('typing').child(userId);
      
      if (isTyping) {
        await typingRef.set(ServerValue.timestamp);
        // Auto-remove typing status after 3 seconds
        typingRef.onDisconnect().remove();
      } else {
        await typingRef.remove();
      }
    } catch (e) {
      throw Exception('Failed to set typing status: $e');
    }
  }

  Stream<Map<String, bool>> getTypingUsers(String chatId) {
    return _chatsRef.child(chatId).child('typing').onValue.map((event) {
      final typingUsers = <String, bool>{};
      
      if (event.snapshot.exists) {
        final typingData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final now = DateTime.now().millisecondsSinceEpoch;
        
        for (final entry in typingData.entries) {
          final lastTyping = entry.value as int? ?? 0;
          // Consider user typing if last update was within 3 seconds
          typingUsers[entry.key] = (now - lastTyping) < 3000;
        }
      }
      
      return typingUsers;
    });
  }

  // Search and discovery
  Future<List<Map<String, dynamic>>> findUsersByMood(String mood, {String? excludeUserId}) async {
    try {
      final snapshot = await _usersRef
          .orderByChild('currentMood')
          .equalTo(mood)
          .get();
      
      final users = <Map<String, dynamic>>[];
      
      if (snapshot.exists) {
        final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
        
        for (final entry in usersMap.entries) {
          if (excludeUserId != null && entry.key == excludeUserId) continue;
          
          final userData = Map<String, dynamic>.from(entry.value as Map);
          userData['id'] = entry.key;
          
          // Only include online users
          if (userData['isOnline'] == true) {
            users.add(userData);
          }
        }
      }
      
      return users;
    } catch (e) {
      throw Exception('Failed to find users by mood: $e');
    }
  }

  // Analytics and insights
  Future<Map<String, int>> getMoodAnalytics(String userId, {int days = 30}) async {
    try {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final startTime = endTime - (days * 24 * 60 * 60 * 1000);
      
      final snapshot = await _moodsRef
          .child(userId)
          .orderByChild('timestamp')
          .startAt(startTime)
          .endAt(endTime)
          .get();
      
      final moodCounts = <String, int>{};
      
      if (snapshot.exists) {
        final moodsMap = Map<String, dynamic>.from(snapshot.value as Map);
        
        for (final moodEntry in moodsMap.values) {
          final mood = moodEntry['mood'] as String?;
          if (mood != null) {
            moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
          }
        }
      }
      
      return moodCounts;
    } catch (e) {
      throw Exception('Failed to get mood analytics: $e');
    }
  }

  // Cleanup and maintenance
  Future<void> cleanupOldData() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      
      // Clean up old typing indicators
      final chatsSnapshot = await _chatsRef.get();
      if (chatsSnapshot.exists) {
        final chatsMap = Map<String, dynamic>.from(chatsSnapshot.value as Map);
        
        for (final chatId in chatsMap.keys) {
          final typingRef = _chatsRef.child(chatId).child('typing');
          final typingSnapshot = await typingRef.get();
          
          if (typingSnapshot.exists) {
            final typingData = Map<String, dynamic>.from(typingSnapshot.value as Map);
            
            for (final entry in typingData.entries) {
              if ((entry.value as int) < cutoffTime) {
                await typingRef.child(entry.key).remove();
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  // Dispose resources
  void dispose() {
    // Cancel any active listeners here if needed
  }
}

// Extension for easier date handling
extension TimestampExtension on int {
  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(this);
  }
}

// Helper class for message data
class ChatMessageData {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String type;
  final String? mood;
  final DateTime timestamp;
  final bool edited;
  final Map<String, dynamic>? metadata;

  ChatMessageData({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.mood,
    required this.timestamp,
    this.edited = false,
    this.metadata,
  });

  factory ChatMessageData.fromMap(Map<String, dynamic> map) {
    return ChatMessageData(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      mood: map['mood'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      edited: map['edited'] ?? false,
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
      'mood': mood,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'edited': edited,
      'metadata': metadata,
    };
  }
}