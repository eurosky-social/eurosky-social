# Local K3d Environment

## Prerequisites

- Docker, k3d v5.0+, kubectl, terraform v1.0+
- Cloudflare account with API token

## Setup

```bash
cd envs/local

# IMPORTANT: Set local kubeconfig to avoid polluting ~/.kube/config
export KUBECONFIG="$(pwd)/kube-config"

# Create k3d cluster
k3d cluster create eurosky-local \
  --k3s-arg "--disable=traefik@server:*" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer

# Configure environment
cp .envrc.example .envrc && cp terraform.auto.tfvars.example terraform.auto.tfvars
# Edit both files with your values

# Option 1: Using direnv (auto-loads/unloads on directory change)
direnv allow

# Option 2: Manual source (once per shell session)
source .envrc
```

## Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Post-Deployment

```bash
# Configure cert-manager for external DNS01 challenges
kubectl patch deployment cert-manager -n cert-manager --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53"},
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--dns01-recursive-nameservers-only"}
]'

# Wait for certificates (~5 minutes)
kubectl get certificates -A -w
```

## Access Services

```bash
# Services available at http://localhost and https://localhost
curl -H "Host: service.local-k8s.u-at-proto.work" http://localhost/

# Verify deployment
kubectl get pods -A
kubectl get ingress -A
```

## Cleanup

```bash
terraform destroy
k3d cluster delete eurosky-local
```

## Troubleshooting

See [SESSION_LEARNINGS.md](../../../SESSION_LEARNINGS.md) for detailed setup issues and solutions.
