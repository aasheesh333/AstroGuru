# Changelog

All notable changes to AstroPrerna are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] — 2026-07-28

### Changed
- **AI engine rewritten from Groq (Llama 3.3 70B) to Google Gemini 2.5
  Flash-Lite**, called from the client via `x-goog-api-key`. Firestore
  document moved from `groq_api_keys/groq_api_list` to
  `gemini_api_keys/gemini_api_list`. `KeyManager` caches for the session;
  local dev can override via `APP_GEMINI_API_KEY` in `assets/.env`.
- **Streaming chat**: AI Sage responses now stream token-by-token using
  Gemini's `streamGenerateContent?alt=sse` endpoint. The chat screen
  subscribes and updates the message bubble incrementally. A Stop
  button cancels the stream; a Regenerate button re-sends the last
  user query. Thinking budget is disabled (0) for low-latency chat.
- **Android SDK bumped to API 36**: `compileSdk 36`, `targetSdk
  36`, AGP `8.7.3`, Kotlin `2.0.21`, Gradle `8.11.1`,
  `desugar_jdk_libs: 2.2.0`. `ext.flutter` block in root
  `android/build.gradle` updated to match.
- **Interest-based notification personalization**: `InterestTracker`
  records per-feature usage counts (horoscope, kundli, chat, love
  match, remedies) in SharedPreferences and syncs to Firestore
  `users/{uid}.interests` hourly. `NotificationService.bootstrapDynamic`
  passes these interests to `AIService.getNotificationSchedule` so
  AI-generated morning/evening/afternoon notifications skew toward the
  user's top features. Fully free, server-side via Firestore + local
  scheduling.
- **Share buttons added** to Horoscope detail screen (AppBar icon)
  and Love Match result view (outlined button). Both use `share_plus`.
- **"Share App" menu item** added to the Profile screen, sharing
  the `shareAppText` localized string.
- **"Rate App"** remains in the Profile screen only. The 7-day +
  3-action auto-trigger has been removed from the home screen to
  respect Play Store policy and avoid surprise prompts.
- **Localized `poweredBy`** string across all 13 ARB files changed from
  "Powered by Groq AI" to "Powered by Google AI".
- **38 `withOpacity()` calls** replaced with `withValues(alpha: ...)`
  ahead of the Flutter 3.27 deprecation (remaining sites beyond the 33
  already fixed in the previous pass).
- **Duplicate `"retry"` ARB key** removed; non-English ARB files
  now contain the same keys as `app_en.arb` so `flutter gen-l10n`
  succeeds.

### Added
- `lib/logic/interest_tracker.dart` — singleton that tracks per-feature
  usage, stores counts in SharedPreferences, and syncs to Firestore
  on an hourly cadence. Provides `getInterests()` for the notification
  flow and `getInterestsSummary()` for prompt injection.
- `lib/services/ai_service.dart` — new `getChatResponseStream()` method
  returns a `Stream<String>` from Gemini's SSE streaming endpoint. JSON
  mode, thinking budget, and message format conversion are all handled
  internally by `_buildGeminiBody` / `_extractGeminiText`.
- ~40 new ARB keys added across all 13 locale files covering chat UI
  (hint, greetings, suggestions, stop, regenerate, export), Kundli
  tabs, horoscope loading/error states, notification permission dialog,
  profile share, and more.
- `share_plus: ^10.1.2` added to `pubspec.yaml`.
- Long-press on AI Sage responses copies the message to the clipboard
  with a SnackBar confirming success.

### Fixed
- Hardcoded English strings in `profile_screen.dart` ("Terms &
  Conditions"), `chat_screen.dart` (hint text, default greeting, length
  warning), `horoscope_detail_screen.dart` (loading, forecast error,
  "N/A", "Close"), `love_match_screen.dart` (analysis failure), and
  `main_screen.dart` (reset history tooltip) are now routed through
  `AppLocalizations`.
- `home_screen.dart` no longer imports `rate_app_launcher.dart` (was
  unused after removing `_maybeRequestInAppReview`).
- Typing indicator in chat removed — the streaming bubble now serves
  the same purpose (empty sage message fills in as chunks arrive).

### Fixed
- **Compile error: `profileShare` l10n key missing** — changed to `profileShareApp`,
  matching the ARB key. Dart compilation would otherwise fail.
- **Compile error: `l10n` used before declaration** in `horoscope_detail_screen.dart`
  `_shareForecast()`. Moved `final l10n = ...` above first referencing line.
- **Release crash: `proguard-rules.pro` missing** — created at
  `android/app/proguard-rules.pro` with keep-rules for Firebase, AdMob,
  OneSignal, local notifications, cached images, speech-to-text, and
  `url_launcher`. With `minifyEnabled true`, these classes were being
  stripped, causing runtime crashes in release builds.
- **`@chatMsgTooLong` @-annotation** added to all 12 non-template ARB files
  so placeholder metadata is consistently defined across locales.
- **Memory leak: `StreamSubscription` never cancelled in chat `dispose()`** —
  `_streamSubscription?.cancel()` now runs in `dispose()`. Without this,
  streaming AI responses would continue emitting after the chat screen
  is popped, triggering `setState() called after dispose()` crashes.
- **`setState() called after dispose()` crashes** — added `if (!mounted) return;`
  guards after every async `await` in `chat_screen._loadHistory()`,
  `home_screen._fetchNewData()`, and wrapped all 18 `setState(() =>
  _isLoading = false)` sites in `login_screen.dart` with `if (mounted)`.
- **Speech recognition callbacks** (`onStatus`, `onError`, `onResult`) now
  check `if (mounted)` before `setState`. Without this, navigating away
  from chat while the microphone was active crashed on the next speech event.
- **Ban dialog navigation with invalidated context** — `Navigator.pop(ctx)`
  followed by `Navigator.pushAndRemoveUntil(ctx, ...)` used the dialog's
  disposed BuildContext. Changed to use the outer widget `context`.
- **Force unwrap on `auth.currentUser!`** — replaced with null-safe check
  using `auth.currentUser` with an early return, preventing crash when
  Firebase session is null after `user.reload()`.
- **Memory leak: 9 controllers never disposed** across `edit_profile_screen`
  (4), `love_match_screen` (2), `kundli_input_screen` (4), and
  `onboarding_screen` (1). Added `dispose()` overrides for each state.
- **`getUserDob` silently corrupting zodiac** — removed today's-date default
  when DOB is unset, now returns empty string. Prevents assigning a
  random sign to new users based solely on current calendar date.
- **Notification badge now shows unread count number** (was a tiny 8px red
  dot virtually invisible on dark theme). Capped at "99+" for overflow.
- Added `APP_GEMINI_API_KEY` to `assets/.env.example` so local dev can
  override the Firestore-fetched key.

### Security
- Same posture as before: Gemini API key fetched from Firestore at
  runtime, never bundled in the APK. The Firestore document path
  changed but the retrieval model is identical.

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
- **Dynamic morning/evening notifications were firing on wrong days**: `scheduleDynamicNotifications` used `matchDateTimeComponents.time` which makes all scheduled notifications become daily recurring alarms at the next matching time (8 AM / 7 PM), not on their intended future dates. Fixed by scheduling each day as a one-time `DateTimeComponents.dateAndTime` notification.
- **Weekly evening notifications (Mon/Wed/Fri/Sat 8:30 PM) relied on fragile `dayOfWeekAndTime` behavior**: the plugin fires on the *next* matching day-of-week+time from now, not "first on/after scheduledDate". Replaced with explicit 4-week one-time schedules (16 notifications) using `DateTimeComponents.dateAndTime`.
- **Missing Android boot receivers**: flutter_local_notifications v17+ requires manual declaration of `ScheduledNotificationBootReceiver` + `ScheduledNotificationReceiver` in `AndroidManifest.xml` for notifications to reschedule after device reboot on Android 14+. Added both receivers with proper intent filters.

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

[Unreleased]: https://github.com/dhanuk/astroguru/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/dhanuk/astroguru/compare/v1.0.0...v1.0.1
