import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingService {
  static final _supabase = Supabase.instance.client;

  /// Find users with the same mood for matching
  static Future<List<Map<String, dynamic>>> findPotentialMatches(String currentUserMood, String currentUserId) async {
    try {
      print('Finding potential matches for mood: $currentUserMood, user: $currentUserId');
      
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('mood', currentUserMood)
          .neq('id', currentUserId)
          .eq('is_online', true)
          .order('last_seen', ascending: false)
          .limit(20)
          .timeout(const Duration(seconds: 30)); // Add timeout

      print('Found ${response.length} potential matches');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error finding matches: $e');
      rethrow; // Re-throw the error so the UI can handle it
    }
  }

  /// Create a match between two users
  static Future<String?> createMatch(String user1Id, String user2Id) async {
    try {
      print('Creating match between $user1Id and $user2Id');
      
      // Check if match already exists
      final existingMatch = await _supabase
          .from('matches')
          .select('id')
          .or('and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)')
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (existingMatch != null) {
        print('Match already exists: ${existingMatch['id']}');
        return existingMatch['id'];
      }

      // Create new match
      final response = await _supabase
          .from('matches')
          .insert({
            'user1_id': user1Id,
            'user2_id': user2Id,
            'matched_at': DateTime.now().toIso8601String(),
            'is_active': true,
          })
          .select('id')
          .single()
          .timeout(const Duration(seconds: 15));

      print('New match created: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('Error creating match: $e');
      return null;
    }
  }

  /// Get user's active matches
  static Future<List<Map<String, dynamic>>> getUserMatches(String userId) async {
    try {
      print('Getting matches for user: $userId');
      
      final response = await _supabase
          .from('matches')
          .select('''
            id,
            matched_at,
            user1_id,
            user2_id,
            user1:user1_id(id, full_name, mood, profile_image_url, last_seen),
            user2:user2_id(id, full_name, mood, profile_image_url, last_seen)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('is_active', true)
          .order('matched_at', ascending: false)
          .timeout(const Duration(seconds: 30));

      print('Found ${response.length} matches');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user matches: $e');
      return [];
    }
  }

  /// Update user online status
  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      print('Updating online status for $userId: $isOnline');
      
      await _supabase
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .timeout(const Duration(seconds: 15));

      print('Online status updated successfully');
    } catch (e) {
      print('Error updating online status: $e');
      // Don't rethrow - this is not critical for the UI
    }
  }

  /// Send a message in a match
  static Future<bool> sendMessage(String matchId, String senderId, String content) async {
    try {
      print('Sending message in match $matchId from $senderId');
      
      await _supabase
          .from('messages')
          .insert({
            'match_id': matchId,
            'sender_id': senderId,
            'content': content,
            'sent_at': DateTime.now().toIso8601String(),
            'is_read': false,
          })
          .timeout(const Duration(seconds: 15));

      print('Message sent successfully');
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Get messages for a match
  static Future<List<Map<String, dynamic>>> getMatchMessages(String matchId) async {
    try {
      print('Getting messages for match: $matchId');
      
      final response = await _supabase
          .from('messages')
          .select('''
            id,
            content,
            sent_at,
            is_read,
            sender:sender_id(id, full_name, profile_image_url)
          ''')
          .eq('match_id', matchId)
          .order('sent_at', ascending: true)
          .timeout(const Duration(seconds: 30));

      print('Found ${response.length} messages');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  /// Test Supabase connection - Add this new method for debugging
  static Future<bool> checkConnection() async {
    try {
      print('Testing Supabase connection...');
      print('User authenticated: ${_supabase.auth.currentUser != null}');
      
      // Try a simple query to test connection
      await _supabase
          .from('profiles')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 10));

      print('Supabase connection successful');
      return true;
    } catch (e) {
      print('Supabase connection failed: $e');
      return false;
    }
  }
}