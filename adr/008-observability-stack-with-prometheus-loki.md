---
title: Observability Stack with Prometheus and Loki
status: accepted
last_updated: 2025-10-28
synopsis: Deploy production-grade observability using kube-prometheus-stack and Loki, replacing Elasticsearch/Kibana with industry-standard, cost-effective solutions for metrics, logs, and alerting.
---

# ADR-008: Observability Stack with Prometheus and Loki

## Context

The infrastructure requires comprehensive observability for production operations:

- **Metrics**: Cluster resources, application performance, SLO tracking
- **Logs**: Centralized log aggregation with search capabilities
- **Alerts**: Proactive notification of degraded states via email
- **Visualization**: Unified dashboards for operational awareness

The initial Elasticsearch/Kibana stack provided log aggregation but lacked integrated metrics and alerting, required significant resources (6GB+ RAM), and had complex operational overhead for a Kubernetes-native environment.

## Decision

Deploy a complete observability stack using:

- **kube-prometheus-stack**: Prometheus, Grafana, Alertmanager, Operator
- **Loki**: Log aggregation in single-binary mode with S3 backend
- **Grafana Alloy**: Unified log collector replacing Promtail
- **Thanos Sidecar**: Long-term metrics storage (30d+ retention) with S3 backend
- **SMTP Alerting**: Email notifications for critical events

Remove Elasticsearch/Kibana stack entirely.

## Rationale

### Cost Efficiency

| Component | Memory | Storage | Notes |
|-----------|--------|---------|-------|
| **Previous: Elastic Stack** | | | |
| Elasticsearch | 4-6GB | 50Gi PV | Resource-intensive |
| Kibana | 1-2GB | - | Heavy dashboard rendering |
| **Current: Prometheus Stack** | | | |
| Prometheus | 256Mi-1Gi | 10Gi PV | TSDB optimized |
| Grafana | 256Mi-512Mi | 2Gi PV | Lightweight dashboards |
| Alertmanager | 32Mi-128Mi | 2Gi PV | Notification routing |
| Loki | 256Mi-1Gi | S3 object storage | Logs stored in S3 |
| Alloy | 64Mi-256Mi/node | - | DaemonSet per node |

### Kubernetes-Native Integration

- **Prometheus Operator**: CRDs for ServiceMonitor, PodMonitor, PrometheusRule
- **Component-Owned Observability**: Each component defines its own alerts in its namespace
- **Auto-Discovery**: Prometheus scrapes all ServiceMonitors cluster-wide
- **PromQL**: Industry-standard query language with extensive ecosystem support

### Unified Alerting

- **Single Alertmanager**: Routes all alerts (infrastructure, applications, platform)
- **Deduplication**: Automatic grouping and silencing across multiple Prometheus replicas
- **Email Templates**: HTML formatted alerts with severity color-coding and context

### Cloud-Agnostic Architecture

- S3-compatible object storage for logs and metrics (works with Scaleway, AWS, MinIO)
- No vendor-specific dependencies
- Standard Helm charts with community support

## Implementation Details

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Kubernetes Cluster                                      │
│                                                         │
│  ┌──────────────┐    ServiceMonitors    ┌────────────┐ │
│  │ cert-manager ├───────────────────────►│            │ │
│  │ external-dns │    PrometheusRules    │ Prometheus │ │
│  │ ingress-nginx├───────────────────────►│  Operator  │ │
│  │ cloudnativepg│                        │            │ │
│  └──────────────┘                        └─────┬──────┘ │
│                                                │        │
│  ┌──────────────┐                        ┌────▼──────┐ │
│  │ Alloy        ├───── logs ────────────►│   Loki    │ │
│  │ (DaemonSet)  │                        │ (single)  │ │
│  └──────────────┘                        └─────┬─────┘ │
│                                                │        │
│  ┌──────────────┐    metrics             ┌────▼──────┐ │
│  │ Prometheus   ├────────────────────────►│  Thanos   │ │
│  │              │                        │ Sidecar   │ │
│  └──────┬───────┘                        └─────┬─────┘ │
│         │                                      │        │
│    ┌────▼──────┐      alerts           ┌──────▼──────┐ │
│    │  Grafana  │◄──────────────────────┤ Alertmanager│ │
│    │           │                        │             │ │
│    └───────────┘                        └──────┬──────┘ │
│                                                │        │
└────────────────────────────────────────────────┼────────┘
                                                 │
                                          ┌──────▼──────┐
                                          │ SMTP Server │
                                          │  (alerts)   │
                                          └─────────────┘
```

### Components Deployed

#### Prometheus Stack (monitoring namespace)

#### Loki Stack (loki namespace)

**Alloy Configuration**: Modern log collector with auto-detection:

- **Discovery**: Kubernetes pod discovery with metadata labels (namespace, pod, container, node)
- **Multiline Support**: Stack trace detection for Java/Python/JavaScript exceptions
- **Format Auto-Detection**: Tries JSON → logfmt → plain text fallback
- **DaemonSet Pattern**: One pod per node for efficient log collection
- **ServiceMonitor**: Self-monitoring metrics exported to Prometheus

#### Custom Alert Rules

We couldn't find pre-cooked alert rules for some core services so we created our own:

**cert-manager** (cert-manager namespace):

```yaml
- alert: CertManagerAbsent
  expr: absent(up{job="cert-manager"})
  for: 10m
  labels:
    severity: critical
  annotations:
    summary: "cert-manager is down"
    description: "cert-manager has been unavailable for 10+ minutes"

- alert: CertificateReadyFalse
  expr: certmanager_certificate_ready_status{condition="False"} == 1
  for: 10m
  labels:
    severity: critical
```

**external-dns** (external-dns namespace):

```yaml
- alert: ExternalDNSRegistryErrorsHigh
  expr: |
    rate(external_dns_registry_errors_total[5m]) > 0.1
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "external-dns registry errors ({{ $labels.source }})"
```

#### Grafana Dashboards

Pre-configured community dashboards:

- **Kubernetes**: Cluster overview, namespaces, pods (gnetId: 7249, 15760, 15757, 15758)
- **Node Metrics**: Node exporter dashboard (gnetId: 1860)
- **Ingress-Nginx**: Request rates, response times (gnetId: 9614)
- **PostgreSQL**: CloudNativePG cluster metrics (gnetId: 20417)
- **cert-manager**: Certificate expiry tracking (gnetId: 11001)
- **Prometheus**: TSDB stats and alertmanager (gnetId: 3662, 19268)
- **Loki**: Log volume and query performance (gnetId: 13639)

#### VPC Public Gateway

On Scaleway, we couldn't egress SMTP traffic until we switched to using a Public Gateway and securing the cluster nodes inside the Private Network by disabling their Public IPs.

### Default Alert Rules

**Disabled for Scaleway Managed K8s**:

- `kubeProxy: false` - Control plane not exposed
- `kubeControllerManager: false` - Managed by Scaleway
- `kubeScheduler: false` - Not accessible

**Enabled** (selection):

- Node resource exhaustion (CPU, memory, disk)
- Pod crash loops and restart rates
- Persistent volume near capacity
- Kubernetes API server errors
- etcd performance degradation
- Container resource throttling

## Monitoring Strategy

### Metrics Collection

- **Infrastructure**: Node resources, Kubernetes API, etcd, kubelet
- **Platform**: Ingress traffic, certificate expiry, DNS updates, database performance
- **Applications**: Custom ServiceMonitors in application namespaces (future)

### Log Aggregation

- **All pod logs**: Captured by Alloy DaemonSet
- **Retention**: 7 days in Loki, long-term in S3 (configurable)
- **Indexing**: By namespace, pod, container, node, log level

### Alerting Severity

- **Critical**: Immediate attention required (service down, certificate expiring <7d)
- **Warning**: Degraded state (high error rates, resource pressure)
- **Info**: Informational (successful operations, state changes)

### External Monitoring

We have configured Hyperping to monitor us from the outside via:

- **Dead Man's Switch**: Prometheus sends heartbeat webhook to Hyperping every minute to check if the alerting system is up and running.
- **Synthetic Monitoring**: External health checks for critical public endpoints to detect issues from external perspective (DNS, network, SSL, response times).

## Understood Risks

### Accepted

- **Single Replicas**: Initial deployment runs single replicas for Prometheus, Grafana, Alertmanager (HA deferred for later)
- **Loki Single-Binary**: Suitable for <100GB/day, requires microservices mode migration for higher volumes
- **7d Local Retention**: Prometheus retains 7 days locally before Thanos offloads to S3
- **Learning Curve**: Team must learn PromQL and LogQL query languages


### Mitigated

- **Data Loss**: S3 backends for long-term storage (Prometheus via Thanos, Loki native)
- **Alert Storms**: Grouping and repeat intervals prevent email floods
- **Resource Exhaustion**: PriorityClass ensures critical components survive node pressure
- **Multi-AZ Failures**: TopologySpreadConstraints distribute pods across zones
- **Component Monitoring**: Self-monitoring via ServiceMonitors (Prometheus monitors itself)

## References

- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Grafana Loki](https://grafana.com/docs/loki/latest/)
- [Grafana Alloy](https://grafana.com/docs/alloy/latest/)
- [Thanos](https://thanos.io/tip/thanos/quick-tutorial.md/)
- [Prometheus Operator](https://prometheus-operator.dev/)
