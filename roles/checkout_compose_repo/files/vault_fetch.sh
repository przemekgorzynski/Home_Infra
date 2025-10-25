#!/usr/bin/env bash
set -euo pipefail

SECRETS_FILE="/secrets/.env"
mkdir -p ./secrets

echo "$(date '+%Y-%m-%d %H:%M:%S') - Fetching secrets from Doppler"

if doppler --project wtr_pro --config apps secrets download --no-file --format docker > "$SECRETS_FILE"; then
    chmod 600 "$SECRETS_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Secrets written to $SECRETS_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to fetch secrets" >&2
fi
