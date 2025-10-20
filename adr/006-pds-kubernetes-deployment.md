---
title: PDS Kubernetes Deployment
status: Accepted
last_updated: 2025-10-19
synopsis: Deploy Bluesky Personal Data Server (PDS) on Kubernetes with Litestream backup, analyzing alignment with infrastructure guidelines.
---

# ADR 006: PDS Kubernetes Deployment

## Context

PDS (Personal Data Server) is a Bluesky ATProto service using SQLite databases for personal data storage. It requires persistent storage and has unique HA limitations due to SQLite's single-writer architecture.

This ADR documents the current deployment architecture and identifies where it aligns with or deviates from established infrastructure guidelines.

## Decision

Deploy PDS as a Kubernetes StatefulSet with:
- Dedicated namespace (`pds`)
- Single replica with PVC due to SQLite usage
- Litestream sidecar for continuous S3 replication providing WAL based backup with max RPO 15 mins RTO 5 mins
- Future Enhancement: Hot standby pod with read-only replicated databases
- Dedicated S3 buckets (backups + blobstore)
- nginx-ingress with TLS termination
- Security hardening (non-root, capabilities dropped, seccomp profile)
