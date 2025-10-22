---
title: Infrastructure as Code with Terraform for now
status: Accepted
last_updated: 2025-10-19
synopsis: Adopt Terraform as our Infrastructure as Code tool for managing Kubernetes infrastructure.
---

# ADR 004: Infrastructure as Code with Terraform for now

## Context

We need a standardized approach to managing infrastructure that supports:

- Cloud-agnostic deployments (initially on Scaleway)
- Environment specific configuration across local, staging, and production
- Automated deployments via CI/CD
- Version-controlled infrastructure changes

## Decision

Use Terraform IaC for a push based approach to infrastructure management for now.  
Consider switching to GitOps for the future.

## Rationale

We understand that **Terraform is not the most ergonomic approach** for infrastructure management, but it represents the **simplest** path forward given our constraints.

## Terraform Code Guidelines

### Module Organization

- **No unnecessary outputs/variables**: Only expose what is needed by other modules, for mapping module dependencies and for differentiating environments setup
- **Clear separation of concerns**: Keep clear separation between the k8s resources and where these resources are running (e.g., separate modules for a cloud provider resources and k8s resources deployed on the cluster)

### Dependency Management

- **Avoid `depends_on`**: Use implicit dependencies through attribute references where possible
- **Avoid race conditions**: Enforce resources graph, ideally without relying on explicit `depends_on`
- **Use attribute references**: Module outputs should reference actual attributes for dependency chaining

### Configuration Management

- **Externalize YAML/JSON**: Externalize YAML/JSON configurations to separate template files instead of inline heredocs

### Documentation

- **Avoid unnecessary comments**: Use comments to document design decisions only when strictly necessary
- **Self-documenting code**: Prefer clear naming over extensive comments

## Risks

- **State Drift**: Terraform's state file desyncs from the cluster's live state (e.g., HPA scaling), leading to noisy plans and attempts to revert valid changes.
- **Security "Blast Radius"**: Developers need overly broad permissions to run terraform apply for simple app changes, creating a risk of destroying infrastructure.
- **Slow Developer Workflow**: Developers face a slow bottleneck, needing to run a full terraform plan on all infrastructure just to deploy a small app update.
- **No Self-Healing**: Terraform is a "push" tool and won't automatically fix manual changes; a deleted deployment stays down until the next terraform apply.