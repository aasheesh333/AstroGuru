# Changelog

All notable changes to AstroPrerna are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Automatic daily notifications not firing on cold start: the schedule was
  only triggered from `MainScreen`'s post-frame callback via
  `checkPermissions`, which was gated on OneSignal being configured. Moved
  static + festival scheduling to `NotificationService.bootstrapStatic()`,
  called from `main()` before `runApp` and independent of OneSignal.
- Festival notification for "today" silently shifted to "tomorrow at the
  same hour" when the scheduled hour was already past; now correctly
  skipped (no shift, no ghost notification).
- Static evening notifications (Mon/Wed/Fri/Sat 8:30 PM) were not cancelled
  when the dynamic AI schedule ran, leaving stale entries from the
  previous cycle. `scheduleDynamicNotifications` now calls `cancelAll()`
  before re-scheduling.
- `AndroidScheduleMode.exactAllowWhileIdle` is user-revocable on Android
  12+; the OS silently degrades to never-fire when denied. Switched all
  scheduled notifications to `inexactAllowWhileIdle` to remove the
  `SCHEDULE_EXACT_ALARM` failure mode.
- Status-bar small icon now explicitly set to `ic_launcher` on every
  `AndroidNotificationDetails` (previously unset, falling back to a blank
  white square on most devices).

### Added
- `lib/logic/hindu_festivals.dart` — hardcoded Hindu-festival table
  (Diwali, Holi, Navratri, Dussehra, Janmashtami, Ram Navami, Karva
  Chauth, Chhath, Guru Nanak Jayanti, etc.) for 2026 and 2027.
  `NotificationService._scheduleFestivals()` schedules the next 14 days
  on every static bootstrap, so a real festival notification fires
  regardless of what the AI returns.
- `NotificationService.bootstrapStatic()` and `bootstrapDynamic({zodiac,
  language})` — split entry points. Static is called from `main()`
  before `runApp`; dynamic is throttled to once every 3 days and called
  from `MainScreen` after the user-provider is ready. Throttle timestamp
  is also cleared on language change to force a refresh.
- `NotificationService.hasPermission()` and `requestPermission()` —
  context-free permission API using the
  `flutter_local_notifications` plugin's `areNotificationsEnabled` /
  `requestNotificationsPermission`, no longer dependent on OneSignal.
- `test/hindu_festivals_test.dart` — table integrity tests
  (sortedness, year-spanning window, Diwali/Holi/Janmashtami present).

### Security
- **Groq API key removed from the APK.** All AI requests now go through a
  server-side Firebase Cloud Function (`functions/src/index.ts`
  `groqProxy`). The function holds the key in a Firestore document
  (`groq_api_keys/groq_api_list`) and caches it in memory for 5 minutes.
- The single-key Firestore-backed approach replaces the previous
  client-side rotation. Groq suspends accounts that rotate keys
  frequently, so we now keep one key and update it manually when needed.
- `lib/config/app_config.dart` resolves env values from `--dart-define`
  first, then dotenv. Secrets are never bundled.

### Added
- Lazy migration of profile images from base64 (SharedPreferences) to
  Firebase Storage at `users/{uid}/avatar.jpg`, with download URL cached
  per user. Falls back to the old base64 image if Storage is unavailable.
- `pumpUsers` backup flags hardened: `allowBackup="false"`,
  `dataExtractionRules`, and `network_security_config.xml` cleartext
  off.
- In-app review prompt (7-day + 3-actions gate) on the home screen.
- Typing-indicator shimmer and loading skeletons in chat, kundli, and
  love-match screens.
- "About", "Rate App", and "Send Feedback" items in the profile screen.
- Global error handler at boot that logs uncaught errors to
  `developer.log` (visible in `adb logcat`). Firebase Crashlytics and
  Analytics integration is deferred to a future release because of a
  firebase_core / firebase_storage major-version conflict at the time
  of writing.
- Centralized color tokens in `AppColors` (gold accent, accent pink)
  replacing 45+ hardcoded `Color(0xFF...)` literals.
- ARB localization in 13 Indian languages; all files synced to 185 keys.
- Lahiri ayanamsa in KundliService.
- Offline geocoding via bundled `StaticCities` table (200+ cities).
- Tests: `static_cities_test.dart`, `love_match_logic_test.dart`,
  updated `widget_test.dart` and `edit_profile_layout_test.dart`.

### Changed
- `AdService` rejects test ad unit IDs at runtime in release mode and
  throws on missing configuration. Test IDs are only used in debug.
- `KeyManager` is now a thin wrapper that checks Firestore for the
  presence of a backend key (no rotation, no `.env` fallback).
- CI workflow: Android-only, explicit `flutter analyze` and
  `flutter test` steps, and `create_env.sh` no longer materializes a
  Groq key.
- `compileSdk` and `targetSdk` bumped to 35; `minSdk` set to 24.
- Splash screen no longer has an artificial 2-second delay.

### Fixed
- Race condition in chat screen where rapid double-tap on "send" could
  send the same message twice.
- Banner-ad layout: reserved 60px placeholder so the bottom nav no
  longer shifts when the ad loads.
- Deprecated `withOpacity` replaced with `withValues(alpha: ...)`
  (33 sites) ahead of the Flutter 3.27 deprecation.
- Hardcoded English strings in chat, kundli, and love-match screens
  moved to `AppLocalizations`.

## [0.x] — pre-1.0 development

The 0.x series shipped under the `AstroGuru` package name and was
internal-only.

[Unreleased]: https://github.com/dhanuk/astroguru/compare/main...HEAD
