# Local K3d Environment

This environment is designed for local development and testing using k3d (k3s in Docker).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- [k3d](https://k3d.io/#installation) v5.0+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [terraform](https://www.terraform.io/downloads) v1.0+
- [Cloudflare account](https://cloudflare.com) with API token for DNS management

## Architecture

Unlike prod/dev environments which use Scaleway cloud infrastructure, the local environment:
- Uses k3d for Kubernetes (k3s in Docker containers)
- Uses local-path storage provisioner (`rancher.io/local-path`)
- Uses servicelb (klipper-lb) for LoadBalancer services
- Deploys MinIO in-cluster for S3-compatible storage
- Uses Cloudflare for external DNS management (same as prod)
- Uses Let's Encrypt staging for TLS certificates (to avoid rate limits)

## Quick Start

### 0. CRITICAL: Set Local Kubeconfig

**EXTREMELY IMPORTANT**: Always use a local kubeconfig to avoid polluting your shared `~/.kube/config`!

The `.envrc` file (created in step 3) automatically sets `KUBECONFIG="$PWD/kube-config"`.

**Verify it's set correctly:**
```bash
echo $KUBECONFIG
# Should show: /path/to/terraform/envs/local/kube-config
# NOT: ~/.kube/config
```

**If not using direnv**, manually export before running kubectl:
```bash
export KUBECONFIG="$(pwd)/kube-config"
```

### 1. Create k3d Cluster

**IMPORTANT**: Ensure `KUBECONFIG` is set (see step 0) before running this command!

```bash
k3d cluster create eurosky-local \
  --k3s-arg "--disable=traefik@server:*" \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer
```

This will automatically write the kubeconfig to your `$KUBECONFIG` path.

**Why these settings:**
- **Disable Traefik:** k3s ships with Traefik, but we use nginx-ingress (same as prod/dev). Keeping both would conflict on ports 80/443.
- **Keep metrics-server:** Enabled by default in k3s. Provides `kubectl top` support and HPA metrics.
- **Keep servicelb:** CRITICAL - Do NOT use `--disable=servicelb`. This component is essential for LoadBalancer services to work.

### 2. Verify Cluster

```bash
kubectl cluster-info
kubectl get nodes
kubectl get storageclass
```

You should see `local-path` as the default storage class.

### 3. Configure Environment

```bash
cd terraform/envs/local

# Copy example files
cp .envrc.example .envrc
cp terraform.auto.tfvars.example terraform.auto.tfvars

# Edit .envrc with your secrets
vim .envrc

# Generate random secrets (examples in .envrc.example)
openssl rand -hex 16  # for 16-byte secrets
openssl rand -hex 32  # for 32-byte secrets

# Load environment variables
# Option 1: Using direnv (auto-loads/unloads on directory change)
direnv allow

# Option 2: Manual source (once per shell session)
source .envrc

# Edit terraform.auto.tfvars with your configuration
vim terraform.auto.tfvars
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 5. Post-Deployment Configuration

#### Create Database Roles

CloudNativePG creates databases but NOT roles. Create them manually:

```bash
kubectl exec -n databases postgres-cluster-1 -c postgres -- psql -U postgres <<'EOF'
CREATE ROLE plc WITH LOGIN PASSWORD 'your-plc-password';
CREATE DATABASE plc OWNER plc;
CREATE ROLE relay WITH LOGIN PASSWORD 'your-relay-password';
CREATE DATABASE relay OWNER relay;
EOF
```

#### Configure cert-manager for DNS01

For Let's Encrypt DNS01 challenges with external domains:

```bash
kubectl patch deployment cert-manager -n cert-manager --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53"},
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--dns01-recursive-nameservers-only"}
]'
```

#### Create MinIO Buckets

```bash
# Get MinIO pod name
MINIO_POD=$(kubectl get pod -n minio-system -l app=minio -o jsonpath='{.items[0].metadata.name}')

# Create buckets
kubectl exec -n minio-system $MINIO_POD -- mc alias set local http://localhost:9000 minioadmin minioadmin
kubectl exec -n minio-system $MINIO_POD -- mc mb local/postgres-backups
kubectl exec -n minio-system $MINIO_POD -- mc mb local/pds-blobstore
kubectl exec -n minio-system $MINIO_POD -- mc mb local/pds-backups
```

### 6. Wait for Certificates

Let's Encrypt certificate issuance takes ~5 minutes:

```bash
# Watch certificate status
kubectl get certificates -A -w

# Check specific certificate
kubectl describe certificate pds-tls -n pds
```

### 7. Verify Deployment

```bash
# Check all pods
kubectl get pods -A

# Check ingresses
kubectl get ingress -A

# Check external-dns logs
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns --tail=50

# Test HTTP connectivity
curl http://localhost/_health -H "Host: pds.local-k8s.u-at-proto.work"
```

## Accessing Services

Services are accessible via:
- HTTP: `http://localhost:80`
- HTTPS: `https://localhost:443`
- Kubernetes API: `https://localhost:6443`

Add `Host` header for specific services:
```bash
curl -H "Host: ozone.local-k8s.u-at-proto.work" http://localhost/
```

## Troubleshooting

### Pods Stuck in Pending

Check PVC status:
```bash
kubectl get pvc -A
```

If storage class is wrong, delete PVC and redeploy:
```bash
kubectl delete pvc <pvc-name> -n <namespace>
terraform apply
```

### LoadBalancer Not Working

Verify servicelb is running:
```bash
kubectl get ds -A | grep svclb
```

Should show DaemonSets like `svclb-ingress-nginx-controller-local`.

### Certificates Not Issuing

Check cert-manager logs:
```bash
kubectl logs -n cert-manager -l app=cert-manager --tail=100
```

Common issues:
- DNS01 validation using cluster DNS (apply the cert-manager patch above)
- Cloudflare API token missing or invalid
- DNS propagation delays (wait 5-10 minutes)

### External-DNS Not Creating Records

Check ingress status:
```bash
kubectl get ingress -A -o yaml | grep -A5 "status:"
```

Ingress must have LoadBalancer IP in status. If empty, manually patch:
```bash
kubectl patch ingress <ingress-name> -n <namespace> \
  -p '{"status":{"loadBalancer":{"ingress":[{"ip":"<loadbalancer-ip>"}]}}}' \
  --type=merge --subresource=status
```

## Cleanup

```bash
# Destroy infrastructure
terraform destroy

# Delete k3d cluster
k3d cluster delete eurosky-local
```

## Key Differences from Production

| Aspect | Production (Scaleway) | Local (k3d) |
|--------|----------------------|-------------|
| Cloud Provider | Scaleway Kapsule | None (k3d) |
| Storage | scw-bssd | rancher.io/local-path |
| LoadBalancer | Scaleway LB | servicelb (klipper-lb) |
| S3 Storage | Scaleway Object Storage | MinIO (in-cluster) |
| Certificates | Let's Encrypt prod | Let's Encrypt staging |
| High Availability | Multi-zone, autoscaling | Single node |
| Networking | VPC, Private Network | Docker bridge |

## Known Limitations

1. **Single Node**: k3d runs on a single Docker container, no HA
2. **Storage Performance**: local-path uses host filesystem, slower than cloud storage
3. **No Multi-Zone**: Can't test zone failover scenarios
4. **Resource Limits**: Limited by host machine resources
5. **Network Isolation**: All traffic goes through localhost
6. **Certificate Validation**: Using staging certs (browsers will show warnings)

## Development Workflow

1. Make changes to terraform configuration
2. Apply changes: `terraform apply`
3. Test changes locally
4. Commit and push
5. Deploy to dev environment for integration testing
6. Deploy to prod after validation

## Additional Resources

- [k3d Documentation](https://k3d.io/)
- [k3s Documentation](https://docs.k3s.io/)
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner)
- [CloudNativePG Documentation](https://cloudnative-pg.io/)
- [Session Learnings](../../../SESSION_LEARNINGS.md) - Detailed technical learnings from setting up this environment
