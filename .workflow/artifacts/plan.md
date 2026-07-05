---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-10
job_id: wtr-10-68hm6z
---

# WTR-10 — Implementation plan

## Approach

This plan delivers the production-readiness infrastructure for the WTS integration: WireMock E2E test stubs, deployment configuration files, and comprehensive documentation. The work is organized around three parallel tracks — testing infrastructure, deployment config, and documentation — with minimal interdependencies, allowing the Implement phase to tackle them concurrently where possible.

**Resolving Open Questions:**

Following microservice and RetailX conventions, this plan makes these decisions:

- **ADR location**: Place in `web-transaction-microsite/docs/adr/001-fire-and-forget-design.md` — the ADR documents a design decision specific to WTS's behavior, so it belongs in the WTS repo. Follow the ADR template format with numbered files.
- **Security scopes**: Document placeholder scopes `wts:write` and `wts:read` in the README — actual OAuth/OIDC scope configuration is out-of-scope per spec, but the README should reference where these scopes are validated.
- **Docker Compose**: Create `docker-compose.e2e.yml` as a new file extending the base `docker-compose.yml` (if one exists) or standalone. This keeps E2E test setup isolated from local dev configuration.
- **WireMock timeout duration**: Use 5000ms (5 seconds) for the timeout stub — long enough to trigger timeout handling in orders-microsite without blocking CI excessively.
- **microsite.yaml template**: Assume greenfield with standard RetailX ECS Fargate structure: `build`, `deploy`, and `environments` sections. Reference AWS parameter store paths for secrets (e.g., `/retailx/{env}/wts/db-connection-string`).
- **Slack channels**: Use `#deployments-wts` for web-transaction-microsite and `#deployments-orders` for orders-microsite — placeholder names that align with typical org patterns.
- **Feature flag defaults**: Default `wts.integration.enabled` to `false` in prod, `true` in dev/staging — allows safe rollout with manual prod enable.

**Testing Strategy:**

The WireMock stubs cover three scenarios essential to validating fire-and-forget behavior:
1. **Happy path (201/200)**: Orders-microsite successfully creates a transaction (`POST /v1/webtransaction` → 201) and later updates it (`PUT /v1/webtransaction/reference/{ref}` → 200). Verifies the integration works when WTS is healthy.
2. **Server error (500)**: WTS returns 500 on POST. Orders-microsite logs the error but does not block order processing. Verifies fire-and-forget: order completes even when WTS fails.
3. **Timeout**: WTS takes >5s to respond. Orders-microsite times out and continues. Verifies resilience to slow/hanging WTS.

Each stub is a JSON file in `orders-microsite/tests/wiremock/mappings/` following WireMock's [request matching](http://wiremock.org/docs/request-matching/) and [response templating](http://wiremock.org/docs/response-templating/) formats.

**Deployment Config Structure:**

The `microsite.yaml` files follow this structure (simplified pseudo-schema):

```yaml
service:
  name: web-transaction-microsite
  build:
    dockerfile: Dockerfile
    context: .
  deploy:
    platform: ecs-fargate
    cpu: 512
    memory: 1024
    replicas: {dev: 1, staging: 2, prod: 3}
  database:
    type: rds-postgres
    parameterStore: /retailx/{env}/wts/db-connection-string
  notifications:
    slack: "#deployments-wts"
  environments:
    dev: {...}
    staging: {...}
    prod: {...}
```

For orders-microsite, the config includes `featureFlags: wts.integration.enabled` in each environment block.

**Documentation Deliverables:**

1. **web-transaction-microsite/README.md**: Replaces any existing README with a comprehensive guide covering:
   - Architecture overview (fire-and-forget writes to Postgres, no external dependencies)
   - Local dev setup (Docker Compose with Postgres, env vars, port mappings)
   - API endpoints (`POST /v1/webtransaction`, `PUT /v1/webtransaction/reference/{ref}`, `GET /v1/webtransaction/{id}`, `GET /v1/webtransaction/reference/{ref}`)
   - Security scopes (`wts:write`, `wts:read`)
   - Deployment process (references `microsite.yaml`, RetailX pipeline)

2. **web-transaction-microsite/docs/adr/001-fire-and-forget-design.md**: ADR documenting:
   - **Context**: Orders-microsite needs to store transaction metadata without blocking order completion
   - **Decision**: WTS uses fire-and-forget HTTP calls with no retries or error propagation
   - **Consequences**: Resilient to WTS downtime; potential for data loss on persistent failures; orders-microsite must log failures for manual reconciliation
   - **Alternatives considered**: Synchronous with retries (rejected: adds latency), message queue (rejected: over-engineered for MVP)

3. **orders-microsite/CHANGELOG.md**: Add entry for the WTS integration:
   ```markdown
   ## [Unreleased]
   ### Added
   - Web Transaction Store (WTS) integration for reconciliation metadata
     - Fire-and-forget POST/PUT calls to WTS endpoints
     - Feature flag `wts.integration.enabled` for gradual rollout
     - WireMock E2E test stubs for happy path and failure scenarios
   ```

**Docker Compose E2E Setup:**

The `docker-compose.e2e.yml` brings up three services:
- `postgres`: WTS database (uses official `postgres:14` image, mounts init script creating `reconciliation_transaction` table)
- `web-transaction-microsite`: Builds from local Dockerfile, connects to postgres, exposes port 8080
- `orders-microsite-test`: Runs integration tests with WireMock stubs, calls WTS endpoints, verifies database state

The E2E test flow:
1. Docker Compose starts postgres and web-transaction-microsite
2. orders-microsite-test container runs test suite with WireMock
3. Test creates a fake order, triggering WTS POST (201 response)
4. Test simulates reconciliation, triggering WTS PUT (200 response)
5. Test queries postgres directly to verify `reconciliation_transaction` row exists with updated `reconcile_status`
6. Test repeats with 500 and timeout stubs, verifying orders-microsite logs errors but does not fail

**CI/CD Pipeline Files:**

Create `.github/workflows/retailx-deploy-wts.yml` and `.github/workflows/retailx-deploy-orders.yml` as placeholder CI configs. Each workflow:
- Triggers on push to `main` or manual dispatch
- Builds Docker image
- Runs tests (unit + E2E)
- Deploys to dev → staging → prod environments via RetailX deploy action (stubbed as a comment in YAML)
- Posts deployment notification to Slack

These are minimal stubs sufficient for the E2E measurement suite to verify their existence and structure, not production-ready CI.

## Files in scope

**Web Transaction Microsite:**
- `web-transaction-microsite/README.md`
- `web-transaction-microsite/docs/adr/001-fire-and-forget-design.md`
- `web-transaction-microsite/microsite.yaml`
- `web-transaction-microsite/Dockerfile` (stub for E2E)

**Orders Microsite:**
- `orders-microsite/CHANGELOG.md`
- `orders-microsite/microsite.yaml`
- `orders-microsite/tests/wiremock/mappings/wts-post-201-success.json`
- `orders-microsite/tests/wiremock/mappings/wts-put-200-success.json`
- `orders-microsite/tests/wiremock/mappings/wts-post-500-error.json`
- `orders-microsite/tests/wiremock/mappings/wts-post-timeout.json`

**Shared E2E Infrastructure:**
- `docker-compose.e2e.yml`
- `.github/workflows/retailx-deploy-wts.yml`
- `.github/workflows/retailx-deploy-orders.yml`

## Plan Steps

### Step 1: Create web-transaction-microsite README
- Test mode: `test-after`
- Files: `web-transaction-microsite/README.md`
- Test strategy: E2E script verifies README exists and contains required sections: "Architecture", "Local Development", "API Endpoints", "Security Scopes", "Deployment". Uses `grep` to check for section headers and key terms (fire-and-forget, Postgres, `POST /v1/webtransaction`, `wts:write`).

### Step 2: Create ADR for fire-and-forget design
- Test mode: `test-after`
- Files: `web-transaction-microsite/docs/adr/001-fire-and-forget-design.md`
- Test strategy: E2E script verifies ADR file exists and follows ADR template structure: title, status, context, decision, consequences, alternatives. Checks for key terms: "fire-and-forget", "no retries", "data loss", "resilience".

### Step 3: Create web-transaction-microsite deployment config
- Test mode: `test-after`
- Files: `web-transaction-microsite/microsite.yaml`
- Test strategy: E2E script verifies YAML file exists, parses as valid YAML, contains required keys: `service.name`, `deploy.platform: ecs-fargate`, `database.type: rds-postgres`, `notifications.slack`, `environments` with `dev`, `staging`, `prod`.

### Step 4: Create orders-microsite CHANGELOG entry
- Test mode: `test-after`
- Files: `orders-microsite/CHANGELOG.md`
- Test strategy: E2E script verifies CHANGELOG exists and contains "Web Transaction Store" or "WTS integration" entry under `[Unreleased]` section. Checks for "fire-and-forget", "feature flag", and "`wts.integration.enabled`" keywords.

### Step 5: Create orders-microsite deployment config
- Test mode: `test-after`
- Files: `orders-microsite/microsite.yaml`
- Test strategy: E2E script verifies YAML file exists, parses as valid YAML, contains required keys: `service.name`, `deploy.platform`, `notifications.slack`, `featureFlags` section with `wts.integration.enabled`. Validates feature flag defaults per environment (dev: true, staging: true, prod: false).

### Step 6: Create WireMock stub — POST 201 success
- Test mode: `test-after`
- Files: `orders-microsite/tests/wiremock/mappings/wts-post-201-success.json`
- Test strategy: E2E script verifies JSON file exists, parses as valid JSON, follows WireMock stub structure: `request.method: POST`, `request.urlPathPattern: /v1/webtransaction`, `response.status: 201`, `response.headers.Content-Type: application/json`, `response.jsonBody` with id/reference fields.

### Step 7: Create WireMock stub — PUT 200 success
- Test mode: `test-after`
- Files: `orders-microsite/tests/wiremock/mappings/wts-put-200-success.json`
- Test strategy: E2E script verifies JSON file exists, parses as valid JSON, follows WireMock stub structure: `request.method: PUT`, `request.urlPathPattern: /v1/webtransaction/reference/.*`, `response.status: 200`, `response.jsonBody` with updated `reconcileStatus`.

### Step 8: Create WireMock stub — POST 500 error
- Test mode: `test-after`
- Files: `orders-microsite/tests/wiremock/mappings/wts-post-500-error.json`
- Test strategy: E2E script verifies JSON file exists, parses as valid JSON, follows WireMock stub structure: `request.method: POST`, `response.status: 500`, `response.body: Internal Server Error` or similar error message.

### Step 9: Create WireMock stub — POST timeout
- Test mode: `test-after`
- Files: `orders-microsite/tests/wiremock/mappings/wts-post-timeout.json`
- Test strategy: E2E script verifies JSON file exists, parses as valid JSON, follows WireMock stub structure: `request.method: POST`, `response.fixedDelayMilliseconds: 5000` (5 seconds), `response.status: 200` (response that arrives too late).

### Step 10: Create Docker Compose E2E configuration
- Test mode: `test-after`
- Files: `docker-compose.e2e.yml`
- Test strategy: E2E script verifies YAML file exists, parses as valid Docker Compose YAML, contains services: `postgres`, `web-transaction-microsite`, `orders-microsite-test`. Validates postgres service uses `postgres:14` image, WTS service exposes port 8080, test service has `depends_on: [postgres, web-transaction-microsite]`.

### Step 11: Create web-transaction-microsite Dockerfile stub
- Test mode: `test-after`
- Files: `web-transaction-microsite/Dockerfile`
- Test strategy: E2E script verifies Dockerfile exists and contains basic Spring Boot Dockerfile structure: `FROM` clause with JRE base image (e.g., `eclipse-temurin:17-jre`), `COPY` for JAR file, `EXPOSE` port, `ENTRYPOINT` with `java -jar`.

### Step 12: Create RetailX CI workflow for web-transaction-microsite
- Test mode: `test-after`
- Files: `.github/workflows/retailx-deploy-wts.yml`
- Test strategy: E2E script verifies YAML file exists, parses as valid GitHub Actions workflow, contains jobs: `build`, `test`, `deploy`. Validates workflow triggers on `push` to `main`, includes steps for Docker build, test execution, and deployment (stubbed). Checks for Slack notification step.

### Step 13: Create RetailX CI workflow for orders-microsite
- Test mode: `test-after`
- Files: `.github/workflows/retailx-deploy-orders.yml`
- Test strategy: E2E script verifies YAML file exists, parses as valid GitHub Actions workflow, similar structure to WTS workflow. Validates deployment includes environment-specific feature flag configuration for `wts.integration.enabled`.

### Step 14: End-to-end integration validation
- Test mode: `test-after`
- Files: All files from Steps 1-13
- Test strategy: E2E script performs cross-file validation: (1) Verify endpoint URLs in README match WireMock stub paths. (2) Confirm Dockerfile referenced in `web-transaction-microsite/microsite.yaml` exists. (3) Check Docker Compose service names match deployment config service names. (4) Validate feature flag name in orders-microsite deployment config matches CHANGELOG documentation. (5) Verify ADR filename follows numbering convention (001-*.md). (6) Confirm all WireMock stubs target the same base path (`/v1/webtransaction`).

## Risks

- **WireMock stub format variations**: Different WireMock versions have slightly different JSON schema requirements (e.g., `urlPathPattern` vs `urlPattern`). Mitigation: Use WireMock 2.x format (most common) with `urlPathPattern` for regex matching.
- **Docker Compose local vs CI differences**: E2E test verifies Docker Compose syntax but cannot actually run containers in the measurement script (no Docker daemon in CI). Mitigation: Document that the E2E test validates structure only; actual container orchestration testing is out-of-scope per spec.
- **Microsite.yaml schema unknown**: No existing microsite.yaml examples in this repo, so the plan assumes a structure based on common ECS patterns. If RetailX has a specific schema, the Implement phase may need to adjust. Mitigation: E2E script validates only required keys, allowing flexibility in schema details.
- **CHANGELOG merge conflicts**: If orders-microsite CHANGELOG is actively updated, adding the `[Unreleased]` entry could conflict. Mitigation: Place entry at the top of the file; if `[Unreleased]` section doesn't exist, create it.
- **ADR directory convention**: If web-transaction-microsite uses a different docs structure (e.g., `docs/decisions/` instead of `docs/adr/`), the ADR path may be non-standard. Mitigation: Follow common ADR convention (`docs/adr/`); E2E test checks for this path specifically.
- **Feature flag configuration format**: The spec mentions feature flag `wts.integration.enabled` but doesn't specify how orders-microsite reads this (env var, config file, parameter store). Mitigation: Document in microsite.yaml as a YAML key; actual implementation mechanism is out-of-scope.

## Out-of-Plan (deferred)

- **Actual Docker container execution**: E2E measurement script validates Docker Compose and Dockerfile structure but does not run containers or execute integration tests. True container orchestration testing requires Docker daemon and is beyond bash script scope.
- **WireMock server setup**: Creating the WireMock stubs but not setting up a running WireMock server or test harness to load them. Actual test execution framework is assumed to exist in orders-microsite.
- **Database schema initialization**: Docker Compose references postgres, but the actual Flyway migrations (from WTR-3) are not re-integrated here. E2E test assumes `reconciliation_transaction` table exists.
- **Production-ready CI pipelines**: The GitHub Actions workflows are minimal stubs sufficient for E2E validation, not production-ready with secrets management, multi-region deployment, rollback logic, etc.
- **Slack webhook integration**: Deployment config references Slack channels, but actual webhook URLs and authentication are out-of-scope.
- **OAuth/OIDC scope validation**: README documents security scopes (`wts:write`, `wts:read`) but does not implement scope validation middleware.
- **Parameter store secret paths**: Deployment config references AWS parameter store paths (e.g., `/retailx/{env}/wts/db-connection-string`) but does not create these parameters or configure IAM permissions.
- **Load testing or performance benchmarks**: Out-of-scope per spec Non-Goals.
- **Production monitoring dashboards**: Out-of-scope per spec Non-Goals; only deployment notifications are in scope.
- **Rollback procedures**: Deployment config supports multi-environment promotion (dev → staging → prod) but does not define rollback workflows.
- **Manual reconciliation tooling**: ADR mentions manual reconciliation for persistent WTS failures, but no tooling or runbook is provided.
