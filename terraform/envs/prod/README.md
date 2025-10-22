# Eurosky Infrastructure

Kubernetes on Scaleway with Ozone moderation and Bluesky PDS.

## Setup

```bash
cd envs/dev  # or envs/prod
cp .env.example .env && cp terraform.auto.tfvars.example terraform.auto.tfvars
# Edit both files

source .env

# First time: Create buckets for terraform state
scw object bucket create name="terraform-state-bucket-${SCW_DEFAULT_PROJECT_ID}" region="${SCW_DEFAULT_REGION}"

# First time: Create buckets for backups and PDS blobs (avoid managing with Terraform to not risk deletion)
scw object bucket create name=eurosky-backups-${SUBDOMAIN} region="${SCW_DEFAULT_REGION}"
scw object bucket create name=eurosky-pds-blobs-${SUBDOMAIN} region="${SCW_DEFAULT_REGION}"

# Deploy
terraform init -backend-config="bucket=$STATE_BUCKET"
terraform plan -out=tfplan
terraform apply tfplan

# Get kubeconfig
scw k8s kubeconfig install $(terraform output -raw cluster_id)
```
