import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/material.dart';
import '../screens/mood_option.dart';
// Import your chat screen
import 'chat_screen.dart'; // Update this path as needed

class MoodScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const MoodScreen({super.key, this.userData});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen>
    with TickerProviderStateMixin {
  String? _selectedMood;
  bool _isNavigating = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _buttonScaleAnimation;

  final List<MoodOption> _moodOptions = [
    MoodOption(
      id: 'happy',
      label: 'Happy',
      emoji: '😊',
      animatedChar: '😊',
      color: const Color(0xFFFFD700),
      gradient: [const Color(0xFFFFB74D), const Color(0xFFFF9800)],
      description: 'Radiating positive energy and joy',
      intensity: 'High Energy',
      suggestions: ['Share your happiness', 'Spread positivity', 'Celebrate life'],
      aiPrompt: 'The user is feeling happy and energetic. Engage with enthusiasm and help them maintain this positive state.',
      chatTheme: 'celebratory',
    ),
    MoodOption(
      id: 'sad',
      label: 'Sad',
      emoji: '😢',
      animatedChar: '😢',
      color: const Color(0xFF4FC3F7),
      gradient: [const Color(0xFF42A5F5), const Color(0xFF2196F3)],
      description: 'Processing emotions and seeking comfort',
      intensity: 'Reflective',
      suggestions: ['Talk to someone', 'Practice mindfulness', 'Be gentle with yourself'],
      aiPrompt: 'The user is feeling sad and needs emotional support. Be empathetic, gentle, and offer comfort.',
      chatTheme: 'supportive',
    ),
    MoodOption(
      id: 'tired',
      label: 'Tired',
      emoji: '😴',
      animatedChar: '😴',
      color: const Color(0xFF6B73FF),
      gradient: [const Color(0xFF7986CB), const Color(0xFF5C6BC0)],
      description: 'Need some rest and recharge',
      intensity: 'Low Energy',
      suggestions: ['Take a break', 'Practice self-care', 'Rest and recover'],
      aiPrompt: 'The user is feeling tired and drained. Offer gentle support and energy-restoring suggestions.',
      chatTheme: 'calming',
    ),
    MoodOption(
      id: 'angry',
      label: 'Angry',
      emoji: '😠',
      animatedChar: '😠',
      color: const Color(0xFFFF5722),
      gradient: [const Color(0xFFEF5350), const Color(0xFFE53935)],
      description: 'Feeling intense and need to channel energy',
      intensity: 'High Intensity',
      suggestions: ['Channel your energy', 'Express safely', 'Find healthy outlets'],
      aiPrompt: 'The user is feeling angry. Help them process this emotion constructively and find healthy outlets.',
      chatTheme: 'energetic',
    ),
    MoodOption(
      id: 'depressed',
      label: 'Depressed',
      emoji: '😞',
      animatedChar: '😞',
      color: const Color(0xFF9C27B0),
      gradient: [const Color(0xFFAB47BC), const Color(0xFF8E24AA)],
      description: 'Going through a difficult time',
      intensity: 'Deep Processing',
      suggestions: ['Seek support', 'Professional help', 'You are not alone'],
      aiPrompt: 'The user is feeling depressed. Provide compassionate support and gentle encouragement to seek help.',
      chatTheme: 'compassionate',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _floatingAnimation = Tween<double>(begin: -20.0, end: 20.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _handleMoodSelect(MoodOption mood) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMood = mood.id;
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _startChat() async {
    if (_selectedMood == null || _isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });

    HapticFeedback.mediumImpact();
    _buttonController.forward();
    
    final selectedMood = _moodOptions.firstWhere((m) => m.id == _selectedMood);
    
    // Convert to your chat screen's expected MoodOption format
    final chatMoodData = selectedMood.toJson();

    try {
      // Navigate to chat screen with mood data
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedChatScreen(
            userData: widget.userData,
            selectedMood: _selectedMood,
            moodData: selectedMood,
          ),
        ),
      );
    } catch (e) {
      // Handle navigation error
      debugPrint('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to start chat. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        _buttonController.reverse();
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final userName = widget.userData?['name'] ?? '';
    final greeting = hour < 12 
        ? 'Good Morning' 
        : hour < 18 
            ? 'Good Afternoon' 
            : 'Good Evening';
    
    return userName.isNotEmpty ? '$greeting, $userName' : greeting;
  }

  @override
  Widget build(BuildContext context) {
    final selectedMoodData = _selectedMood != null 
        ? _moodOptions.firstWhere((m) => m.id == _selectedMood)
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Elements
            ..._buildBackgroundElements(),
            
            // Floating Particles
            _buildFloatingParticles(selectedMoodData),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Enhanced Header Card
                    _buildHeaderCard(selectedMoodData),
                    
                    const SizedBox(height: 30),
                    
                    // Mood Selection Cards
                    _buildMoodSelector(),
                    
                    const SizedBox(height: 30),
                    
                    // CTA Button
                    _buildCTAButton(),
                    
                    if (_selectedMood != null) ...[
                      const SizedBox(height: 30),
                      _buildFeaturePreview(),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Loading Overlay
            if (_isNavigating) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(100), // Increased height
    child: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.1),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 45, 12, 12), // Further reduced padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible( // Wrapped in Flexible
                  flex: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Further reduced padding
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF9C27B0),
                              Color(0xFFE91E63),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10), // Slightly smaller radius
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withOpacity(0.25),
                              blurRadius: 10, // Reduced blur
                              spreadRadius: 1, // Reduced spread
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 18, // Further reduced size
                        ),
                      ),
                      const SizedBox(width: 10), // Reduced spacing
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SAHAYAM',
                              style: const TextStyle(
                                fontSize: 18, // Further reduced font size
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1, // Reduced line height
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Emotional Intelligence Platform',
                              style: TextStyle(
                                fontSize: 9, // Further reduced font size
                                color: Colors.grey[400],
                                height: 1.0, // Reduced line height
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Added spacing
                Flexible( // Wrapped in Flexible
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14, // Reduced font size
                        ),
                        overflow: TextOverflow.ellipsis, // Added overflow handling
                        maxLines: 1, // Limited to one line
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Text(
                        TimeOfDay.now().format(context),
                        style: TextStyle(
                          fontSize: 11, // Reduced font size
                          color: Colors.grey[400],
                        ),
                        overflow: TextOverflow.ellipsis, // Added overflow handling
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

  Widget _buildFloatingParticles(MoodOption? selectedMoodData) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: List.generate(15, (index) {
            return Positioned(
              left: (index * 60.0 % MediaQuery.of(context).size.width),
              top: 200 + (index * 40.0) + _floatingAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: (selectedMoodData?.color ?? const Color(0xFF7C4DFF))
                      .withOpacity(0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (selectedMoodData?.color ?? const Color(0xFF7C4DFF)),
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
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF9C27B0),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connecting to MoodSync AI...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing your personalized experience',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundElements() {
    return [
      // Dynamic gradient mesh
      AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: _pulseAnimation.value,
                  colors: [
                    const Color(0xFF9C27B0).withOpacity(0.2),
                    const Color(0xFFE91E63).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      
      // Animated geometric patterns
      Positioned(
        top: 100,
        left: 50,
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _particleController.value * 2 * math.pi,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
      
      Positioned(
        top: 300,
        right: 60,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value * 0.5,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildHeaderCard(MoodOption? selectedMoodData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF9C27B0),
                          Color(0xFFE91E63),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.25),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatingAnimation.value * 0.1),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE1BEE7)],
                          ).createShader(bounds),
                          child: Text(
                            'How are you feeling today?',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 350 ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your mood to connect with personalized AI support',
                          style: TextStyle(
                            color: const Color(0xFFE1BEE7),
                            fontSize: MediaQuery.of(context).size.width < 350 ? 14 : 16,
                            height: 1.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Selected Mood Display
              if (selectedMoodData != null) ...[
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              selectedMoodData.gradient[0].withOpacity(0.2),
                              selectedMoodData.gradient[1].withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(
                            color: selectedMoodData.color.withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: selectedMoodData.color.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: selectedMoodData.gradient,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: selectedMoodData.color.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _floatingController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatingAnimation.value * 0.1),
                                    child: Text(
                                      selectedMoodData.animatedChar,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected Mood',
                                    style: TextStyle(
                                      color: Color(0xFFE1BEE7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        selectedMoodData.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: selectedMoodData.gradient,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          selectedMoodData.intensity,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selectedMoodData.description,
                                    style: const TextStyle(
                                      color: Color(0xFFE1BEE7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value * 0.8,
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4CAF50),
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Emotional State',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: _moodOptions.asMap().entries.map((entry) {
                  int index = entry.key;
                  MoodOption mood = entry.value;
                  bool isSelected = _selectedMood == mood.id;
                  
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 150 * (index + 1)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () => _handleMoodSelect(mood),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                transform: Matrix4.identity()
                                  ..scale(isSelected ? 1.02 : 1.0),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [
                                              mood.gradient[0].withOpacity(0.2),
                                              mood.gradient[1].withOpacity(0.1),
                                            ]
                                          : [
                                              Colors.white.withOpacity(0.05),
                                              Colors.white.withOpacity(0.02),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? mood.color.withOpacity(0.4)
                                          : Colors.white.withOpacity(0.1),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: mood.color.withOpacity(0.2),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Animated Character
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? LinearGradient(colors: mood.gradient)
                                              : LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0.15),
                                                    Colors.white.withOpacity(0.1),
                                                  ],
                                                ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: mood.color.withOpacity(0.4),
                                                    blurRadius: 15,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          mood.animatedChar,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 20),
                                      
                                      // Mood Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mood.label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              mood.description,
                                              style: const TextStyle(
                                                color: Color(0xFFE1BEE7),
                                                fontSize: 14,
                                                height: 1.3,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Selection Indicator
                                      AnimatedOpacity(
                                        opacity: isSelected ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: mood.gradient),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButton() {
    final selectedMoodData = _selectedMood != null 
        ? _moodOptions.firstWhere((m) => m.id == _selectedMood)
        : null;

    return Center(
      child: AnimatedBuilder(
        animation: _buttonScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _buttonScaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: _selectedMood != null
                    ? [
                        BoxShadow(
                          color: (selectedMoodData?.color ?? const Color(0xFF9C27B0)).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: _selectedMood != null && !_isNavigating ? _startChat : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMood != null 
                      ? selectedMoodData?.color ?? const Color(0xFF9C27B0)
                      : Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: _selectedMood != null 
                      ? WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return (selectedMoodData?.gradient[1] ?? const Color(0xFF7B1FA2));
                          }
                          return selectedMoodData?.color ?? const Color(0xFF9C27B0);
                        })
                      : WidgetStateProperty.all(Colors.grey.shade600),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isNavigating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        _isNavigating
                            ? 'Connecting...'
                            : _selectedMood != null 
                                ? 'Start MoodSync Chat'
                                : 'Select your mood to begin',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_selectedMood != null && !_isNavigating) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturePreview() {
    final selectedMoodData = _selectedMood != null 
        ? _moodOptions.firstWhere((m) => m.id == _selectedMood)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selectedMoodData?.gradient ?? [
                          const Color(0xFF9C27B0),
                          const Color(0xFFE91E63)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedMoodData?.animatedChar ?? '✨',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalized for ${selectedMoodData?.label ?? "Your Mood"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          selectedMoodData?.chatTheme.toUpperCase() ?? 'ADAPTIVE',
                          style: TextStyle(
                            color: selectedMoodData?.color ?? const Color(0xFF9C27B0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Mood-specific suggestions preview
              if (selectedMoodData != null) ...[
                const Text(
                  'What you can expect:',
                  style: TextStyle(
                    color: Color(0xFFE1BEE7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ...selectedMoodData.suggestions.take(2).map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: selectedMoodData.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(width: 16),
              ],

              // Standard features
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Get personalized emotional guidance from MoodSync AI',
                          style: TextStyle(
                            color: Color(0xFFE1BEE7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB74D).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood-Based Matching',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Connect with others experiencing similar emotions',
                          style: TextStyle(
                            color: Color(0xFFE1BEE7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF42A5F5).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real-Time Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Instant emotional support available 24/7',
                          style: TextStyle(
                            color: Color(0xFFE1BEE7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}