# Draft spec — WTR-10: E2E verification, deployment config, and docs

## Problem
The web-transaction-microsite (WTS) and orders-microsite integration needs end-to-end testing infrastructure, deployment configuration, and documentation to be production-ready. Currently missing:
- WireMock test stubs in orders-microsite to verify WTS integration behavior (happy path + failure modes)
- Deployment configuration (microsite.yaml) for both services in the RetailX pipeline
- Documentation covering architecture, setup, integration points, and design decisions

## Goal
Complete the cross-cutting deliverables required to deploy and maintain the WTS integration: E2E test harness with WireMock stubs, deployment configuration with feature flag control, and comprehensive documentation.

## Non-Goals
- Implementing the actual WTS or orders-microsite integration logic (assumed complete)
- Performance testing or load testing
- Production monitoring/alerting setup beyond Slack channel routing
- Database migration scripts (RDS Postgres binding only)

## Users / Surfaces affected
**orders-microsite:**
- `tests/` directory — new WireMock stub definitions for WTS endpoints
- `CHANGELOG.md` — integration documentation entry
- Deployment config — `microsite.yaml` with WTS feature flag

**web-transaction-microsite:**
- `README.md` — new/updated with architecture, dev setup, endpoints, security scopes
- Deployment config — `microsite.yaml` with RDS Postgres binding
- New ADR document — fire-and-forget design rationale and failure modes

**Shared:**
- Docker Compose configuration for E2E testing
- RetailX CI/CD pipeline definitions for both services

## Acceptance Criteria
- WireMock stubs in orders-microsite tests cover:
  - `POST /v1/webtransaction` returning 201
  - `PUT /v1/webtransaction/reference/{ref}` returning 200
  - Failure scenarios (500 error, timeout) exercising fire-and-forget behavior
- `microsite.yaml` deployment configuration exists for both services with:
  - Image build definitions
  - ECS Fargate task definitions
  - RDS Postgres binding for WTS
  - Slack channel routing
  - Environment promotion path: dev → staging → prod
  - Feature flag `wts.integration.enabled` in orders-microsite
- Documentation complete:
  - `README.md` in web-transaction-microsite covers architecture, dev setup, endpoints, security scopes
  - `CHANGELOG.md` entry in orders-microsite documents the integration
  - ADR created explaining fire-and-forget rationale and failure modes
- E2E test passes: Docker Compose brings up Postgres + WTS + orders-microsite with WireMock, fake order creates `reconciliation_transaction` row that gets updated
- CI green in RetailX for both microsites

## Open Questions
1. Where should the ADR document be located — in orders-microsite, web-transaction-microsite, or a shared docs repo?
2. What are the specific security scopes required for the WTS endpoints (referenced in README)?
3. Does the existing Docker Compose setup need modification, or is a new compose file required for E2E testing?
4. What is the expected timeout duration for the WireMock timeout failure stub?
5. Are there existing microsite.yaml templates in the RetailX pipeline that should be followed, or is this greenfield?
6. What Slack channel(s) should receive deployment notifications for each service?
7. Should the feature flag default to enabled or disabled in each environment (dev/staging/prod)?

## Out-of-Scope
- Implementing application-level error handling or retry logic (fire-and-forget is already designed)
- Setting up production database schemas or running migrations (only binding configuration)
- Creating new CI/CD pipeline infrastructure (using existing RetailX pipeline)
- Monitoring dashboards or metrics collection beyond deployment notifications

---
_Reply on this ticket to refine. When you're happy, comment `APPROVED` (uppercase, standalone) and the workflow will move to the Plan phase._
_Job: wtr-10-oer48n · Ref: wtr-10-oer48n:intake:1_
