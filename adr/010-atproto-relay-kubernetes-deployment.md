---
title: ATProto Relay Deployment
status: Accepted
last_updated: 2025-11-07
synopsis: Deploy Relay as Kubernetes StatefulSet for ATProto Firehose distribution with websocket support and SQLite persistence.
---

# ADR 010: ATProto Relay Deployment

## Context

ATProto Relay aggregates repository events from multiple PDS instances and redistributes them via firehose websocket connections.


## Constraints

- **Current limitation:** Relay has NO coordination mechanism for multiple instances.  
- **Resource usage:**  
  - CPU: scales with consumers but generally light
  - Memory: mainly used for caching identities and can grow large.
  - Net: Firehouse is currently oscillating between 1.25/2.5 megabytes/sec - 1x upstream in total, 1x downstream per consumer.
- **Storage:** Maintain a replay window that scales with the network, average of 4-6GB / hour

## Decision

Deploy relay as Kubernetes StatefulSet with:

- **Single replica** for lack of coordination.
- **Litestream sidecar** for S3-replicated SQLite backups (15min RPO)
- **Websocket-enabled NGINX ingress** with HTTP/1.1 enforcement
- **CronJob** for upstream host synchronization
- **Prometheus ServiceMonitor** for metrics collection

## Consequences

- Single point of failure.  
- Failover is K8S managed.  
- Data is persisted to PVC so should survive pod/node failures because Upcloud manages the block storage.  
- More complex failures scenarios are handled by Litestream replication to S3 (mainly to store accounts takedown info) but will need to rebuild the replay window.  
- Decent level of observability via the K8S monitoring stack + Ingress and Relay metrics/log.
