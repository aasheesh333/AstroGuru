#!/bin/bash

# Define the output file
ENV_FILE="assets/.env"

# Ensure assets directory exists
mkdir -p assets

# Clear the file
echo "" > "$ENV_FILE"

echo "Generating $ENV_FILE from environment variables..."

# Function to write env var
write_env() {
    local key=$1
    local local_key="APP_$key"
    local ci_key="$key"
    local value=""

    # Check for local key (APP_PREFIX)
    if [ ! -z "${!local_key}" ]; then
        value="${!local_key}"
        echo "Found local variable: $local_key"
    # Check for CI key (NO PREFIX)
    elif [ ! -z "${!ci_key}" ]; then
        value="${!ci_key}"
        echo "Found CI variable: $ci_key"
    fi

    # Write to file if value is found
    if [ ! -z "$value" ]; then
        echo "APP_$key=$value" >> "$ENV_FILE"
    else
        echo "Warning: Variable $key not found in environment."
    fi
}

# List of variables to check
# These correspond to keys used in dotenv.env['APP_...'] in the Dart code
write_env "ONESIGNAL_APP_ID"
write_env "GROQ_API_KEY"

# Optional: write other variables if they might be needed in .env later,
# though only the above two are strictly required by the current Dart code.
# write_env "ADMOB_APP_ID"

echo "$ENV_FILE generated."
cat "$ENV_FILE"
