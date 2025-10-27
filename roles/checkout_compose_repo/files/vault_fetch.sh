#!/usr/bin/env bash
set -euo pipefail

SECRETS_DIR="/secrets"
SECRETS_FILE="$SECRETS_DIR/.env"
LOG_FILE="/var/log/doppler_fetch.log"

mkdir -p "$SECRETS_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

{
    echo "==========================================="
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Fetching secrets from Doppler"

    TMP_FILE="$(mktemp)"

    # Fetch secrets from Doppler
    if doppler --project wtr_pro --config apps secrets download --no-file --format docker > "$TMP_FILE" 2>>"$LOG_FILE"; then
        if [[ ! -s "$TMP_FILE" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Doppler returned an empty file!"
            rm -f "$TMP_FILE"
            exit 1
        fi

        # Normalize line endings (cross-platform)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/\r$//' "$TMP_FILE"
        else
            sed -i 's/\r$//' "$TMP_FILE"
        fi

        # Overwrite .env with export-ready lines
        awk '/^[A-Za-z_][A-Za-z0-9_]*=/{print "export " $0}' "$TMP_FILE" > "$SECRETS_FILE"
        chmod 600 "$SECRETS_FILE"

        rm -f "$TMP_FILE"

        echo "$(date '+%Y-%m-%d %H:%M:%S') - Secrets successfully written to $SECRETS_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Doppler command failed"
        exit 1
    fi
} >> "$LOG_FILE" 2>&1
