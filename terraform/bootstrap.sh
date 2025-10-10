#!/bin/bash
set -e

if ! command -v scw &> /dev/null; then
    echo "Error: Scaleway CLI (scw) not installed"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) not installed"
    exit 1
fi

if [ ! -f .env ]; then
    echo "Error: .env file not found. Run: cp .env.example .env"
    exit 1
fi

source .env

REQUIRED_SECRETS=(
    "SCW_ACCESS_KEY"
    "SCW_SECRET_KEY"
    "SCW_DEFAULT_PROJECT_ID"
    "SCW_DEFAULT_ORGANIZATION_ID"
    "SCW_DEFAULT_REGION"
    "SCW_DEFAULT_ZONE"
    "STATE_BUCKET"
)

REQUIRED_VARS=(
    "TF_VAR_hostname"
)

for var in "${REQUIRED_SECRETS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var not set in .env"
        exit 1
    fi
done

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var not set in .env"
        exit 1
    fi
done

if ! scw object bucket create name="$STATE_BUCKET" region="$SCW_DEFAULT_REGION" 2>/dev/null; then
    if ! scw object bucket list | grep -q "$STATE_BUCKET"; then
        echo "Error: Failed to create bucket"
        exit 1
    fi
fi

if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI. Run: gh auth login"
    exit 1
fi

for secret in "${REQUIRED_SECRETS[@]}"; do
    echo "${!secret}" | gh secret set "$secret"
done

for var in "${REQUIRED_VARS[@]}"; do
    echo "${!var}" | gh variable set "$var"
done

echo "Bootstrap complete. Bucket: $STATE_BUCKET"
