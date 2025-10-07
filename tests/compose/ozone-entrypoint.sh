#!/bin/sh
set -e

# Wait for DID file from setup-ozone
DID_FILE="/data/ozone-admin-did.txt"

echo "Waiting for setup-ozone to create DID file..."
while [ ! -f "$DID_FILE" ]; do
  sleep 1
done

ADMIN_DID=$(cat "$DID_FILE")
echo "Using admin DID: $ADMIN_DID"

# Set environment variables and start Ozone with the original entrypoint
OZONE_ADMIN_DIDS="$ADMIN_DID" OZONE_SERVER_DID="$ADMIN_DID" exec dumb-init -- node --enable-source-maps service/index.js
