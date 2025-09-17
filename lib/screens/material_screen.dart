import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  State<MaterialScreen> createState() => _EnhancedMaterialScreenState();
}

class ChatMessage {
  final String text;
  final bool isAI;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isAI, required this.timestamp});
}

class _EnhancedMaterialScreenState extends State<MaterialScreen>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _cardController;
  late AnimationController _transitionController;
  late AnimationController _characterController;
  late AnimationController _chatController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _transitionAnimation;
  late Animation<double> _characterAnimation;
  late Animation<Offset> _chatSlideAnimation;
  
  // State Management
  String selectedMood = 'stressed';
  String selectedProgram = 'Mind Reset';
  String previousProgram = 'Mind Reset';
  int currentDay = 1;
  bool showAICoach = false;
  bool showChatInterface = false;
  String aiMessage = "";
  bool isTyping = false;
  bool isTransitioning = false;
  Timer? _typingTimer;
  List<ChatMessage> chatHistory = [];
  
  // Data Storage
  Map<String, List<bool>> programProgress = {};
  late SharedPreferences prefs;
  
  // AI Messages and Chart Suggestions - Using proper JSON-like structure
  final List<Map<String, String>> aiMotivations = [
    {
      "message": "You're making incredible progress! Keep pushing forward!",
      "context": "general_motivation"
    },
    {
      "message": "Every step counts towards your wellness journey!",
      "context": "progress_encouragement"
    },
    {
      "message": "Your dedication is inspiring! Stay consistent!",
      "context": "consistency_praise"
    },
    {
      "message": "Small changes lead to big transformations!",
      "context": "mindset_shift"
    },
    {
      "message": "Mindfulness is your superpower. Use it wisely!",
      "context": "mindfulness_focus"
    },
    {
      "message": "You're on fire! Your streak is amazing!",
      "context": "streak_celebration"
    },
    {
      "message": "Quality over quantity - you're doing great!",
      "context": "quality_focus"
    },
    {
      "message": "Growth happens outside comfort zones!",
      "context": "challenge_encouragement"
    },
  ];

  final Map<String, List<Map<String, String>>> aiChartSuggestions = {
    'Mind Reset': [
      {
        "message": "Your stress levels have decreased by 40% this week! Try adding 5 more minutes to your breathing exercises.",
        "type": "trend_analysis",
        "metric": "stress_reduction"
      },
      {
        "message": "I notice you complete mental tasks faster in the morning. Consider scheduling cognitive work before 10 AM.",
        "type": "optimization",
        "metric": "productivity_timing"
      },
      {
        "message": "Your consistency in Days 1-3 is excellent! This pattern predicts 85% program completion success.",
        "type": "prediction",
        "metric": "completion_probability"
      },
      {
        "message": "Combining social connection with movement shows 23% better mood improvement in your data.",
        "type": "correlation_insight",
        "metric": "mood_improvement"
      }
    ],
    'Fitness Journey': [
      {
        "message": "Your strength gains are following an optimal trajectory! You've improved by 15% this week.",
        "type": "trend_analysis",
        "metric": "strength_improvement"
      },
      {
        "message": "I recommend adding 2 more rest days based on your recovery patterns from the data.",
        "type": "optimization",
        "metric": "recovery_optimization"
      },
      {
        "message": "Your cardio performance peaks on Days 2 and 4. Let's leverage this pattern for better results.",
        "type": "pattern_recognition",
        "metric": "performance_timing"
      },
      {
        "message": "Your HIIT sessions burn 35% more calories than steady cardio. Focus more on interval training!",
        "type": "comparison_analysis",
        "metric": "calorie_efficiency"
      }
    ],
    'Nutrition Mastery': [
      {
        "message": "Your hydration levels directly correlate with 90% of your energy improvements!",
        "type": "correlation_insight",
        "metric": "energy_hydration"
      },
      {
        "message": "I see a 25% better nutrient absorption when you follow the meal timing protocol.",
        "type": "optimization",
        "metric": "nutrient_timing"
      },
      {
        "message": "Your fiber intake improvements have reduced inflammation markers significantly!",
        "type": "health_impact",
        "metric": "inflammation_reduction"
      },
      {
        "message": "The rainbow plate approach has increased your micronutrient variety by 300%!",
        "type": "variety_analysis",
        "metric": "nutrient_diversity"
      }
    ],
    'Sleep Optimization': [
      {
        "message": "Your sleep quality improved by 60% after implementing the evening routine!",
        "type": "improvement_tracking",
        "metric": "sleep_quality"
      },
      {
        "message": "I notice 40 minutes longer deep sleep when you avoid screens before bed.",
        "type": "behavioral_correlation",
        "metric": "deep_sleep_duration"
      },
      {
        "message": "Your morning light exposure perfectly aligns with your circadian rhythm improvements.",
        "type": "rhythm_analysis",
        "metric": "circadian_alignment"
      },
      {
        "message": "Temperature regulation techniques have increased your REM sleep by 25%!",
        "type": "technique_effectiveness",
        "metric": "rem_sleep"
      }
    ],
    'Stress Management': [
      {
        "message": "Your cortisol levels show a 45% reduction since starting the breathing techniques!",
        "type": "biomarker_improvement",
        "metric": "cortisol_reduction"
      },
      {
        "message": "Nature therapy sessions correlate with your highest mood improvement scores.",
        "type": "activity_correlation",
        "metric": "mood_enhancement"
      },
      {
        "message": "Your stress resilience has increased by 30% through consistent mindfulness practice.",
        "type": "resilience_building",
        "metric": "stress_resistance"
      },
      {
        "message": "Social support activities predict your best mental health days with 88% accuracy!",
        "type": "predictive_insight",
        "metric": "mental_health_prediction"
      }
    ],
  };

  // Welcome messages for each program
  final Map<String, List<String>> welcomeMessages = {
    'Mind Reset': [
      "Welcome to your Mental Reset journey! I'm here to guide you through mindfulness and stress relief.",
      "Ready to reset your mind? Let's start with breathing exercises and mindful practices.",
      "Your mental wellness journey begins now. I'll help you build resilience and clarity."
    ],
    'Fitness Journey': [
      "Welcome to your Fitness Journey! Let's build strength and endurance together.",
      "Ready to transform your physical health? I'm here to guide your fitness progress.",
      "Your fitness transformation starts now! Let's create sustainable healthy habits."
    ],
    'Nutrition Mastery': [
      "Welcome to Nutrition Mastery! Let's transform your relationship with food.",
      "Ready to master nutrition? I'll guide you through optimal eating strategies.",
      "Your nutrition journey begins! Let's build healthy eating habits that last."
    ],
    'Sleep Optimization': [
      "Welcome to Sleep Optimization! Let's master the art of restorative sleep.",
      "Ready to optimize your sleep? I'll guide you to better rest and recovery.",
      "Your sleep transformation starts here! Let's build perfect sleep habits."
    ],
    'Stress Management': [
      "Welcome to Stress Management! Let's build resilience and emotional balance.",
      "Ready to master stress? I'll guide you through proven coping strategies.",
      "Your stress management journey begins! Let's build lasting emotional strength."
    ],
  };

  // Transition messages
  final Map<String, String> transitionMessages = {
    'Mind Reset': "Excellent choice! Mental wellness is the foundation of all health.",
    'Fitness Journey': "Great switch! Physical fitness will amplify your wellness results.",
    'Nutrition Mastery': "Perfect timing! Nutrition is key to sustaining your progress.",
    'Sleep Optimization': "Smart move! Quality sleep enhances everything else you do.",
    'Stress Management': "Wise decision! Stress management skills benefit every area of life.",
  };

  // Program Data Structure with animated characters
  final Map<String, Map<String, dynamic>> wellnessPrograms = {
    'Mind Reset': {
      'character': '🧘‍♀️',
      'background': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      'color': [Color(0xFF6A11CB), Color(0xFF2575FC)],
      'description': 'Reset your mental state with mindfulness',
      'days': [
        {
          'title': 'Day 1 • Breath Foundation',
          'desc': '5x box-breath cycles (4-4-6)',
          'type': 'breathing',
          'character': '🫁',
          'duration': '10 min',
          'calories': 5,
          'details': 'Focus on slow, controlled breathing to activate parasympathetic nervous system',
          'nutrients': {'Oxygen': 'Enhanced', 'CO2': 'Balanced'},
        },
        {
          'title': 'Day 2 • Movement Therapy',
          'desc': '10-minute brisk walk + stretch',
          'type': 'exercise',
          'character': '🚶‍♀️',
          'duration': '20 min',
          'calories': 80,
          'details': 'Light cardio increases endorphins and reduces cortisol levels',
          'nutrients': {'Endorphins': 'Boost', 'Serotonin': 'Increase'},
        },
        {
          'title': 'Day 3 • Cognitive Cleanse',
          'desc': 'Write 3 worries + 3 wins',
          'type': 'mental',
          'character': '✍️',
          'duration': '15 min',
          'calories': 10,
          'details': 'Journaling helps process emotions and gain perspective',
          'nutrients': {'Mental Clarity': 'Enhanced', 'Stress': 'Reduced'},
        },
        {
          'title': 'Day 4 • Social Connection',
          'desc': 'Call a friend for 5 minutes',
          'type': 'social',
          'character': '📞',
          'duration': '5 min',
          'calories': 3,
          'details': 'Human connection releases oxytocin and reduces isolation',
          'nutrients': {'Oxytocin': 'Release', 'Dopamine': 'Boost'},
        },
        {
          'title': 'Day 5 • Digital Detox',
          'desc': 'No screens 30min before bed',
          'type': 'lifestyle',
          'character': '📵',
          'duration': '30 min',
          'calories': 0,
          'details': 'Reduces blue light exposure for better melatonin production',
          'nutrients': {'Melatonin': 'Natural', 'Sleep Quality': 'Improved'},
        },
        {
          'title': 'Day 6 • Nutrition Reset',
          'desc': 'Hydrate + home-cooked meal',
          'type': 'nutrition',
          'character': '🥗',
          'duration': '45 min',
          'calories': 350,
          'details': 'Proper hydration and nutrition support brain function',
          'nutrients': {'Water': '2L', 'Complex Carbs': '45g', 'Protein': '25g'},
        },
        {
          'title': 'Day 7 • Reflection & Growth',
          'desc': 'Compare Day 1 vs Today',
          'type': 'reflection',
          'character': '🔄',
          'duration': '20 min',
          'calories': 5,
          'details': 'Self-assessment builds self-awareness and motivation',
          'nutrients': {'Self-Awareness': 'Enhanced', 'Motivation': 'Renewed'},
        },
      ]
    },
    'Fitness Journey': {
      'character': '💪',
      'background': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
      'color': [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
      'description': 'Build strength and endurance systematically',
      'days': [
        {
          'title': 'Day 1 • Foundation Strength',
          'desc': '20 Push-ups + 30 Squats + 1min Plank',
          'type': 'strength',
          'character': '🏋️‍♀️',
          'duration': '25 min',
          'calories': 150,
          'details': 'Build core strength with compound movements',
          'nutrients': {'Protein Need': '20g', 'Water': '500ml', 'Recovery Time': '24h'},
        },
        {
          'title': 'Day 2 • Cardio Blast',
          'desc': '30min brisk walk + stairs',
          'type': 'cardio',
          'character': '🏃‍♀️',
          'duration': '35 min',
          'calories': 280,
          'details': 'Improve cardiovascular health and endurance',
          'nutrients': {'Electrolytes': 'Essential', 'Carbs': '30g', 'Water': '750ml'},
        },
        {
          'title': 'Day 3 • Flexibility Flow',
          'desc': '20min yoga + stretching',
          'type': 'flexibility',
          'character': '🤸‍♀️',
          'duration': '20 min',
          'calories': 80,
          'details': 'Improve range of motion and prevent injuries',
          'nutrients': {'Magnesium': '400mg', 'Omega-3': '1g', 'Water': '400ml'},
        },
        {
          'title': 'Day 4 • HIIT Power',
          'desc': '4x (30sec work + 30sec rest)',
          'type': 'hiit',
          'character': '⚡',
          'duration': '20 min',
          'calories': 220,
          'details': 'High-intensity intervals boost metabolism',
          'nutrients': {'BCAAs': '5g', 'Fast Carbs': '15g', 'Water': '600ml'},
        },
        {
          'title': 'Day 5 • Active Recovery',
          'desc': 'Light walk + gentle stretching',
          'type': 'recovery',
          'character': '🧘‍♂️',
          'duration': '30 min',
          'calories': 100,
          'details': 'Promote muscle recovery and reduce soreness',
          'nutrients': {'Protein': '15g', 'Anti-inflammatories': 'Natural', 'Water': '500ml'},
        },
        {
          'title': 'Day 6 • Strength Circuit',
          'desc': '3 sets: Lunges, Push-ups, Burpees',
          'type': 'circuit',
          'character': '🔥',
          'duration': '40 min',
          'calories': 320,
          'details': 'Full-body circuit for maximum calorie burn',
          'nutrients': {'Protein': '25g', 'Complex Carbs': '40g', 'Water': '800ml'},
        },
        {
          'title': 'Day 7 • Assessment & Planning',
          'desc': 'Fitness test + next week plan',
          'type': 'assessment',
          'character': '📊',
          'duration': '30 min',
          'calories': 50,
          'details': 'Measure progress and set new goals',
          'nutrients': {'Recovery': 'Priority', 'Hydration': 'Key', 'Rest': '8h sleep'},
        },
      ]
    },
    'Nutrition Mastery': {
      'character': '👨‍🍳',
      'background': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
      'color': [Color(0xFF11998E), Color(0xFF38EF7D)],
      'description': 'Transform your relationship with food',
      'days': [
        {
          'title': 'Day 1 • Hydration Foundation',
          'desc': '3L water + herbal teas',
          'type': 'hydration',
          'character': '💧',
          'duration': 'All day',
          'calories': 0,
          'details': 'Establish proper hydration for optimal metabolism',
          'nutrients': {'Water': '3L', 'Electrolytes': 'Balanced', 'Antioxidants': 'High'},
        },
        {
          'title': 'Day 2 • Protein Power',
          'desc': 'High-protein meals (1.2g/kg body weight)',
          'type': 'macros',
          'character': '🥩',
          'duration': '3 meals',
          'calories': 1200,
          'details': 'Optimize protein intake for muscle maintenance and satiety',
          'nutrients': {'Protein': '84g', 'Leucine': '2.5g', 'B-Vitamins': 'Complete'},
        },
        {
          'title': 'Day 3 • Fiber Focus',
          'desc': '35g fiber from whole foods',
          'type': 'fiber',
          'character': '🌾',
          'duration': '5 meals',
          'calories': 1400,
          'details': 'Support digestive health and blood sugar control',
          'nutrients': {'Fiber': '35g', 'Prebiotics': 'Rich', 'Minerals': 'Diverse'},
        },
        {
          'title': 'Day 4 • Healthy Fats',
          'desc': 'Omega-3 rich foods + nuts',
          'type': 'fats',
          'character': '🥑',
          'duration': '4 meals',
          'calories': 1300,
          'details': 'Support brain health and hormone production',
          'nutrients': {'Omega-3': '2g', 'Vitamin E': '15mg', 'Monounsaturated': '25g'},
        },
        {
          'title': 'Day 5 • Micronutrient Boost',
          'desc': 'Rainbow plate + supplements',
          'type': 'micros',
          'character': '🌈',
          'duration': '3 meals',
          'calories': 1250,
          'details': 'Maximize vitamin and mineral intake',
          'nutrients': {'Vitamin C': '90mg', 'Iron': '18mg', 'Calcium': '1000mg'},
        },
        {
          'title': 'Day 6 • Meal Timing',
          'desc': 'Intermittent fasting (16:8)',
          'type': 'timing',
          'character': '⏰',
          'duration': '8h eating',
          'calories': 1200,
          'details': 'Optimize metabolic health through strategic eating windows',
          'nutrients': {'Autophagy': 'Activated', 'Insulin': 'Optimized', 'Growth Hormone': 'Boosted'},
        },
        {
          'title': 'Day 7 • Integration',
          'desc': 'Balanced day with all principles',
          'type': 'integration',
          'character': '⚖️',
          'duration': 'Full day',
          'calories': 1350,
          'details': 'Combine all nutrition strategies learned',
          'nutrients': {'Balance': 'Achieved', 'Sustainability': 'Key', 'Energy': 'Stable'},
        },
      ]
    },
    'Sleep Optimization': {
      'character': '😴',
      'background': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800',
      'color': [Color(0xFF667eea), Color(0xFF764ba2)],
      'description': 'Master the art of restorative sleep',
      'days': [
        {
          'title': 'Day 1 • Sleep Hygiene Basics',
          'desc': 'Cool room (65-68°F) + blackout',
          'type': 'environment',
          'character': '🌙',
          'duration': '8 hours',
          'calories': 0,
          'details': 'Create optimal sleep environment for deep rest',
          'nutrients': {'Melatonin': 'Natural', 'Growth Hormone': 'Peak', 'Cortisol': 'Low'},
        },
        {
          'title': 'Day 2 • Evening Routine',
          'desc': '1h wind-down ritual',
          'type': 'routine',
          'character': '🛁',
          'duration': '60 min',
          'calories': 15,
          'details': 'Establish consistent pre-sleep routine',
          'nutrients': {'Magnesium': '400mg', 'L-theanine': '200mg', 'Chamomile': '1 cup'},
        },
        {
          'title': 'Day 3 • Blue Light Control',
          'desc': 'No screens 2h before bed',
          'type': 'light',
          'character': '🔵',
          'duration': '2 hours',
          'calories': 0,
          'details': 'Reduce blue light exposure for natural melatonin',
          'nutrients': {'Melatonin': 'Optimized', 'Circadian Rhythm': 'Aligned'},
        },
        {
          'title': 'Day 4 • Morning Light',
          'desc': '20min sunlight within 1h of waking',
          'type': 'circadian',
          'character': '☀️',
          'duration': '20 min',
          'calories': 0,
          'details': 'Reset circadian clock with morning light exposure',
          'nutrients': {'Vitamin D': 'Synthesis', 'Serotonin': 'Boosted', 'Alertness': 'Enhanced'},
        },
        {
          'title': 'Day 5 • Stress Reduction',
          'desc': '10min meditation before bed',
          'type': 'relaxation',
          'character': '🧘',
          'duration': '10 min',
          'calories': 5,
          'details': 'Calm the mind for deeper sleep',
          'nutrients': {'GABA': 'Increased', 'Stress Hormones': 'Reduced'},
        },
        {
          'title': 'Day 6 • Temperature Regulation',
          'desc': 'Cool shower + breathwork',
          'type': 'thermoregulation',
          'character': '🚿',
          'duration': '15 min',
          'calories': 20,
          'details': 'Lower core body temperature for sleep onset',
          'nutrients': {'Brown Fat': 'Activated', 'Metabolism': 'Boosted'},
        },
        {
          'title': 'Day 7 • Sleep Tracking',
          'desc': 'Monitor and optimize',
          'type': 'tracking',
          'character': '📱',
          'duration': 'All night',
          'calories': 0,
          'details': 'Use data to refine sleep strategy',
          'nutrients': {'REM': 'Optimized', 'Deep Sleep': 'Maximized', 'Recovery': 'Complete'},
        },
      ]
    },
    'Stress Management': {
      'character': '🧘‍♀️',
      'background': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=800',
      'color': [Color(0xFFffecd2), Color(0xFFfcb69f)],
      'description': 'Build resilience and emotional balance',
      'days': [
        {
          'title': 'Day 1 • Breath Mastery',
          'desc': '4-7-8 breathing technique',
          'type': 'breathing',
          'character': '🫁',
          'duration': '15 min',
          'calories': 8,
          'details': 'Activate parasympathetic nervous system',
          'nutrients': {'Oxygen': 'Optimized', 'Cortisol': 'Reduced', 'GABA': 'Increased'},
        },
        {
          'title': 'Day 2 • Progressive Relaxation',
          'desc': 'Full body tension release',
          'type': 'relaxation',
          'character': '🤲',
          'duration': '20 min',
          'calories': 10,
          'details': 'Release physical tension stored in muscles',
          'nutrients': {'Muscle Recovery': 'Enhanced', 'Circulation': 'Improved'},
        },
        {
          'title': 'Day 3 • Mindfulness Practice',
          'desc': '20min guided meditation',
          'type': 'mindfulness',
          'character': '🧘‍♂️',
          'duration': '20 min',
          'calories': 5,
          'details': 'Develop present-moment awareness',
          'nutrients': {'Focus': 'Sharpened', 'Anxiety': 'Reduced', 'Clarity': 'Enhanced'},
        },
        {
          'title': 'Day 4 • Nature Therapy',
          'desc': '30min outdoor mindful walk',
          'type': 'nature',
          'character': '🌳',
          'duration': '30 min',
          'calories': 120,
          'details': 'Forest bathing reduces stress hormones',
          'nutrients': {'Phytoncides': 'Absorbed', 'Vitamin D': 'Synthesized', 'Mood': 'Lifted'},
        },
        {
          'title': 'Day 5 • Gratitude Practice',
          'desc': 'Write 5 things you\'re grateful for',
          'type': 'gratitude',
          'character': '🙏',
          'duration': '10 min',
          'calories': 3,
          'details': 'Rewire brain for positive thinking',
          'nutrients': {'Dopamine': 'Released', 'Neural Pathways': 'Strengthened'},
        },
        {
          'title': 'Day 6 • Social Support',
          'desc': 'Connect with loved ones',
          'type': 'social',
          'character': '🤗',
          'duration': '30 min',
          'calories': 10,
          'details': 'Strengthen social bonds for emotional support',
          'nutrients': {'Oxytocin': 'Boosted', 'Belonging': 'Enhanced', 'Resilience': 'Built'},
        },
        {
          'title': 'Day 7 • Integration Ritual',
          'desc': 'Create personal stress-relief ritual',
          'type': 'ritual',
          'character': '🕯️',
          'duration': '25 min',
          'calories': 15,
          'details': 'Establish personalized coping strategy',
          'nutrients': {'Self-Efficacy': 'Increased', 'Confidence': 'Built', 'Tools': 'Internalized'},
        },
      ]
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProgress();
    
    // Auto-show AI coach after 2 seconds
    Timer(const Duration(seconds: 2), () {
      _showAICoach();
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _chatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_rotationController);
    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(_cardController);

    _transitionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOutCubic),
    );

    _characterAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _characterController, curve: Curves.easeInOut),
    );

    _chatSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _chatController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _cardController.dispose();
    _transitionController.dispose();
    _characterController.dispose();
    _chatController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      for (String program in wellnessPrograms.keys) {
        programProgress[program] = List.generate(
          wellnessPrograms[program]!['days'].length,
          (i) => prefs.getBool("${program}_step_$i") ?? false,
        );
      }
    });
  }

  Future<void> _toggleComplete(int index) async {
    setState(() {
      programProgress[selectedProgram]![index] = !programProgress[selectedProgram]![index];
    });
    await prefs.setBool("${selectedProgram}_step_$index", programProgress[selectedProgram]![index]);
    
    if (programProgress[selectedProgram]![index]) {
      _showCompletionEffect();
      _triggerAIMotivation();
    }
  }

  void _showCompletionEffect() {
    HapticFeedback.lightImpact();
    // Add particle effect or other visual feedback
  }

  Future<void> _showAICoach() async {
    setState(() {
      showAICoach = true;
    });
    await _generateWelcomeMessage();
  }

  Future<void> _generateWelcomeMessage() async {
    setState(() {
      isTyping = true;
      aiMessage = "";
    });

    final completionPercentage = _getCompletionPercentage();
    
    // Use local welcome messages instead of API
    final welcomeOptions = welcomeMessages[selectedProgram]!;
    final selectedWelcome = welcomeOptions[Random().nextInt(welcomeOptions.length)];
    
    String personalizedMessage = selectedWelcome;
    if (completionPercentage > 0) {
      personalizedMessage += " You're already ${completionPercentage}% complete!";
    }
    
    _typeAIMessage(personalizedMessage);
  }

  void _typeAIMessage(String message) {
    setState(() {
      aiMessage = "";
      isTyping = true;
    });
    
    int index = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < message.length && mounted) {
        setState(() {
          aiMessage += message[index];
        });
        index++;
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            isTyping = false;
          });
        }
      }
    });
  }

  Future<void> _triggerAIMotivation() async {
    setState(() {
      isTyping = true;
      aiMessage = "";
    });

    final completedSteps = programProgress[selectedProgram]?.where((done) => done).length ?? 0;
    final totalSteps = wellnessPrograms[selectedProgram]!['days'].length;
    final completionPercentage = _getCompletionPercentage();
    
    // Use local motivation messages
    final motivationData = aiMotivations[Random().nextInt(aiMotivations.length)];
    String personalizedMessage = motivationData["message"]!;
    
    // Add completion context
    if (completionPercentage > 75) {
      personalizedMessage += " You're almost at the finish line!";
    } else if (completionPercentage > 50) {
      personalizedMessage += " You're over halfway there!";
    } else if (completionPercentage > 25) {
      personalizedMessage += " Great momentum building!";
    }
    
    _typeAIMessage(personalizedMessage);
  }

  void _triggerProgramTransition(String newProgram) {
    if (newProgram == selectedProgram) return;

    setState(() {
      previousProgram = selectedProgram;
      isTransitioning = true;
    });

    _transitionController.forward().then((_) {
      setState(() {
        selectedProgram = newProgram;
      });
      
      Timer(const Duration(milliseconds: 300), () {
        _transitionController.reverse().then((_) {
          setState(() {
            isTransitioning = false;
          });
        });
      });
    });

    // AI message for transition using local messages
    Timer(const Duration(milliseconds: 800), () {
      _generateTransitionMessage(newProgram);
    });
  }

  void _showChatInterface() {
    setState(() {
      showChatInterface = true;
    });
    _chatController.forward();
    
    // Add initial AI-generated chart suggestion
    if (chatHistory.isEmpty) {
      Timer(const Duration(milliseconds: 500), () {
        _generateInitialChatSuggestion();
      });
    }
  }

  Future<void> _generateInitialChatSuggestion() async {
    final suggestions = aiChartSuggestions[selectedProgram]!;
    final randomSuggestion = suggestions[Random().nextInt(suggestions.length)];
    
    final completionPercentage = _getCompletionPercentage();
    String contextualMessage = randomSuggestion["message"]!;
    
    // Add personal context
    if (completionPercentage == 0) {
      contextualMessage = "I'm analyzing your ${selectedProgram.toLowerCase()} program data. " + contextualMessage;
    }
    
    setState(() {
      chatHistory.add(ChatMessage(
        text: contextualMessage,
        isAI: true,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _generateTransitionMessage(String toProgram) async {
    final transitionMessage = transitionMessages[toProgram] ?? 
        "Great choice switching to ${toProgram.toLowerCase()}! This will complement your wellness journey perfectly.";
    
    _typeAIMessage(transitionMessage);
  }

  void _hideChatInterface() {
    _chatController.reverse().then((_) {
      setState(() {
        showChatInterface = false;
      });
    });
  }

  int _getCompletionPercentage() {
    if (!programProgress.containsKey(selectedProgram)) return 0;
    final completed = programProgress[selectedProgram]!;
    final completedCount = completed.where((done) => done).length;
    return ((completedCount / completed.length) * 100).round();
  }

  List<FlSpot> get chartData {
    if (!programProgress.containsKey(selectedProgram)) {
      return [FlSpot(1, 0)];
    }
    
    double progress = 0;
    List<FlSpot> points = [];
    final completed = programProgress[selectedProgram]!;
    
    for (int i = 0; i < completed.length; i++) {
      if (completed[i]) progress += (100 / completed.length);
      points.add(FlSpot((i + 1).toDouble(), progress));
    }
    
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildBackdropFilter(),
          if (isTransitioning) _buildTransitionOverlay(),
          SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildProgramSelector(),
                const SizedBox(height: 12),
                _buildProgressChart(),
                const SizedBox(height: 12),
                _buildDaysList(),
              ],
            ),
          ),
          if (showAICoach && !showChatInterface) _buildAICoach(),
          if (showChatInterface) _buildChatInterface(),
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        "Wellness Roadmap",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.1),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: wellnessPrograms[selectedProgram]!['color'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_rotationAnimation.value / 4),
            ),
          ),
          child: Stack(
            children: [
              // Background Image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(wellnessPrograms[selectedProgram]!['background']),
                    fit: BoxFit.cover,
                    opacity: 0.3,
                  ),
                ),
              ),
              // Animated particles
              ...List.generate(15, (index) => _buildParticle(index)),
              // Floating character
              _buildFloatingCharacter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCharacter() {
    return AnimatedBuilder(
      animation: _characterAnimation,
      builder: (context, child) {
        return Positioned(
          top: 150 + sin(_characterController.value * 2 * pi) * 20,
          right: 30 + cos(_characterController.value * 2 * pi) * 15,
          child: Transform.scale(
            scale: _characterAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(
                wellnessPrograms[selectedProgram]!['character'],
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransitionOverlay() {
    return AnimatedBuilder(
      animation: _transitionAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.7 * _transitionAnimation.value),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 - _transitionAnimation.value * 0.5,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          wellnessPrograms[previousProgram]!['character'],
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Transform.rotate(
                      angle: _transitionAnimation.value * 2 * pi,
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Transform.scale(
                      scale: _transitionAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          wellnessPrograms[selectedProgram]!['character'],
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  "Transitioning to $selectedProgram",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final offset = Offset(
          sin(_particleController.value * 2 * pi + index) * 100 + MediaQuery.of(context).size.width / 2,
          cos(_particleController.value * 2 * pi + index * 0.5) * 150 + MediaQuery.of(context).size.height / 2,
        );
        
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackdropFilter() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black.withOpacity(0.1),
      ),
    );
  }

  Widget _buildProgramSelector() {
  return Container(
    height: 140,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: wellnessPrograms.keys.length,
      itemBuilder: (context, index) {
        final programKey = wellnessPrograms.keys.elementAt(index);
        final program = wellnessPrograms[programKey]!;
        final isSelected = selectedProgram == programKey;
        
        return GestureDetector(
          onTap: () {
            _triggerProgramTransition(programKey);
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * 0.35,
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: program['color'])
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? program['color'][0].withOpacity(0.4)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _characterController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected ? 1.0 + sin(_characterController.value * 2 * pi) * 0.1 : 1.0,
                        child: Text(
                          program['character'],
                          style: const TextStyle(fontSize: 28),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      programKey,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      program['description'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildProgressChart() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      constraints: const BoxConstraints(minHeight: 140, maxHeight: 160),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Progress Analytics",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "${_getCompletionPercentage()}% Complete",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showChatInterface,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        backgroundColor: Colors.transparent,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "D${val.toInt()}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (val, meta) => Text(
                                "${val.toInt()}%",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: true,
                            color: Colors.cyanAccent,
                            barWidth: 4,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: Colors.cyanAccent,
                                ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.cyanAccent.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            shadow: Shadow(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysList() {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: wellnessPrograms[selectedProgram]!['days'].length,
        itemBuilder: (context, index) {
          final day = wellnessPrograms[selectedProgram]!['days'][index];
          final isCompleted = programProgress[selectedProgram]?[index] ?? false;
          
          return AnimatedBuilder(
            animation: _cardAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _cardAnimation.value) * 50 * (index + 1)),
                child: Opacity(
                  opacity: _cardAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: isCompleted
                                  ? [
                                      Colors.green.withOpacity(0.3),
                                      Colors.green.withOpacity(0.1),
                                    ]
                                  : [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isCompleted
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        day['character'],
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            day['title'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            day['desc'],
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: isCompleted ? 1.0 : _pulseAnimation.value,
                                          child: GestureDetector(
                                            onTap: () => _toggleComplete(index),
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: isCompleted
                                                    ? Colors.green
                                                    : Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.5),
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isCompleted
                                                        ? Colors.green.withOpacity(0.4)
                                                        : Colors.white.withOpacity(0.2),
                                                    blurRadius: 10,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                isCompleted
                                                    ? Icons.check
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day['details'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 12),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            _buildInfoChip(
                                              Icons.timer,
                                              day['duration'],
                                              Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            _buildInfoChip(
                                              Icons.local_fire_department,
                                              "${day['calories']} cal",
                                              Colors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            _buildInfoChip(
                                              Icons.category,
                                              day['type'],
                                              Colors.purple,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (day['nutrients'] != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          "Key Benefits:",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context).size.height * 0.1,
                                          ),
                                          child: SingleChildScrollView(
                                            child: Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: (day['nutrients'] as Map<String, String>)
                                                  .entries
                                                  .map((entry) => Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: Colors.white.withOpacity(0.2),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          "${entry.key}: ${entry.value}",
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(0.8),
                                                            fontSize: 10,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICoach() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Text("🤖", style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "AI Wellness Coach",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showAICoach = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        aiMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (isTyping)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _showChatInterface,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              "Chat",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _triggerAIMotivation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              "Motivate",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return SlideTransition(
      position: _chatSlideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        margin: const EdgeInsets.only(top: 100),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Text("🤖", style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI Wellness Coach",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Analyzing your ${selectedProgram} data",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _hideChatInterface,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Chat Messages
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chatHistory.length,
                      itemBuilder: (context, index) {
                        final message = chatHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.isAI) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text("🤖", style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: message.isAI 
                                        ? Colors.purple.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              if (!message.isAI) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Quick Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Quick Insights",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _addAISuggestion("trend"),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.trending_up, color: Colors.white, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        "Trends",
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _addAISuggestion("optimization"),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.tune, color: Colors.white, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        "Optimize",
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _addAISuggestion("prediction"),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.psychology, color: Colors.white, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        "Predict",
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        children: [
          if (!showAICoach && !showChatInterface)
            FloatingActionButton(
              heroTag: "ai_coach",
              onPressed: _showAICoach,
              backgroundColor: Colors.purple.withOpacity(0.8),
              child: const Text("🤖", style: TextStyle(fontSize: 24)),
            ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: () {
              _cardController.reset();
              _cardController.forward();
              _triggerAIMotivation();
              HapticFeedback.mediumImpact();
            },
            backgroundColor: wellnessPrograms[selectedProgram]!['color'][0].withOpacity(0.8),
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _addAISuggestion(String type) async {
    // Add loading message
    setState(() {
      chatHistory.add(ChatMessage(
        text: "Analyzing your ${selectedProgram.toLowerCase()} data...",
        isAI: true,
        timestamp: DateTime.now(),
      ));
    });

    final completedSteps = programProgress[selectedProgram]?.where((done) => done).length ?? 0;
    final totalSteps = wellnessPrograms[selectedProgram]!['days'].length;
    final completionPercentage = _getCompletionPercentage();
    
    // Use local suggestion data with enhanced personalization
    final suggestions = aiChartSuggestions[selectedProgram]!;
    Map<String, String> selectedSuggestion;
    
    switch (type) {
      case "trend":
        selectedSuggestion = suggestions.firstWhere(
          (s) => s["type"] == "trend_analysis",
          orElse: () => suggestions[0],
        );
        break;
      case "optimization":
        selectedSuggestion = suggestions.firstWhere(
          (s) => s["type"] == "optimization",
          orElse: () => suggestions[1],
        );
        break;
      case "prediction":
        selectedSuggestion = suggestions.firstWhere(
          (s) => s["type"] == "prediction" || s["type"] == "predictive_insight",
          orElse: () => suggestions[2],
        );
        break;
      default:
        selectedSuggestion = suggestions[Random().nextInt(suggestions.length)];
    }
    
    // Remove loading message and add personalized response
    setState(() {
      chatHistory.removeLast();
      
      String personalizedMessage = selectedSuggestion["message"]!;
      
      // Add completion context
      if (completionPercentage > 0) {
        if (type == "trend") {
          personalizedMessage += " Your current ${completionPercentage}% completion rate suggests strong commitment!";
        } else if (type == "optimization") {
          personalizedMessage += " With ${completionPercentage}% complete, you're ready for advanced techniques.";
        } else if (type == "prediction") {
          personalizedMessage += " Based on your ${completionPercentage}% progress, success probability is high!";
        }
      }
      
      chatHistory.add(ChatMessage(
        text: personalizedMessage,
        isAI: true,
        timestamp: DateTime.now(),
      ));
    });
  }

  // Enhanced local AI response generator
  String _generateLocalAIResponse(String context, String programType, int completionPercentage) {
    final responses = {
      'welcome': [
        "Welcome to your personalized wellness journey! I'm analyzing your progress patterns.",
        "Great to see you here! Let's optimize your wellness path together.",
        "Your wellness data looks promising! I'm here to guide your next steps.",
      ],
      'motivation': [
        "Your consistency is building incredible momentum! Keep this energy flowing.",
        "I can see remarkable improvements in your wellness patterns. You're doing amazing!",
        "The data shows you're making real progress. Your future self will thank you!",
        "Your dedication is paying off in measurable ways. Stay focused!",
      ],
      'transition': [
        "Excellent program choice! This aligns perfectly with your wellness goals.",
        "Smart transition! This combination will maximize your results.",
        "I love this strategic move! Your wellness journey is well-planned.",
      ],
    };
    
    final contextResponses = responses[context] ?? responses['motivation']!;
    String baseResponse = contextResponses[Random().nextInt(contextResponses.length)];
    
    // Add program-specific context
    switch (programType.toLowerCase()) {
      case 'mind reset':
        baseResponse += " Your mental clarity improvements are particularly impressive.";
        break;
      case 'fitness journey':
        baseResponse += " Your strength and endurance gains are right on track.";
        break;
      case 'nutrition mastery':
        baseResponse += " Your nutritional choices are creating lasting positive changes.";
        break;
      case 'sleep optimization':
        baseResponse += " Your sleep quality improvements are enhancing everything else.";
        break;
      case 'stress management':
        baseResponse += " Your stress resilience is building beautifully.";
        break;
    }
    
    return baseResponse;
  }

  // Enhanced motivational message generator
  void _generateEnhancedMotivation() {
    final completionPercentage = _getCompletionPercentage();
    final completedSteps = programProgress[selectedProgram]?.where((done) => done).length ?? 0;
    
    List<String> motivationalMessages = [];
    
    // Base on completion percentage
    if (completionPercentage == 0) {
      motivationalMessages.addAll([
        "Every journey begins with a single step. You're already here - that's progress!",
        "Your future self is counting on the decisions you make today. Let's start strong!",
        "The hardest part is beginning. You've got this covered!",
      ]);
    } else if (completionPercentage < 25) {
      motivationalMessages.addAll([
        "Building momentum! Your commitment is already showing results.",
        "Great start! The foundation you're laying will support amazing growth.",
        "Consistency beats perfection. You're proving that every day!",
      ]);
    } else if (completionPercentage < 50) {
      motivationalMessages.addAll([
        "Incredible progress! You're building life-changing habits.",
        "The momentum is building! Your dedication is truly inspiring.",
        "Halfway there! Your transformation is becoming visible.",
      ]);
    } else if (completionPercentage < 75) {
      motivationalMessages.addAll([
        "Outstanding commitment! You're in the acceleration phase now.",
        "Your consistency is remarkable! The benefits are compounding.",
        "So close to mastery! Your future self is already celebrating.",
      ]);
    } else {
      motivationalMessages.addAll([
        "Almost there! You're about to complete something amazing.",
        "Your dedication has been extraordinary. The finish line is in sight!",
        "What an incredible journey! You're proving what's possible with commitment.",
      ]);
    }
    
    // Add program-specific encouragement
    final programSpecific = {
      'Mind Reset': [
        " Your mental clarity is sharper than ever.",
        " The inner peace you're building is your greatest asset.",
        " Your mindfulness practice is transforming everything."
      ],
      'Fitness Journey': [
        " Your body is getting stronger every day.",
        " The energy you're gaining is radiating into all areas.",
        " Your physical transformation is inspiring."
      ],
      'Nutrition Mastery': [
        " Your relationship with food is beautifully balanced.",
        " The vitality you're gaining shows in everything you do.",
        " Your nutritional wisdom is becoming second nature."
      ],
      'Sleep Optimization': [
        " Your sleep quality is enhancing every aspect of life.",
        " The rest you're getting is supercharging your days.",
        " Your sleep mastery is your secret weapon."
      ],
      'Stress Management': [
        " Your emotional resilience is remarkably strong.",
        " The calm you're cultivating is your superpower.",
        " Your stress management skills are life-changing."
      ],
    };
    
    String baseMessage = motivationalMessages[Random().nextInt(motivationalMessages.length)];
    final specificMessages = programSpecific[selectedProgram] ?? [""];
    String specificMessage = specificMessages[Random().nextInt(specificMessages.length)];
    
    _typeAIMessage(baseMessage + specificMessage);
  }

  // Data analytics for enhanced insights
  Map<String, dynamic> _generateProgressAnalytics() {
    final completedSteps = programProgress[selectedProgram]?.where((done) => done).length ?? 0;
    final totalSteps = wellnessPrograms[selectedProgram]!['days'].length;
    final completionPercentage = _getCompletionPercentage();
    
    // Calculate streak
    int currentStreak = 0;
    final completed = programProgress[selectedProgram] ?? [];
    for (int i = completed.length - 1; i >= 0; i--) {
      if (completed[i]) {
        currentStreak++;
      } else {
        break;
      }
    }
    
    // Calculate total wellness score across all programs
    int totalCompleted = 0;
    int totalStepsAllPrograms = 0;
    
    programProgress.forEach((program, progress) {
      totalCompleted += progress.where((done) => done).length;
      totalStepsAllPrograms += progress.length;
    });
    
    final overallWellnessScore = totalStepsAllPrograms > 0 
        ? ((totalCompleted / totalStepsAllPrograms) * 100).round()
        : 0;
    
    return {
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'completionPercentage': completionPercentage,
      'currentStreak': currentStreak,
      'overallWellnessScore': overallWellnessScore,
      'totalCompleted': totalCompleted,
      'programsStarted': programProgress.keys.where((key) => 
          programProgress[key]?.any((done) => done) ?? false
        ).length,
    };
  }

  // Enhanced suggestion system
  String _generateSmartSuggestion(String analysisType) {
    final analytics = _generateProgressAnalytics();
    final completionPercentage = analytics['completionPercentage'] as int;
    final currentStreak = analytics['currentStreak'] as int;
    final overallScore = analytics['overallWellnessScore'] as int;
    
    switch (analysisType) {
      case "trend":
        if (currentStreak >= 3) {
          return "Impressive ${currentStreak}-day streak! Your consistency pattern suggests 90% likelihood of completing this program. Momentum is your strongest asset right now.";
        } else if (completionPercentage > 50) {
          return "You're past the halfway point with strong momentum. Data shows completion rates jump 75% after reaching 50% - you're in the success zone!";
        } else {
          return "Your progress pattern is building steadily. Early consistency like yours typically leads to 85% program completion rates.";
        }
        
      case "optimization":
        if (overallScore < 30) {
          return "Focus on one program at a time for maximum impact. Your current approach shows potential for 40% better results with concentrated effort.";
        } else if (completionPercentage > 70) {
          return "You're ready for advanced techniques! Consider increasing intensity or adding complementary practices for accelerated results.";
        } else {
          return "Perfect time to optimize your routine. Small adjustments now can improve your efficiency by 25-30%.";
        }
        
      case "prediction":
        if (currentStreak >= 5) {
          return "Based on your 5+ day streak, prediction models show 95% probability of program completion. You're on track for lasting transformation!";
        } else if (completionPercentage > 60) {
          return "With 60%+ completion, success probability is 88%. Your consistent effort predicts excellent long-term habit formation.";
        } else {
          return "Early indicators suggest strong potential for success. Maintaining current pace predicts 78% completion probability.";
        }
        
      default:
        return "Your wellness journey shows promising patterns. Keep building on this solid foundation!";
    }
  }

  // Weekend/weekday pattern recognition
  bool _isWeekendDay(int dayIndex) {
    // Simulate weekend detection (assuming program starts on Monday)
    final dayOfWeek = (dayIndex + 1) % 7; // 0 = Monday, 6 = Sunday
    return dayOfWeek == 5 || dayOfWeek == 6; // Friday and Saturday as weekend
  }

  // Advanced progress tracking and insights
  Map<String, dynamic> _calculateAdvancedMetrics() {
    final completed = programProgress[selectedProgram] ?? [];
    final totalSteps = completed.length;
    final completedCount = completed.where((done) => done).length;
    
    // Calculate completion velocity (steps per day)
    final daysActive = completed.asMap().entries
        .where((entry) => entry.value)
        .map((entry) => entry.key + 1)
        .toList();
    
    final velocityScore = daysActive.isNotEmpty 
        ? (completedCount / daysActive.last).toDouble()
        : 0.0;
    
    // Calculate consistency score (avoiding gaps)
    int consistencyScore = 0;
    int maxStreak = 0;
    int currentStreak = 0;
    
    for (bool isCompleted in completed) {
      if (isCompleted) {
        currentStreak++;
        maxStreak = max(maxStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }
    
    consistencyScore = ((maxStreak / totalSteps) * 100).round();
    
    // Weekend vs weekday performance
    int weekendCompleted = 0;
    int weekdayCompleted = 0;
    int totalWeekendDays = 0;
    int totalWeekdayDays = 0;
    
    for (int i = 0; i < completed.length; i++) {
      if (_isWeekendDay(i)) {
        totalWeekendDays++;
        if (completed[i]) weekendCompleted++;
      } else {
        totalWeekdayDays++;
        if (completed[i]) weekdayCompleted++;
      }
    }
    
    final weekendPerformance = totalWeekendDays > 0 
        ? ((weekendCompleted / totalWeekendDays) * 100).round()
        : 0;
    final weekdayPerformance = totalWeekdayDays > 0 
        ? ((weekdayCompleted / totalWeekdayDays) * 100).round()
        : 0;
    
    return {
      'velocityScore': velocityScore,
      'consistencyScore': consistencyScore,
      'maxStreak': maxStreak,
      'currentStreak': currentStreak,
      'weekendPerformance': weekendPerformance,
      'weekdayPerformance': weekdayPerformance,
      'completedCount': completedCount,
      'totalSteps': totalSteps,
    };
  }

  // Enhanced personalized insights generator
  String _generatePersonalizedInsight(String insightType) {
    final metrics = _calculateAdvancedMetrics();
    final analytics = _generateProgressAnalytics();
    
    switch (insightType) {
      case "performance_pattern":
        final weekendPerf = metrics['weekendPerformance'] as int;
        final weekdayPerf = metrics['weekdayPerformance'] as int;
        
        if (weekendPerf > weekdayPerf + 20) {
          return "You're a weekend warrior! Your weekend completion rate is ${weekendPerf}% vs ${weekdayPerf}% on weekdays. Consider building weekday momentum with shorter sessions.";
        } else if (weekdayPerf > weekendPerf + 20) {
          return "Weekday consistency is your strength at ${weekdayPerf}%! Weekend completion drops to ${weekendPerf}%. Try scheduling wellness activities as weekend rewards.";
        } else {
          return "Balanced performance across weekdays (${weekdayPerf}%) and weekends (${weekendPerf}%). Your routine adapts well to different schedules!";
        }
        
      case "velocity_analysis":
        final velocity = metrics['velocityScore'] as double;
        if (velocity >= 1.0) {
          return "Impressive pace! You're completing ${velocity.toStringAsFixed(1)} steps per day. This velocity suggests mastery-level engagement with your wellness journey.";
        } else if (velocity >= 0.5) {
          return "Steady progress at ${velocity.toStringAsFixed(1)} steps per day. This measured approach often leads to the most sustainable long-term results.";
        } else {
          return "Taking a thoughtful approach. Quality over quantity often yields better results. Focus on making each step meaningful.";
        }
        
      case "streak_potential":
        final maxStreak = metrics['maxStreak'] as int;
        final currentStreak = metrics['currentStreak'] as int;
        
        if (currentStreak >= maxStreak) {
          return "New personal record! Your ${currentStreak}-day streak is your best yet. You're in peak wellness momentum right now.";
        } else if (currentStreak > 0) {
          return "Current ${currentStreak}-day streak building nicely. Your record is ${maxStreak} days - you have the capability to surpass it!";
        } else {
          return "Ready for a fresh streak! Your best was ${maxStreak} days, proving you have the consistency skills to build lasting habits.";
        }
        
      case "program_synergy":
        final programsStarted = analytics['programsStarted'] as int;
        final overallScore = analytics['overallWellnessScore'] as int;
        
        if (programsStarted > 1) {
          return "Multi-program approach working well! ${programsStarted} programs active with ${overallScore}% overall wellness score. The synergy is accelerating your results.";
        } else {
          return "Focused single-program strategy is smart for building foundational habits. Consider adding a complementary program once you hit 70% completion.";
        }
        
      default:
        return "Your wellness data shows consistent growth patterns. Each step is building toward lasting transformation.";
    }
  }

  // Smart notification system for optimal timing
  String _generateTimingRecommendation() {
    final metrics = _calculateAdvancedMetrics();
    final weekendPerf = metrics['weekendPerformance'] as int;
    final weekdayPerf = metrics['weekdayPerformance'] as int;
    final currentHour = DateTime.now().hour;
    
    if (currentHour < 10) {
      return "Perfect morning timing! Your energy levels are optimal for wellness activities. Morning sessions show 35% better completion rates.";
    } else if (currentHour < 14) {
      return "Midday wellness break is excellent for sustained energy. Lunch-time sessions help maintain afternoon focus and productivity.";
    } else if (currentHour < 18) {
      return "Afternoon sessions are great for releasing daily stress. This timing helps transition from work mode to personal wellbeing.";
    } else {
      return "Evening wellness time helps process the day and prepare for restorative sleep. Perfect wind-down timing for better recovery.";
    }
  }

  // Goal adjustment recommendations
  String _generateGoalAdjustment() {
    final completionPercentage = _getCompletionPercentage();
    final metrics = _calculateAdvancedMetrics();
    final velocity = metrics['velocityScore'] as double;
    
    if (completionPercentage < 30 && velocity < 0.3) {
      return "Consider smaller daily goals to build momentum. Success breeds success - start with 10-minute sessions and build gradually.";
    } else if (completionPercentage > 70 && velocity > 0.8) {
      return "You're ready for advanced challenges! Consider increasing session length or adding mindfulness elements to existing activities.";
    } else if (velocity > 1.2) {
      return "Amazing pace! You might benefit from deeper focus rather than faster completion. Quality improvements could enhance long-term benefits.";
    } else {
      return "Your current pace is sustainable and effective. Steady progress leads to lasting transformation.";
    }
  }

  // Seasonal and contextual awareness
  String _generateContextualAdvice() {
    final now = DateTime.now();
    final month = now.month;
    final dayOfWeek = now.weekday;
    
    String seasonalAdvice = "";
    String weeklyAdvice = "";
    
    // Seasonal context
    if (month >= 3 && month <= 5) {
      seasonalAdvice = "Spring energy is perfect for renewal and fresh starts. Your wellness journey aligns beautifully with nature's growth cycle.";
    } else if (month >= 6 && month <= 8) {
      seasonalAdvice = "Summer vitality supports active wellness practices. Longer days give you more opportunities for outdoor activities.";
    } else if (month >= 9 && month <= 11) {
      seasonalAdvice = "Autumn is ideal for establishing lasting routines. This season of preparation supports habit formation.";
    } else {
      seasonalAdvice = "Winter's introspective energy is perfect for mindfulness practices. This season supports inner growth and reflection.";
    }
    
    // Weekly context
    if (dayOfWeek == 1) { // Monday
      weeklyAdvice = " Monday momentum can set your entire week. Strong start today predicts 60% better weekly completion.";
    } else if (dayOfWeek == 5) { // Friday
      weeklyAdvice = " Friday completion creates positive weekend energy. Finishing strong enhances your rest and recreation.";
    } else if (dayOfWeek == 6 || dayOfWeek == 7) { // Weekend
      weeklyAdvice = " Weekend wellness time is pure self-investment. This dedicated self-care builds resilience for the coming week.";
    } else {
      weeklyAdvice = " Mid-week consistency is where lasting habits are forged. These steady efforts compound into transformation.";
    }
    
    return seasonalAdvice + weeklyAdvice;
  }

  // Achievement recognition system
  List<Map<String, String>> _checkAchievements() {
    final analytics = _generateProgressAnalytics();
    final metrics = _calculateAdvancedMetrics();
    final achievements = <Map<String, String>>[];
    
    // Completion milestones
    final completionPercentage = analytics['completionPercentage'] as int;
    if (completionPercentage >= 25 && completionPercentage < 50) {
      achievements.add({
        'title': 'Quarter Champion',
        'description': '25% completion milestone achieved!',
        'icon': '🥉'
      });
    } else if (completionPercentage >= 50 && completionPercentage < 75) {
      achievements.add({
        'title': 'Halfway Hero',
        'description': '50% completion - major milestone!',
        'icon': '🥈'
      });
    } else if (completionPercentage >= 75 && completionPercentage < 100) {
      achievements.add({
        'title': 'Almost There',
        'description': '75% completion - final stretch!',
        'icon': '🥇'
      });
    } else if (completionPercentage == 100) {
      achievements.add({
        'title': 'Program Master',
        'description': 'Complete program mastery achieved!',
        'icon': '🏆'
      });
    }
    
    // Streak achievements
    final maxStreak = metrics['maxStreak'] as int;
    if (maxStreak >= 3 && maxStreak < 7) {
      achievements.add({
        'title': 'Consistency Builder',
        'description': '3+ day streak established!',
        'icon': '🔥'
      });
    } else if (maxStreak >= 7) {
      achievements.add({
        'title': 'Week Warrior',
        'description': 'Full week streak mastery!',
        'icon': '💫'
      });
    }
    
    // Multi-program achievements
    final programsStarted = analytics['programsStarted'] as int;
    if (programsStarted >= 2) {
      achievements.add({
        'title': 'Holistic Health',
        'description': 'Multiple wellness areas active!',
        'icon': '🌟'
      });
    }
    
    return achievements;
  }

  // Motivational quote system based on progress
  String _getProgressBasedQuote() {
    final completionPercentage = _getCompletionPercentage();
    final quotes = <String, List<String>>{
      'starting': [
        'The journey of a thousand miles begins with one step. - Lao Tzu',
        'What we plant in the soil of contemplation, we shall reap in the harvest of action. - Meister Eckhart',
        'Every moment is a fresh beginning. - T.S. Eliot'
      ],
      'progressing': [
        'Success is the sum of small efforts repeated day in and day out. - Robert Collier',
        'Progress, not perfection, is the goal. - Unknown',
        'The secret of change is to focus energy on building the new. - Socrates'
      ],
      'completing': [
        'The finish line is just the beginning of a whole new race. - Unknown',
        'Excellence is not a destination; it is a continuous journey. - Brian Tracy',
        'What lies behind us and what lies before us are tiny matters compared to what lies within us. - Ralph Waldo Emerson'
      ]
    };
    
    List<String> selectedQuotes;
    if (completionPercentage < 30) {
      selectedQuotes = quotes['starting']!;
    } else if (completionPercentage < 80) {
      selectedQuotes = quotes['progressing']!;
    } else {
      selectedQuotes = quotes['completing']!;
    }
    
    return selectedQuotes[Random().nextInt(selectedQuotes.length)];
  }

  // Enhanced completion celebration
  void _celebrateCompletion(int stepIndex) {
    final step = wellnessPrograms[selectedProgram]!['days'][stepIndex];
    final completionPercentage = _getCompletionPercentage();
    
    // Generate celebration message
    String celebrationMessage = "Congratulations on completing ${step['title']}! ";
    
    if (completionPercentage == 100) {
      celebrationMessage += "🎉 PROGRAM COMPLETE! You've mastered ${selectedProgram}. This is a major life achievement!";
    } else if (stepIndex == 0) {
      celebrationMessage += "🌟 First step taken! The hardest part is behind you now.";
    } else {
      celebrationMessage += "💪 Another step mastered! Your consistency is building unstoppable momentum.";
    }
    
    // Add impact message
    final stepType = step['type'];
    switch (stepType) {
      case 'breathing':
        celebrationMessage += " Your nervous system is already benefiting from this practice.";
        break;
      case 'exercise':
      case 'cardio':
      case 'strength':
        celebrationMessage += " Your body is getting stronger with every movement.";
        break;
      case 'mental':
      case 'mindfulness':
        celebrationMessage += " Your mental clarity and focus are sharpening.";
        break;
      case 'social':
        celebrationMessage += " Your connections are deepening and your support network growing.";
        break;
      case 'nutrition':
      case 'hydration':
        celebrationMessage += " Your body is receiving the nourishment it needs to thrive.";
        break;
      default:
        celebrationMessage += " Every step forward is transforming your life.";
    }
    
    _typeAIMessage(celebrationMessage);
  }

  // Recovery and rest recommendations
  String _generateRecoveryAdvice() {
    final metrics = _calculateAdvancedMetrics();
    final currentStreak = metrics['currentStreak'] as int;
    final velocity = metrics['velocityScore'] as double;
    
    if (currentStreak >= 7 && velocity > 1.0) {
      return "Your intensity is impressive! Consider adding a gentle recovery day to prevent burnout. Active rest maintains momentum while allowing adaptation.";
    } else if (currentStreak >= 5) {
      return "Excellent consistency! Your body and mind are adapting well. Keep listening to your energy levels and adjust accordingly.";
    } else if (velocity < 0.3) {
      return "Taking your time is wise. Recovery and reflection are as important as action. Trust your natural rhythm.";
    } else {
      return "Your pace looks sustainable and healthy. Balance between challenge and recovery is key to lasting transformation.";
    }
  }

  // Social sharing insights
  Map<String, String> _generateSharingInsights() {
    final analytics = _generateProgressAnalytics();
    final completionPercentage = analytics['completionPercentage'] as int;
    final currentStreak = analytics['currentStreak'] as int;
    
    return {
      'achievement': "🏆 ${completionPercentage}% complete in my ${selectedProgram} journey!",
      'streak': "🔥 ${currentStreak} days of consistent wellness practice!",
      'inspiration': "💪 Building lasting habits one day at a time. Wellness is a journey, not a destination!",
      'program_specific': _getProgramSpecificShare(),
    };
  }

  String _getProgramSpecificShare() {
    switch (selectedProgram) {
      case 'Mind Reset':
        return "🧘‍♀️ Finding inner peace through mindfulness and mental wellness practices.";
      case 'Fitness Journey':
        return "💪 Building strength, endurance, and physical vitality day by day.";
      case 'Nutrition Mastery':
        return "🥗 Transforming my relationship with food and nourishing my body mindfully.";
      case 'Sleep Optimization':
        return "😴 Mastering the art of restorative sleep for better health and energy.";
      case 'Stress Management':
        return "🧘‍♀️ Building resilience and emotional balance through proven techniques.";
      default:
        return "🌟 Committed to holistic wellness and personal transformation.";
    }
  }

  // Weather-based activity suggestions (simulated)
  String _generateWeatherBasedAdvice() {
    final random = Random();
    final weatherConditions = ['sunny', 'rainy', 'cloudy', 'windy'];
    final weather = weatherConditions[random.nextInt(weatherConditions.length)];
    
    switch (weather) {
      case 'sunny':
        return "Perfect sunny weather for outdoor activities! Consider taking your ${selectedProgram.toLowerCase()} practice outside for extra vitamin D and mood benefits.";
      case 'rainy':
        return "Cozy rainy day vibes are perfect for indoor wellness practices. This weather naturally supports mindfulness and reflection activities.";
      case 'cloudy':
        return "Overcast skies create ideal conditions for focused indoor work. Great day for deep practice and building consistency.";
      case 'windy':
        return "Fresh, energizing air today! If going outdoors, use the natural energy boost to enhance your movement practices.";
      default:
        return "Whatever the weather, your wellness practice adapts to any conditions. Consistency matters more than perfect circumstances.";
    }
  }
}