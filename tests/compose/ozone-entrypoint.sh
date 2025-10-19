#!/bin/sh
set -e

# Check if OZONE_ADMIN_DIDS is already set (from startup script)
if [ -n "$OZONE_ADMIN_DIDS" ]; then
  echo "Using admin DID from environment: $OZONE_ADMIN_DIDS"
  ADMIN_DID="$OZONE_ADMIN_DIDS"
else
  # Fall back to reading from file (legacy behavior)
  DID_FILE="/data/ozone-admin-did.txt"
  if [ ! -f "$DID_FILE" ]; then
    echo "ERROR: $DID_FILE not found and OZONE_ADMIN_DIDS not set. setup-ozone must run first."
    exit 1
  fi
  ADMIN_DID=$(cat "$DID_FILE")
  echo "Using admin DID from file: $ADMIN_DID"
  export OZONE_ADMIN_DIDS="$ADMIN_DID"
fi

export OZONE_SERVER_DID="$ADMIN_DID"

# Export runtime config vars for Next.js to read in app/layout.tsx
# These override the NEXT_PUBLIC_ prefixed vars
export PLC_DIRECTORY_URL
export HANDLE_RESOLVER_URL

exec dumb-init -- node --enable-source-maps service/index.js
