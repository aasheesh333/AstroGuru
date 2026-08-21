import 'dart:io';
import 'package:flutter/services.dart';

/// Helper to detect whether Google Play Services (GMS) is available on the
/// device. OPPO/realme/OnePlus devices sold outside the Google ecosystem (and
/// all Chinese-market devices) do NOT ship GMS — calling GMS-dependent APIs
/// (Google Sign-In, AdMob, FCM/OneSignal) on them surfaces a system-level
/// "This app requires Google Play services" prompt, which store reviewers
/// flag as "Mandatory Download from GP".
///
/// We detect GMS availability once at startup via a native MethodChannel
/// (GoogleApiAvailability.isGooglePlayServicesAvailable) and gate all
/// GMS-dependent initialization and UI on the result.
class GmsAvailability {
  GmsAvailability._();

  static const MethodChannel _channel =
      MethodChannel('com.dhanuk.astroprerna/gms');

  /// Cached result. `null` means "not checked yet" — we treat unknown as
  /// available so behaviour on Google devices is unchanged.
  static bool? _available;

  /// Returns true if Google Play Services is usable on this device.
  /// Defaults to true on non-Android platforms and if the check fails.
  static Future<bool> isAvailable() async {
    if (_available != null) return _available!;
    if (!Platform.isAndroid) {
      _available = true;
      return true;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isGmsAvailable');
      _available = result ?? true;
    } catch (_) {
      // If the platform channel is missing/fails, assume GMS is present so
      // we don't accidentally disable features on Google devices.
      _available = true;
    }
    return _available!;
  }

  /// Synchronous snapshot after [isAvailable] has been awaited at least once.
  /// Returns true when unknown (fail-open for Google devices).
  static bool get isAvailableSync => _available ?? true;

  /// Overrides the cached value (mainly for tests).
  static void debugSet(bool value) => _available = value;
}
