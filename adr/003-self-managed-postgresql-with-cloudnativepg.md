---
title: Self-Managed PostgreSQL with CloudNativePG
status: Accepted
last_updated: 2025-10-15
synopsis: Use CloudNativePG operator for self-managed PostgreSQL on Kubernetes, achieving significant cost savings (~€48/month) while maintaining production-grade HA and cloud portability.
---

# ADR 003: Self-Managed PostgreSQL with CloudNativePG

## Context

We need a PostgreSQL database solution for Eurosky services (Ozone, future PDS). Options considered:

1. Managed database service (e.g., Scaleway Managed PostgreSQL)
2. Self-managed PostgreSQL using CloudNativePG operator

## Decision

Use CloudNativePG operator to self-manage PostgreSQL on Kubernetes.

## Rationale

**Cost efficiency:**

- CloudNativePG: ~€48/month (3 instances on shared cluster)
- Managed DB: Significantly higher cost for equivalent HA setup

**Cloud-agnostic approach:**

- Aligns with infrastructure portability goals ([ADR-002](../adr/002-infrastructure-portability.md))
- Works identically across any Kubernetes cluster
- No vendor lock-in to specific managed database service

**Production-grade features:**

- Built-in high availability (3 replicas with automatic failover)
- Automated backup and WAL archiving to S3
- Multi-AZ distribution for fault tolerance
- Zero-downtime rolling updates

**Operational benefits:**

- Single shared cluster serves multiple applications (Ozone, PDS)
- Native Kubernetes integration
- Comprehensive monitoring via Prometheus

## Understood risks

- Requires PostgreSQL operational knowledge
- We own backup/restore procedures
- More components to monitor and troubleshoot
- Initial setup complexity (mitigated by operator automation)

## Implementation Details

- **Operator**: CloudNativePG v1.27 with Barman Cloud Plugin
- **Backup**: S3-compatible object storage with 30-day retention
- **HA**: 3 instances spread across 2 availability zones
- **Archive timeout**: 1 hour (cost-optimized for WAL archiving)
