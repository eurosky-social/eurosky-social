# Upcloud

## Setup

```bash
cd envs/upcloud
cp .envrc.example .envrc && cp terraform.auto.tfvars.example terraform.auto.tfvars
# Edit both files

# Option 1: Using direnv (auto-loads/unloads on directory change)
direnv allow

# Option 2: Manual source (once per shell session)
source .envrc

$STORAGE_SERVICE_NAME="your-storage-service"
upctl objectstorage create --name $STORAGE_SERVICE_NAME --region europe-1
upctl object-storage bucket create $STORAGE_SERVICE_NAME --name terraform-state
upctl objectstorage user create $STORAGE_SERVICE_NAME --username terraform-state
upctl objectstorage access-key create $STORAGE_SERVICE_NAME --username terraform-state
# Copy access_key_id and secret_access_key from output above to .env

upctl objectstorage show eurosky-storage -o json | jq -r '.endpoints[0].domain_name'
# Copy domain to AWS_ENDPOINT_URL_S3 in .env

# Log in the console, assign the user access to the bucket
## TODO: find a way to do this via CLI
```

# Deploy
terraform init -backend-config="bucket=$STATE_BUCKET" -backend-config="endpoint=$AWS_ENDPOINT_URL_S3"
terraform plan -out=tfplan
terraform apply tfplan

# Get kubeconfig
```bash
cluster_id=$(terraform output -raw cluster_id)
upctl kubernetes config $cluster_id --write kube-config
export KUBECONFIG=kube-config
k9s
```