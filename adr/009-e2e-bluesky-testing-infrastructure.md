---
title: E2E Bluesky Testing Infrastructure with Docker Compose
status: Accepted
last_updated: 2025-10-28
synopsis: Implement comprehensive end-to-end testing for Bluesky moderation workflows using Docker Compose locally and in CI, with plans to migrate to Kubernetes for shared local/cloud configuration.
---

# ADR 009: E2E Bluesky Testing Infrastructure with Docker Compose

## Context

In the process of discovering how we can run part of the Bluesky stack, we need to validate that the entire stack works together correctly, particularly for critical moderation workflows. We find extermely convenient to replicate the full Bluesky infrastructure stack in a local environment (PLC, PDS, Relay, JetStream, AppView, Feedgen, Social, Ozone) and poke it with real UI interactions.

The project started by adapting work from `u-at-proto` for basic infrastructure setup. We needed to quickly understand and test how Bluesky moderation works in practice, requiring an accelerated implementation approach.

## Decision

Implement comprehensive E2E testing infrastructure using Docker Compose for local development and CI/CD, with Playwright for UI automation testing the complete moderation workflow.

### Test Journey

The E2E test suite executes the following user journey:

1. Set up the complete Bluesky infrastructure stack
2. Create three users: Alice, Bob, and an Ozone Admin
3. Alice creates a post
4. Bob replies with spam content
5. Alice reports Bob's spam reply
6. Admin reviews the report and issues a takedown action via Ozone
7. Admin sends a notification email to Bob about the takedown
8. Alice verifies Bob's post is removed
9. Bob attempts to post and sees account takedown notice
10. Bob checks email and finds the moderation notice from Ozone Admin

### Infrastructure Components

- **Core Services**: PLC, PDS, Relay, JetStream, AppView, Feedgen
- **UI Services**: Social (Bluesky web client), Ozone (moderation dashboard)
- **Supporting Services**: MailDev (email testing)
- **Test Runners**: Jest (API testing), Playwright (UI testing)

## Rationale

### Starting Simple with Docker Compose

**Decision**: Begin with Docker Compose (`u-at-proto/docker-compose`) as the foundation, then adapt for moderation testing (`./docker-compose`).

- **Speed**: Docker Compose allows rapid iteration and experimentation
- **Simplicity**: Easier to understand and debug full stack locally
- **Foundation**: Reused existing `u-at-proto` work, minimizing initial setup time
- **Urgency**: Needed to quickly uncover how moderation works in practice

**Drawbacks**:

- Different setup then cloud deployment
- Required lots of hacking due to services dependencies

### Real DNS Requirement

**Challenge**: UI signup requires real DNS resolution.

- **Root Cause**: Bluesky signup flow validates DNS records for PDS discovery
- **Current Solution**: Using real DNS with Cloudflare (configured via environment variables)
- **Alternative Approaches**: Not yet explored (local DNS overrides, custom resolvers, etc.)

### Tailscale Integration

**Initial Approach**: Used Tailscale with TLS certificate features for secure networking.

**Evolution**: Moved away from Tailscale's TLS features but retained basic networking.

**Current Status**:

- Tailscale integration still present in the codebase
- Useful for certain scenarios (remote access, secure tunneling)
- Not essential for core testing workflow
- **Decision**: Keep for now as it provides optional utility

### CI/CD Integration

**GitHub Actions Workflow** (`.github/workflows/e2e-test.yml`):

- Automated on every push to `main`
- Runs complete test suite (Jest + Playwright)
- TLS certificate caching (encryption/decryption) to avoid Let's Encrypt rate limits
- Publishes test traces and Playwright reports to GitHub Pages

**Observability**:

- Playwright HTML reports with traces provides complete vision of the journey
- Video recordings of test runs in CI (actually this is broken since starting using multiple browsers)
- Container health status reporting
- Full Docker logs on failure

## Future Direction

### Migration to Kubernetes

**Planned Evolution**: Transition from Docker Compose to Kubernetes (likely K3s) for local development.

**Benefits**:

- **Shared Configuration**: Same infrastructure-as-code for local and cloud environments
- **Production Parity**: Local environment matches production more closely
- **Consistency**: Eliminates Docker Compose vs Kubernetes configuration drift
- **Learning**: Team develops deeper Kubernetes expertise in safe local environment

**Timeline**: To be determined based on cloud deployment progress and team capacity.

## Consequences

### Positive

- **Documentation**: Full user journey from signup to moderation validates our understanding
- **UI Validation**: Playwright tests catch real user-facing issues
- **CI Automation**: Every commit validates the complete system works - will be especially useful if we move to local k8s

### Negative

- **Maintenance Burden**: Multiple services to keep updated and compatible - hopefully solvable with local k8s
- **DNS & Tailscale Dependency**: Real DNS requirement and Tailscale add complexity

## Related Files

- `docker-compose.yml` - Main composition file including all services
- `tests/browser/alice-bob-interaction.spec.ts` - Complete E2E test journey (tests/browser/alice-bob-interaction.spec.ts:124)
- `.github/workflows/e2e-test.yml` - CI/CD workflow configuration
- `startup.sh` - Service orchestration script
- `u-at-proto/docker-compose` - Original infrastructure foundation

## References

- **Commit**: `eed6423` - Test UI E2E BSky moderation
- **Bluesky AT Protocol**: https://atproto.com/
- **Ozone Moderation**: https://github.com/bluesky-social/ozone
- **Playwright**: https://playwright.dev/
