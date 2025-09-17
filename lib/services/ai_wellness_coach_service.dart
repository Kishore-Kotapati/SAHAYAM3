import 'dart:convert';
import 'package:http/http.dart' as http;

class AIWellnessCoachService {
  static const String _backendUrl = 'http://localhost:3000';
  
  AIWellnessCoachService();

  Future<String> getWellnessAdvice(String query, {String? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/wellness-coach/advice'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'context': context,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "I'm here to support your wellness journey. What specific area would you like guidance on?";
      }
    } catch (e) {
      print('Backend error: $e');
    }
    
    return "I'm here to help with your wellness journey. Please try asking your question again, and I'll do my best to provide helpful guidance.";
  }

  Future<String> getStressManagementTips() async {
    return await getWellnessAdvice(
      "Can you provide some effective stress management techniques for students?",
      context: "User is looking for stress relief strategies"
    );
  }

  Future<String> getMindfulnessGuidance() async {
    return await getWellnessAdvice(
      "How can I practice mindfulness in my daily routine?",
      context: "User wants to incorporate mindfulness practices"
    );
  }

  Future<String> getSleepHygieneTips() async {
    return await getWellnessAdvice(
      "What are some good sleep hygiene practices for better rest?",
      context: "User is seeking better sleep quality"
    );
  }

  Future<String> getExerciseMotivation() async {
    return await getWellnessAdvice(
      "How can I stay motivated to exercise regularly?",
      context: "User needs motivation for physical activity"
    );
  }
}
