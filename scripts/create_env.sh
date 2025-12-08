#!/bin/bash

# Function to decode base64 safely (removing newlines)
decode_base64() {
    echo "$1" | tr -d '\n' | base64 -d
}

# Decode google-services.json
if [ -n "$FIREBASE_JSON_BASE64" ]; then
    echo "Creating google-services.json from FIREBASE_JSON_BASE64..."
    decode_base64 "$FIREBASE_JSON_BASE64" > android/app/google-services.json
    echo "google-services.json created."
elif [ -n "$APP_FIREBASE_JSON_BASE64" ]; then
    echo "Creating google-services.json from APP_FIREBASE_JSON_BASE64..."
    decode_base64 "$APP_FIREBASE_JSON_BASE64" > android/app/google-services.json
    echo "google-services.json created."
else
    echo "FIREBASE_JSON_BASE64 or APP_FIREBASE_JSON_BASE64 not found, skipping google-services.json creation."
fi

# Local Keystore Setup (for local builds/sandbox using APP_ variables)
# Only create if they don't exist to avoid overwriting existing local config
if [ ! -f android/upload-keystore.jks ] && [ -n "$APP_KEYSTORE_BASE64" ]; then
    echo "Creating android/upload-keystore.jks from APP_KEYSTORE_BASE64..."
    decode_base64 "$APP_KEYSTORE_BASE64" > android/upload-keystore.jks
    echo "android/upload-keystore.jks created."
fi

if [ ! -f android/key.properties ] && [ -n "$APP_KEYSTORE_PASSWORD" ]; then
    echo "Creating android/key.properties from APP_ variables..."
    echo "storePassword=$APP_KEYSTORE_PASSWORD" > android/key.properties
    echo "keyPassword=$APP_KEY_PASSWORD" >> android/key.properties
    # Default alias if not specified
    if [ -n "$APP_KEY_ALIAS" ]; then
        echo "keyAlias=$APP_KEY_ALIAS" >> android/key.properties
    else
        echo "keyAlias=mykey" >> android/key.properties
    fi
    echo "storeFile=../upload-keystore.jks" >> android/key.properties
    echo "android/key.properties created."
fi

# Map Environment Variables (Prioritize CI/Env vars, fallback to APP_ prefixed)
OS_APP_ID=${ONESIGNAL_APP_ID:-$APP_ONESIGNAL_APP_ID}
OS_API_KEY=${ONESIGNAL_API_KEY:-$APP_ONESIGNAL_API_KEY}
AM_APP_ID=${ADMOB_APP_ID:-$APP_ADMOB_APP_ID}
AM_BANNER_ID=${ADMOB_BANNER_ID:-$APP_ADMOB_BANNER_ID}
AM_INTER_ID=${ADMOB_INTERSTITIAL_ID:-$APP_ADMOB_INTERSTITIAL_ID}
AM_REWARD_ID=${ADMOB_REWARDED_ID:-$APP_ADMOB_REWARDED_ID}
G_API_KEY=${GROQ_API_KEY:-$APP_GROQ_API_KEY}
PKG_NAME=${PACKAGE_NAME:-$APP_PACKAGE_NAME}
V_CODE=${VERSION_CODE:-$APP_VERSION_CODE}
V_NAME=${VERSION_NAME:-$APP_VERSION_NAME}

echo "Creating assets/.env file..."
cat <<EOF > assets/.env
APP_ONESIGNAL_APP_ID=$OS_APP_ID
APP_ONESIGNAL_API_KEY=$OS_API_KEY
APP_ADMOB_APP_ID=$AM_APP_ID
APP_ADMOB_BANNER_ID=$AM_BANNER_ID
APP_ADMOB_INTERSTITIAL_ID=$AM_INTER_ID
APP_ADMOB_REWARDED_ID=$AM_REWARD_ID
APP_GROQ_API_KEY=$G_API_KEY
APP_PACKAGE_NAME=$PKG_NAME
APP_VERSION_CODE=$V_CODE
APP_VERSION_NAME=$V_NAME
EOF
echo ".env file created."
