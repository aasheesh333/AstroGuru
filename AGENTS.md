# AGENTS.md

AstroPrerna — Flutter 3.29.3 / Dart `>=3.6.0 <4.0.0`. **Android-only**: there is no `ios/` directory and no iOS build job in CI. Do not add iOS-only plugins or assume Cupertino paths.

## Quick start

```bash
flutter pub get
flutter gen-l10n                          # regenerate AppLocalizations from lib/l10n/*.arb
cp assets/.env.example assets/.env        # one-time, before first local run
flutter run -d <device>
```

## Verification (mirrors CI)

```bash
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test --no-pub
```

`.github/workflows/build.yml` runs both on every push and PR, then builds `apk` and `appbundle` release artifacts. There is no iOS job. Concurrency cancels in-progress runs on the same ref.

## Layout

- `lib/main.dart` — app entry; wires Firebase, providers (`LanguageProvider`, `UserProvider`), and services
- `lib/config/app_config.dart` — env resolution; see "Env & secrets" below
- `lib/logic/` — pure Dart: `KundliService`, `StaticCities`, `KeyManager`, `InterestTracker`, validators, `love_match_logic`
- `lib/services/` — `AdService`, `NotificationService`, `AIService`
- `lib/screens/` — UI; one file per screen
- `lib/widgets/` — reusable (`AdLockedWidget`, `AstroCard`, `GradientButton`, `AstroTextParser`, `BabaAvatar`)
- `lib/theme/app_colors.dart` — the **only** place for color tokens
- `lib/l10n/app_en.arb` — English template; 12 sibling ARB files (all must have identical keys)
- `scripts/create_env.sh` — CI helper that materializes `assets/.env`, `android/app/google-services.json`, and the keystore from GitHub secrets
- `firebase-debug.log` — transient; safe to delete, gets regenerated on the next `firebase` command

## Hard constraints (would break the app if violated)

- **Gemini API key never ships in the APK.** All AI calls go through `AIService` which uses the `x-goog-api-key` header. The key lives in the Firestore doc `gemini_api_keys/gemini_api_list` (single key, no rotation). `lib/logic/key_manager.dart` fetches the key from Firestore and caches it for the session. Local dev can override via `APP_GEMINI_API_KEY` in `assets/.env`.
- **`assets/.env` is never bundled in release.** It is in `.gitignore`. CI passes values via `--dart-define` and re-creates the file from secrets during the build step only. Do not remove it from `.gitignore` and do not reference it as a Flutter asset.
- **No `Color(0xFF...)` literals** in feature code. Add or reuse a token in `lib/theme/app_colors.dart`.
- **No `withOpacity()`** — use `withValues(alpha: ...)` instead (Flutter 3.27+ safe).
- **No hardcoded English** in `lib/screens/` or `lib/widgets/`. Add the key to `lib/l10n/app_en.arb` first, mirror it into the other 12 ARB files, then run `flutter gen-l10n`. Use `AppLocalizations.of(context)!.yourKey`. All ARB keys must be `camelCase`.
- **Per-user SharedPreferences namespacing.** Prefix every key with the user id (`uid_…`) so logout/login does not leak data across accounts.
- **Profile images** live at `users/{uid}/avatar.jpg` in Firebase Storage. Base64 in SharedPreferences is a legacy fallback that is lazy-migrated to Storage on next sign-in; new code should always use the download URL.
- **Android security flags** are set in `android/app/src/main/AndroidManifest.xml` (`usesCleartextTraffic="false"`, `allowBackup="false"`, `dataExtractionRules`, `network_security_config.xml`). Do not relax them.

## AI System (Google Gemini)

`AIService` calls the Gemini 3.5 Flash-Lite API (`gemini-3.5-flash-lite`) directly from the client with the key fetched from Firestore by `KeyManager`. The key is on the free tier (~15 RPM); `_postGemini` already retries 429s with exponential backoff (3 attempts, 1s→2s→4s). Bump the constant in `lib/services/ai_service.dart` whenever Google retires a model. Historical model rotation: `gemini-2.5-flash-lite` (deprecated mid-2026, HTTP 404) → `gemini-3.1-flash-lite` (intermittent 404s during deprecation rollout) → `gemini-3.5-flash-lite` (current, GA-stable). (`gemini-2.0-flash-lite` is NOT a safe fallback; that key has hit free-tier quota and returns 429.)

- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent` (non-streaming) and `:streamGenerateContent?alt=sse` (streaming).
- **Auth**: `x-goog-api-key` header (not Bearer token).
- **Message format conversion** happens inside `_postGemini` / `_buildGeminiBody`:
  - `role: "system"` → `systemInstruction.parts[0].text`
  - `role: "user"` → `contents[].role: "user"`
  - `role: "assistant"` → `contents[].role: "model"`
  - `max_tokens` → `generationConfig.maxOutputTokens`
  - `temperature` → `generationConfig.temperature`
  - `response_format: {type: "json_object"}` → `generationConfig.responseMimeType: "application/json"`
- **Thinking budget**: JSON-mode calls use `thinkingConfig.thinkingBudget: 512`; chat calls use `0` (disabled for fast streaming).
- **Streaming chat** via `getChatResponseStream()`: SSE parsing of `data:` lines yields text chunks. The chat screen subscribes and updates the UI incrementally.
- **Prompt builders** (`dailyHoroscopeSystemPrompt`, `chatResponseMessages`, etc.) return strings / message-lists in the **internal format** (system/user/assistant roles). Callers do not need to speak Gemini format — conversion is internal.

## Interest-based Notifications

`InterestTracker` records per-feature usage counts (horoscope, kundli, chat, love_match, remedies) in SharedPreferences and syncs them to Firestore (`users/{uid}.interests`) hourly. `NotificationService.bootstrapDynamic` reads these interests and passes them to `AIService.getNotificationSchedule` which weights AI-generated notification content toward the user's top interests. This is a fully free, server-side approach using Firestore + existing local notification scheduling.

## Env & secrets

`AppConfig` resolves each value as: `--dart-define=KEY=value` (CI) → `assets/.env` (local dev). For local work, copy `assets/.env.example` to `assets/.env` and fill in the public AdMob / OneSignal / Firebase values. If `.env` is missing the app falls back to test ad unit IDs in debug mode and skips OneSignal. A `APP_GEMINI_API_KEY` in `assets/.env` is **not** bundled in release builds.

CI invokes `scripts/create_env.sh`, which also writes `android/app/google-services.json` from `FIREBASE_JSON_BASE64` / `APP_FIREBASE_JSON_BASE64`, and decodes the keystore + `android/key.properties` from `KEYSTORE_*` / `APP_KEYSTORE_*` secrets. The `create_env.sh` script is the single source of truth for the secret → file mapping; keep it in sync with `.github/workflows/build.yml` step "Configure Keystore" if you change either.

## Android Build

- `compileSdk 36` / `targetSdk 36` / `minSdk 24`
- AGP `8.7.3` / Kotlin `2.0.21` / Gradle `8.11.1`
- `ext.flutter` block in root `android/build.gradle` must match app `build.gradle` for plugin compat
- `desugar_jdk_libs: 2.2.0` for API 36 support

## Firebase

Firebase project: `astroprerna-7ee7c` (alias in `.firebaserc`). Cloud Functions are not deployed. API keys and user data live in Firestore collections (`gemini_api_keys`, `users`, `password_resets`).

## Conventions

- State management: `provider` package, exposed via `MultiProvider` in `main.dart`. New `ChangeNotifier`s go in `lib/logic/` and are registered in `main.dart`.
- Routing: named routes on `MaterialApp` in `main.dart`. Add new top-level routes there; sub-screens use `Navigator.push` with `MaterialPageRoute`.
- Ads: `AdService` rejects test ad unit IDs in release mode and throws on missing config — never catch-and-ignore a `AdService` throw. Only the rewarded / interstitial flows are wired (for `AdLockedWidget`); banner ads are intentionally not used.
- Fonts: `google_fonts` package; do not bundle font files in `assets/`.
- Tests: `mocktail` for mocking. The existing tests are in `test/` (`widget_test.dart`, `edit_profile_layout_test.dart`, `static_cities_test.dart`, `love_match_logic_test.dart`, `ai_service_prompts_test.dart`, `ai_service_language_test.dart`). Add new tests next to the unit under test, mirroring the existing style.
- Share: use `share_plus` package for sharing content. The "Share App" item is in the profile screen.

## Common tasks

- **Add a localized string:** `app_en.arb` → other 12 ARBs → `flutter gen-l10n` → reference via `AppLocalizations.of(context)!.yourKey`. All keys must be `camelCase`.
- **Add a color:** edit `lib/theme/app_colors.dart`; reference the new constant elsewhere.
- **Regenerate launcher icons:** `dart run flutter_launcher_icons` (config in `pubspec.yaml`).
- **Bump `compileSdk` / `targetSdk` / `minSdk`:** `android/app/build.gradle`. Bump the matching `compileSdkVersion`/`minSdkVersion` in `android/build.gradle` `ext.flutter` block too.
- **Rotate Gemini key:** update the Firestore doc `gemini_api_keys/gemini_api_list` via Firebase Console. No code changes needed. The KeyManager re-fetches on next cold start.

## Out of scope

- Firebase Crashlytics and Analytics — intentionally deferred. Uncaught errors are logged via `dart:developer` `log` (visible in `adb logcat` under the `AstroPrerna` logger name); a global `FlutterError.onError` and `PlatformDispatcher.onError` are installed in `main.dart`.
- iOS — no `ios/` directory exists and CI does not build it.
- In-app review auto-trigger — moved to manual "Rate App" in profile screen only.
