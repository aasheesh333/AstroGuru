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
- `test/hindu_festivals_test.dart` — table integrity tests
  (sortedness, year-spanning window, Diwali/Holi/Janmashtami present).
- `test/kundli_context_test.dart` — verifies the kundli narrative builder
  produces sign names (not raw rashi ids), handles missing nakshatra
  gracefully, and formats the birth date / time / place prefix correctly.
- `test/ai_service_prompts_test.dart` — verifies that the daily, weekly,
  and monthly horoscope prompts, the AI Sage chat system prompt, the
  remedies prompt, and the quote prompt all fold the user's kundli
  context into the system prompt when provided, and that the legacy
  "General Query." placeholder is gone.
- `lib/utils/rate_app_launcher.dart` — single source of truth for the
  Android `applicationId` and the `openStoreListing()` call.
- `UserProvider.birthTime` and `birthPlace` fields, persisted to
  per-user SharedPreferences via `UserSession.setBirthTime` /
  `setBirthPlace`. The kundli input screen now writes these on Generate.
- `UserProvider.getKundliContext()` — convenience method that runs
  `KundliService.calculateChart` over the user's stored birth details
  and returns a 1-paragraph narrative suitable for AI prompts.
- `lib/logic/kundli_context.dart` — `KundliContextBuilder.build({chart,
  birthDate, birthTime, birthPlace})` produces a multi-line string with
  sign names (no raw rashi ids) and doshas. `KundliService._generateSummary`
  now delegates to this builder so all consumers of the kundli summary
  (remedies, chat, etc.) get the new format automatically.

### Changed
- Rate App menu item and home-screen auto-trigger now call
  `InAppReview.openStoreListing()` instead of
  `InAppReview.requestReview()`. This opens the Play Store listing
  directly (no in-app sheet quota, no "wait until Google allows it"
  behavior). The 90-day manual cooldown and the 7-day + 3-action
  auto-trigger gate are unchanged.
- AI prompts (daily/weekly/monthly horoscope, daily quote, AI Sage
  chat, love match, remedies) now accept an optional `kundliContext`
  and inject it into the system prompt. Call sites in
  `home_screen`, `horoscope_detail_screen`, `chat_screen`, and
  `love_match_screen` build the context from `UserProvider` and pass
  it through. The result: AI responses reference the user's actual
  Lagna, Moon sign, and doshas instead of a generic zodiac-only summary.
- Default Groq temperature lowered from `0.7` to `0.6` to make
  horoscopes feel less like obvious template copy.
- L10n key `ratingDialogFailed` renamed to `openStoreFailed` (message
  updated to "Could not open the Play Store.") across all 13 ARB files.
- AI Sage chat now responds strictly in the app's currently selected
  language by default, and ignores incidental mentions of other
  languages mid-conversation. The chat system prompt includes an
  explicit `LANGUAGE RULE` (full language name, "respond strictly in
  $langName", "do not switch unless asked", "continue in it for the
  rest of the conversation") so the model treats language as a hard
  instruction. All other AI prompts (daily/weekly/monthly horoscope,
  daily quote, remedies, love match) now reference the target language
  by its full name (e.g. "Hindi", "Tamil") instead of its ISO code, so
  the model never falls back to English.
- `AIService.detectLanguageOverride(userMessage)` scans each user
  message for a clear directive to switch (e.g. "Hindi mein baat karo",
  "Tamil la sollu", "respond in English please") and returns a language
  code that overrides the app default for the rest of the chat session.
  Detection is conservative (requires a verb cue near the language
  name) to avoid false positives on phrases like "I am learning
  Spanish." The override is now **sticky across all chats and across
  app restarts** — once the user says "Tamil la sollu", every future
  chat (in the same account) responds in Tamil. Changing the app
  language in settings clears the override.

### Added
- `test/ai_service_language_test.dart` — 12 cases covering
  `languageNameFor` (13 locales + fallback), `detectLanguageOverride`
  (English / Hindi / Dravidian directives, case-insensitivity,
  negative cases), and the strict-language chat system prompt format.
- `test/user_session_chat_language_test.dart` — 4 cases covering
  `UserSession.getChatLanguage` / `setChatLanguage` persistence
  (unset, set, overwrite, clear).
- `UserProvider.chatLanguage` — per-user sticky AI Sage language
  override. Loaded from `UserSession` in `loadUserData`, persisted
  via `setChatLanguage(code)` (pass `null` to clear), and reset on
  `clear()`. The chat screen reads `provider.chatLanguage` on every
  send and writes back whenever `AIService.detectLanguageOverride`
  picks up a new directive.

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
