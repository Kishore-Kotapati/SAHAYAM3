import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../screens/mood_option.dart';

class EnhancedChatScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? selectedMood;
  final MoodOption? moodData;
  
  const EnhancedChatScreen({
    Key? key, 
    this.userData,
    this.selectedMood,
    this.moodData,
  }) : super(key: key);

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  WebSocketChannel? _channel;
  
  List<ChatMessage> messages = [];
  Map<String, dynamic>? matchData;
  bool _isTyping = false;
  bool _showAIHelper = false;
  bool _isConnected = false;
  bool _isConnecting = true;
  String _connectionStatus = 'Connecting...';
  String _roomId = '';
  
  // Enhanced Animations
  late AnimationController _animationController;
  late AnimationController _bubbleAnimController;
  late AnimationController _typingAnimController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _backgroundController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _typingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _backgroundAnimation;
  
  // Enhanced Mood colors mapping with gradients
  final Map<String, List<Color>> moodGradients = {
    'happy': [const Color(0xFFFFB74D), const Color(0xFFFF9800), const Color(0xFFFF6F00)],
    'sad': [const Color(0xFF42A5F5), const Color(0xFF2196F3), const Color(0xFF1976D2)],
    'anxious': [const Color(0xFFAB47BC), const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
    'calm': [const Color(0xFF26C6DA), const Color(0xFF00BCD4), const Color(0xFF0097A7)],
    'excited': [const Color(0xFFEF5350), const Color(0xFFE53935), const Color(0xFFD32F2F)],
    'tired': [const Color(0xFF7986CB), const Color(0xFF5C6BC0), const Color(0xFF3F51B5)],
    'angry': [const Color(0xFFFF5722), const Color(0xFFE53935), const Color(0xFFD32F2F)],
    'depressed': [const Color(0xFF8E24AA), const Color(0xFF7B1FA2), const Color(0xFF6A1B9A)],
    'neutral': [const Color(0xFF42A5F5), const Color(0xFF2196F3), const Color(0xFF1976D2)],
    'default': [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFF5a67d8)],
  };

  static const String _backendUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupMatchData();
    _initializeChat();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bubbleAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _typingAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimController,
      curve: Curves.elasticOut,
    ));

    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_typingAnimController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: -30.0,
      end: 30.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_backgroundController);
    
    _animationController.forward();
  }

  void _setupMatchData() {
    final selectedMood = widget.selectedMood ?? 'neutral';
    final moodData = widget.moodData;
    
    matchData = {
      'username': 'MoodSync AI',
      'shared_mood': selectedMood,
      'room_id': 'room_${DateTime.now().millisecondsSinceEpoch}',
      'mood_data': moodData?.toJson(),
      'intensity': moodData?.intensity ?? 'Neutral',
      'description': moodData?.description ?? 'Connecting minds and hearts',
    };
  }

  List<Color> get currentGradient {
    final mood = matchData?['shared_mood']?.toLowerCase() ?? 'default';
    return moodGradients[mood] ?? moodGradients['default']!;
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isConnecting = true;
        _connectionStatus = 'Connecting to MoodSync...';
        _isConnected = false;
      });

      _roomId = matchData?['room_id'] ?? 'room_${DateTime.now().millisecondsSinceEpoch}';
      
      // Simulate connection for demo - replace with real connection logic
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isConnecting = false;
        _isConnected = false; // Set to offline mode for demo
        _connectionStatus = 'Offline mode - AI support available';
      });
      
      _addWelcomeMessages();
      
    } catch (e) {
      print('Connection failed: $e');
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _connectionStatus = 'Connection failed - Using offline mode';
      });
      _addWelcomeMessages();
    }
  }

  void _addWelcomeMessages() {
    final mood = matchData?['shared_mood'] ?? 'neutral';
    final moodDescription = matchData?['description'] ?? '';
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        ChatMessage(
          text: "Welcome to MoodSync! You're feeling $mood today.",
          isMe: false,
          senderName: "MoodSync",
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      );
    });
    

  }

  void _addMessage(ChatMessage message) {
    if (mounted) {
      setState(() {
        messages.add(message);
      });
      
      _bubbleAnimController.forward(from: 0);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addMessage(
      ChatMessage(
        text: text,
        isMe: true,
        senderName: widget.userData?['fullName'] ?? 'You',
        timestamp: DateTime.now(),
        mood: _detectMood(text),
      ),
    );

    _simulateAIResponse(text);
    _messageController.clear();
  }

  Future<void> _simulateAIResponse(String userMessage) async {
    try {
      setState(() {
        _isTyping = true;
      });

      final response = await http.post(
        Uri.parse('$_backendUrl/api/mood-chat/support'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': userMessage,
          'mood': widget.selectedMood,
          'context': 'User is in a mood chat session. Respond like a supportive, caring, and empathetic partner.',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addMessage(
          ChatMessage(
            text: data['response'] ?? "I'm here to listen and support you.",
            isMe: false,
            senderName: "MoodSync AI",
            timestamp: DateTime.now(),
            isAI: true,
          ),
        );
      } else {
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Backend API Error: $e');
      _addMessage(
        ChatMessage(
          text: "I'm here to listen and support you. Your emotions are important.",
          isMe: false,
          senderName: "MoodSync AI",
          timestamp: DateTime.now(),
          isAI: true,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  String _detectMood(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains(RegExp(r'\b(happy|great|excited|amazing|wonderful)\b'))) return 'happy';
    if (lowerText.contains(RegExp(r'\b(sad|down|depressed|upset|low)\b'))) return 'sad';
    if (lowerText.contains(RegExp(r'\b(anxious|worried|nervous|stressed)\b'))) return 'anxious';
    if (lowerText.contains(RegExp(r'\b(calm|peaceful|relaxed|serene)\b'))) return 'calm';
    if (lowerText.contains(RegExp(r'\b(angry|mad|furious|irritated)\b'))) return 'angry';
    if (lowerText.contains(RegExp(r'\b(tired|exhausted|sleepy|drained)\b'))) return 'tired';
    return matchData?['shared_mood'] ?? 'neutral';
  }

  void _showAIAssistant() {
    final mood = matchData?['shared_mood'] ?? 'neutral';
    final starters = _getMoodBasedStarters(mood);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              currentGradient[0],
              currentGradient[1],
              currentGradient[2],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: currentGradient[0].withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 0.8,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Conversation Starters',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Here are some thoughtful ways to express yourself:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: starters.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 200 * (index + 1)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: GestureDetector(
                            onTap: () {
                              _messageController.text = starters[index];
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.95),
                                    Colors.white.withOpacity(0.85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: currentGradient.take(2).toList()),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      starters[index],
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  List<String> _getMoodBasedStarters(String mood) {
    final Map<String, List<String>> starters = {
      'happy': [
        "I'm feeling so grateful today",
        "Something amazing happened that made me smile",
        "I want to share this positive energy",
        "What's bringing you joy right now?",
        "Let's celebrate the good moments together!"
      ],
      'sad': [
        "I'm going through something difficult",
        "Sometimes it helps just to talk",
        "I'm feeling down and could use support",
        "What helps you when you're feeling low?",
        "I could really use some gentle words today"
      ],
      'anxious': [
        "My mind is racing and I need to talk",
        "I'm feeling overwhelmed",
        "Does anyone else struggle with anxiety?",
        "What helps you when worry takes over?",
        "I need some reassurance"
      ],
      'angry': [
        "I'm feeling frustrated",
        "Something happened that really bothered me",
        "How do you handle anger in a healthy way?",
        "I'm worked up and could use perspective",
        "Let me share what's making me upset"
      ],
      'tired': [
        "I'm feeling drained",
        "Exhaustion is hitting me hard today",
        "How do you recharge when you're spent?",
        "I need some gentle conversation",
        "What helps when you're running on empty?"
      ]
    };
    
    return starters[mood] ?? [
      "How are you feeling today?",
      "What's been on your mind?",
      "I'd love to connect with someone",
      "What's helping you get through today?",
      "Sometimes we all need someone to talk to"
    ];
  }

  Widget _buildEnhancedBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                currentGradient[0].withOpacity(0.15),
                currentGradient[1].withOpacity(0.08),
                currentGradient[2].withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
        ),
        
        AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Stack(
              children: List.generate(20, (index) {
                final angle = _backgroundAnimation.value + (index * pi / 10);
                final radius = 100 + (index * 20);
                final x = MediaQuery.of(context).size.width / 2 + cos(angle) * radius;
                final y = MediaQuery.of(context).size.height / 2 + sin(angle) * radius;
                
                return Positioned(
                  left: x,
                  top: y,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: currentGradient[index % 3].withOpacity(0.3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: currentGradient[index % 3].withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _bubbleAnimController.dispose();
    _typingAnimController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    currentGradient[0].withOpacity(0.9),
                    currentGradient[1].withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentGradient[0].withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              Stack(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value * 0.9,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: Text(
                            widget.moodData?.animatedChar ?? '🤖',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_isTyping)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 0.8,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matchData?['username'] ?? 'MoodSync Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _isTyping 
                          ? 'AI is thinking...' 
                          : 'Feeling ${matchData?['shared_mood'] ?? 'connected'} • ${matchData?['intensity'] ?? 'Neutral'}',
                        key: ValueKey(_isTyping),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value * 0.8,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isConnected 
                      ? const Color(0xFF4CAF50) 
                      : (_isConnecting ? const Color(0xFFFF9800) : const Color(0xFFE57373)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isConnected 
                          ? const Color(0xFF4CAF50) 
                          : (_isConnecting ? const Color(0xFFFF9800) : const Color(0xFFE57373))).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isConnected 
                      ? Icons.cloud_done 
                      : (_isConnecting ? Icons.cloud_sync : Icons.cloud_off),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildEnhancedBackground(),
          SafeArea(
            child: Column(
              children: [
                if (_isConnecting || !_isConnected)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isConnecting 
                          ? [const Color(0xFFFF9800).withOpacity(0.9), const Color(0xFFFFB74D).withOpacity(0.8)]
                          : [const Color(0xFFE57373).withOpacity(0.9), const Color(0xFFEF5350).withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnecting ? const Color(0xFFFF9800) : const Color(0xFFE57373)).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value * 0.8,
                              child: Icon(
                                _isConnecting ? Icons.sync : Icons.wifi_off,
                                color: Colors.white,
                                size: 20,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isConnecting ? 'Connecting to MoodSync...' : 'Offline Mode Active',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _isConnecting ? 'Finding your emotional support network' : 'AI support still available',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: messages.isEmpty
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _floatingController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _floatingAnimation.value * 0.2),
                                      child: Container(
                                        padding: const EdgeInsets.all(40),
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            colors: [
                                              currentGradient[0].withOpacity(0.3),
                                              currentGradient[1].withOpacity(0.2),
                                              currentGradient[2].withOpacity(0.1),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: currentGradient[0].withOpacity(0.3),
                                              blurRadius: 40,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          widget.moodData?.animatedChar ?? '💭',
                                          style: const TextStyle(fontSize: 80),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: currentGradient,
                                  ).createShader(bounds),
                                  child: Text(
                                    'Your emotional sanctuary awaits',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.15),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'You\'re feeling ${matchData?['shared_mood']} • ${matchData?['description'] ?? 'Let\'s explore together'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return EnhancedMessageBubble(
                              message: messages[index],
                              animation: _scaleAnimation,
                              gradient: currentGradient,
                              isConsecutive: index > 0 && messages[index-1].isMe == messages[index].isMe,
                            );
                          },
                        ),
                ),
                
                if (_isTyping)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.95),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: currentGradient[0].withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.moodData?.animatedChar ?? '🤖',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                height: 20,
                                child: AnimatedBuilder(
                                  animation: _typingAnimation,
                                  builder: (context, child) {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: List.generate(3, (index) {
                                        final delay = index * 0.3;
                                        final animValue = (_typingAnimation.value + delay) % 1.0;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: 8,
                                          height: 8 + (6 * sin(animValue * pi * 2)).abs(),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [currentGradient[0], currentGradient[1]],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: currentGradient[0].withOpacity(0.4),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, -8),
                        blurRadius: 25,
                        color: currentGradient[0].withOpacity(0.15),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value * 0.9,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: currentGradient.take(2).toList()),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentGradient[0].withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                                  onPressed: _showAIAssistant,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade50,
                                  Colors.white,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: currentGradient[0].withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: GoogleFonts.poppins(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Express your feelings...',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.sentiment_satisfied_alt,
                                    color: currentGradient[0],
                                    size: 24,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value * 0.9,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: currentGradient.take(2).toList()),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentGradient[0].withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                                  onPressed: _sendMessage,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Supporting Classes
class ChatMessage {
  final String text;
  final bool isMe;
  final String senderName;
  final DateTime timestamp;
  final String? mood;
  final bool isSystem;
  final bool isAI;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.senderName,
    required this.timestamp,
    this.mood,
    this.isSystem = false,
    this.isAI = false,
  });
}

// Enhanced Message Bubble Widget
class EnhancedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Animation<double> animation;
  final List<Color> gradient;
  final bool isConsecutive;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.animation,
    required this.gradient,
    this.isConsecutive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return ScaleTransition(
        scale: animation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradient[0].withOpacity(0.2),
                    gradient[1].withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: gradient[0].withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: gradient[0],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (message.isAI) {
      return ScaleTransition(
        scale: animation,
        child: Container(
          margin: EdgeInsets.only(
            top: isConsecutive ? 4 : 16,
            bottom: 8,
            left: 16,
            right: 60,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isConsecutive)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient.take(2).toList()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Colors.white,
                  ),
                )
              else
                const SizedBox(width: 40),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient[0].withOpacity(0.1),
                        gradient[1].withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                      bottomLeft: isConsecutive ? const Radius.circular(20) : const Radius.circular(4),
                    ),
                    border: Border.all(
                      color: gradient[0].withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isConsecutive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            message.senderName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: gradient[0],
                            ),
                          ),
                        ),
                      Text(
                        message.text,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User messages (right side)
    return ScaleTransition(
      scale: animation,
      child: Container(
        margin: EdgeInsets.only(
          top: isConsecutive ? 4 : 16,
          bottom: 8,
          left: 60,
          right: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient.take(2).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: isConsecutive ? const Radius.circular(20) : const Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.text,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (!isConsecutive)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: gradient[0].withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: gradient[0],
                ),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}
