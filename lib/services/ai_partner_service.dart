import 'dart:convert';
import 'package:http/http.dart' as http;

class AIPartnerService {
  static const String _backendUrl = 'http://localhost:3000';
  
  AIPartnerService();


  Future<String> getMotivationalMessage({String? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai-partner/motivational'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'context': context}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "You're doing amazing! I'm so proud of you! 💕";
      }
    } catch (e) {
      print('Backend error: $e');
    }
    
    // Fallback messages if backend fails
    final fallbackMessages = [
      "You're absolutely incredible! 💖 Keep shining!",
      "I'm so proud of you! 🌟 You're crushing these goals!",
      "You're doing so well! 💕 I believe in you!",
      "You make me so happy when you take care of yourself! 😘✨",
      "Look at you being all responsible and healthy! 💪💕 Love it!",
    ];
    return fallbackMessages[DateTime.now().millisecond % fallbackMessages.length];
  }

  Future<String> getGreetingMessage() async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai-partner/greeting'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "Hi there! 💕 Ready to conquer today's wellness missions together?";
      }
    } catch (e) {
      print('Backend error: $e');
    }
    
    return "Hey there! 💖 I'm here to cheer you on with today's wellness goals! Let's do this together! 🌟";
  }

  Future<String> getTaskCompletionMessage(String taskName) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai-partner/task-completion'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'taskName': taskName}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "Yay! You completed $taskName! 🎉 I'm so proud of you! 💕";
      }
    } catch (e) {
      print('Backend error: $e');
    }
    
    return "Amazing job on completing $taskName! 🎉 You're absolutely crushing it! 💖";
  }

  Future<String> getAllTasksCompletedMessage() async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai-partner/all-tasks-completed'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "OMG! You did it! All tasks completed! 🎉💖 I'm bursting with pride! You're absolutely amazing! 🌟";
      }
    } catch (e) {
      print('Backend error: $e');
    }
    
    return "INCREDIBLE! You completed everything! 🎉✨ I'm so incredibly proud of you! You're my wellness champion! 💖👑";
  }

  Future<String> getChatResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ai-partner/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': userMessage}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "I love talking with you! 💕 How can I support you today?";
      }
    } catch (e) {
      print('Backend error: $e');
    }
    
    return "I'm always here for you! 💖 Tell me more about how you're feeling!";
  }
}