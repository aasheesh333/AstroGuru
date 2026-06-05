import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized runtime configuration.
///
/// Resolution order for each value:
/// 1. `--dart-define=KEY=value` (used by CI)
/// 2. `assets/.env` (used by local dev with
///    `flutter run --dart-define-from-file=assets/.env`)
///
/// NEVER put secrets in this file. The Groq API key is held by the backend
/// (`functions/src/index.ts`) and the client only talks to it through the
/// `groqProxy` Cloud Function.
class AppConfig {
  static bool _loaded = false;

  /// Call once at app start, before any other code reads env values.
  static Future<void> load({String fileName = 'assets/.env'}) async {
    if (_loaded) return;
    try {
      await dotenv.load(fileName: fileName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppConfig: .env not loaded ($e), using --dart-define values.');
      }
    }
    _loaded = true;
  }

  // `String.fromEnvironment` is a compile-time constant, so each value needs
  // its own explicit call. The helper below falls back to dotenv when the
  // compile-time value is empty.

  static String get admobAppId => _firstNonEmpty(
        const String.fromEnvironment('APP_ADMOB_APP_ID'),
        'APP_ADMOB_APP_ID',
      );

  static String get admobBannerId => _firstNonEmpty(
        const String.fromEnvironment('APP_ADMOB_BANNER_ID'),
        'APP_ADMOB_BANNER_ID',
      );

  static String get admobInterstitialId => _firstNonEmpty(
        const String.fromEnvironment('APP_ADMOB_INTERSTITIAL_ID'),
        'APP_ADMOB_INTERSTITIAL_ID',
      );

  static String get admobRewardedId => _firstNonEmpty(
        const String.fromEnvironment('APP_ADMOB_REWARDED_ID'),
        'APP_ADMOB_REWARDED_ID',
      );

  static String get oneSignalAppId => _firstNonEmpty(
        const String.fromEnvironment('APP_ONESIGNAL_APP_ID'),
        'APP_ONESIGNAL_APP_ID',
      );

  static String get oneSignalApiKey => _firstNonEmpty(
        const String.fromEnvironment('APP_ONESIGNAL_API_KEY'),
        'APP_ONESIGNAL_API_KEY',
      );

  static String _firstNonEmpty(String fromDefine, String envKey) {
    if (fromDefine.isNotEmpty) return fromDefine;
    return _fromDotEnv(envKey);
  }

  static String _fromDotEnv(String key) {
    try {
      final v = dotenv.env[key];
      if (v == null || v.isEmpty) return '';
      return v;
    } catch (_) {
      // dotenv not loaded; treat as missing.
      return '';
    }
  }
}
