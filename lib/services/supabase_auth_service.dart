import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // User data model
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Check if user is currently authenticated
  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Register a new user with Supabase Auth and store profile data
  static Future<Map<String, dynamic>?> registerUser({
    required String fullName,
    required String email,
    required String password,
    required int age,
    required String gender,
    required String mood,
  }) async {
    try {
      print('Debug - Attempting Supabase registration with email: $email');
      
      // Sign up with Supabase Auth
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'age': age,
          'gender': gender,
          'mood': mood,
        },
      );
      
      print('Debug - Supabase response: ${response.user?.id}');
      print('Debug - Supabase session: ${response.session?.accessToken != null}');

      if (response.user != null) {
        // Store additional user profile data in profiles table
        final profileData = {
          'id': response.user!.id,
          'full_name': fullName,
          'email': email,
          'age': age,
          'gender': gender,
          'mood': mood,
          'created_at': DateTime.now().toIso8601String(),
        };

        print('Debug - Upserting profile data: $profileData');
        
        // Use upsert to handle existing profiles
        await _supabase
            .from('profiles')
            .upsert(profileData);

        // Store user data locally for quick access
        await _storeUserDataLocally(profileData);

        return {
          'success': true,
          'user': profileData,
          'message': 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed. Please try again.',
        };
      }
    } on AuthException catch (e) {
      print('Debug - AuthException: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      print('Debug - General Exception: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Sign in existing user
  static Future<Map<String, dynamic>?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch user profile data
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        // Store user data locally
        await _storeUserDataLocally(profileResponse);

        return {
          'success': true,
          'user': profileResponse,
          'message': 'Login successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid credentials',
        };
      }
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  /// Check if user session exists and auto-login
  static Future<Map<String, dynamic>?> checkExistingSession() async {
    try {
      // Check if user is already authenticated
      if (isAuthenticated) {
        // Fetch fresh user data from database
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', currentUser!.id)
            .single();

        // Update local storage with fresh data
        await _storeUserDataLocally(profileResponse);

        return {
          'success': true,
          'user': profileResponse,
          'message': 'Session restored',
        };
      }

      // Check local storage for user data
      final userData = await _getUserDataFromLocal();
      if (userData != null) {
        return {
          'success': true,
          'user': userData,
          'message': 'Local session found',
        };
      }

      return null;
    } catch (e) {
      print('Session check error: $e');
      return null;
    }
  }

  /// Sign out user
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _clearUserDataLocally();
    } catch (e) {
      print('Sign out error: $e');
      // Clear local data even if remote signout fails
      await _clearUserDataLocally();
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>?> updateProfile({
    String? fullName,
    int? age,
    String? gender,
  }) async {
    try {
      if (!isAuthenticated) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', currentUser!.id);

      // Fetch updated profile
      final updatedProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      // Update local storage
      await _storeUserDataLocally(updatedProfile);

      return {
        'success': true,
        'user': updatedProfile,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile: $e',
      };
    }
  }

  /// Store user data locally using SharedPreferences
  static Future<void> _storeUserDataLocally(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(userData));
      await prefs.setBool(_isLoggedInKey, true);
    } catch (e) {
      print('Error storing user data locally: $e');
    }
  }

  /// Get user data from local storage
  static Future<Map<String, dynamic>?> _getUserDataFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!isLoggedIn) return null;

      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return json.decode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data from local storage: $e');
      return null;
    }
  }

  /// Clear user data from local storage
  static Future<void> _clearUserDataLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.setBool(_isLoggedInKey, false);
    } catch (e) {
      print('Error clearing user data locally: $e');
    }
  }

  /// Get user data (from local storage or current session)
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    // First try to get from current session
    if (isAuthenticated) {
      try {
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', currentUser!.id)
            .single();
        return profileResponse;
      } catch (e) {
        print('Error fetching current user data: $e');
      }
    }

    // Fallback to local storage
    return await _getUserDataFromLocal();
  }

  /// Check if user exists by email
  static Future<bool> userExists(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send reset email: $e',
      };
    }
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
