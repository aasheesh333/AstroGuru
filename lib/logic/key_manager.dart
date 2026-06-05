import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// The client no longer holds a Groq API key directly. Production requests
/// are routed through the `groqProxy` Firebase Cloud Function, which holds
/// the key on the server side. This class is kept as a thin wrapper so
/// legacy code paths that called `KeyManager().init()` still work, and so
/// we can use it to detect "no key configured" at boot without exposing
/// the key in the APK.
class KeyManager {
  static final KeyManager _instance = KeyManager._internal();
  factory KeyManager() => _instance;
  KeyManager._internal();

  bool _hasKey = false;

  /// Verify that the backend has a key configured. Throws if not.
  Future<void> init() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groq_api_keys')
          .doc('groq_api_list')
          .get();
      if (doc.exists && doc.data() != null) {
        _hasKey = doc.data()!.values
            .any((v) => v is String && v.toString().isNotEmpty);
      }
    } catch (e) {
      debugPrint('KeyManager: init failed: $e');
    }
  }

  bool get hasKey => _hasKey;
}
