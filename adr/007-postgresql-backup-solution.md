---
title: PostgreSQL Backup and Disaster Recovery Strategy
status: Accepted
last_updated: 2025-10-23
synopsis: Use CloudNativePG Barman plugin with daily base backups and 5-minute WAL archiving for 5-minute RPO, 3-5 minute RTO disaster recovery, with S3 storage managed outside Terraform.
---

# ADR 007: PostgreSQL Backup and Disaster Recovery Strategy

## Context

We need a robust backup and disaster recovery solution for our self-managed PostgreSQL cluster ([ADR-003](./003-self-managed-postgresql-with-cloudnativepg.md)) that:

- Protects against data loss from operational errors, infrastructure failures, or disasters
- Provides predictable Recovery Point Objective (RPO) and Recovery Time Objective (RTO)
- Prevents accidental backup deletion through infrastructure changes
- Aligns with our cloud-agnostic approach ([ADR-002](./002-deploy-on-kubernetes.md))
- Works reliably with minimal operational overhead

**Critical Constraint:** 

- CloudNativePG Barman plugin can only perform **cluster-level physical backups** but not per-database backups. This means all databases in a PostgreSQL cluster share the same backup strategy. For different backup strategies per application, separate PostgreSQL clusters are required.
- This also has implication at recovery: we cannot restore individual databases independently, and corruption are at risk of damaging all DBs.
- Mitigation: split in per-application clusters eventually.

## Decision

Use CloudNativePG's Barman Cloud Plugin for PostgreSQL backups with the following configuration:

- **Base backup frequency**: Daily at 2 AM UTC
- **WAL archiving frequency**: Every 5 minutes (`archive_timeout: 5m` in production)
- **RPO target**: 5 minutes maximum data loss (time between WAL archives)
- **RTO target**: 3-5 minutes to operational database tested on a MB-sized DB
- **Backup storage**: S3-compatible object storage (Scaleway Object Storage)
- **Retention**: 30 days
- **S3 bucket management**: Manual creation outside Terraform

## Rationale

### Barman Cloud Plugin Selection

**Industry standard:**
- Barman is the de facto standard for PostgreSQL backup and recovery
- Mature, well-tested, and actively maintained
- Native integration with CloudNativePG operator

**Practicality:**
- Built-in support for any S3-compatible storage
- Automated backup scheduling via Kubernetes CronJob
- Zero-configuration WAL archiving/ Point-in-Time Recovery

### Backup Strategy

**WAL archiving**
- Every 5 minutes via `archive_timeout` parameter in production
- Allows point-in-time recovery with 5-minute RPO
- Continuous archiving of transaction logs to S3
- Applies to entire cluster (all databases)

**Base backups (snapshots)**
- Daily at 2 AM UTC via ScheduledBackup resource
- Full physical backup of entire cluster (PGDATA directory)
- Reduces WAL replay time during recovery
- **Multiple schedules possible**: Can create additional ScheduledBackup resources (e.g., hourly) for the same cluster
- All base backups capture the entire cluster, not individual databases

### S3 Bucket Management Outside Terraform

**Problem with Terraform-managed storage:**
- `terraform destroy` could accidentally delete backup buckets
- State file corruption could trigger bucket recreation
- Human error during infrastructure changes could wipe backups
- TODO: backup data stored/replicated in another org bucket, so that  can only be accessed with a complete different set of permissions

## Implementation Details

### Backup Configuration

**Storage structure:**
```
s3://eurosky-backups-prod/postgres/
├── postgres-cluster/
│   ├── base/
│   │   ├── 20251023T120000/  # Base backup every 1h
│   │   ├── 20251023T120500/
│   │   └── 20251023T121000/
│   └── wals/                  # WAL segments (archived continuously)
│       └── 0000000100000000/
└── postgres-cluster-v2/       # Recovery cluster (different serverName)
    └── base/
```

### Manual Backup Trigger

**Create on-demand backup:**
```bash
kubectl create -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: manual-backup-$(date +%s)
  namespace: databases
spec:
  method: plugin
  pluginConfiguration:
    name: barman-cloud.cloudnative-pg.io
  cluster:
    name: postgres-cluster
EOF
```

**Monitor backup progress:**
```bash
kubectl get backup -n databases -w
```

**Verify backup in S3:**
```bash
source .env
aws s3 ls s3://eurosky-backups-prod/postgres/postgres-cluster/base/ \
  --endpoint-url=https://s3.fr-par.scw.cloud
```

### Disaster Recovery Process

**1. Update Terraform configuration:**
```hcl
# terraform/envs/prod/terraform.auto.tfvars
postgres_cluster_name                 = "postgres-cluster-v2"  # New cluster name
postgres_recovery_source_cluster_name = "postgres-cluster"     # Source cluster
postgres_enable_recovery              = true
```

**2. Apply Terraform to create recovery cluster:**
```bash
cd terraform/envs/prod
source .env
terraform apply -auto-approve
```

**3. Wait for recovery to complete:**
```bash
kubectl wait --for=condition=Ready pod \
  -l cnpg.io/cluster=postgres-cluster-v2 \
  -n databases --timeout=300s
```

**4. Verify database integrity:**
```bash
# Check table ownership
kubectl exec -n databases postgres-cluster-v2-1 -c postgres -- \
  psql -U postgres -d ozone -c "\dt" | grep -c "ozone_user"

# Verify row counts match expectations
kubectl exec -n databases postgres-cluster-v2-1 -c postgres -- \
  psql -U postgres -d ozone -c "SELECT COUNT(*) FROM moderation_event"
```

**5. Application reconnection:**
- Ozone deployment seen automatically reconnecting to new cluster while testing

### Cluster Naming Strategy

CloudNativePG requires unique `serverName` for each recovery to prevent S3 path conflicts:

```
postgres-cluster      # Original
postgres-cluster-v2   # First recovery
postgres-cluster-v3   # Second recovery
```

**Why this matters:**
- CloudNativePG has "Expected empty archive" safety check
- Prevents accidentally overwriting WAL files from previous recoveries
- Each cluster gets isolated S3 path for WAL archiving

## WAL Continuity Risks and Mitigation

### Critical Discovery: Silent Data Loss

**Testing date**: 2025-10-23

**What we tested:**
- Created baseline backup with 24 rows
- Added 3 rows, each in separate WAL segments (8, 9, A in hex)
- Deleted WAL segment 9 (middle segment)
- Attempted recovery

**Results:**
- ✅ Recovery completed successfully (exit code 0)
- ✅ Replayed WAL segment 8: 25 rows recovered
- ❌ **Silent data loss**: 2 rows missing (segments 9 and A)
- ❌ PostgreSQL cannot skip segment 9 to use segment A

**Key findings:**

1. **Sequential requirement**: PostgreSQL stops WAL replay at first missing segment, even if later segments exist in S3
2. **No error indication**: Recovery logs show only successful restorations, no warnings about gaps
3. **Silent success**: Recovery completes without errors, creating false sense of complete recovery
4. **Detection challenge**: Only way to detect loss is comparing processed backup logs vs S3 bucket contents or database content vs application metrics

**Recovery log behavior:**
```
✅ restored log file "000000010000000000000008" from archive
❌ [NO MENTION OF SEGMENT 9 - silently skipped]
✅ archive recovery complete  [FALSE SENSE OF SUCCESS]
```

## Monitoring and Verification

### Backup Success Monitoring

**Check scheduled backup status:**
```bash
kubectl get scheduledbackup -n databases
kubectl describe scheduledbackup postgres-scheduled-backup -n databases
```

**List recent backups:**
```bash
kubectl get backup -n databases --sort-by=.metadata.creationTimestamp
```

**Verify S3 storage:**
```bash
# Check latest backups
aws s3 ls s3://eurosky-backups-prod/postgres/postgres-cluster/base/ \
  --endpoint-url=https://s3.fr-par.scw.cloud | tail -5

# Verify backup size (should be consistent)
aws s3 ls s3://eurosky-backups-prod/postgres/postgres-cluster/base/ \
  --endpoint-url=https://s3.fr-par.scw.cloud --recursive --human-readable
```

### Alerts to Implement

- Base backup failure for 2+ consecutive attempts
- Base backup age > 25 hours (daily backups should complete within 24h)
- WAL archiving failure or missing WAL segments
- WAL archive age > 10 minutes (should archive every 5 minutes in production)
- S3 bucket access errors
- Recovery test failures (quarterly DR drills)

## Recovery Testing to Implement

- Test in local/dev k8s deployment
- Disaster recovery game days
- Chaos engineering

## Understood Risks

### Risks Accepted

- **5-minute RPO**: Up to 5 minutes of data could be lost between WAL archives (acceptable for current workload)
- **WAL continuity dependency**: Recovery relies on continuous, sequential WAL segments
- **Silent data loss risk**: Missing WAL segments cause silent data loss without errors
- **Manual S3 management**: Bucket lifecycle managed manually outside Terraform (acceptable trade-off for safety)

### Risks Mitigated

- **Complete data loss**: Daily base backups + 5-minute WAL archiving provide disaster recovery
- **Accidental deletion**: S3 buckets managed outside Terraform prevent `terraform destroy` accidents
- **Long recovery times**: Daily base backups reduce WAL replay to < 24 hours maximum
- **Cluster infrastructure loss**: Recovery process documented and tested

### Operational Considerations

- **Backup verification**: Monitor daily base backup completion and 5-minute WAL archiving
- **WAL continuity monitoring**: Alert on missing WAL segments or archiving failures
- **S3 costs**: Monitor storage growth, WAL segments accumulate every 5 minutes (30-day retention)
- **Recovery practice**: Quarterly drills ensure team familiarity with process
- **Documentation**: Keep recovery runbook updated with lessons learned

## Related ADRs

- [ADR-002: Deploy on Kubernetes](./002-deploy-on-kubernetes.md) - Infrastructure platform
- [ADR-003: Self-Managed PostgreSQL with CloudNativePG](./003-self-managed-postgresql-with-cloudnativepg.md) - Database choice
- [ADR-004: Infrastructure as Code with Terraform](./004-infrastructure-as-code-with-terraform.md) - IaC approach

## References

- [CloudNativePG Documentation](https://cloudnative-pg.io/documentation/current/)
- [Barman Documentation](https://pgbarman.org/)
