import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

class KeyManager {
  static final KeyManager _instance = KeyManager._internal();
  factory KeyManager() => _instance;
  KeyManager._internal();

  String? _cachedKey;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('gemini_api_keys')
          .doc('gemini_api_list')
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        for (final v in data.values) {
          final s = v?.toString() ?? '';
          if (s.isNotEmpty) {
            _cachedKey = s;
            developer.log('KeyManager: loaded Gemini key from Firestore (len=${s.length}).');
            return;
          }
        }
      }
    } catch (e) {
      developer.log('KeyManager: Firestore fetch failed: $e');
    }

    if (_cachedKey == null || _cachedKey!.isEmpty) {
      final local = dotenv.env['APP_GEMINI_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'] ?? '';
      if (local.isNotEmpty) {
        _cachedKey = local;
        developer.log('KeyManager: loaded Gemini key from .env (len=${local.length}).');
      }
    }
  }

  Future<String> getApiKey() async {
    if (!_initialized || _cachedKey == null) {
      await init();
    }
    return _cachedKey ?? '';
  }

  bool get hasKey => (_cachedKey ?? '').isNotEmpty;
}
