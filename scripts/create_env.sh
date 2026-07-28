#!/bin/bash
set -e

# Create a .env file with PUBLIC values for the build.
# AdMob IDs and OneSignal are public. The Gemini API key is stored in
# Firestore under `gemini_api_keys/gemini_api_list` and NEVER ships in the APK.
# The optional APP_GEMINI_API_KEY env var allows local dev to run without Firestore.
mkdir -p assets
echo "Creating assets/.env (public values, optional local Gemini key)..."
: > assets/.env

[ -n "$APP_ADMOB_APP_ID" ] && echo "APP_ADMOB_APP_ID=$APP_ADMOB_APP_ID" >> assets/.env
[ -n "$APP_ADMOB_BANNER_ID" ] && echo "APP_ADMOB_BANNER_ID=$APP_ADMOB_BANNER_ID" >> assets/.env
[ -n "$APP_ADMOB_INTERSTITIAL_ID" ] && echo "APP_ADMOB_INTERSTITIAL_ID=$APP_ADMOB_INTERSTITIAL_ID" >> assets/.env
[ -n "$APP_ADMOB_REWARDED_ID" ] && echo "APP_ADMOB_REWARDED_ID=$APP_ADMOB_REWARDED_ID" >> assets/.env
[ -n "$APP_ONESIGNAL_APP_ID" ] && echo "APP_ONESIGNAL_APP_ID=$APP_ONESIGNAL_APP_ID" >> assets/.env
[ -n "$APP_ONESIGNAL_API_KEY" ] && echo "APP_ONESIGNAL_API_KEY=$APP_ONESIGNAL_API_KEY" >> assets/.env
[ -n "$APP_GEMINI_API_KEY" ] && echo "APP_GEMINI_API_KEY=$APP_GEMINI_API_KEY" >> assets/.env

echo "Assets env created."

# Create google-services.json
# We use tr -d '\n' to ensure no newlines break the base64 decoding
if [ -n "$APP_FIREBASE_JSON_BASE64" ]; then
    echo "Creating google-services.json from APP_FIREBASE_JSON_BASE64..."
    echo "$APP_FIREBASE_JSON_BASE64" | tr -d '\n' | base64 --decode > android/app/google-services.json
elif [ -n "$FIREBASE_JSON_BASE64" ]; then
    echo "Creating google-services.json from FIREBASE_JSON_BASE64..."
    echo "$FIREBASE_JSON_BASE64" | tr -d '\n' | base64 --decode > android/app/google-services.json
else
    echo "Warning: No Firebase JSON base64 variable found. google-services.json might be missing."
fi

# Create key.properties and keystore
if [ -n "$APP_KEYSTORE_BASE64" ]; then
    echo "Decoding Keystore..."
    echo "$APP_KEYSTORE_BASE64" | tr -d '\n' | base64 --decode > android/app/upload-keystore.jks

    echo "Creating android/key.properties..."
    echo "storePassword=$APP_KEYSTORE_PASSWORD" > android/key.properties
    echo "keyPassword=$APP_KEY_PASSWORD" >> android/key.properties
    echo "keyAlias=${APP_KEY_ALIAS:-mykey}" >> android/key.properties
    echo "storeFile=upload-keystore.jks" >> android/key.properties
else
    echo "Warning: APP_KEYSTORE_BASE64 not found. Signed build will fail."
fi

