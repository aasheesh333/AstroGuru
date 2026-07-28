import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

class KeyManager {
  static final KeyManager _instance = KeyManager._internal();
  factory KeyManager() => _instance;
  KeyManager._internal();

  String? _cachedKey;
  bool _initialized = false;

  // Diagnostic: why was the key empty after init()? Surfaced via
  // [lastFailureReason] so callers / UI can show a useful message
  // instead of blindly assuming "no key configured".
  String? lastFailureReason;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    bool firestorePermissionDenied = false;
    bool docMissing = false;
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('gemini_api_keys')
          .doc('gemini_api_list')
          .get();
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        docMissing = true;
      } else {
        final data = docSnapshot.data()!;
        for (final v in data.values) {
          final s = v?.toString() ?? '';
          if (s.isNotEmpty) {
            _cachedKey = s;
            lastFailureReason = null;
            developer.log('KeyManager: loaded Gemini key from Firestore (len=${s.length}).');
            return;
          }
        }
        // Doc exists but every value was null/empty.
        lastFailureReason = 'Firestore doc gemini_api_keys/gemini_api_list has no non-empty key field.';
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        firestorePermissionDenied = true;
      }
      developer.log('KeyManager: Firestore fetch failed (${e.code}): $e');
    } catch (e) {
      developer.log('KeyManager: Firestore fetch failed: $e');
    }

    if (docMissing) {
      lastFailureReason = 'gemini_api_keys/gemini_api_list does not exist in Firestore.';
    } else if (firestorePermissionDenied) {
      lastFailureReason = 'Firestore denied read of gemini_api_keys/gemini_api_list — check firestore.rules.';
    }

    if (_cachedKey == null || _cachedKey!.isEmpty) {
      final local = dotenv.env['APP_GEMINI_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'] ?? '';
      if (local.isNotEmpty) {
        _cachedKey = local;
        lastFailureReason = null;
        developer.log('KeyManager: loaded Gemini key from .env (len=${local.length}).');
      } else if (lastFailureReason == null) {
        lastFailureReason = 'No Gemini key found in Firestore or assets/.env (APP_GEMINI_API_KEY).';
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
