---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-10
job_id: wtr-10-oer48n
---

# WTR-10 — Implementation plan

## Approach

This ticket addresses deployment readiness for the web-transaction-microsite (WTS) service. The spec describes cross-service deliverables spanning both WTS and orders-microsite, but this plan scopes only to artifacts that belong in the **web-transaction-microsite repository**.

The WTS service already has functional REST endpoints (`POST /v1/webtransaction`, `PUT /v1/webtransaction/reference/{ref}`) with OAuth2 JWT security requiring `write:web-transaction` and `read:web-transaction` scopes. The integration pattern is fire-and-forget: orders-microsite calls WTS endpoints asynchronously without expecting success responses or retries. This design tolerates WTS unavailability without blocking order processing.

The implementation will deliver: (1) comprehensive README documentation covering architecture, API contracts, security model, and local development workflow; (2) an ADR explaining the fire-and-forget integration pattern and its failure mode trade-offs; (3) deployment configuration (microsite.yaml) defining ECS Fargate tasks, RDS Postgres binding, environment promotion paths, and Slack notifications; (4) extended Docker Compose configuration supporting E2E testing scenarios including WireMock simulation of orders-microsite clients.

Orders-microsite deliverables (WireMock stubs, CHANGELOG entry, feature flag config) are explicitly out-of-plan as they require commits to a separate repository not present in this workspace. The E2E Docker Compose setup will include a WireMock service with example mappings demonstrating how orders-microsite would stub WTS endpoints, serving as both documentation and a local testing harness.

## Files in scope

### Documentation to create:
- `docs/adr/001-fire-and-forget-integration.md`

### Documentation to update:
- `README.md` (expand architecture, endpoints, security sections)

### Deployment configuration to create:
- `microsite.yaml`

### Docker Compose configuration to update:
- `docker-compose.yml` (add wiremock service for E2E testing)

### WireMock mappings to create (example stubs):
- `docker/wiremock/mappings/create-transaction-success.json`
- `docker/wiremock/mappings/update-transaction-success.json`
- `docker/wiremock/mappings/server-error.json`
- `docker/wiremock/mappings/timeout.json`

## Plan Steps

### Step 1: Create ADR for fire-and-forget integration pattern
- Test mode: `test-after`
- Files: `docs/adr/001-fire-and-forget-integration.md`
- Test strategy: Documentation artifact; verify by reading ADR and confirming it addresses: (1) context: why fire-and-forget vs synchronous/retry patterns, (2) decision: orders-microsite sends WTS calls without blocking on responses, (3) consequences: positive (order flow never blocked by WTS outage), negative (potential data loss if WTS is down, manual reconciliation needed), (4) failure modes: WTS 500 error, network timeout, database unavailable. No automated tests for documentation.

### Step 2: Expand README with production-ready documentation
- Test mode: `test-after`
- Files: `README.md`
- Test strategy: Update existing README to add sections: **Architecture** (fire-and-forget integration pattern, Postgres persistence, OAuth2 resource server), **API Endpoints** (table listing POST/GET/PUT endpoints with required scopes and example payloads), **Security Model** (OAuth2 JWT validation, required scopes `read:web-transaction` and `write:web-transaction`, issuer-uri and audience validation), **Local Development** (retain existing setup steps), **Environment Configuration** (reference to application-{dev,staging,prod}.yml profiles). Verify by reading the updated README and confirming all sections are present and accurate.

### Step 3: Create deployment configuration (microsite.yaml)
- Test mode: `test-after`
- Files: `microsite.yaml`
- Test strategy: Create RetailX pipeline deployment config defining: (1) Docker image build from Dockerfile with Gradle bootJar, (2) ECS Fargate task definition (CPU: 512, memory: 1024MB, health check: /actuator/health), (3) RDS Postgres binding via environment variables (DB_URL, DB_USERNAME, DB_PASSWORD from AWS Secrets Manager), (4) environment promotion: dev → staging → prod with manual approval gates before prod, (5) Slack notifications to #deployments channel on success/failure. Verify by linting YAML syntax and confirming all required keys are present. No runtime test; deployment config is verified during actual deploy.

### Step 4: Extend Docker Compose with E2E testing setup
- Test mode: `test-after`
- Files: `docker-compose.yml`, `docker/wiremock/mappings/*.json`
- Test strategy: Add `wiremock` service to docker-compose.yml (image: wiremock/wiremock:3.3.1, port 8081, volume mount ./docker/wiremock/mappings). Create four WireMock mapping files demonstrating how orders-microsite stubs would work: (1) POST /v1/webtransaction → 201 with Location header, (2) PUT /v1/webtransaction/reference/{ref} → 200, (3) POST /v1/webtransaction → 500 (simulating WTS outage), (4) POST /v1/webtransaction → fixed delay 30s + socket timeout (simulating network timeout). Verify by running `docker compose up wiremock` and curling each stub endpoint to confirm expected responses. E2E test validation: manually create a transaction via WireMock, verify WTS postgres contains the row.

## Risks

1. **Orders-microsite scope creep**: The spec requests WireMock stubs "in orders-microsite tests/" and a CHANGELOG entry in that service. This plan explicitly excludes those deliverables as they require commits to a separate repository. Mitigation: deliver example WireMock mappings in THIS repo as documentation/reference; orders-microsite team can copy them. If this is insufficient, the ticket should be split into WTR-10a (WTS) and WTR-10b (orders-microsite).

2. **RetailX microsite.yaml schema unknown**: The spec references "RetailX pipeline" and "microsite.yaml" but no template exists in this repo. The plan assumes a standard ECS/Fargate deployment config structure based on AWS best practices. Mitigation: if RetailX has a specific schema or required fields, the microsite.yaml will need revision during code review. Open question 5 in the spec asks about templates — this should be answered before implementation.

3. **Security scope documentation incomplete**: The README expansion will document the existing scopes (`read:web-transaction`, `write:web-transaction`) visible in SecurityConfiguration.kt and WebTransactionController.kt, but the spec's open question 2 asks "what are the specific security scopes required?" This suggests the documented scopes may be provisional. Mitigation: document what exists now; if scopes change, update README in a follow-up.

4. **E2E test definition ambiguity**: The spec acceptance criteria says "E2E test passes: Docker Compose brings up Postgres + WTS + orders-microsite with WireMock, fake order creates reconciliation_transaction row that gets updated." However, this repo does not contain orders-microsite code. The plan interprets "E2E test" as a manual verification step using WireMock to simulate orders-microsite calls, not an automated test suite. Mitigation: if an automated E2E test is required, it would need to be a Bash script or Gradle task that curls WireMock → curls WTS → asserts database state. This is not included in the current plan but could be added in Step 4 if clarified.

5. **Slack channel and feature flag defaults unknown**: Open questions 6 and 7 ask about Slack channels and feature flag defaults. The plan assumes: Slack channel = `#deployments`, feature flag N/A for WTS (only orders-microsite has `wts.integration.enabled`). Mitigation: placeholder values can be updated during implementation or code review once answers are provided.

## Out-of-Plan (deferred)

1. **Orders-microsite WireMock stubs**: The spec requests "WireMock test stubs in orders-microsite tests/" to verify WTS integration. This requires modifying a separate repository. Deferred; example mappings provided in THIS repo can serve as a reference implementation.

2. **Orders-microsite CHANGELOG entry**: The spec requests documenting the integration in orders-microsite's CHANGELOG.md. Deferred; this is a separate repo commit.

3. **Orders-microsite feature flag config**: The spec requests `wts.integration.enabled` feature flag in orders-microsite deployment config. Deferred; this is a separate repo commit.

4. **RetailX CI/CD pipeline definitions**: The spec acceptance criteria mentions "CI green in RetailX for both microsites." The microsite.yaml config is the artifact consumed by RetailX CI/CD, but the plan does not include creating GitHub Actions workflows or modifying .github/workflows/agent.yml. The existing agent.yml is orchestration-only (Jira webhook → Claude Code), not a build/deploy pipeline. Deferred unless clarified.

5. **Database migration scripts**: The spec explicitly lists this as a non-goal. The microsite.yaml will reference RDS Postgres binding but will not include Flyway migration files or schema DDL. The existing application.yml has `jpa.hibernate.ddl-auto: validate`, implying migrations are managed out-of-band. Deferred.

6. **Production monitoring/alerting**: Explicitly out-of-scope per spec. The plan includes Slack deployment notifications but no CloudWatch alarms, PagerDuty integrations, or Grafana dashboards. Deferred.

7. **Automated E2E test execution**: The spec describes an E2E test scenario but does not specify whether it should be automated (e.g., a `./gradlew e2eTest` task) or manual. The plan delivers Docker Compose + WireMock setup for manual testing. If automated E2E tests are required, they would need: (1) Testcontainers to manage docker-compose lifecycle, (2) RestAssured or Spring WebTestClient to call WireMock and WTS, (3) database assertions via JPA repository. This is substantial work and deferred unless explicitly requested.
