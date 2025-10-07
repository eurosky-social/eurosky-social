#!/bin/sh
set -e

echo "Reading Ozone admin DID..."
OZONE_DID=$(cat /ozone-data/ozone-admin-did.txt)
echo "Ozone DID: $OZONE_DID"

echo "Restarting PDS with updated moderation service DID..."
# Signal PDS to restart with the new DID
# Docker Compose will handle the actual restart
echo "$OZONE_DID" > /pds-data/.ozone-did-configured
echo "✅ Configuration complete"
