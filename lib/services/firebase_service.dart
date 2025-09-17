
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;
  static bool mockMode = false;

  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
      mockMode = false;
    } catch (e) {
      // Fallback to mock mode if Firebase isn't configured.
      debugPrint('Firebase init failed, switching to mock mode: $e');
      mockMode = true;
    }
  }

  static Future<User?> signInAnonymously() async {
    if (mockMode) return null;
    final cred = await auth.signInAnonymously();
    return cred.user;
  }
}
