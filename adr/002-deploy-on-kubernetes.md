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

- **Cloud portability**: Easy deployment across different clouds (Scaleway, Upcloud, AWS) or locally
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

## Core Principles

- Cloud-agnostic design (avoid cloud/vendor lock-in)
- Infrastructure as Code (Terraform?)
- Environments: local (dev/CI), staging, production
- Automation-first (CI/CD for everything)
- Zero-downtime operations

## Platform

- Managed Kubernetes clusters from cloud providers
- Local Kubernetes environment for development / CI testing with a single command setup
- Object storage for backups

## High Availability

- All services deployed with redundancy
- Automatic failover without manual intervention
- Health monitoring for all components
- No single points of failure

## Scaling

- Automatic scaling (based on CPU utilization?)
- Tiered approach: always-on minimum resources + scale up with larger instances
- Some services to support scale-to-zero when idle
- Hot-swapping without service interruption

## Security

- Secrets injected via CI/CD (never committed to repositories)
- Cloud provider IAM for cluster authentication
- Role-based access control with environment isolation
- Network traffic restricted by default (explicit allow-listing)
- Container vulnerability scanning in CI/CD pipeline
- Security standards enforced for all workloads
- Logs exported to S3 for backup and compliance

## Data Management

- Relational database with high availability (3+ replicas)
- Automated backups with point-in-time recovery
- Connection pooling to optimize database connections
- Schema migrations as part of application deployment
- Stateful workloads isolated from stateless applications
- Object storage for unstructured data

## Disaster Recovery

- RPO: Maximum 1 hour data loss
- RTO: Operational within 4 hours
- Automated daily backups with hourly incrementals
- 30-day retention + monthly archives (1 year)
- Single-region initially, architecture supports multi-region migration
- Quarterly disaster recovery drills

## Observability

- Comprehensive metrics collection and visualization
- Centralized log aggregation
- Distributed tracing for critical paths
- Alerting with defined escalation policies
- SLO: ideally 99.9% uptime, <500ms p95 latency
- Pre-built dashboards for services and infrastructure

## Networking

- Cloud provider multi AZ load balancers with health checks
- HTTPS for all service communication (TLS termination at ingress)
- Ingress-Level Rate Limiting
- Full visibility into ingress and egress traffic
- Automatic service discovery (using Service Object?)
- CDN for static assets and DDoS protection

## Deployment Strategy

- Integration testing in ephemeral environments
- Health checks (readiness, liveness) for all services
- Zero-downtime deployments with connection draining whenever possible
- Automated rollback on error thresholds
- Backwards-compatible database migrations whenever possible
- Ideally progressive rollouts for critical services (canary deployments)

## State Management

- Application services designed as stateless ideally
- WebSocket connections handled with session affinity
- Distributed caching where needed

## Development Workflow

- Local Kubernetes matches production architecture
- Hot-reload for rapid iteration ideally
- Ephemeral test environments in CI/CD
- Integration tests against real Kubernetes clusters
