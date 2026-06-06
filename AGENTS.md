# AGENTS.md

AstroPrerna — Flutter 3.24.5 / Dart `>=3.4.0 <4.0.0`. **Android-only**: there is no `ios/` directory and no iOS build job in CI. Do not add iOS-only plugins or assume Cupertino paths.

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
- `lib/logic/` — pure Dart: `KundliService`, `StaticCities`, `KeyManager`, validators, `love_match_logic`
- `lib/services/` — `AdService`, `NotificationService`, `AIService`
- `lib/screens/` — UI; one file per screen
- `lib/widgets/` — reusable (`AdLockedWidget`, `AstroCard`, `GradientButton`, …)
- `lib/theme/app_colors.dart` — the **only** place for color tokens
- `lib/l10n/app_en.arb` — English template; 12 sibling ARB files
- `functions/` — Firebase Cloud Functions (Node 20, TypeScript); `src/index.ts` `groqProxy` is the AI gateway
- `scripts/create_env.sh` — CI helper that materializes `assets/.env`, `android/app/google-services.json`, and the keystore from GitHub secrets
- `firebase-debug.log` — transient; safe to delete, gets regenerated on the next `firebase` command

## Hard constraints (would break the app if violated)

- **Groq API key never ships in the APK.** All AI calls go through the `groqProxy` Cloud Function. The key lives in the Firestore doc `groq_api_keys/groq_api_list` (single key, no rotation; update manually when needed — Groq suspends accounts that rotate). `lib/logic/key_manager.dart` only checks presence; it does not read `.env` for the key.
- **`assets/.env` is never bundled in release.** It is in `.gitignore`. CI passes values via `--dart-define` and re-creates the file from secrets during the build step only. Do not remove it from `.gitignore` and do not reference it as a Flutter asset.
- **No `Color(0xFF...)` literals** in feature code. Add or reuse a token in `lib/theme/app_colors.dart`.
- **No hardcoded English** in `lib/screens/` or `lib/widgets/`. Add the key to `lib/l10n/app_en.arb` first, mirror it into the other 12 ARB files, then run `flutter gen-l10n`. Use `AppLocalizations.of(context)!.yourKey`.
- **Per-user SharedPreferences namespacing.** Prefix every key with the user id (`uid_…`) so logout/login does not leak data across accounts.
- **Profile images** live at `users/{uid}/avatar.jpg` in Firebase Storage. Base64 in SharedPreferences is a legacy fallback that is lazy-migrated to Storage on next sign-in; new code should always use the download URL.
- **Android security flags** are set in `android/app/src/main/AndroidManifest.xml` (`usesCleartextTraffic="false"`, `allowBackup="false"`, `dataExtractionRules`, `network_security_config.xml`). Do not relax them.

## Env & secrets

`AppConfig` resolves each value as: `--dart-define=KEY=value` (CI) → `assets/.env` (local dev). For local work, copy `assets/.env.example` to `assets/.env` and fill in the public AdMob / OneSignal / Firebase values. If `.env` is missing the app falls back to test ad unit IDs in debug mode and skips OneSignal. A `APP_GROQ_API_KEY` in `assets/.env` is **not** bundled in release builds (it exists only to let local dev exercise `AIService` without a Firestore round-trip).

CI invokes `scripts/create_env.sh`, which also writes `android/app/google-services.json` from `FIREBASE_JSON_BASE64` / `APP_FIREBASE_JSON_BASE64`, and decodes the keystore + `android/key.properties` from `KEYSTORE_*` / `APP_KEYSTORE_*` secrets. The `create_env.sh` script is the single source of truth for the secret → file mapping; keep it in sync with `.github/workflows/build.yml` step "Configure Keystore" if you change either.

## Cloud Functions & Firebase

```bash
cd functions && npm install && npm run build
firebase deploy --only functions
firebase deploy --only storage
```

Firebase project: `astroprerna-7ee7c` (alias in `.firebaserc`). The Cloud Functions API must be enabled on the project, and the deployer account needs `cloudfunctions.functions.list` and `run.services.list` (see `firebase-debug.log` for an example of the failure when these are missing).

## Conventions

- State management: `provider` package, exposed via `MultiProvider` in `main.dart`. New `ChangeNotifier`s go in `lib/logic/` and are registered in `main.dart`.
- Routing: named routes on `MaterialApp` in `main.dart`. Add new top-level routes there; sub-screens use `Navigator.push` with `MaterialPageRoute`.
- Ads: `AdService` rejects test ad unit IDs in release mode and throws on missing config — never catch-and-ignore a `AdService` throw. Only the rewarded / interstitial flows are wired (for `AdLockedWidget`); banner ads are intentionally not used.
- Fonts: `google_fonts` package; do not bundle font files in `assets/`.
- Tests: `mocktail` for mocking. The existing tests are in `test/` (`widget_test.dart`, `edit_profile_layout_test.dart`, `static_cities_test.dart`, `love_match_logic_test.dart`). Add new tests next to the unit under test, mirroring the existing style.

## Common tasks

- **Add a localized string:** `app_en.arb` → other 12 ARBs → `flutter gen-l10n` → reference via `AppLocalizations.of(context)!.keyName`.
- **Add a color:** edit `lib/theme/app_colors.dart`; reference the new constant elsewhere.
- **Regenerate launcher icons:** `dart run flutter_launcher_icons` (config in `pubspec.yaml`).
- **Bump `compileSdk` / `targetSdk` / `minSdk`:** `android/app/build.gradle`. Bump the matching `compileSdkVersion`/`minSdkVersion` in any plugin `build.gradle` files too.

## Out of scope

- Firebase Crashlytics and Analytics — intentionally deferred. Uncaught errors are logged via `dart:developer` `log` (visible in `adb logcat` under the `AstroPrerna` logger name); a global `FlutterError.onError` and `PlatformDispatcher.onError` are installed in `main.dart`. Do not add `firebase_crashlytics` / `firebase_analytics` without first resolving the `firebase_core` / `firebase_storage` major-version conflict noted in `CHANGELOG.md`.
- iOS — no `ios/` directory exists and CI does not build it.
