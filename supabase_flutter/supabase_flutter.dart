import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;
  
  // Get the Supabase client instance
  SupabaseClient get client => _client;
  
  // Current user getter
  User? get currentUser => _client.auth.currentUser;
  
  // Auth stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Initialize Supabase
  Future<void> initialize({
    required String url,
    required String anonKey,
    bool enableLogging = false,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: enableLogging,
      );
      _client = Supabase.instance.client;
      
      // Set up real-time subscriptions
      _setupRealtimeSubscriptions();
      
      print('Supabase initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    // Enable real-time for tables that need it
    _client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // Handle real-time message updates
          },
        )
        .subscribe();
  }

  // Authentication methods
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // User profile methods
  Future<Map<String, dynamic>> createUserProfile({
    required String userId,
    required String username,
    required String email,
    String? profilePicture,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final profileData = {
        'id': userId,
        'username': username,
        'email': email,
        'profile_picture': profilePicture,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_online': true,
        'current_mood': 'neutral',
        'last_seen': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      final response = await _client
          .from('profiles')
          .insert(profileData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('profiles')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> setUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _client
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to set online status: $e');
    }
  }

  // Mood management
  Future<void> updateUserMood(String userId, String mood) async {
    try {
      // Update user's current mood
      await _client
          .from('profiles')
          .update({
            'current_mood': mood,
            'mood_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Store mood history for analytics
      await _client.from('mood_history').insert({
        'user_id': userId,
        'mood': mood,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update mood: $e');
    }
  }

  Stream<String?> getUserMoodStream(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? data.first['current_mood'] as String? : null);
  }

  // Match management
  Future<String> createMatch({
    required String user1Id,
    required String user2Id,
    required String sharedMood,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final matchData = {
        'user1_id': user1Id,
        'user2_id': user2Id,
        'shared_mood': sharedMood,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        ...?additionalData,
      };
      
      final response = await _client
          .from('matches')
          .insert(matchData)
          .select('id')
          .single();
      
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  Future<Map<String, dynamic>?> getMatch(String matchId) async {
    try {
      final response = await _client
          .from('matches')
          .select('*, profiles!matches_user1_id_fkey(username, profile_picture), profiles!matches_user2_id_fkey(username, profile_picture)')
          .eq('id', matchId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Failed to get match: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserMatches(String userId) {
    return _client
        .from('matches')
        .stream(primaryKey: ['id'])
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('last_activity', ascending: false);
  }

  // Chat room management
  Future<String> createChatRoom({
    required String matchId,
    required List<String> participants,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final chatData = {
        'match_id': matchId,
        'participants': participants,
        'created_at': DateTime.now().toIso8601String(),
        'last_message': null,
        'last_message_time': null,
        'message_count': 0,
        ...?additionalData,
      };
      
      final response = await _client
          .from('chat_rooms')
          .insert(chatData)
          .select('id')
          .single();
      
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<Map<String, dynamic>?> getChatRoom(String chatId) async {
    try {
      final response = await _client
          .from('chat_rooms')
          .select()
          .eq('id', chatId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Failed to get chat room: $e');
    }
  }

  Future<Map<String, dynamic>?> getChatRoomByMatch(String matchId) async {
    try {
      final response = await _client
          .from('chat_rooms')
          .select()
          .eq('match_id', matchId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      throw Exception('Failed to get chat room by match: $e');
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
      final messageData = {
        'chat_id': chatId,
        'sender_id': senderId,
        'text': text,
        'type': messageType,
        'mood': mood,
        'created_at': DateTime.now().toIso8601String(),
        'edited': false,
        'metadata': metadata,
      };
      
      final response = await _client
          .from('messages')
          .insert(messageData)
          .select('id')
          .single();
      
      // Update chat room with last message info
      await _client
          .from('chat_rooms')
          .update({
            'last_message': text,
            'last_message_time': DateTime.now().toIso8601String(),
            'last_message_sender': senderId,
          })
          .eq('id', chatId);

      // Increment message count
      await _client.rpc('increment_message_count', params: {'chat_room_id': chatId});
      
      // Update match activity
      final chatRoom = await getChatRoom(chatId);
      if (chatRoom != null && chatRoom['match_id'] != null) {
        await _client
            .from('matches')
            .update({'last_activity': DateTime.now().toIso8601String()})
            .eq('id', chatRoom['match_id']);
      }
      
      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId, {int limit = 50}) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .limit(limit);
  }

  Future<List<Map<String, dynamic>>> getMessagesPaginated(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('*, profiles(username, profile_picture)')
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.reversed.toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _client
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    try {
      await _client
          .from('messages')
          .update({
            'text': newText,
            'edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // Typing indicator
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      if (isTyping) {
        await _client
            .from('typing_indicators')
            .upsert({
              'chat_id': chatId,
              'user_id': userId,
              'is_typing': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
      } else {
        await _client
            .from('typing_indicators')
            .delete()
            .eq('chat_id', chatId)
            .eq('user_id', userId);
      }
    } catch (e) {
      throw Exception('Failed to set typing status: $e');
    }
  }

  Stream<Map<String, bool>> getTypingUsers(String chatId) {
    return _client
        .from('typing_indicators')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .eq('chat_id', chatId)
        .map((data) {
          final typingUsers = <String, bool>{};
          final now = DateTime.now();
          
          for (final item in data) {
            final updatedAt = DateTime.parse(item['updated_at'] as String);
            final isRecent = now.difference(updatedAt).inSeconds < 3;
            
            if (isRecent && item['is_typing'] == true) {
              typingUsers[item['user_id'] as String] = true;
            }
          }
          
          return typingUsers;
        });
  }

  // Search and discovery
  Future<List<Map<String, dynamic>>> findUsersByMood(
    String mood, {
    String? excludeUserId,
    int limit = 10,
  }) async {
    try {
      var query = _client
          .from('profiles')
          .select()
          .eq('current_mood', mood)
          .eq('is_online', true)
          .limit(limit);

      if (excludeUserId != null) {
        query = query.neq('id', excludeUserId);
      }

      final response = await query;
      return response;
    } catch (e) {
      throw Exception('Failed to find users by mood: $e');
    }
  }

  // Analytics
  Future<Map<String, int>> getMoodAnalytics(String userId, {int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final response = await _client
          .from('mood_history')
          .select('mood')
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String());
      
      final moodCounts = <String, int>{};
      
      for (final record in response) {
        final mood = record['mood'] as String;
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
      
      return moodCounts;
    } catch (e) {
      throw Exception('Failed to get mood analytics: $e');
    }
  }

  // File upload (for profile pictures, etc.)
  Future<String> uploadFile(
    String bucketName,
    String fileName,
    List<int> fileBytes, {
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await _client.storage
          .from(bucketName)
          .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(
            upsert: true,
            metadata: metadata,
          ));
      
      // Get public URL
      final publicUrl = _client.storage
          .from(bucketName)
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String bucketName, String fileName) async {
    try {
      await _client.storage.from(bucketName).remove([fileName]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Real-time subscriptions
  RealtimeChannel subscribeToMessages(
    String chatId,
    void Function(Map<String, dynamic>) onInsert, {
    void Function(Map<String, dynamic>)? onUpdate,
    void Function(Map<String, dynamic>)? onDelete,
  }) {
    final channel = _client.channel('messages_$chatId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) => onInsert(payload.newRecord),
    );
    
    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_id',
          value: chatId,
        ),
        callback: (payload) => onUpdate(payload.newRecord),
      );
    }
    
    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_id',
          value: chatId,
        ),
        callback: (payload) => onDelete(payload.oldRecord),
      );
    }
    
    channel.subscribe();
    return channel;
  }

  // Cleanup methods
  Future<void> cleanupOldTypingIndicators() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 1));
      
      await _client
          .from('typing_indicators')
          .delete()
          .lt('updated_at', cutoffTime.toIso8601String());
    } catch (e) {
      print('Error cleaning up typing indicators: $e');
    }
  }

  Future<void> cleanupOldMoodHistory({int daysToKeep = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      await _client
          .from('mood_history')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
    } catch (e) {
      print('Error cleaning up mood history: $e');
    }
  }

  // Helper methods for presence
  void startPresenceUpdates(String userId) {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (currentUser != null) {
        setUserOnlineStatus(userId, true);
      } else {
        timer.cancel();
      }
    });
  }

  // Dispose method
  void dispose() {
    _client.dispose();
  }
}

// Data models for type safety
class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String type;
  final String? mood;
  final DateTime createdAt;
  final bool edited;
  final DateTime? editedAt;
  final Map<String, dynamic>? metadata;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.mood,
    required this.createdAt,
    this.edited = false,
    this.editedAt,
    this.metadata,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] ?? '',
      chatId: map['chat_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      mood: map['mood'],
      createdAt: DateTime.parse(map['created_at']),
      edited: map['edited'] ?? false,
      editedAt: map['edited_at'] != null ? DateTime.parse(map['edited_at']) : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'type': type,
      'mood': mood,
      'created_at': createdAt.toIso8601String(),
      'edited': edited,
      'edited_at': editedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class UserProfileModel {
  final String id;
  final String username;
  final String email;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnline;
  final String currentMood;
  final DateTime lastSeen;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
    required this.isOnline,
    required this.currentMood,
    required this.lastSeen,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profilePicture: map['profile_picture'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isOnline: map['is_online'] ?? false,
      currentMood: map['current_mood'] ?? 'neutral',
      lastSeen: DateTime.parse(map['last_seen']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_online': isOnline,
      'current_mood': currentMood,
      'last_seen': lastSeen.toIso8601String(),
    };
  }
}