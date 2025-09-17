import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  /// Initialize auth provider and check for existing session
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      final sessionResult = await SupabaseAuthService.checkExistingSession();
      
      if (sessionResult != null && sessionResult['success'] == true) {
        _currentUser = sessionResult['user'];
        _isAuthenticated = true;
        _errorMessage = null;
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize auth: $e';
      _currentUser = null;
      _isAuthenticated = false;
    }
    
    _setLoading(false);
  }

  /// Register new user
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required int age,
    required String gender,
    required String mood,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await SupabaseAuthService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
        age: age,
        gender: gender,
        mood: mood,
      );

      if (result != null && result['success'] == true) {
        _currentUser = result['user'];
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result?['message'] ?? 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration error: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Sign in user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await SupabaseAuthService.signInUser(
        email: email,
        password: password,
      );

      if (result != null && result['success'] == true) {
        _currentUser = result['user'];
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result?['message'] ?? 'Login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await SupabaseAuthService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Sign out error: $e';
    }
    
    _setLoading(false);
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    int? age,
    String? gender,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await SupabaseAuthService.updateProfile(
        fullName: fullName,
        age: age,
        gender: gender,
      );

      if (result != null && result['success'] == true) {
        _currentUser = result['user'];
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result?['message'] ?? 'Profile update failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Profile update error: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Check if user exists
  Future<bool> checkUserExists(String email) async {
    try {
      return await SupabaseAuthService.userExists(email);
    } catch (e) {
      _errorMessage = 'Error checking user: $e';
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await SupabaseAuthService.resetPassword(email);
      
      if (result['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result['message'];
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Password reset error: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get user display name
  String get userDisplayName {
    if (_currentUser == null) return 'Guest';
    return _currentUser!['full_name'] ?? _currentUser!['email'] ?? 'User';
  }

  /// Get user email
  String get userEmail {
    if (_currentUser == null) return '';
    return _currentUser!['email'] ?? '';
  }

  /// Get user age
  int get userAge {
    if (_currentUser == null) return 0;
    return _currentUser!['age'] ?? 0;
  }

  /// Get user gender
  String get userGender {
    if (_currentUser == null) return '';
    return _currentUser!['gender'] ?? '';
  }
}
