
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'mood_screen.dart';
import 'match_screen.dart';
import 'material_screen.dart';
import 'maps_screen.dart';
import 'mission_screen.dart';
import 'matching_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _index = 0;
  late AnimationController _backgroundController;
  late AnimationController _fabController;
  late AnimationController _navController;
  late AnimationController _dragController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _navAnimation;
  late Animation<double> _dragAnimation;

  // Draggable FAB position and state - positioned in bottom-right corner
  Offset _fabPosition = const Offset(300, 600); // Bottom-right area (will be adjusted based on screen size)
  bool _isDragging = false;
  bool _isLongPressing = false;
  bool _canDrag = false;

  final _pages = const [
    MoodScreen(),
    MatchingScreen(), // Updated to use the new mood-based matching screen
    MaterialScreen(),
    MapsScreen(),
    MissionScreen(),
  ];

  final _labels = const ['Mood', 'Match', 'Material', 'Maps', 'Mission'];
  final _icons = const [
    Icons.emoji_emotions_outlined,
    Icons.favorite_outline, // Changed to heart icon for mood matching
    Icons.auto_stories_outlined,
    Icons.map_outlined,
    Icons.check_circle_outline,
  ];

  final _selectedIcons = const [
    Icons.emoji_emotions,
    Icons.forum,
    Icons.auto_stories,
    Icons.map,
    Icons.check_circle,
  ];

  final _gradients = const [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFfee140)],
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Set initial FAB position after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialFABPosition();
    });
  }

  void _setInitialFABPosition() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    setState(() {
      // Position FAB in bottom-right corner with some margin
      _fabPosition = Offset(
        screenWidth - 100, // 100px from right edge
        screenHeight - 180, // 180px from bottom (above bottom nav)
      );
    });
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _navAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _navController, curve: Curves.easeOutCubic),
    );
    _dragAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _dragController, curve: Curves.easeOutBack),
    );

    _backgroundController.repeat();
    _fabController.forward();
    _navController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _fabController.dispose();
    _navController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  // Helper function to clamp opacity values
  double _clampOpacity(double value) {
    return value.clamp(0.0, 1.0);
  }

  // Helper function to get dynamic FAB icon based on current mode
  IconData _getFABIcon() {
    const fabIcons = [
      Icons.mood_rounded,        // Mood
      Icons.chat_bubble_rounded, // Match
      Icons.library_books_rounded, // Material
      Icons.explore_rounded,     // Maps
      Icons.rocket_launch_rounded, // Mission
    ];
    return fabIcons[_index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: PageTransitionSwitcher(
        transitionBuilder: (child, animation, secondaryAnimation) =>
            SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        ),
        child: Container(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: _buildGlassmorphicBottomNav(),
    );
  }

  Widget _buildLongPressDraggableFAB() {
    return Positioned(
      left: _fabPosition.dx - 32.5, // Center the FAB (65/2 = 32.5)
      top: _fabPosition.dy - 32.5,
      child: GestureDetector(
        // Long press to activate dragging
        onLongPressStart: (details) {
          setState(() {
            _isLongPressing = true;
            _canDrag = true;
          });
          _dragController.forward();
          HapticFeedback.mediumImpact();
        },
        
        // Start dragging after long press
        onPanStart: (details) {
          if (_canDrag) {
            setState(() {
              _isDragging = true;
            });
            HapticFeedback.lightImpact();
          }
        },
        
        // Update position while dragging
        onPanUpdate: (details) {
          if (_canDrag && _isDragging) {
            setState(() {
              // Get screen bounds
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              
              // Update position with bounds checking
              // Allowing FAB to be positioned anywhere on screen with reasonable margins
              double newX = (details.globalPosition.dx).clamp(50.0, screenWidth - 50.0);
              double newY = (details.globalPosition.dy).clamp(120.0, screenHeight - 140.0); // Top margin for app bar, bottom margin for nav
              
              _fabPosition = Offset(newX, newY);
            });
            HapticFeedback.selectionClick();
          }
        },
        
        // End dragging
        onPanEnd: (details) {
          if (_canDrag) {
            setState(() {
              _isDragging = false;
              _isLongPressing = false;
              _canDrag = false;
            });
            _dragController.reverse();
            HapticFeedback.mediumImpact();
          }
        },
        
        // Cancel long press
        onLongPressCancel: () {
          setState(() {
            _isLongPressing = false;
            _canDrag = false;
            _isDragging = false;
          });
          _dragController.reverse();
        },
        
        // Handle tap when not dragging
        onTap: () {
          if (!_canDrag && !_isDragging && !_isLongPressing) {
            HapticFeedback.mediumImpact();
            _showAdvancedQuickActions();
          }
        },
        
        child: AnimatedBuilder(
          animation: Listenable.merge([_fabAnimation, _dragAnimation]),
          builder: (context, child) {
            final scale = _dragAnimation.value;
            final baseSize = _isDragging ? 75.0 : 65.0;
            final scaledSize = baseSize * scale;
            
            return AnimatedContainer(
              duration: Duration(milliseconds: _isDragging ? 0 : 300),
              curve: Curves.easeOutCubic,
              width: scaledSize,
              height: scaledSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(_clampOpacity(
                      _isLongPressing || _isDragging ? 0.5 : 0.3
                    )),
                    Colors.white.withOpacity(_clampOpacity(
                      _isLongPressing || _isDragging ? 0.3 : 0.1
                    )),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_clampOpacity(
                      _isDragging ? 0.4 : _isLongPressing ? 0.3 : 0.2
                    )),
                    blurRadius: _isDragging ? 30 : _isLongPressing ? 25 : 20,
                    spreadRadius: _isDragging ? 5 : _isLongPressing ? 3 : 2,
                    offset: Offset(0, _isDragging ? 12 : _isLongPressing ? 10 : 8),
                  ),
                  BoxShadow(
                    color: _gradients[_index][0].withOpacity(_clampOpacity(
                      _isDragging ? 0.5 : _isLongPressing ? 0.4 : 0.2
                    )),
                    blurRadius: _isDragging ? 25 : _isLongPressing ? 20 : 15,
                    spreadRadius: _isDragging ? 3 : _isLongPressing ? 2 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(_clampOpacity(
                            _isLongPressing || _isDragging ? 0.6 : 0.3
                          )),
                          width: _isLongPressing || _isDragging ? 2.5 : 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing ring effect when long pressing or dragging
                          if (_isLongPressing || _isDragging)
                            AnimatedBuilder(
                              animation: _backgroundAnimation,
                              builder: (context, child) {
                                final pulseSize = 60 + 15 * math.sin(_backgroundAnimation.value * 6 * math.pi);
                                final pulseOpacity = _clampOpacity(
                                  0.4 + 0.3 * math.sin(_backgroundAnimation.value * 6 * math.pi)
                                );
                                
                                return Container(
                                  width: pulseSize,
                                  height: pulseSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(pulseOpacity),
                                      width: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          // Secondary pulsing ring for enhanced effect
                          if (_isDragging)
                            AnimatedBuilder(
                              animation: _backgroundAnimation,
                              builder: (context, child) {
                                final outerPulseSize = 70 + 20 * math.sin(
                                  _backgroundAnimation.value * 4 * math.pi + math.pi / 2
                                );
                                final outerPulseOpacity = _clampOpacity(
                                  0.2 + 0.2 * math.sin(
                                    _backgroundAnimation.value * 4 * math.pi + math.pi / 2
                                  )
                                );
                                
                                return Container(
                                  width: outerPulseSize,
                                  height: outerPulseSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _gradients[_index][1].withOpacity(outerPulseOpacity),
                                      width: 1.5,
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          // Main icon with enhanced animations
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return RotationTransition(
                                turns: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              _isDragging || _isLongPressing 
                                  ? Icons.open_with_rounded 
                                  : _getFABIcon(),
                              key: ValueKey(
                                _isDragging || _isLongPressing ? 'dragging' : _index
                              ),
                              size: (_isDragging || _isLongPressing) ? 35 : 30,
                              color: Colors.white,
                            ),
                          ),
                          
                          // Visual feedback overlay
                          if (_isLongPressing && !_isDragging)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(_clampOpacity(0.1)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        final animValue = _backgroundAnimation.value;
        final stopValue = 0.5 + 0.3 * math.sin(animValue * 2 * math.pi);
        final clampedStop = stopValue.clamp(0.0, 1.0);
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _gradients[_index][0].withOpacity(_clampOpacity(0.8)),
                _gradients[_index][1].withOpacity(_clampOpacity(0.6)),
                _gradients[(_index + 1) % _gradients.length][0].withOpacity(_clampOpacity(0.4)),
              ],
              stops: [
                0.0,
                clampedStop,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated orbs - reduced size by 30%
              Positioned(
                top: 100 + 35 * math.sin(animValue * 2 * math.pi), // 50 -> 35 (30% reduction)
                right: 50 + 21 * math.cos(animValue * 1.5 * math.pi), // 30 -> 21 (30% reduction)
                child: _buildGlowingOrb(105, Colors.white.withOpacity(_clampOpacity(0.1))), // 150 -> 105 (30% reduction)
              ),
              Positioned(
                bottom: 200 + 21 * math.cos(animValue * 1.8 * math.pi), // 30 -> 21 (30% reduction)
                left: 30 + 28 * math.sin(animValue * 2.2 * math.pi), // 40 -> 28 (30% reduction)
                child: _buildGlowingOrb(140, Colors.white.withOpacity(_clampOpacity(0.05))), // 200 -> 140 (30% reduction)
              ),
              Positioned(
                top: 300 + 14 * math.sin(animValue * 3 * math.pi), // 20 -> 14 (30% reduction)
                left: 200 + 17.5 * math.cos(animValue * 2.5 * math.pi), // 25 -> 17.5 (30% reduction)
                child: _buildGlowingOrb(70, Colors.white.withOpacity(_clampOpacity(0.08))), // 100 -> 70 (30% reduction)
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowingOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Stack(
          children: List.generate(15, (index) {
            final offset = _backgroundAnimation.value * 2 * math.pi + index * 0.5;
            final opacityValue = _clampOpacity(0.3 + 0.4 * math.sin(offset));
            
            return Positioned(
              left: 50 + (screenWidth - 100) * 
                     ((math.sin(offset * 0.8 + index) + 1) / 2),
              top: 100 + (screenHeight - 200) * 
                    ((math.cos(offset * 0.6 + index * 1.5) + 1) / 2),
              child: Container(
                width: (4 + index % 6).toDouble(),
                height: (4 + index % 6).toDouble(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(opacityValue),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(_clampOpacity(0.3)),
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

  Widget _buildGlassmorphicAppBar() {
    return Container(
      height: 77, // Increased from 67 by 15% (67 * 1.15 = 77.05 ≈ 77)
      margin: const EdgeInsets.fromLTRB(16, 50, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21), // Increased from 18 by 15% (18 * 1.15 = 20.7 ≈ 21)
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(_clampOpacity(0.25)),
                  Colors.white.withOpacity(_clampOpacity(0.1)),
                ],
              ),
              borderRadius: BorderRadius.circular(21), // Increased from 18 by 15%
              border: Border.all(
                color: Colors.white.withOpacity(_clampOpacity(0.3)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gradients[_index][0].withOpacity(_clampOpacity(0.2)),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Enhanced shimmer effect
                AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: -120 + 350 * _backgroundAnimation.value,
                      child: Container(
                        width: 120,
                        height: 77, // Updated to match new app bar height
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(_clampOpacity(0.4)),
                              Colors.white.withOpacity(_clampOpacity(0.6)),
                              Colors.white.withOpacity(_clampOpacity(0.4)),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Animated background orbs
                AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          right: 10 + 8 * math.sin(_backgroundAnimation.value * 2 * math.pi),
                          top: 15 + 5 * math.cos(_backgroundAnimation.value * 1.5 * math.pi),
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _gradients[_index][1].withOpacity(_clampOpacity(0.3)),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 15 + 6 * math.cos(_backgroundAnimation.value * 2.2 * math.pi),
                          bottom: 10 + 4 * math.sin(_backgroundAnimation.value * 1.8 * math.pi),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _gradients[_index][0].withOpacity(_clampOpacity(0.25)),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: RotationTransition(
                              turns: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(_index),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(_clampOpacity(0.2)),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Icon(
                            _selectedIcons[_index],
                            size: 25, // Increased from 22 by 15% (22 * 1.15 = 25.3 ≈ 25)
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7), // Increased from 6 by 15% (6 * 1.15 = 6.9 ≈ 7)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _labels[_index],
                          key: ValueKey(_index),
                          style: GoogleFonts.poppins(
                            fontSize: 13, // Increased from 11 by 15% (11 * 1.15 = 12.65 ≈ 13)
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(_clampOpacity(0.3)),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                              Shadow(
                                color: _gradients[_index][0].withOpacity(_clampOpacity(0.5)),
                                offset: const Offset(0, 0),
                                blurRadius: 8,
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
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicBottomNav() {
    return AnimatedBuilder(
      animation: _navAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _navAnimation.value)),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: 14 + (MediaQuery.of(context).size.width * 0.37 * 0.5), // Increased horizontal margin to center the shortened bar
              vertical: 14,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21), // Reduced from 30 by 30% (30 * 0.7 = 21)
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 56, // Increased from 46 to accommodate labels (46 * 1.2 = 55.2 ≈ 56)
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(_clampOpacity(0.2)),
                        Colors.white.withOpacity(_clampOpacity(0.05)),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(21), // Reduced from 30 by 30%
                    border: Border.all(
                      color: Colors.white.withOpacity(_clampOpacity(0.3)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_labels.length, (i) {
                      final isSelected = i == _index;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _index = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, // Increased from 11 to accommodate new height (11 * 1.1 ≈ 12)
                            vertical: 4, // Reduced to accommodate label text
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14), // Reduced from 20 by 30% (20 * 0.7 = 14)
                            color: isSelected 
                                ? Colors.white.withOpacity(_clampOpacity(0.25))
                                : Colors.transparent,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _gradients[i][0].withOpacity(_clampOpacity(0.3)),
                                      blurRadius: 10, // Reduced from 15 by 30% (15 * 0.7 = 10.5 ≈ 10)
                                      spreadRadius: 1, // Reduced from 2 by 50%
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected ? _selectedIcons[i] : _icons[i],
                                  key: ValueKey('${i}_$isSelected'),
                                  size: isSelected ? 15 : 13, // Reduced from 21:19 by 30% (21*0.7=14.7≈15, 19*0.7=13.3≈13)
                                  color: isSelected 
                                      ? Colors.white 
                                      : Colors.white.withOpacity(_clampOpacity(0.6)),
                                ),
                              ),
                              const SizedBox(height: 2), // Small gap between icon and label
                              // Always show label with animation
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: GoogleFonts.poppins(
                                  fontSize: isSelected ? 9 : 8, // Small font size for labels
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected 
                                      ? Colors.white 
                                      : Colors.white.withOpacity(_clampOpacity(0.6)),
                                ),
                                child: Text(
                                  _labels[i],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 2), // Small gap before indicator
                                Container(
                                  height: 2, // Reduced from 3 by 30% (3 * 0.7 = 2.1 ≈ 2)
                                  width: 14, // Reduced from 20 by 30% (20 * 0.7 = 14)
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(1), // Reduced from 2 by 50%
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(_clampOpacity(0.6)),
                                        blurRadius: 6, // Reduced from 8 by 25%
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAdvancedQuickActions() {
    showModal(
      context: context,
      builder: (context) => _buildAdvancedQuickActions(),
    );
  }

  Widget _buildAdvancedQuickActions() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(_clampOpacity(0.25)),
                Colors.white.withOpacity(_clampOpacity(0.1)),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(_clampOpacity(0.3)),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Quick Actions",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(_clampOpacity(0.2)),
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
              const SizedBox(height: 25),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: const [
                  _AdvancedQuickAction(
                    icon: Icons.search_rounded,
                    label: "Search",
                    gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  _AdvancedQuickAction(
                    icon: Icons.notifications_active_rounded,
                    label: "Alerts",
                    gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
                  ),
                  _AdvancedQuickAction(
                    icon: Icons.settings_rounded,
                    label: "Settings",
                    gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  _AdvancedQuickAction(
                    icon: Icons.favorite_rounded,
                    label: "Favorites",
                    gradient: [Color(0xFFfa709a), Color(0xFFfee140)],
                  ),
                  _AdvancedQuickAction(
                    icon: Icons.share_rounded,
                    label: "Share",
                    gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                  ),
                  _AdvancedQuickAction(
                    icon: Icons.help_rounded,
                    label: "Help",
                    gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
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

class _AdvancedQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;

  const _AdvancedQuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
        // Add your action logic here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label action triggered'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: gradient[0],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient.map((c) => c.withOpacity(0.3)).toList(),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}