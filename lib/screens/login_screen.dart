import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Existing controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isFormVisible = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
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
      // ignore audio errors
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Login method with Supabase authentication
  Future<void> _login() async {
    if (!mounted) return;
    
    // Enhanced validation with animations
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _shakeForm();
      _showStatusSnackbar(
        'Please enter email and password',
        Colors.red,
        Icons.error,
      );
      return;
    }

    // Email format - simplified check
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.') || email.length < 5) {
      _shakeForm();
      _showStatusSnackbar(
        'Please enter a valid email',
        Colors.red,
        Icons.alternate_email,
      );
      return;
    }

    // Password min length
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
      
      // Use Supabase authentication to sign in the user
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        _showSuccessAnimation();
        _showStatusSnackbar(
          'Welcome back ${authProvider.userDisplayName}!',
          Colors.green,
          Icons.check_circle,
        );

        // Navigate to home screen
        Future.delayed(const Duration(milliseconds: 1200), () {
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
        _showStatusSnackbar(
          authProvider.errorMessage ?? 'Login failed. Please try again.',
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
    _emailController.dispose();
    _passwordController.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();

    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
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
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.white, width: 2),
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
                  ..._particles
                      .map(
                        (particle) => AnimatedBuilder(
                          animation: _particleController,
                          builder: (context, child) {
                            return Positioned(
                              left: particle.x +
                                  sin(_particleController.value * 2 * pi +
                                          particle.phase) *
                                      particle.amplitude,
                              top: particle.y +
                                  cos(_particleController.value * 2 * pi +
                                          particle.phase) *
                                      particle.amplitude,
                              child: Opacity(
                                opacity: (sin(
                                              _particleController.value *
                                                      2 *
                                                      pi +
                                                  particle.phase,
                                            ) +
                                        1) /
                                    2 *
                                    0.6,
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
                      )
                      .toList(),
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
                      Colors.purple
                          .withOpacity(0.4 + sin(_rotationController.value) * 0.1),
                      Colors.blue
                          .withOpacity(0.3 + cos(_rotationController.value) * 0.1),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_fadeAnimation, _slideAnimation, _scaleAnimation]),
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
                                        Icons.login,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Enhanced Title
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.blue,
                                    Colors.purple
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Text(
                                  "Welcome Back",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Sign in to continue your journey",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Enhanced Form Fields
                              SizedBox(
                                width: 320,
                                child: Column(
                                  children: [
                                    // Email Field
                                    TextField(
                                      controller: _emailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration(
                                          "Email *", Icons.alternate_email),
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Field
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration(
                                          "Password *", Icons.lock),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Enhanced Login Button
                              SizedBox(
                                width: 280,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
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
                                          color: Colors.purple
                                              .withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Text("Signing In..."),
                                              ],
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.login),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Sign In",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Register Link
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.8)),
                                    children: [
                                      const TextSpan(
                                          text: "Don't have an account? "),
                                      TextSpan(
                                        text: "Register",
                                        style: TextStyle(
                                          color: Colors.blue.shade300,
                                          fontWeight: FontWeight.bold,
                                          decoration:
                                              TextDecoration.underline,
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
}

// Password field widget with visibility toggle
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;

  const _PasswordField({
    required this.controller,
    required this.decoration,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: widget.decoration.copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white),
          onPressed: () {
            setState(() => _obscure = !_obscure);
          },
        ),
      ),
    );
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