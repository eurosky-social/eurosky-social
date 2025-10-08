#!/bin/sh
set -e

DID_FILE="/data/ozone-admin-did.txt"

if [ ! -f "$DID_FILE" ]; then
  echo "ERROR: $DID_FILE not found. setup-ozone must run first."
  exit 1
fi

OZONE_DID=$(cat "$DID_FILE")
echo "Using Ozone DID: $OZONE_DID"

export HEPA_OZONE_DID="$OZONE_DID"
exec dumb-init -- /hepa run
