#!/bin/sh
set -e

UPSTREAM_RELAY="${UPSTREAM_RELAY_HOST:-https://relay1.us-west.bsky.network}"
LOCAL_RELAY="${LOCAL_RELAY_HOST:-http://relay.relay.svc.cluster.local:2470}"
BATCH_SIZE="${BATCH_SIZE:-500}"

echo "$(date): Syncing hosts from ${UPSTREAM_RELAY} to ${LOCAL_RELAY}"

cursor=""
total_added=0
total_existing=0
total_errors=0

while true; do
  # Call listHosts on upstream relay
  if [ -z "$cursor" ]; then
    response=$(curl -sf "${UPSTREAM_RELAY}/xrpc/com.atproto.sync.listHosts?limit=${BATCH_SIZE}" || echo '{"hosts":[]}')
  else
    response=$(curl -sf "${UPSTREAM_RELAY}/xrpc/com.atproto.sync.listHosts?limit=${BATCH_SIZE}&cursor=${cursor}" || echo '{"hosts":[]}')
  fi

  # Extract hostnames with active/idle status
  hosts=$(echo "$response" | jq -r '.hosts[] | select(.status == "active" or .status == "idle") | .hostname')

  # Add each host via admin API
  for hostname in $hosts; do
    result=$(curl -sf -w "\n%{http_code}" \
      -X POST \
      -u "admin:${RELAY_ADMIN_PASSWORD}" \
      -H "Content-Type: application/json" \
      -d "{\"hostname\":\"${hostname}\"}" \
      "${LOCAL_RELAY}/admin/pds/requestCrawl" 2>/dev/null || echo "error\n000")

    http_code=$(echo "$result" | tail -n1)

    if [ "$http_code" = "200" ]; then
      total_added=$((total_added + 1))
      echo "  ✓ $hostname (new)"
    elif [ "$http_code" = "000" ]; then
      total_errors=$((total_errors + 1))
      echo "  ✗ $hostname (error)"
    else
      total_existing=$((total_existing + 1))
    fi
  done

  # Check for next page
  cursor=$(echo "$response" | jq -r '.cursor // empty')
  if [ -z "$cursor" ]; then
    break
  fi
done

echo "$(date): Sync complete. Added: $total_added, Existing: $total_existing, Errors: $total_errors"
