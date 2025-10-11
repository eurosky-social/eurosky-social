# Terraform Configuration for Eurosky

This directory contains Terraform configuration for deploying Eurosky infrastructure to Scaleway Serverless Containers.

## Prerequisites

1. **Scaleway Account** with API credentials
2. **Terraform** installed (v1.10+ for native S3 locking)
3. **Scaleway CLI** (scw) - for bucket creation
4. **GitHub CLI** (gh) - for uploading secrets (optional, used by bootstrap script)

## Quick Start

```bash
cp .env.example .env

# Edit .env with your Scaleway credentials

source .env

# Bootstrap is only needed the first time to create the S3 bucket and upload GitHub secrets
./bootstrap.sh

terraform init -backend-config="bucket=$STATE_BUCKET"
terraform plan
terraform apply
```
