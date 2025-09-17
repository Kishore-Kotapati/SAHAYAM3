import 'package:flutter/material.dart';

class MoodOption {
  final String id;
  final String label;
  final String emoji;
  final String animatedChar;
  final Color color;
  final List<Color> gradient;
  final String description;
  final String intensity;
  final List<String> suggestions;
  final String aiPrompt;
  final String chatTheme;

  const MoodOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.animatedChar,
    required this.color,
    required this.gradient,
    required this.description,
    required this.intensity,
    required this.suggestions,
    required this.aiPrompt,
    required this.chatTheme,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'emoji': emoji,
      'animatedChar': animatedChar,
      'color': color.value,
      'colors': gradient.map((c) => c.value).toList(),
      'description': description,
      'intensity': intensity,
      'suggestions': suggestions,
      'aiPrompt': aiPrompt,
      'chatTheme': chatTheme,
    };
  }

  factory MoodOption.fromJson(Map<String, dynamic> json) {
    return MoodOption(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      emoji: json['emoji'] ?? '😐',
      animatedChar: json['animatedChar'] ?? '💭',
      color: Color(json['color'] ?? 0xFF9C27B0),
      gradient: (json['colors'] as List<dynamic>?)
          ?.map((c) => Color(c as int))
          .toList() ?? [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      description: json['description'] ?? '',
      intensity: json['intensity'] ?? 'Neutral',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      aiPrompt: json['aiPrompt'] ?? 'Default AI prompt',
      chatTheme: json['chatTheme'] ?? 'default',
    );
  }
}