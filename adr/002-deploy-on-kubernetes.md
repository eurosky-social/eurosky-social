---
title: Deploy on Kubernetes
status: Accepted
last_updated: 2025-10-15
synopsis: Deploy all Eurosky services on Kubernetes instead of serverless to achieve cloud portability, better control, and avoid scale-to-zero/WebSocket limitations.
---

# ADR 002: Deploy on Kubernetes

## Context

We evaluated serverless containers (Scaleway Serverless) vs Kubernetes for hosting Eurosky services.

## Decision

Deploy all Eurosky services on Kubernetes (Scaleway Kapsule).

## Rationale

**Serverless limitations encountered:**

- **Scale-to-zero issues**: Problems with scaling behavior and WebSockets usage of many ATProto services

**Kubernetes advantages:**

- **Cloud portability**: Easy deployment across different clouds (Scaleway, AWS, GCP) or locally
- **Testing flexibility**: Run full stack locally
- **Better control**: Fine-grained control over networking, scaling, and resource allocation
- **Standards compliance**: Industry-standard orchestration

## Understood risks

- Higher operational complexity compared to serverless
- Always-on infrastructure (no scale-to-zero cost savings)
- Steeper learning curve for less technical users
- More components to maintain and monitor

## Implementation Details

**Platform:** Scaleway Kapsule (managed Kubernetes)

**Cluster Configuration:**

- Initially Single Cloud, Single Region, Multi-AZ deployment (fr-par-*) - good enough for HA launch
- Multi-nodes - nodes size, numbers to be revisited

**Core Components:**

- **Ingress**: nginx-ingress
- **TLS**: cert-manager + Let's Encrypt
- **DNS**: Scaleway DNS with health checks
- **Observability**: Elasticsearch + Kibana

**High Availability:**

- Pod topology spread across zones (maxSkew: 1)
- Pod anti-affinity on nodes (required)
- Multiple replicas for critical services
- Managed LoadBalancers per availability zone
