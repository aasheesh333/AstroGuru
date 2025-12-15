import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

class KeyManager {
  static final KeyManager _instance = KeyManager._internal();
  factory KeyManager() => _instance;
  KeyManager._internal();

  List<String> _apiKeys = [];
  int _currentIndex = 0;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Fetch from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('groq_api_keys')
          .doc('groq_api_list')
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        // Extract values (keys) ignoring keys (emails)
        final List<String> fetchedKeys = data.values
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();

        if (fetchedKeys.isNotEmpty) {
          _apiKeys = fetchedKeys;
          developer.log("KeyManager: Fetched ${_apiKeys.length} keys from Firestore.");
        }
      }
    } catch (e) {
      developer.log("KeyManager: Failed to fetch keys from Firestore: $e");
    }

    // 2. Fallback to Env
    if (_apiKeys.isEmpty) {
      final String localKey = dotenv.env['APP_GROQ_API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';
      if (localKey.isNotEmpty) {
        _apiKeys.add(localKey);
        developer.log("KeyManager: Using fallback local key.");
      }
    }

    // 3. Load Index from Storage
    if (_apiKeys.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _currentIndex = prefs.getInt('groq_key_index') ?? 0;

      // Validation
      if (_currentIndex >= _apiKeys.length) {
        _currentIndex = 0;
      }
    }

    _initialized = true;
  }

  Future<String> getNextKey() async {
    if (!_initialized) await init();
    if (_apiKeys.isEmpty) return '';

    String key = _apiKeys[_currentIndex];

    // Increment and Rotate
    _currentIndex++;
    if (_currentIndex >= _apiKeys.length) {
      _currentIndex = 0;
    }

    // Persist Index asynchronously (Best effort)
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('groq_key_index', _currentIndex);
    });

    return key;
  }

  // Helper to force rotate if a key fails (429)
  Future<String> rotateAndGetKey() async {
    // Force increment
    _currentIndex++;
    if (_apiKeys.isNotEmpty && _currentIndex >= _apiKeys.length) {
      _currentIndex = 0;
    }
    return getNextKey();
  }
}
