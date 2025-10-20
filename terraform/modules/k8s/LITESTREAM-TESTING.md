# Litestream Backup Tests

**Status**: Manual testing only - needs conversion to e2e automated tests

## Quick Validation

```bash
# Check Litestream running and initialized 3 system DBs
kubectl logs -n pds pds-0 -c litestream --tail=50 | grep "initialized db"

# Verify databases exist
kubectl exec -n pds pds-0 -c pds -- ls -lh /pds/*.sqlite

# Check S3 backups created
aws s3 ls s3://$BUCKET/litestream/pds/system/ --recursive --endpoint-url=$ENDPOINT

# Test restore: delete pod, wait for restart, verify data intact
kubectl delete pod pds-0 -n pds && kubectl wait --for=condition=ready pod/pds-0 -n pds --timeout=300s
kubectl logs -n pds pds-0 -c litestream-restore
```

## Test Coverage Needed

1. ✅ **Litestream starts** - logs show 3 DBs initialized (account, sequencer, did_cache)
2. ✅ **S3 backups created** - generations/ directories exist with WAL files
3. ✅ **Replication works** - file count increases after writes
4. ✅ **Restore works** - pod restart recovers data from S3
5. ✅ **No errors** - monitor logs over time
6. ❌ **User DBs NOT backed up** - `/pds/actors/*/store.sqlite` ignored (expected - awaits Litestream fork)

## Known Issues

- **Sync interval**: 15m (dev) - too long for production (needs 10s)
- **User databases**: Not backed up - requires custom Litestream fork with recursive scanning
- **Metrics**: No Prometheus endpoint - cannot measure replication lag

## Next Steps

Convert to e2e automated tests:
- Kubernetes test framework (e.g., `kubetest2`, Ginkgo)
- Verify Litestream initialization
- Trigger writes, wait for replication
- Test disaster recovery (delete pod, verify restore)
- Validate S3 backup structure
- Monitor for errors over time

See ADR-006 for architecture decisions.
