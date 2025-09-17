import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/ai_partner_service.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fabController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;
  
  bool showAIBot = false;
  bool isAITyping = false;
  String aiMessage = "";
  Timer? _aiTypingTimer;
  late AIPartnerService _aiService;
  final TextEditingController _chatController = TextEditingController();
  bool showChatInput = false;

  final tasks = [
    {
      'title': '10-Minute Mindful Walk',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/3039/3039436.png',
      'category': 'Movement',
      'points': 10,
    },
    {
      'title': '5-Minute Guided Meditation',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/4151/4151587.png',
      'category': 'Mindfulness',
      'points': 15,
    },
    {
      'title': 'Drink 2 Glasses of Water',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/1046/1046786.png',
      'category': 'Health',
      'points': 5,
    },
    {
      'title': 'Write Down 3 Gratitude Notes',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      'category': 'Mental Health',
      'points': 20,
    },
    {
      'title': 'Stretch for 7 Minutes',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/4151/4151588.png',
      'category': 'Movement',
      'points': 10,
    },
    {
      'title': 'Listen to Calm Music',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/727/727245.png',
      'category': 'Relaxation',
      'points': 8,
    },
    {
      'title': 'Read 5 Pages of a Book',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/29/29302.png',
      'category': 'Learning',
      'points': 15,
    },
    {
      'title': 'Call a Loved One',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/724/724664.png',
      'category': 'Social',
      'points': 25,
    },
    {
      'title': 'Do 5x Deep Breaths',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/727/727269.png',
      'category': 'Mindfulness',
      'points': 5,
    },
    {
      'title': 'Digital Detox (15 min)',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/1041/1041916.png',
      'category': 'Mental Health',
      'points': 20,
    },
    {
      'title': 'Journal Your Thoughts',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/2921/2921222.png',
      'category': 'Mental Health',
      'points': 15,
    },
    {
      'title': 'Practice 5-Min Yoga Flow',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/2965/2965567.png',
      'category': 'Movement',
      'points': 20,
    },
    {
      'title': 'Smile in the Mirror',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/2589/2589175.png',
      'category': 'Mental Health',
      'points': 5,
    },
    {
      'title': 'Eat a Fresh Fruit',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/415/415733.png',
      'category': 'Health',
      'points': 10,
    },
    {
      'title': 'Declutter Your Desk',
      'done': false,
      'img': 'https://cdn-icons-png.flaticon.com/512/5026/5026401.png',
      'category': 'Productivity',
      'points': 15,
    },
  ];

  @override
  void initState() {
    super.initState();
    _aiService = AIPartnerService();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_backgroundController);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _fabAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
    _fabController.forward();
    
    // Start AI bot after 3 seconds
    Timer(const Duration(seconds: 3), () {
      _showAIGreeting();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _fabController.dispose();
    _aiTypingTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  void _showAIGreeting() async {
    setState(() {
      showAIBot = true;
      isAITyping = true;
    });
    
    final greeting = await _aiService.getGreetingMessage();
    _typeAIMessage(greeting);
  }

  void _typeAIMessage(String message) {
    setState(() {
      aiMessage = "";
      isAITyping = true;
    });
    
    int index = 0;
    _aiTypingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < message.length) {
        setState(() {
          aiMessage += message[index];
        });
        index++;
      } else {
        timer.cancel();
        setState(() {
          isAITyping = false;
        });
      }
    });
  }

  void _onTaskCompleted(int index) {
    setState(() {
      tasks[index]['done'] = !(tasks[index]['done'] as bool);
    });
    
    if (tasks[index]['done'] as bool) {
      _showCompletionEffect(index);
      _triggerAIMotivation(tasks[index]['title'] as String);
    }
  }

  void _showCompletionEffect(int index) {
    // Trigger completion animation and effects
    HapticFeedback.lightImpact();
  }

  void _triggerAIMotivation([String? taskName]) async {
    String message;
    final completedTasks = tasks.where((t) => t['done'] as bool).length;
    
    if (completedTasks == tasks.length) {
      message = await _aiService.getAllTasksCompletedMessage();
    } else if (taskName != null) {
      message = await _aiService.getTaskCompletionMessage(taskName);
    } else {
      message = await _aiService.getMotivationalMessage();
    }
    
    _typeAIMessage(message);
  }

  void _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    
    final userMessage = _chatController.text.trim();
    _chatController.clear();
    
    final response = await _aiService.getChatResponse(userMessage);
    _typeAIMessage(response);
  }

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t['done'] as bool).length;
    final progress = completed / tasks.length;
    final totalPoints = tasks
        .where((t) => t['done'] as bool)
        .fold(0, (sum, task) => sum + (task['points'] as int));

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF6A11CB),
                    const Color(0xFF2575FC),
                    (math.sin(_backgroundAnimation.value) + 1) / 2,
                  )!,
                  Color.lerp(
                    const Color(0xFF2575FC),
                    const Color(0xFF6A11CB),
                    (math.cos(_backgroundAnimation.value) + 1) / 2,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: GradientRotation(_backgroundAnimation.value / 4),
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(20, (index) => _buildParticle(index)),
                
                // Main content
                SafeArea(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(progress, totalPoints),
                          const SizedBox(height: 16),
                          _buildProgressSection(progress),
                          const SizedBox(height: 24),
                          _buildMissionList(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // AI Bot Overlay
                if (showAIBot) _buildAIBot(),
                
                // Chat Input Overlay
                if (showChatInput) _buildChatInput(),
                
                // Floating Action Button
                _buildFloatingButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        final offset = Offset(
          math.sin(_backgroundAnimation.value + index) * 100 + MediaQuery.of(context).size.width / 2,
          math.cos(_backgroundAnimation.value + index * 0.5) * 150 + MediaQuery.of(context).size.height / 2,
        );
        
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double progress, int totalPoints) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Missions 🌿",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Text(
                    "⭐ $totalPoints Points",
                    style: GoogleFonts.poppins(
                      color: Colors.amber[100],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: CircularPercentIndicator(
              radius: 50,
              lineWidth: 10,
              percent: progress,
              center: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              progressColor: Colors.greenAccent,
              backgroundColor: Colors.white.withOpacity(0.2),
              animation: true,
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          LinearPercentIndicator(
            lineHeight: 16,
            percent: progress,
            barRadius: const Radius.circular(12),
            backgroundColor: Colors.white.withOpacity(0.2),
            progressColor: Colors.greenAccent,
            animation: true,
            curve: Curves.easeInOutCubic,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${tasks.where((t) => t['done'] as bool).length}/${tasks.length} completed",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                progress == 1.0 ? "🎉 All Done!" : "Keep going! 💪",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    return Expanded(
      child: ListView.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (i * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildTaskCard(i),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(int index) {
    final task = tasks[index];
    final isCompleted = task['done'] as bool;
    
    return GestureDetector(
      onTap: () => _onTaskCompleted(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isCompleted 
                ? Colors.green.withOpacity(0.3)
                : Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(task['img'] as String),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.white : Colors.black87,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          task['category'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isCompleted ? Colors.white70 : Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+${task['points']} pts",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isCompleted ? Colors.white70 : Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  value: isCompleted,
                  onChanged: (v) => _onTaskCompleted(index),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  activeColor: Colors.white,
                  checkColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBot() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Text(
                "💕",
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Your AI Partner 💖",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aiMessage + (isAITyping ? "▌" : ""),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      showChatInput = !showChatInput;
                    });
                  },
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showAIBot = false;
                      showChatInput = false;
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Positioned(
      bottom: 180,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFC44569)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "Chat with your girlfriend... 💕",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendChatMessage(),
              ),
            ),
            IconButton(
              onPressed: _sendChatMessage,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Color(0xFFFF6B9D),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "ai",
              onPressed: () {
                setState(() {
                  showAIBot = !showAIBot;
                });
                if (showAIBot) {
                  _triggerAIMotivation();
                }
              },
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "refresh",
              onPressed: () {
                setState(() {
                  for (var task in tasks) {
                    task['done'] = false;
                  }
                });
                _typeAIMessage("🔄 Fresh start! Let's tackle these missions together!");
              },
              backgroundColor: const Color(0xFF764ba2),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}