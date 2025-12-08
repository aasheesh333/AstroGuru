#!/bin/bash

# Decode google-services.json from base64 environment variable
if [ -n "$FIREBASE_JSON_BASE64" ]; then
    echo "Creating google-services.json..."
    echo "$FIREBASE_JSON_BASE64" | base64 -d > android/app/google-services.json
    echo "google-services.json created."
else
    echo "FIREBASE_JSON_BASE64 not found, skipping google-services.json creation."
fi

echo "Creating assets/.env file..."
cat <<EOF > assets/.env
APP_ONESIGNAL_APP_ID=$ONESIGNAL_APP_ID
APP_ONESIGNAL_API_KEY=$ONESIGNAL_API_KEY
APP_ADMOB_APP_ID=$ADMOB_APP_ID
APP_ADMOB_BANNER_ID=$ADMOB_BANNER_ID
APP_ADMOB_INTERSTITIAL_ID=$ADMOB_INTERSTITIAL_ID
APP_ADMOB_REWARDED_ID=$ADMOB_REWARDED_ID
APP_GROQ_API_KEY=$GROQ_API_KEY
APP_PACKAGE_NAME=$PACKAGE_NAME
APP_VERSION_CODE=$VERSION_CODE
APP_VERSION_NAME=$VERSION_NAME
EOF
echo ".env file created."
