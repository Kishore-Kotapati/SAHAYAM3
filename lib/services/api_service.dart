// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://your-app.vercel.app';
  // For development: 'http://localhost:3000' or 'http://10.0.2.2:3000'
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // Authentication
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    int? age,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'age': age,
          'gender': gender,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // AI Girlfriend Services
  static Future<String> getGirlfriendGreeting({
    String? timeOfDay,
    String? userName,
    int? streakDays,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai-girlfriend/greeting'),
        headers: headers,
        body: jsonEncode({
          'timeOfDay': timeOfDay ?? _getTimeOfDay(),
          'userName': userName,
          'streakDays': streakDays ?? 0,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] ? data['response'] : 'Hey beautiful! 💕';
    } catch (e) {
      return 'Hey gorgeous! Ready to start your wellness journey? 💖';
    }
  }

  static Future<String> getGirlfriendMotivation({
    String? context,
    String? mood,
    String? achievement,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai-girlfriend/motivational'),
        headers: headers,
        body: jsonEncode({
          'context': context,
          'mood': mood,
          'achievement': achievement,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] ? data['response'] : 'You\'re amazing, babe! 💖';
    } catch (e) {
      return 'Keep going, sweetheart! I\'m so proud of you! 🌟';
    }
  }

  static Future<String> getTaskCompletionMessage({
    required String taskName,
    String? difficulty,
    int? timeSpent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai-girlfriend/task-completion'),
        headers: headers,
        body: jsonEncode({
          'taskName': taskName,
          'difficulty': difficulty,
          'timeSpent': timeSpent,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] ? data['response'] : 'Great job on $taskName! 🎉';
    } catch (e) {
      return 'Amazing work, honey! 💕';
    }
  }

  static Future<String> getAllTasksCompleteMessage({
    int? totalTasks,
    int? streakDays,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai-girlfriend/all-tasks-completed'),
        headers: headers,
        body: jsonEncode({
          'totalTasks': totalTasks,
          'streakDays': streakDays,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] ? data['response'] : 'You did it all! So proud! 🎉💖';
    } catch (e) {
      return 'Incredible! All tasks done! 👑✨';
    }
  }

  static Future<String> chatWithGirlfriend({
    required String message,
    String? mood,
    String? context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai-girlfriend/chat'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'mood': mood,
          'context': context,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] ? data['response'] : 'I love talking with you! 💕';
    } catch (e) {
      return 'I\'m here for you, babe! 💖';
    }
  }

  // Wellness Coach
  static Future<String> getWellnessAdvice({
    required String query,
    String? context,
    String? urgency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/wellness-coach/advice'),
        headers: headers,
        body: jsonEncode({
          'query': query,
          'context': context,
          'urgency': urgency,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] ? data['response'] : 'I\'m here to help with your wellness journey.';
    } catch (e) {
      return 'Let me help you with that wellness question.';
    }
  }

  // Mood Support
  static Future<String> getMoodSupport({
    required String message,
    String? mood,
    int? intensity,
    String? context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mood-chat/support'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'mood': mood,
          'intensity': intensity,
          'context': context,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] ? data['response'] : 'I\'m here to support you. 💙';
    } catch (e) {
      return 'Your feelings are valid. I\'m here to listen.';
    }
  }

  // Mood Tracking
  static Future<Map<String, dynamic>> saveMoodEntry({
    required String userId,
    required String mood,
    required int scale,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mood'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'mood': mood,
          'scale': scale,
          'notes': notes,
          'tags': tags,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to save mood entry'};
    }
  }

  static Future<Map<String, dynamic>> getMoodHistory({
    required String userId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/mood/$userId?limit=$limit&offset=$offset'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch mood history'};
    }
  }

  // Task Management
  static Future<Map<String, dynamic>> completeTask({
    required String userId,
    required String taskName,
    String? category,
    String? difficulty,
    int? timeSpent,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'taskName': taskName,
          'category': category,
          'difficulty': difficulty,
          'timeSpent': timeSpent,
          'notes': notes,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to complete task'};
    }
  }

  static Future<Map<String, dynamic>> getUserTasks({
    required String userId,
    String? date,
    String? category,
    int limit = 50,
  }) async {
    try {
      String url = '$baseUrl/api/tasks/$userId?limit=$limit';
      if (date != null) url += '&date=$date';
      if (category != null) url += '&category=$category';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch tasks'};
    }
  }

  // Analytics
  static Future<Map<String, dynamic>> getUserAnalytics({
    required String userId,
    int timeframe = 30,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/analytics/$userId?timeframe=$timeframe'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch analytics'};
    }
  }

  // Profile Management
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    Map<String, dynamic>? preferences,
    List<String>? wellnessGoals,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/profile/$userId'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'preferences': preferences,
          'wellnessGoals': wellnessGoals,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/$userId'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch profile'};
    }
  }

  // Insights
  static Future<Map<String, dynamic>> getUserInsights({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/insights/$userId'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch insights'};
    }
  }

  // Utility
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'ERROR', 'message': 'Cannot reach server'};
    }
  }

  // Helper methods
  static String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }
}

// Usage Example:
class MoodSyncUsage {
  static Future<void> exampleUsage() async {
    // Register user
    final registerResult = await ApiService.register(
      fullName: 'John Doe',
      email: 'john@example.com',
      password: 'password123',
      age: 25,
      gender: 'male',
    );

    if (registerResult['success']) {
      final userId = registerResult['userId'];
      
      // Get AI girlfriend greeting
      final greeting = await ApiService.getGirlfriendGreeting(
        userName: 'John',
        streakDays: 3,
      );
      print('Greeting: $greeting');

      // Complete a task
      await ApiService.completeTask(
        userId: userId,
        taskName: 'Morning meditation',
        category: 'mental',
        timeSpent: 10,
      );

      // Get task completion message
      final taskMessage = await ApiService.getTaskCompletionMessage(
        taskName: 'Morning meditation',
        difficulty: 'easy',
        timeSpent: 10,
      );
      print('Task completion: $taskMessage');

      // Save mood
      await ApiService.saveMoodEntry(
        userId: userId,
        mood: 'happy',
        scale: 8,
        notes: 'Feeling great after meditation!',
        tags: ['meditation', 'morning'],
      );

      // Get analytics
      // Get analytics
      final analytics = await ApiService.getUserAnalytics(
        userId: userId,
        timeframe: 7, // last 7 days
      );
      
      if (analytics['success']) {
        print('Completed today: ${analytics['analytics']['completedToday']}');
        print('Streak: ${analytics['analytics']['streakDays']} days');
        print('Average mood: ${analytics['analytics']['averageMood']}/10');
      }

      // Chat with AI girlfriend
      final chatResponse = await ApiService.chatWithGirlfriend(
        message: "I'm feeling a bit stressed about work today",
        mood: 'stressed',
        context: 'work pressure',
      );
      print('AI Response: $chatResponse');

      // Get wellness advice
      final advice = await ApiService.getWellnessAdvice(
        query: "How can I manage work stress better?",
        context: "office job, long hours",
        urgency: "medium",
      );
      print('Wellness advice: $advice');
    }
  }
}