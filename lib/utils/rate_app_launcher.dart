import 'package:in_app_review/in_app_review.dart';

/// Opens the Play Store listing for this app on Android. There is no quota on
/// this call, so it's safe to expose behind a user-driven button as well as a
/// one-shot auto-trigger. On unsupported devices the call is a no-op (or
/// throws, which callers should catch).
class RateAppLauncher {
  static const String _packageName = 'com.dhanuk.astroprerna';

  /// The Android applicationId. Exposed so the URL fallback (e.g. for a
  /// future "copy link" feature) can reference the same value without
  /// duplicating the literal.
  static String get packageName => _packageName;

  /// Opens the Play Store listing for this app. Returns `true` if the
  /// platform supports the call, `false` otherwise. The plugin's
  /// [openStoreListing] already reads the applicationId from
  /// AndroidManifest on Android, so we pass no arguments.
  static Future<bool> openPlayStoreListing() async {
    final InAppReview inAppReview = InAppReview.instance;
    final bool available = await inAppReview.isAvailable();
    if (!available) return false;
    await inAppReview.openStoreListing();
    return true;
  }
}
