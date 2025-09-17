import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/matching_service.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _potentialMatches = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    print('MatchingScreen initialized');
    _initializeAnimations();
    
    // Delay to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPotentialMatches();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadPotentialMatches() async {
    print('Starting to load potential matches...');
    
    if (!mounted) {
      print('Widget not mounted, returning');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Test connection first
      final connectionTest = await MatchingService.checkConnection();
      if (!connectionTest) {
        throw Exception('Unable to connect to the server. Please check your internet connection.');
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      print('Current user: ${currentUser != null ? "Found" : "NULL"}');
      
      if (currentUser == null) {
        throw Exception('Please log in to find matches');
      }
      
      if (currentUser['id'] == null) {
        throw Exception('User session is invalid. Please log in again.');
      }

      print('Calling findPotentialMatches with mood: ${currentUser['mood']}, userId: ${currentUser['id']}');
      
      final matches = await MatchingService.findPotentialMatches(
        currentUser['mood'] ?? 'Happy',
        currentUser['id'],
      );
      
      print('Received ${matches.length} matches');
      
      if (mounted) {
        setState(() {
          _potentialMatches = matches;
          _isLoading = false;
          _errorMessage = null;
        });
        print('UI updated with matches');
      }

      // Update online status (don't block UI if this fails)
      try {
        await MatchingService.updateOnlineStatus(currentUser['id'], true);
        print('Online status updated');
      } catch (statusError) {
        print('Failed to update online status (non-critical): $statusError');
      }
      
    } catch (e) {
      print('Error in _loadPotentialMatches: $e');
      
      // CRITICAL: Always stop loading, even on error
      if (mounted) {
        setState(() {
          _isLoading = false;
          _potentialMatches = [];
          _errorMessage = e.toString();
        });
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load matches: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadPotentialMatches(),
            ),
          ),
        );
      }
    }
  }

  void _onSwipeLeft() {
    _animateCard(() {
      _nextCard();
    });
  }

  void _onSwipeRight() async {
    print('Swiping right...');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        print('Current user is null in _onSwipeRight');
        return;
      }
      
      if (_currentIndex >= _potentialMatches.length) {
        print('Index out of bounds: $_currentIndex >= ${_potentialMatches.length}');
        return;
      }

      final targetUser = _potentialMatches[_currentIndex];
      print('Creating match between ${currentUser['id']} and ${targetUser['id']}');
      
      final matchId = await MatchingService.createMatch(
        currentUser['id'],
        targetUser['id'],
      );

      print('Match result: $matchId');

      if (matchId != null && mounted) {
        _showMatchDialog(targetUser, matchId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create match. Please try again.'),
            backgroundColor: Colors.orange.shade600,
          ),
        );
      }
      
    } catch (e) {
      print('Error in _onSwipeRight: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create match: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
    
    _animateCard(() {
      _nextCard();
    });
  }

  void _animateCard(VoidCallback onComplete) {
    _animationController.forward().then((_) {
      onComplete();
      _animationController.reverse();
    });
  }

  void _nextCard() {
    setState(() {
      _currentIndex++;
      if (_currentIndex >= _potentialMatches.length) {
        _loadPotentialMatches(); // Reload when we run out of cards
        _currentIndex = 0;
      }
    });
  }

  void _showMatchDialog(Map<String, dynamic> matchedUser, String matchId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade400, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "It's a Match!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You and ${matchedUser['full_name']} both have the same mood: ${matchedUser['mood']}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 175, 12, 239).withOpacity(0.2),
                        foregroundColor: const Color.fromARGB(255, 231, 229, 229),
                      ),
                      child: const Text("Keep Swiping"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              matchId: matchId,
                              otherUser: matchedUser,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 195, 12, 220),
                        foregroundColor: const Color.fromARGB(255, 241, 240, 243),
                      ),
                      child: const Text("Start Chat"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mood Matching',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade400, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPotentialMatches,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 3, 189, 214), const Color.fromARGB(255, 3, 74, 71)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _potentialMatches.isEmpty
                    ? _buildNoMatchesView()
                    : _buildSwipeView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadPotentialMatches,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 80,
            color: const Color.fromARGB(255, 239, 8, 201),
          ),
          const SizedBox(height: 20),
          Text(
            'No matches found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try changing your mood or check back later!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _loadPotentialMatches,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeView() {
    if (_potentialMatches.isEmpty || _currentIndex >= _potentialMatches.length) {
      return const Center(child: Text('No more matches'));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 50, 20, 100),
      child: Stack(
        children: [
          // Background cards
          for (int i = _currentIndex + 1; 
               i < min(_currentIndex + 3, _potentialMatches.length); 
               i++)
            _buildStackedCard(_potentialMatches[i], i - _currentIndex),
          
          // Current card
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: _buildStackedCard(_potentialMatches[_currentIndex], 0),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStackedCard(Map<String, dynamic> user, int stackIndex) {
    final offset = stackIndex * 8.0;
    final scale = 1.0 - (stackIndex * 0.05);
    
    return Transform.translate(
      offset: Offset(offset, offset),
      child: Transform.scale(
        scale: scale,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.pink.withOpacity(0.1),
                  Colors.blue.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image placeholder
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          _getMoodColor(user['mood'] ?? 'Happy').withOpacity(0.3),
                          _getMoodColor(user['mood'] ?? 'Happy').withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: _getMoodColor(user['mood'] ?? 'Happy'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // User info with action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['full_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Heart button (like)
                      GestureDetector(
                        onTap: () => _onSwipeRight(),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Cross button (pass)
                      GestureDetector(
                        onTap: () => _onSwipeLeft(),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        _getMoodIcon(user['mood'] ?? 'Happy'),
                        color: _getMoodColor(user['mood'] ?? 'Happy'),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Feeling ${user['mood'] ?? 'Happy'}',
                        style: TextStyle(
                          fontSize: 18,
                          color: _getMoodColor(user['mood'] ?? 'Happy'),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(Icons.cake, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '${user['age'] ?? 'Unknown'} years old',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        user['gender'] == 'Male' ? Icons.male : 
                        user['gender'] == 'Female' ? Icons.female : Icons.person,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user['gender'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Match indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getMoodColor(user['mood'] ?? 'Happy').withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: _getMoodColor(user['mood'] ?? 'Happy'),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Same mood match!',
                          style: TextStyle(
                            color: _getMoodColor(user['mood'] ?? 'Happy'),
                            fontWeight: FontWeight.w600,
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
      ),
    );
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
        return Colors.yellow.shade700;
      case 'Sad':
        return Colors.blue.shade600;
      case 'Excited':
        return Colors.orange.shade600;
      case 'Calm':
        return Colors.green.shade600;
      case 'Anxious':
        return Colors.purple.shade600;
      case 'Romantic':
        return Colors.pink.shade600;
      case 'Adventurous':
        return Colors.red.shade600;
      case 'Peaceful':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class ChatScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initializeAnimations();
    _messageController.addListener(_onTextChanged);
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _typingAnimationController.repeat(reverse: true);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
    }
  }

  Map<String, dynamic> _getMoodTheme(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return {
          'primary': const Color(0xFFFFD700),
          'secondary': const Color(0xFFFFA500),
          'background': [const Color(0xFFFFF9E6), const Color(0xFFFFF3CC)],
          'accent': const Color(0xFFFF8C00),
          'icon': Icons.sentiment_very_satisfied,
          'gradient': [const Color(0xFFFFE066), const Color(0xFFFFB347)],
        };
      case 'sad':
        return {
          'primary': const Color(0xFF4A90E2),
          'secondary': const Color(0xFF357ABD),
          'background': [const Color(0xFFE6F3FF), const Color(0xFFCCE7FF)],
          'accent': const Color(0xFF2E5BBA),
          'icon': Icons.sentiment_very_dissatisfied,
          'gradient': [const Color(0xFF6BB6FF), const Color(0xFF4A90E2)],
        };
      case 'excited':
        return {
          'primary': const Color(0xFFFF6B35),
          'secondary': const Color(0xFFE55A31),
          'background': [const Color(0xFFFFF0E6), const Color(0xFFFFE0CC)],
          'accent': const Color(0xFFCC4125),
          'icon': Icons.celebration,
          'gradient': [const Color(0xFFFF8A5B), const Color(0xFFFF6B35)],
        };
      case 'calm':
        return {
          'primary': const Color(0xFF66BB6A),
          'secondary': const Color(0xFF4CAF50),
          'background': [const Color(0xFFE8F5E8), const Color(0xFFD4F1D4)],
          'accent': const Color(0xFF388E3C),
          'icon': Icons.spa,
          'gradient': [const Color(0xFF81C784), const Color(0xFF66BB6A)],
        };
      case 'anxious':
        return {
          'primary': const Color(0xFF9C27B0),
          'secondary': const Color(0xFF8E24AA),
          'background': [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
          'accent': const Color(0xFF7B1FA2),
          'icon': Icons.psychology,
          'gradient': [const Color(0xFFBA68C8), const Color(0xFF9C27B0)],
        };
      case 'romantic':
        return {
          'primary': const Color(0xFFE91E63),
          'secondary': const Color(0xFFD81B60),
          'background': [const Color(0xFFFCE4EC), const Color(0xFFF8BBD9)],
          'accent': const Color(0xFFC2185B),
          'icon': Icons.favorite,
          'gradient': [const Color(0xFFF06292), const Color(0xFFE91E63)],
        };
      case 'adventurous':
        return {
          'primary': const Color(0xFFFF5722),
          'secondary': const Color(0xFFF4511E),
          'background': [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
          'accent': const Color(0xFFE64A19),
          'icon': Icons.explore,
          'gradient': [const Color(0xFFFF8A65), const Color(0xFFFF5722)],
        };
      case 'peaceful':
        return {
          'primary': const Color(0xFF26C6DA),
          'secondary': const Color(0xFF00BCD4),
          'background': [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
          'accent': const Color(0xFF00ACC1),
          'icon': Icons.self_improvement,
          'gradient': [const Color(0xFF4DD0E1), const Color(0xFF26C6DA)],
        };
      default:
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF1976D2),
          'background': [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          'accent': const Color(0xFF1565C0),
          'icon': Icons.mood,
          'gradient': [const Color(0xFF42A5F5), const Color(0xFF2196F3)],
        };
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      setState(() {
        _messages = [];
        _isLoading = false;
      });
      
      if (_messages.isNotEmpty) {
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      _showError('Please log in to send messages');
      return;
    }

    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'match_id': widget.matchId,
      'sender_id': currentUser['id'],
      'message': messageText,
      'timestamp': DateTime.now().toIso8601String(),
      'is_read': false,
    };

    setState(() {
      _messages.add(newMessage);
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isSending = false);
      
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg['id'] == newMessage['id']);
        _isSending = false;
      });
      
      _showError('Failed to send message: $e');
      _messageController.text = messageText;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isMe = message['sender_id'] == currentUser?['id'];
    final moodTheme = _getMoodTheme(widget.otherUser['mood'] ?? 'Happy');
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(false),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isMe 
                          ? LinearGradient(
                              colors: moodTheme['gradient'],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.grey.shade100, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: Radius.circular(isMe ? 24 : 8),
                        bottomRight: Radius.circular(isMe ? 8 : 24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _formatTimestamp(message['timestamp']),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 12),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isMe) {
    final moodTheme = _getMoodTheme(widget.otherUser['mood'] ?? 'Happy');
    final String name;
    if (isMe) {
      final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
      name = currentUser?['full_name'] ?? 'Me';
    } else {
      name = widget.otherUser['full_name'] ?? 'User';
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMe 
              ? moodTheme['gradient']
              : [Colors.grey.shade400, Colors.grey.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          _buildAvatar(false),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(
                              (0.4 + 0.4 * sin((_typingAnimation.value + i * 0.3) * 2 * pi)).clamp(0.2, 0.8)
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodTheme = _getMoodTheme(widget.otherUser['mood'] ?? 'Happy');
    
    return Scaffold(
      backgroundColor: moodTheme['background'][0],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: moodTheme['gradient'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                ),
              ),
              child: Center(
                child: Text(
                  (widget.otherUser['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUser['full_name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        moodTheme['icon'],
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Feeling ${widget.otherUser['mood'] ?? 'Happy'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              // Video call functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {
              // Voice call functionality
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: moodTheme['background'],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(moodTheme['primary']),
                      ),
                    )
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: _messages.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isSending) {
                              return _buildTypingIndicator();
                            }
                            return _buildMessage(_messages[index]);
                          },
                        ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final moodTheme = _getMoodTheme(widget.otherUser['mood'] ?? 'Happy');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: moodTheme['gradient'],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: moodTheme['primary'].withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              moodTheme['icon'],
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: moodTheme['primary'],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You both are feeling ${widget.otherUser['mood']?.toLowerCase()} - perfect match!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to ${widget.otherUser['full_name']}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final moodTheme = _getMoodTheme(widget.otherUser['mood'] ?? 'Happy');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: moodTheme['background'][0],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: moodTheme['primary'].withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: moodTheme['primary'],
                    size: 24,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isTyping 
                  ? moodTheme['primary']
                  : Colors.grey.shade400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _isTyping 
                      ? (moodTheme['primary'] as Color).withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _isSending ? null : _sendMessage,
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isTyping ? Icons.send_rounded : Icons.mic,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }
}