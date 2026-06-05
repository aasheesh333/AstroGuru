# AstroPrerna

AstroPrerna is a Flutter-based Vedic astrology app for Android, supporting
13 Indian languages. The app offers kundli generation, AI chat with a Vedic
Guru persona, love-compatibility analysis, daily/weekly/monthly horoscopes,
and personalized remedies.

## Tech stack

- **Flutter 3.24.x** (Dart SDK >= 3.5)
- **Firebase**: Auth, Firestore, Storage, Cloud Functions, Crashlytics, Analytics
- **OneSignal** for push notifications
- **AdMob** for ads (banner / interstitial / rewarded)
- **Sweph** (Dart port) for Vedic chart calculation with **Lahiri ayanamsa**
- **Groq** (`llama-3.3-70b-versatile`) for AI text generation, called through
  a server-side Firebase Cloud Function proxy so the API key never ships
  in the APK
- **`flutter_localizations`** + ARB files for 13-language i18n

## Architecture

```
lib/
  config/         AppConfig — env (--dart-define → dotenv) resolution
  l10n/           13 ARB files (English + 12 Indic)
  logic/          Pure Dart: KundliService, StaticCities, validators,
                  love_match_logic, KeyManager (Firestore check)
  screens/        UI screens (chat, kundli, profile, ...)
  services/       AdService, NotificationService, AIService
  theme/          AppColors, AppTheme
  utils/          Validators, ZodiacUtils
  widgets/        Reusable widgets (banner ad, gradient button, ...)
  main.dart       App entry — wires Firebase, providers, services

functions/        Firebase Cloud Functions (Node 20, TypeScript)
  src/index.ts    groqProxy — the only place the Groq key lives

storage.rules     Firebase Storage rules
firebase.json     Firebase project config (storage, functions)
.firebaserc       Firebase project alias
```

### Key security & ops decisions

- **API keys never ship in the APK.** Groq is invoked through the
  `groqProxy` Cloud Function. The function reads the key from the
  `groq_api_keys/groq_api_list` Firestore document and caches it in
  memory for 5 minutes. The client only ever sees `{ content }` in
  the response.
- **Single key, no rotation.** Groq suspends accounts that rotate keys
  frequently. The single key is held in Firestore and updated manually
  by the operator.
- **Rate-limited proxy.** 30 calls/min and 500 calls/day per signed-in
  user. Client retries with exponential backoff (1s→8s, 4 attempts).
- **Per-user namespacing.** All SharedPreferences entries are prefixed
  with `uid_`, so logging out and logging in as a different user does
  not leak data.
- **Network security.** `usesCleartextTraffic="false"`, no backup,
  no data extraction, and a hard `network_security_config.xml`.
- **Profile images** are stored in Firebase Storage at
  `users/{uid}/avatar.jpg`. Legacy base64 images are lazy-migrated
  to Storage on next sign-in.

## Building a release

### Prerequisites

- Flutter 3.24.5 (stable)
- Java 17 (Zulu recommended for CI parity)
- Android SDK with `compileSdk = 35`, `targetSdk = 35`, `minSdk = 24`
- A Firebase project (default: `astroprerna-7ee7c`)

### Local debug build

```bash
flutter pub get
flutter gen-l10n
flutter run -d <device>
```

Local dev reads from `assets/.env` automatically. Copy the template:

```bash
cp assets/.env.example assets/.env
# Edit values for your AdMob / OneSignal / Firebase setup
```

If `assets/.env` is absent the app falls back to test ad unit IDs in
debug mode, and the OneSignal integration is skipped (no crash).

### Local release build

```bash
flutter build apk --release \
  --dart-define=APP_ADMOB_APP_ID=ca-app-pub-... \
  --dart-define=APP_ADMOB_BANNER_ID=ca-app-pub-... \
  --dart-define=APP_ADMOB_INTERSTITIAL_ID=ca-app-pub-... \
  --dart-define=APP_ADMOB_REWARDED_ID=ca-app-pub-... \
  --dart-define=APP_ONESIGNAL_APP_ID=...
```

Note: never pass a Groq key here. The client cannot read the key and
the function uses its own Firestore-backed secret.

### CI

`.github/workflows/build.yml` builds APK + AAB on every push and PR.
It is **Android-only** — there is no `ios/` folder. It also runs
`flutter analyze` and `flutter test`. The CI workflow materializes
`assets/.env` from GitHub secrets before building; see
`scripts/create_env.sh`.

### Cloud Functions

Deploy the AI proxy:

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

Make sure the Firestore doc `groq_api_keys/groq_api_list` exists and
contains at least one non-empty string field whose name doesn't matter
(the function picks the first one).

### Storage rules

```bash
firebase deploy --only storage
```

## i18n

The app supports 13 languages: English, Hindi, Bengali, Marathi, Tamil,
Telugu, Gujarati, Punjabi, Kannada, Malayalam, Odia, Assamese, Urdu.

Add a new key to `lib/l10n/app_en.arb` first, then add it (with the same
key name) to each of the other 12 ARB files. After editing, run
`flutter gen-l10n` to regenerate the `AppLocalizations` class.

## Testing

```bash
flutter test
```

Test files in `test/`:

- `widget_test.dart` — splash + routing smoke test
- `edit_profile_layout_test.dart` — field order and readonly-email layout
- `static_cities_test.dart` — geocoding fallback behaviour
- `love_match_logic_test.dart` — score range invariants

## Contributing

1. Branch from `edit-profile-forgot-password-…` (or the current default).
2. Keep `flutter analyze` clean and `flutter test` green.
3. New strings go to `app_en.arb` first, then are synced to the others.
4. Do not commit secrets; `assets/.env` is `.gitignore`d.
