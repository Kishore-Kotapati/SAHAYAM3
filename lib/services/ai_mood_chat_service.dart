import 'dart:convert';
import 'package:http/http.dart' as http;

class AIMoodChatService {
  static const String _backendUrl = 'http://localhost:3000';
  
  AIMoodChatService();

  Future<String> getMoodSupport(String message, {String? mood, String? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/mood-chat/support'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'mood': mood,
          'context': context,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "I understand you're going through something right now. Your feelings are valid, and I'm here to listen. How can I best support you?";
      }
    } catch (e) {
      print('Backend error: $e');
    }
    
    return "I'm here to listen and support you through whatever you're feeling. Your emotions are important and valid.";
  }

  Future<String> getAnxietySupport(String userMessage) async {
    return await getMoodSupport(
      userMessage,
      mood: "anxious",
      context: "User is experiencing anxiety and needs emotional support"
    );
  }

  Future<String> getDepressionSupport(String userMessage) async {
    return await getMoodSupport(
      userMessage,
      mood: "depressed", 
      context: "User is feeling down and needs compassionate support"
    );
  }

  Future<String> getStressSupport(String userMessage) async {
    return await getMoodSupport(
      userMessage,
      mood: "stressed",
      context: "User is feeling overwhelmed and needs stress management support"
    );
  }

  Future<String> getGeneralMoodSupport(String userMessage, String currentMood) async {
    return await getMoodSupport(
      userMessage,
      mood: currentMood,
      context: "User needs emotional support and understanding"
    );
  }
}
