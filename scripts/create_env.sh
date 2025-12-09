#!/bin/bash
set -e

# Create assets/.env
mkdir -p assets
echo "Creating assets/.env..."
# Only add keys if they are set in the environment
[ -n "$APP_GROQ_API_KEY" ] && echo "APP_GROQ_API_KEY=$APP_GROQ_API_KEY" >> assets/.env
[ -n "$GROQ_API_KEY" ] && echo "APP_GROQ_API_KEY=$GROQ_API_KEY" >> assets/.env # Mapping for CI
[ -n "$APP_ONESIGNAL_APP_ID" ] && echo "APP_ONESIGNAL_APP_ID=$APP_ONESIGNAL_APP_ID" >> assets/.env
[ -n "$APP_ONESIGNAL_API_KEY" ] && echo "APP_ONESIGNAL_API_KEY=$APP_ONESIGNAL_API_KEY" >> assets/.env
[ -n "$ADMOB_BANNER_ID" ] && echo "APP_ADMOB_BANNER_ID=$ADMOB_BANNER_ID" >> assets/.env
[ -n "$ADMOB_INTERSTITIAL_ID" ] && echo "APP_ADMOB_INTERSTITIAL_ID=$ADMOB_INTERSTITIAL_ID" >> assets/.env
[ -n "$ADMOB_REWARDED_ID" ] && echo "APP_ADMOB_REWARDED_ID=$ADMOB_REWARDED_ID" >> assets/.env

# Add other keys as needed
echo "Assets env created."

# Create google-services.json
if [ -n "$APP_FIREBASE_JSON_BASE64" ]; then
    echo "Creating google-services.json from APP_FIREBASE_JSON_BASE64..."
    echo "$APP_FIREBASE_JSON_BASE64" | base64 --decode | tr -d '\n' > android/app/google-services.json
elif [ -n "$FIREBASE_JSON_BASE64" ]; then
    echo "Creating google-services.json from FIREBASE_JSON_BASE64..."
    echo "$FIREBASE_JSON_BASE64" | base64 --decode | tr -d '\n' > android/app/google-services.json
else
    echo "Warning: No Firebase JSON base64 variable found. google-services.json might be missing."
fi
