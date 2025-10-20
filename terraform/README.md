# Terraform Configuration for Eurosky

Deploys Kubernetes infrastructure to Scaleway with Ozone moderation service and Bluesky PDS.

## Prerequisites

1. **Scaleway Account** with API credentials
2. **Terraform** v1.10+
3. **Scaleway CLI** (scw)

## Quick Start

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with Scaleway credentials and generate secrets (see .env.example comments)

# 2. Bootstrap (first time only - creates S3 state bucket)
source .env
./bootstrap.sh

# 3. Deploy
terraform init -backend-config="bucket=$STATE_BUCKET"
terraform plan
terraform apply

# 4. Get kubeconfig
scw k8s kubeconfig install $(terraform output -raw cluster_id)
```
