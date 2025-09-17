import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class SplashService {
  /// Determine the initial route based on authentication status
  static Future<String> determineInitialRoute(AuthProvider authProvider) async {
    // Initialize auth provider to check for existing sessions
    await authProvider.initialize();
    
    // If user is authenticated, go directly to home
    if (authProvider.isAuthenticated) {
      return '/home';
    }
    
    // Otherwise, show registration screen
    return '/register';
  }

  /// Handle app startup logic
  static Future<void> handleAppStartup(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    try {
      // Initialize authentication without showing loading dialog
      await authProvider.initialize();

      // Navigate based on auth status
      if (authProvider.isAuthenticated && context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: authProvider.currentUser,
        );
      } else if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/register');
      }
    } catch (e) {
      // Show error and navigate to register
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Startup error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/register');
      }
    }
  }
}
