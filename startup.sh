#!/bin/bash
set -ex

# Load environment if .env exists
if [ -f .env ]; then
    source .env
fi

docker compose up -d --wait bsky

sleep 5

docker compose run --rm setup-ozone

# Read the DID file and export the admin DID
ADMIN_DID_FILE="./tests/data/ozone-admin-did.txt"
if [ ! -f "$ADMIN_DID_FILE" ]; then
    echo "ERROR: $ADMIN_DID_FILE not found. setup-ozone must run first."
    exit 1
fi
ADMIN_DID=$(cat "$ADMIN_DID_FILE")
export OZONE_ADMIN_DIDS="$ADMIN_DID"
export OZONE_ADMIN_DID="$ADMIN_DID"
export PDS_MOD_SERVICE_DID="$ADMIN_DID"
export ATP_DEFAULT_LABELER_DID="$ADMIN_DID"
echo "Using admin DID: $ADMIN_DID"

docker compose up -d --force-recreate bsky

# Start remaining services
echo "Starting remaining services..."
docker compose up -d --wait