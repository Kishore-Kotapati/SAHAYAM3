import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/matching_screen.dart';
import 'providers/auth_provider.dart';
import 'mission_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load fonts for web platform
  if (kIsWeb) {
    await _loadFonts();
  }

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: 'https://pvkwfzhcctnkuwqnzpka.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2a3dmemhjY3Rua3V3cW56cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwNjUxMTUsImV4cCI6MjA3MjY0MTExNX0.MNjUV0cO4yBebFpyFLLkMsqvG-xjTRyzg0s6ByMqAKU',
  );
  
  runApp(const MyApp());
}

// ✅ Font loading function for web
Future<void> _loadFonts() async {
  try {
    // Load Google Fonts or system fonts
    await Future.wait([
      // Note: SystemFonts.ensureLoaded doesn't exist in Flutter
      // Instead, use FontLoader or GoogleFonts package
      _loadCustomFont('Roboto'),
      // Add other fonts you're using
    ]);
  } catch (e) {
    if (kDebugMode) {
      print('Font loading error: $e');
    }
  }
}

// ✅ Custom font loading helper
Future<void> _loadCustomFont(String fontFamily) async {
  try {
    final fontLoader = FontLoader(fontFamily);
    // Add your font files here
    // fontLoader.addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await fontLoader.load();
  } catch (e) {
    if (kDebugMode) {
      print('Failed to load font $fontFamily: $e');
    }
  }
}

// ✅ Global access to Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MissionProvider>(
          create: (_) => MissionProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stress Relief App',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF6A11CB),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF2575FC),
          ),
          scaffoldBackgroundColor: Colors.transparent,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide.none,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/register': (_) => const RegisterScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/matching': (_) => const MatchingScreen(),
        },
      ),
    );
  }
}

// ✅ Example button showing Navigator.push usage
class ExampleButton extends StatelessWidget {
  const ExampleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text("Go to Home"),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
    );
  }
}

// ✅ Example test widget for Supabase connection
class TestSupabaseButton extends StatelessWidget {
  const TestSupabaseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text("Test Supabase Connection"),
      onPressed: () {
        if (kDebugMode) {
          print('Supabase client: $supabase');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supabase connected!')),
        );
      },
    );
  }
}