---
title: Ozone Kubernetes Deployment
status: Accepted
last_updated: 2025-10-19
synopsis: Deploy Ozone moderation service on Kubernetes with production-grade configuration, analyzing alignment with infrastructure guidelines.
---

# ADR 005: Ozone Kubernetes Deployment

## Context

Ozone is a moderation service for ATProto/Bluesky networks that requires PostgreSQL and WebSocket support.

This ADR documents the current deployment architecture and identifies where it aligns with or deviates from established infrastructure guidelines.

## Decision

Deploy Ozone as a Kubernetes Deployment with:
- Dedicated namespace (`ozone`)
- CloudNativePG PostgreSQL database
- nginx-ingress with TLS termination
- Session affinity for WebSocket connections
- Multi-zone topology distribution
- Security hardening (non-root, capabilities dropped, seccomp profile)

