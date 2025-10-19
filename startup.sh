#!/bin/bash
set -e

# Load environment if .env exists
if [ -f .env ]; then
    source .env
fi

# Run setup-ozone as a one-off task (won't be restarted by subsequent 'up' commands)
docker compose run --rm setup-ozone

# Read the DID file and export the admin DID
ADMIN_DID_FILE="./tests/data/ozone-admin-did.txt"
if [ ! -f "$ADMIN_DID_FILE" ]; then
    echo "ERROR: $ADMIN_DID_FILE not found. setup-ozone must run first."
    exit 1
fi
ADMIN_DID=$(cat "$ADMIN_DID_FILE")
export OZONE_ADMIN_DIDS="$ADMIN_DID"
export OZONE_ADMIN_DID="$ADMIN_DID"  # For ozone.yml OZONE_ADMIN_DIDS variable
export PDS_MOD_SERVICE_DID="$ADMIN_DID"
echo "Using admin DID: $ADMIN_DID"

# Recreate PDS with the admin DID environment variable
docker compose up -d --force-recreate pds

# Start all remaining services
docker compose up -d --wait
