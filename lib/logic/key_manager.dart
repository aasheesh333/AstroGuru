import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

/// Resolves the Groq API key used by [AIService] for direct (client-side)
/// requests to `api.groq.com`. Resolution order:
///   1. Firestore doc `groq_api_keys/groq_api_list` — preferred so the key
///      can be rotated without an app release.
///   2. `APP_GROQ_API_KEY` / `GROQ_API_KEY` from `assets/.env` (local dev).
///
/// A single key is used. Rotation was removed per product decision.
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
          .collection('groq_api_keys')
          .doc('groq_api_list')
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        for (final v in data.values) {
          final s = v?.toString() ?? '';
          if (s.isNotEmpty) {
            _cachedKey = s;
            developer.log('KeyManager: loaded key from Firestore (len=${s.length}).');
            return;
          }
        }
      }
    } catch (e) {
      developer.log('KeyManager: Firestore fetch failed: $e');
    }

    if (_cachedKey == null || _cachedKey!.isEmpty) {
      final local = dotenv.env['APP_GROQ_API_KEY'] ?? dotenv.env['GROQ_API_KEY'] ?? '';
      if (local.isNotEmpty) {
        _cachedKey = local;
        developer.log('KeyManager: loaded key from .env (len=${local.length}).');
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
