# Eurosky Infrastructure

Kubernetes on Scaleway with Ozone moderation and Bluesky PDS.

## Setup

```bash
cd envs/scaleway
cp .env.example .env 
# Edit .env and fill in all required variables

source .env

# First time: Create buckets for terraform state
scw object bucket create name=${STATE_BUCKET} region=${SCW_DEFAULT_REGION}

# First time: Create buckets for backups and PDS blobs (avoid managing with Terraform to not risk deletion)
scw object bucket create name=${TF_VAR_backup_bucket_name} region=${SCW_DEFAULT_REGION}
scw object bucket create name=${TF_VAR_pds_blobstore_bucket_name} region=${SCW_DEFAULT_REGION}

# Deploy
terraform init -backend-config="bucket=$STATE_BUCKET"  -backend-config="endpoint=$AWS_ENDPOINT_URL_S3" 
terraform plan -out=tfplan
terraform apply tfplan

# Get kubeconfig
scw k8s kubeconfig install $(terraform output -raw cluster_id | sed -E "s/fr-par\/(.*)%/\1/")
```
