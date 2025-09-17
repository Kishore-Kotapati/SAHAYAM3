import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  String _mood = 'Happy';
  bool _isLoading = false;
  bool _isFormVisible = false;
  bool _isPasswordVisible = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _titleController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _titleAnimation;

  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
    'https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0',
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
    'https://images.unsplash.com/photo-1503264116251-35a269479413',
    'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _carouselTimer;

  // Floating particles
  final List<FloatingParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
    
    // Use WidgetsBinding to ensure operations happen after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playBackgroundSound();
      _startAutoScroll();
      _startAnimations();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _titleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );
  }

  void _initializeParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(FloatingParticle());
    }
  }

  void _startAnimations() {
    if (!mounted) return;
    
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _rotationController.repeat();
    _particleController.repeat();
    _titleController.repeat(reverse: true);
    
    if (mounted) {
      setState(() {
        _isFormVisible = true;
      });
    }
  }

  void _startAutoScroll() {
    if (!mounted) return;
    
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _backgroundImages.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _playBackgroundSound() async {
    if (!mounted) return;
    
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.3);
      await _audioPlayer.play(
        UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      );
    } catch (e) {
      print('Audio playback failed: $e');
    }
  }

  // Updated registration method with Supabase authentication
  Future<void> _register() async {
    if (!mounted) return;
    
    // Enhanced validation with animations
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _shakeForm();
      _showStatusSnackbar(
        'Please fill all required fields',
        Colors.red,
        Icons.error,
      );
      return;
    }

    // Email validation - debug version
    final email = _emailController.text.trim();
    print('Debug - Email entered: "$email"');
    print('Debug - Email length: ${email.length}');
    print('Debug - Contains @: ${email.contains('@')}');
    print('Debug - Contains .: ${email.contains('.')}');
    
    // Skip email validation for now to test registration
    // if (!email.contains('@') || !email.contains('.') || email.length < 5) {
    //   _shakeForm();
    //   _showStatusSnackbar(
    //     'Please enter a valid email address',
    //     Colors.red,
    //     Icons.email,
    //   );
    //   return;
    // }

    // Age validation
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 13 || age > 120) {
      _shakeForm();
      _showStatusSnackbar(
        'Please enter a valid age (13-120)',
        Colors.red,
        Icons.cake,
      );
      return;
    }

    // Password validation
    if (_passwordController.text.length < 6) {
      _shakeForm();
      _showStatusSnackbar(
        'Password must be at least 6 characters',
        Colors.red,
        Icons.lock,
      );
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Use Supabase authentication to register the user
      final success = await authProvider.register(
        fullName: _nameController.text.trim(),
        email: email,
        password: _passwordController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        mood: _mood,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        _showSuccessAnimation();
        _showStatusSnackbar(
          'Welcome ${authProvider.userDisplayName}! Registration successful.',
          Colors.green,
          Icons.check_circle,
        );
        
        // Navigate to home screen with user data
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: authProvider.currentUser,
            );
          }
        });
      } else {
        _shakeForm();
        final errorMsg = authProvider.errorMessage ?? 'Registration failed. Please try again.';
        print('Debug - Registration failed with error: $errorMsg');
        _showStatusSnackbar(
          errorMsg,
          Colors.red,
          Icons.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      _shakeForm();
      _showStatusSnackbar(
        'Network error: Please check your connection and try again',
        Colors.red,
        Icons.signal_wifi_off,
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  void _shakeForm() {
    if (!mounted) return;
    _slideController.reset();
    _slideController.forward();
  }

  void _showSuccessAnimation() {
    if (!mounted) return;
    _scaleController.reset();
    _scaleController.forward();
  }

  void _showStatusSnackbar(String message, Color color, IconData icon) {
    if (!mounted) return;
    
    // Use addPostFrameCallback to ensure ScaffoldMessenger is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();
    
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background with parallax effect
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return Stack(
                children: [
                  // PageView Background
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _backgroundImages.length,
                    itemBuilder: (context, index) {
                      return Transform.scale(
                        scale: 1.1,
                        child: Image.network(
                          _backgroundImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    },
                  ),
                  
                  // Animated particles
                  ..._particles.map((particle) => 
                    AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        return Positioned(
                          left: particle.x + sin(_particleController.value * 2 * pi + particle.phase) * particle.amplitude,
                          top: particle.y + cos(_particleController.value * 2 * pi + particle.phase) * particle.amplitude,
                          child: Opacity(
                            opacity: (sin(_particleController.value * 2 * pi + particle.phase) + 1) / 2 * 0.6,
                            child: Container(
                              width: particle.size,
                              height: particle.size,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).toList(),
                ],
              );
            },
          ),

          // Enhanced gradient overlay with animated colors
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.purple.withOpacity(0.4 + sin(_rotationController.value) * 0.1),
                      Colors.blue.withOpacity(0.3 + cos(_rotationController.value) * 0.1),
                      Colors.black.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),

          // Animated Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: AnimatedBuilder(
                animation: Listenable.merge([_fadeAnimation, _slideAnimation, _scaleAnimation]),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated Logo/Icon
                              AnimatedBuilder(
                                animation: _rotationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotationController.value * 0.1,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // SMOOTH AND OPTIMIZED TITLE
                              AnimatedBuilder(
                                animation: _titleAnimation,
                                builder: (context, child) {
                                  final glowIntensity = 0.6 + 0.4 * sin(_titleAnimation.value * 2 * pi);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                    child: Column(
                                      children: [
                                        // Main title with simple gradient and glow
                                        ShaderMask(
                                          shaderCallback: (bounds) => LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.cyan.withOpacity(0.9),
                                              Colors.purple.withOpacity(0.9),
                                              Colors.white,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                          child: Text(
                                            "SAHAYAM",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Cursive',
                                              fontSize: 42,
                                              fontWeight: FontWeight.w700,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.white,
                                              letterSpacing: 1.5,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white.withOpacity(glowIntensity * 0.8),
                                                  blurRadius: 20,
                                                ),
                                                Shadow(
                                                  color: Colors.cyan.withOpacity(glowIntensity * 0.6),
                                                  blurRadius: 15,
                                                  offset: const Offset(-2, -1),
                                                ),
                                                Shadow(
                                                  color: Colors.purple.withOpacity(glowIntensity * 0.6),
                                                  blurRadius: 15,
                                                  offset: const Offset(2, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Simple animated underline
                                        Container(
                                          height: 2,
                                          width: 200 + sin(_titleAnimation.value * 2 * pi) * 20,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(1),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.cyan.withOpacity(glowIntensity * 0.8),
                                                Colors.purple.withOpacity(glowIntensity * 0.8),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(height: 12),
                              // Enhanced subtitle with glow
                              AnimatedBuilder(
                                animation: _titleAnimation,
                                builder: (context, child) {
                                  final subtitleGlow = 0.6 + 0.4 * sin(_titleAnimation.value * 2 * pi);
                                  return Text(
                                    "Connect with others who understand",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w400,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white.withOpacity(subtitleGlow * 0.5),
                                          blurRadius: 8,
                                        ),
                                        Shadow(
                                          color: Colors.blue.withOpacity(subtitleGlow * 0.3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                              const SizedBox(height: 32),

                              // Enhanced Form Fields
                              SizedBox(
                                width: 320,
                                child: Column(
                                  children: [
                                    // Name Field
                                    TextField(
                                      controller: _nameController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Full Name *", Icons.person),
                                    ),
                                    const SizedBox(height: 20),

                                    // Email Field
                                    TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Email Address *", Icons.email),
                                    ),
                                    const SizedBox(height: 20),

                                    // Age Field
                                    TextField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Age *", Icons.cake),
                                    ),
                                    const SizedBox(height: 20),

                                    // Enhanced Gender Dropdown
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _gender,
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                          isExpanded: true,
                                          dropdownColor: Colors.black.withOpacity(0.8),
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                          items: <String>[
                                            'Male',
                                            'Female',
                                            'Non-binary',
                                            'Prefer not to say'
                                          ].map((value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getGenderIcon(value),
                                                    color: Colors.white.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(value),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() => _gender = value!);
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Mood Dropdown
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _mood,
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                          isExpanded: true,
                                          dropdownColor: Colors.black.withOpacity(0.8),
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                          items: <String>[
                                            'Happy',
                                            'Sad', 
                                            'Excited',
                                            'Calm',
                                            'Anxious',
                                            'Romantic',
                                            'Adventurous',
                                            'Peaceful'
                                          ].map((value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getMoodIcon(value),
                                                    color: _getMoodColor(value),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(value),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() => _mood = value!);
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Password Field
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration(
                                        "Password *",
                                        Icons.lock,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),

                              // Enhanced Register Button
                              SizedBox(
                                width: 280,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _isLoading
                                            ? [Colors.grey, Colors.grey]
                                            : [
                                                Colors.purple.shade400,
                                                Colors.blue.shade400,
                                                Colors.purple.shade400,
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text("Creating Account..."),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.favorite),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Join MoodMatch",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login Link
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                    children: [
                                      const TextSpan(text: "Already have an account? "),
                                      TextSpan(
                                        text: "Login",
                                        style: TextStyle(
                                          color: Colors.blue.shade300,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              Text(
                                "* Required fields",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'Male':
        return Icons.male;
      case 'Female':
        return Icons.female;
      case 'Non-binary':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Sad':
        return Icons.sentiment_very_dissatisfied;
      case 'Excited':
        return Icons.celebration;
      case 'Calm':
        return Icons.spa;
      case 'Anxious':
        return Icons.psychology;
      case 'Romantic':
        return Icons.favorite;
      case 'Adventurous':
        return Icons.explore;
      case 'Peaceful':
        return Icons.self_improvement;
      default:
        return Icons.mood;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.yellow;
      case 'Sad':
        return Colors.blue;
      case 'Excited':
        return Colors.orange;
      case 'Calm':
        return Colors.green;
      case 'Anxious':
        return Colors.purple;
      case 'Romantic':
        return Colors.pink;
      case 'Adventurous':
        return Colors.red;
      case 'Peaceful':
        return Colors.teal;
      default:
        return Colors.white;
    }
  }
}

// Floating particle class for background animation
class FloatingParticle {
  late double x;
  late double y;
  late double size;
  late double phase;
  late double amplitude;

  FloatingParticle() {
    final random = Random();
    x = random.nextDouble() * 400;
    y = random.nextDouble() * 800;
    size = random.nextDouble() * 4 + 2;
    phase = random.nextDouble() * 2 * pi;
    amplitude = random.nextDouble() * 50 + 25;
  }
}