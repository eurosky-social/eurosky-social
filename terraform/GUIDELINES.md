# Infrastructure Guidelines

## Core Principles

- Cloud-agnostic design (initially deploy on Scaleway)
- Infrastructure as Code (Terraform)
- Environment parity (local, staging, production)
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

- Automatic scaling based on CPU utilization
- Tiered approach: always-on minimum resources + scale up with larger instances
- Some services support scale-to-zero when idle
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
- SLO: 99.9% uptime, <500ms p95 latency
- Pre-built dashboards for services and infrastructure

## Networking

- HTTPS for all service communication (TLS termination at ingress)
- Full visibility into ingress and egress traffic
- Service mesh for mTLS, observability, and resilience
- Automatic service discovery
- API gateway for external traffic with rate limiting
- CDN for static assets and DDoS protection
- Cloud provider load balancers with health checks

## Deployment Strategy

- Progressive rollouts for critical services (canary deployments)
- Automated rollback on error thresholds
- Health checks (readiness, liveness) for all services
- Zero-downtime deployments with connection draining
- Backwards-compatible database migrations
- Integration testing in ephemeral environments

## State Management

- Application services designed as stateless
- WebSocket connections handled with session affinity to specific pods
- Distributed caching where needed

## Development Workflow

- Local Kubernetes matches production architecture
- Hot-reload for rapid iteration
- Ephemeral test environments in CI/CD
- Integration tests against real Kubernetes clusters
