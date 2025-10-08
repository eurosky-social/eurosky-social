#!/bin/sh
set -e

DID_FILE="/data/ozone-admin-did.txt"

if [ ! -f "$DID_FILE" ]; then
  echo "ERROR: $DID_FILE not found. setup-ozone must run first."
  exit 1
fi

ADMIN_DID=$(cat "$DID_FILE")
echo "Using admin DID: $ADMIN_DID"

OZONE_ADMIN_DIDS="$ADMIN_DID" OZONE_SERVER_DID="$ADMIN_DID" exec dumb-init -- node --enable-source-maps service/index.js
