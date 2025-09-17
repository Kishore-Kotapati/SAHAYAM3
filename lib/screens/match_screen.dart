
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  
  // Enhanced Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _morphController;
  late AnimationController _heartController;
  late AnimationController _glowController;
  late AnimationController _rippleController;

  // Advanced Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _heartAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rippleAnimation;

  final CardSwiperController _cardController = CardSwiperController();
  final List<FloatingParticle> _particles = [];
  final List<String> _savedProfiles = [];
  
  // Enhanced background images with premium quality
  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1578662996442-48f60103fc96?auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?auto=format&fit=crop&w=1950&q=80',
  ];
  final List<List<Color>> _glassmorphicOverlays = [
  [Colors.pink.withOpacity(0.4), Colors.blue.withOpacity(0.3)],
  [Colors.blue.withOpacity(0.4), Colors.pink.withOpacity(0.3)],
  [Colors.pink.withOpacity(0.4), Colors.lightBlue.withOpacity(0.3)],
  [Colors.blue.shade300.withOpacity(0.4), Colors.pink.shade300.withOpacity(0.3)],
  [Colors.pink.shade200.withOpacity(0.4), Colors.blue.shade200.withOpacity(0.3)],
];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;
  bool _isLoading = false;
  bool _showMatchOverlay = false;
  String _currentMatchedUser = '';

  final profiles = List.generate(10, (i) => ProfileCard(index: i));

  @override
  void initState() {
    super.initState();
    _initializeAdvancedAnimations();
    _initializeEnhancedParticles();
    _startAdvancedAnimations();
    _startAutoScroll();
    _simulateBackendConnection();
  }

  void _initializeAdvancedAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 4 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
    _morphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeInOutBack),
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  void _initializeEnhancedParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(FloatingParticle());
    }
  }

  void _startAdvancedAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
      _rotationController.repeat();
      _particleController.repeat();
      _pulseController.repeat(reverse: true);
      _shimmerController.repeat(reverse: true);
      _morphController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    });
  }

  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _backgroundImages.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _simulateBackendConnection() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _isLoading = Random().nextBool();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    });
  }

  void _showAdvancedMatchAnimation(String userName) {
    setState(() {
      _showMatchOverlay = true;
      _currentMatchedUser = userName;
    });

    _heartController.reset();
    _heartController.forward();
    _rippleController.reset();
    _rippleController.forward();

    HapticFeedback.mediumImpact();

    // Show premium match dialog with glassmorphism
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildMatchDialog(userName),
    );

    // Auto dismiss after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _showMatchOverlay = false;
        });
      }
    });
  }

  Widget _buildMatchDialog(String userName) {
    return AnimatedBuilder(
      animation: _heartAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Glassmorphism background
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.pink.withOpacity(0.3),
                    Colors.purple.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Center(
              child: Transform.scale(
                scale: _heartAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated hearts
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _rippleAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 80 + (_rippleAnimation.value * 40),
                                height: 80 + (_rippleAnimation.value * 40),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.pink.withOpacity(
                                      1 - _rippleAnimation.value,
                                    ),
                                    width: 3,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.pink, Colors.red.shade300],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.pink, Colors.purple],
                        ).createShader(bounds),
                        child: const Text(
                          "It's a Match!",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "You and $userName liked each other",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassmorphicButton(
                              "Keep Playing",
                              Icons.refresh,
                              Colors.grey,
                              () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildGlassmorphicButton(
                              "Start Chat",
                              Icons.chat_bubble,
                              Colors.blue,
                              () {
                                Navigator.of(context).pop();
                                _navigateToChat(userName);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassmorphicButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(String userName) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(userName: userName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _saveProfile(String userName) {
    setState(() {
      _savedProfiles.add(userName);
    });
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bookmark, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Profile Saved!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$userName added to your saved list',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _morphController.dispose();
    _heartController.dispose();
    _glowController.dispose();
    _rippleController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.0],
                  transform: GradientRotation(_shimmerAnimation.value * 0.1),
                ),
              ),
            );
          },
        ),
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.purple,
                        Colors.pink,
                        Colors.orange,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ).createShader(bounds),
                    child: const Text(
                      "Peer Matching",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    Positioned(
                      right: -30,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  const Icon(Icons.bookmark, color: Colors.white, size: 20),
                  if (_savedProfiles.isNotEmpty)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '${_savedProfiles.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            onPressed: () => _showSavedProfiles(),
          ),
        ],
      ),
      body: Stack(
  children: [
    // Enhanced animated background with images AND glassmorphic overlays
    AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: [
            // Base background images
            PageView.builder(
              controller: _pageController,
              itemCount: _backgroundImages.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _morphAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.1 + (_morphAnimation.value * 0.05),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(_backgroundImages[index]),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3),
                              BlendMode.overlay,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Glassmorphic color overlays on top of images
            // Glassmorphic color overlays on top of images
AnimatedBuilder(
  animation: _morphAnimation,
  builder: (context, child) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.withOpacity(0.4),
            Colors.blue.withOpacity(0.3),
            Colors.transparent,
            Colors.pink.withOpacity(0.2),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
          transform: GradientRotation(_morphAnimation.value * 0.3),
        ),
      ),
    );
  },
),

            // Additional glassmorphic layers
            AnimatedBuilder(
              animation: _morphAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5 + (_morphAnimation.value * 0.5),
                      colors: [
                        Colors.pink.withOpacity(0.3),
                        Colors.blue.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      radius: 1.2 + (sin(_rotationController.value * 2 * pi) * 0.3),
                      colors: [
                        Colors.blue.withOpacity(0.35),
                        Colors.pink.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Glassmorphic floating elements
            ...List.generate(6, (index) {
              final offset = index * 0.5;
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return Positioned(
                    left: 50 + (index * 70) + 
                          sin(_particleController.value * 2 * pi + offset) * 25,
                    top: 120 + (index * 90) + 
                         cos(_particleController.value * 2 * pi + offset) * 15,
                    child: Transform.rotate(
                      angle: _particleController.value * pi + offset,
                      child: Container(
                        width: 60 + (index % 2) * 20,
                        height: 60 + (index % 2) * 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.08),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (index.isEven ? Colors.blue : Colors.pink)
                                  .withOpacity(0.15),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Enhanced floating particles with glassmorphic effect
            ..._particles.map((particle) => AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Positioned(
                  left: particle.x +
                      sin(_particleController.value * 2 * pi + particle.phase) *
                          particle.amplitude,
                  top: particle.y +
                      cos(_particleController.value * 2 * pi + particle.phase) *
                          particle.amplitude * 0.5,
                  child: Transform.rotate(
                    angle: _particleController.value * 2 * pi + particle.phase,
                    child: Opacity(
                      opacity: (sin(_particleController.value * 2 * pi + particle.phase) + 1) /
                          2 * 0.5,
                      child: Container(
                        width: particle.size,
                        height: particle.size,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(particle.size / 3),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.4),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: particle.color.withOpacity(0.2),
                              blurRadius: particle.size * 0.6,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: particle.isHeart
                            ? Center(
                                child: Icon(
                                  Icons.favorite,
                                  size: particle.size * 0.6,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            )).toList(),

            // Final glassmorphic mesh overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.transparent,
                    Colors.white.withOpacity(0.04),
                  ],
                ),
              ),
            ),

            // Subtle color blend overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.blue.withOpacity(0.03),
                    Colors.pink.withOpacity(0.03),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ],
        );
      },
    ),

    // Enhanced card swiper
    AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 110, 16, 160),
              child: CardSwiper(
                controller: _cardController,
                cardsCount: profiles.length,
                cardBuilder: (context, index, _, __) => AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: profiles[index],
                    );
                  },
                ),
                allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                  horizontal: true,
                  vertical: false,
                ),
                onSwipe: (previousIndex, currentIndex, direction) {
                  final names = [
                    "Alex Chen", "Jordan Smith", "Riley Park", 
                    "Casey Williams", "Morgan Davis", "Taylor Kim",
                    "Avery Johnson", "Cameron Lee", "Drew Martinez", "Sage Wilson"
                  ];
                  
                  if (direction == CardSwiperDirection.right) {
                    _showAdvancedMatchAnimation(names[previousIndex]);
                  } else if (direction == CardSwiperDirection.left) {
                    _showPassAnimation();
                  }
                  return true;
                },
              ),
            ),
          ),
        );
      },
    ),

    // Premium action buttons with advanced effects
    Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAdvancedActionButton(
                  icon: Icons.info_outline,
                  color: Colors.blueGrey,
                  onTap: () => _showProfileInfo(),
                  tooltip: "Profile Info",
                ),
                _buildAdvancedActionButton(
                  icon: Icons.bookmark_border,
                  color: Colors.purple,
                  onTap: () => _saveCurrentProfile(),
                  tooltip: "Save Profile",
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.7 + 0.3,
                      child: _buildAdvancedActionButton(
                        icon: Icons.close,
                        color: Colors.red,
                        onTap: () {
                          _cardController.swipe(CardSwiperDirection.left);
                          _showPassAnimation();
                        },
                        big: true,
                        tooltip: "Pass",
                      ),
                    );
                  },
                ),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.7 + 0.3,
                      child: _buildAdvancedActionButton(
                        icon: Icons.favorite,
                        color: Colors.green,
                        onTap: () {
                          _cardController.swipe(CardSwiperDirection.right);
                          final names = [
                            "Alex Chen", "Jordan Smith", "Riley Park", 
                            "Casey Williams", "Morgan Davis", "Taylor Kim",
                            "Avery Johnson", "Cameron Lee", "Drew Martinez", "Sage Wilson"
                          ];
                          _showAdvancedMatchAnimation(names[0]);
                        },
                        big: true,
                        tooltip: "Like",
                      ),
                    );
                  },
                ),
                _buildAdvancedActionButton(
                  icon: Icons.star,
                  color: Colors.amber,
                  onTap: () => _showSuperLike(),
                  tooltip: "Super Like",
                ),
              ],
            ),
          );
        },
      ),
    ),
  
  
  
    // Enhanced floating stats with glassmorphism
    Positioned(
      top: MediaQuery.of(context).padding.top + 90,
      right: 20,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.people, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${profiles.length} nearby',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
          // Enhanced card swiper
          AnimatedBuilder(
            animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 110, 16, 160),
                    child: CardSwiper(
                      controller: _cardController,
                      cardsCount: profiles.length,
                      cardBuilder: (context, index, _, __) => AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: profiles[index],
                          );
                        },
                      ),
                      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                        horizontal: true,
                        vertical: false,
                      ),
                      onSwipe: (previousIndex, currentIndex, direction) {
                        final names = [
                          "Alex Chen", "Jordan Smith", "Riley Park", 
                          "Casey Williams", "Morgan Davis", "Taylor Kim",
                          "Avery Johnson", "Cameron Lee", "Drew Martinez", "Sage Wilson"
                        ];
                        
                        if (direction == CardSwiperDirection.right) {
                          _showAdvancedMatchAnimation(names[previousIndex]);
                        } else if (direction == CardSwiperDirection.left) {
                          _showPassAnimation();
                        }
                        return true;
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Premium action buttons with advanced effects
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAdvancedActionButton(
                        icon: Icons.info_outline,
                        color: Colors.blueGrey,
                        onTap: () => _showProfileInfo(),
                        tooltip: "Profile Info",
                      ),
                      _buildAdvancedActionButton(
                        icon: Icons.bookmark_border,
                        color: Colors.purple,
                        onTap: () => _saveCurrentProfile(),
                        tooltip: "Save Profile",
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 0.7 + 0.3,
                            child: _buildAdvancedActionButton(
                              icon: Icons.close,
                              color: Colors.red,
                              onTap: () {
                                _cardController.swipe(CardSwiperDirection.left);
                                _showPassAnimation();
                              },
                              big: true,
                              tooltip: "Pass",
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value * 0.7 + 0.3,
                            child: _buildAdvancedActionButton(
                              icon: Icons.favorite,
                              color: Colors.green,
                              onTap: () {
                                _cardController.swipe(CardSwiperDirection.right);
                                final names = [
                                  "Alex Chen", "Jordan Smith", "Riley Park", 
                                  "Casey Williams", "Morgan Davis", "Taylor Kim",
                                  "Avery Johnson", "Cameron Lee", "Drew Martinez", "Sage Wilson"
                                ];
                                _showAdvancedMatchAnimation(names[0]);
                              },
                              big: true,
                              tooltip: "Like",
                            ),
                          );
                        },
                      ),
                      _buildAdvancedActionButton(
                        icon: Icons.star,
                        color: Colors.amber,
                        onTap: () => _showSuperLike(),
                        tooltip: "Super Like",
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Enhanced floating stats with glassmorphism
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            right: 20,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.people, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${profiles.length} nearby',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
         if (_showMatchOverlay)
            AnimatedBuilder(
              animation: _heartAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.pink.withOpacity(0.3 * _heartAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: _heartAnimation.value * 2,
                      child: Icon(
                        Icons.favorite,
                        size: 100,
                        color: Colors.pink.withOpacity(0.8),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }



  Widget _buildAdvancedActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool big = false,
    String tooltip = '',
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: EdgeInsets.all(big ? 20 : 14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 20 + (_glowAnimation.value * 10),
                    spreadRadius: 3 + (_glowAnimation.value * 2),
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 5,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: big ? 40 : 28,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPassAnimation() {
    _slideController.reset();
    _slideController.forward();
    HapticFeedback.selectionClick();
  }

  void _showProfileInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProfileInfoSheet(),
    );
  }

  Widget _buildProfileInfoSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey.shade100,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Profile Details",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildInfoCard("Interests", "Music, Travel, Photography, Reading"),
                    _buildInfoCard("Looking for", "Long-term relationship"),
                    _buildInfoCard("Education", "University Graduate"),
                    _buildInfoCard("Work", "Software Developer"),
                    _buildInfoCard("Languages", "English, Spanish, French"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _saveCurrentProfile() {
    final names = [
      "Alex Chen", "Jordan Smith", "Riley Park", 
      "Casey Williams", "Morgan Davis", "Taylor Kim",
      "Avery Johnson", "Cameron Lee", "Drew Martinez", "Sage Wilson"
    ];
    _saveProfile(names[0]);
  }

  void _showSuperLike() {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.withOpacity(0.9),
                Colors.orange.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                "Super Like!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You've used a Super Like!\nThey'll be notified that you're interested.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavedProfiles() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "Saved Profiles",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _savedProfiles.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "No saved profiles yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _savedProfiles.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.purple.shade100,
                                child: Text(
                                  _savedProfiles[index][0],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  _savedProfiles[index],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _navigateToChat(_savedProfiles[index]),
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced ProfileCard with premium features
class ProfileCard extends StatefulWidget {
  final int index;
  const ProfileCard({super.key, required this.index});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moods = [
      {"label": "Energetic", "color": Colors.red, "icon": Icons.flash_on},
      {"label": "Reflective", "color": Colors.indigo, "icon": Icons.nightlight},
      {"label": "Melancholy", "color": Colors.blue, "icon": Icons.water_drop},
      {"label": "Joyful", "color": Colors.orange, "icon": Icons.wb_sunny},
      {"label": "Peaceful", "color": Colors.grey, "icon": Icons.bedtime},
      {"label": "Zen", "color": Colors.teal, "icon": Icons.self_improvement},
      {"label": "Creative", "color": Colors.purple, "icon": Icons.palette},
      {"label": "Adventurous", "color": Colors.green, "icon": Icons.explore},
      {"label": "Romantic", "color": Colors.pink, "icon": Icons.favorite},
      {"label": "Focused", "color": Colors.brown, "icon": Icons.center_focus_strong},
    ];

    final mood = moods[widget.index % moods.length];
    final names = [
      "Alex Chen", "Jordan Smith", "Riley Park", 
      "Casey Williams", "Morgan Davis", "Taylor Kim",
      "Avery Johnson", "Cameron Lee", "Drew Martinez", "Sage Wilson"
    ];
    
    final ages = [19, 20, 21, 22, 19, 20, 23, 21, 20, 22];
    final compatibilities = [87, 92, 78, 95, 83, 89, 91, 85, 94, 88];
    final distances = [0.5, 1.2, 0.8, 2.1, 1.5, 0.3, 1.8, 0.9, 1.1, 2.5];

    final profileImageUrl = 'https://picsum.photos/400/600?random=${widget.index}';

    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: (mood['color'] as Color).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Premium background image
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  mood['color'] as Color,
                                  (mood['color'] as Color).withOpacity(0.7),
                                  Colors.black.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  mood['color'] as Color,
                                  (mood['color'] as Color).withOpacity(0.7),
                                  Colors.black.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 120,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Enhanced gradient overlays
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Shimmer effect overlay
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-1.0, -1.0),
                            end: const Alignment(1.0, 1.0),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Enhanced content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top section with enhanced badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue.shade300,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Enhanced user info
                          Text(
                            "${names[widget.index]} • ${ages[widget.index]}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Enhanced mood indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  (mood['color'] as Color).withOpacity(0.3),
                                  (mood['color'] as Color).withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: (mood['color'] as Color).withOpacity(0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (mood['color'] as Color).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mood['icon'] as IconData,
                                  color: mood['color'] as Color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Feeling ${mood['label'] as String}",
                                  style: TextStyle(
                                    color: mood['color'] as Color,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Enhanced stats with better design
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildStatChip(
                                Icons.favorite,
                                "${compatibilities[widget.index]}% match",
                                Colors.pink,
                              ),
                              _buildStatChip(
                                Icons.location_on,
                                "${distances[widget.index]} km away",
                                Colors.blue,
                              ),
                              _buildStatChip(
                                Icons.school,
                                "Student",
                                Colors.green,
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
          );
        },
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced FloatingParticle with more variety
class FloatingParticle {
  late double x;
  late double y;
  late double size;
  late double phase;
  late double amplitude;
  late Color color;
  late bool isHeart;

  FloatingParticle() {
    final random = Random();
    x = random.nextDouble() * 400;
    y = random.nextDouble() * 800;
    size = random.nextDouble() * 4 + 2;
    phase = random.nextDouble() * 2 * pi;
    amplitude = random.nextDouble() * 40 + 20;
    isHeart = random.nextBool();
    
    final colors = [
      Colors.white,
      Colors.pink.shade200,
      Colors.blue.shade200,
      Colors.purple.shade200,
      Colors.yellow.shade200,
    ];
    color = colors[random.nextInt(colors.length)];
  }
}

// Premium Chat Screen
class ChatScreen extends StatefulWidget {
  final String userName;
  
  const ChatScreen({super.key, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Chat backgrounds
  final List<String> _chatBackgrounds = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?auto=format&fit=crop&w=1950&q=80',
    'https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?auto=format&fit=crop&w=1950&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();

    // Add initial bot messages
    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage("Hey! Thanks for matching with me! 👋");
    });
    
    Future.delayed(const Duration(milliseconds: 2000), () {
      _addBotMessage("I saw you're into ${_getRandomInterest()}. That's awesome!");
    });
  }

  String _getRandomInterest() {
    final interests = ['music', 'travel', 'photography', 'reading', 'hiking', 'cooking'];
    return interests[Random().nextInt(interests.length)];
  }

  void _addBotMessage(String text) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    final userMessage = _messageController.text;
    _messageController.clear();

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotResponse(userMessage);
    });
  }

  void _addBotResponse(String userMessage) {
    final responses = [
      "That's really interesting! Tell me more 😊",
      "I totally agree with that!",
      "Wow, we have so much in common!",
      "That sounds amazing! I'd love to hear more about it",
      "You seem like such a fun person to be around!",
      "I'm really enjoying our conversation!",
      "That's so cool! I've always wanted to try that too",
    ];

    final response = responses[Random().nextInt(responses.length)];
    _addBotMessage(response);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                'https://picsum.photos/100/100?random=${widget.userName.hashCode}',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Online",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.video_call, color: Colors.white, size: 20),
            ),
            onPressed: () => _startVideoCall(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Chat background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_chatBackgrounds[0]),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.overlay,
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 80,
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Message input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.blueAccent],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
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
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://picsum.photos/100/100?random=${widget.userName.hashCode}',
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: message.isUser
                      ? [Colors.blue, Colors.blueAccent]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser 
                      ? const Radius.circular(20) 
                      : const Radius.circular(4),
                  bottomRight: message.isUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.purpleAccent],
                ),
                border: Border.all(color: Colors.white, width: 2),
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
  }

  void _startVideoCall() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.9),
                Colors.teal.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.5),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_call,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                "Video Call",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Calling ${widget.userName}...",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Icon(
                      Icons.videocam_off,
                      size: 24,
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}