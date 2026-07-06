---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-2
job_id: wtr-2-l06yf8
---

# WTR-2 — Implementation plan

## Approach

This plan creates a production-ready Spring Boot 3.3.12 skeleton using Kotlin 1.9.23 with Gradle 8.6+ (Kotlin DSL), enforced quality gates (Ktlint, Detekt, JaCoCo 95%), and local development infrastructure (Postgres 15.4 via Docker Compose). The skeleton will use `com.webtransaction.microsite` as the base package, following standard Spring Boot conventions.

To satisfy the 95% JaCoCo threshold on a greenfield codebase, we include a minimal health check endpoint (`GET /health`) with comprehensive tests. This provides a working baseline that demonstrates the build pipeline, testing infrastructure, and containerization while keeping scope tight.

**Resolving spec ambiguities:**
- **Gradle DSL**: Kotlin DSL (modern default for Kotlin projects)
- **Ktlint version**: 1.1.1 (spec's "11.3.2" appears to be a typo; Ktlint versioning is 1.x as of 2025)
- **Kafka**: Deferred — Docker Compose includes only Postgres 15.4
- **Spring starters**: `web`, `data-jpa`, `actuator`, `test` (minimal viable set for a containerized service with database connectivity)
- **JaCoCo 95%**: Met via health check controller + tests; threshold remains at 95% from day one to establish quality baseline

The multi-stage Dockerfile uses Corretto 17 Alpine for the runtime image. All quality gates (Ktlint, Detekt, JaCoCo) run as part of `./gradlew build` and must pass before merge.

## Files in scope

- `settings.gradle.kts`
- `build.gradle.kts`
- `gradle/wrapper/gradle-wrapper.properties`
- `gradle/wrapper/gradle-wrapper.jar`
- `gradlew`
- `gradlew.bat`
- `src/main/kotlin/com/webtransaction/microsite/Application.kt`
- `src/main/kotlin/com/webtransaction/microsite/controller/HealthController.kt`
- `src/main/resources/application.yml`
- `src/main/resources/application-test.yml`
- `src/test/kotlin/com/webtransaction/microsite/ApplicationTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/controller/HealthControllerTests.kt`
- `docker-compose.yml`
- `Dockerfile`
- `.editorconfig`
- `.gitignore` (update existing)
- `README.md` (update existing)
- `detekt.yml`

## Plan Steps

### Step 1: Initialize Gradle wrapper and base build configuration
- Test mode: `test-after`
- Files: `settings.gradle.kts`, `build.gradle.kts`, `gradle/wrapper/gradle-wrapper.properties`, `gradle/wrapper/gradle-wrapper.jar`, `gradlew`, `gradlew.bat`
- Test strategy: Verify `./gradlew --version` reports Gradle 8.6+. Verify `./gradlew tasks` completes without errors and lists standard Spring Boot tasks. Manual validation only — no automated tests at this stage.

### Step 2: Create Spring Boot application entrypoint
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/Application.kt`, `src/test/kotlin/com/webtransaction/microsite/ApplicationTests.kt`, `src/main/resources/application.yml`, `src/main/resources/application-test.yml`
- Test strategy: Write `ApplicationTests` with `@SpringBootTest` annotation that verifies the Spring context loads successfully. Use H2 in-memory database for tests (configure in `application-test.yml`) to avoid Postgres dependency. Test must pass and achieve >95% coverage on `Application.kt`.

### Step 3: Implement health check endpoint
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/HealthController.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/HealthControllerTests.kt`
- Test strategy: Write `HealthControllerTests` using `@WebMvcTest(HealthController::class)` to verify `GET /health` returns 200 with `{"status":"UP"}` JSON response. Verify all controller code paths are covered (aim for 100% coverage on this class).

### Step 4: Configure Ktlint and Detekt quality gates
- Test mode: `test-after`
- Files: `build.gradle.kts`, `detekt.yml`
- Test strategy: Run `./gradlew ktlintCheck` and verify zero violations. Run `./gradlew detekt` and verify zero violations. Intentionally introduce a style violation (e.g., extra whitespace) and confirm `ktlintCheck` fails. Revert and confirm all existing tests still pass.

### Step 5: Enable JaCoCo coverage verification
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: Run `./gradlew test jacocoTestCoverageVerification` and verify it passes with 95% thresholds on instruction, line, method, and class metrics. Run `./gradlew build` and confirm JaCoCo runs as part of the build. Temporarily comment out one test method, confirm coverage drops below 95% and build fails, then restore.

### Step 6: Create multi-stage Dockerfile
- Test mode: `test-after`
- Files: `Dockerfile`
- Test strategy: Run `docker build -t web-transaction-microsite:local .` and verify it completes successfully. Inspect the final image with `docker inspect web-transaction-microsite:local` and confirm base is `amazoncorretto:17-alpine`. Run `docker run --rm -p 8080:8080 web-transaction-microsite:local` and verify Spring Boot starts, health endpoint is reachable at `http://localhost:8080/health`, and returns expected JSON.

### Step 7: Add Docker Compose with Postgres 15.4
- Test mode: `test-after`
- Files: `docker-compose.yml`, `src/main/resources/application.yml`
- Test strategy: Run `docker compose up -d postgres` and verify `docker compose ps` shows postgres service as healthy. Run `docker compose exec postgres psql -U postgres -c 'SELECT version();'` and confirm it reports Postgres 15.4. Verify application.yml contains correct JDBC URL, username, password for local Postgres. Run `docker compose down -v` to clean up.

### Step 8: Add project configuration files
- Test mode: `test-after`
- Files: `.editorconfig`, `.gitignore`, `README.md`, `detekt.yml`
- Test strategy: Verify `.gitignore` includes Gradle artifacts (`build/`, `.gradle/`, `bin/`), IDE files (`.idea/`, `*.iml`), and OS files (`.DS_Store`). Verify `README.md` documents setup steps (`./gradlew build`, `docker compose up`, how to run tests, how to build Docker image). Verify `.editorconfig` specifies Kotlin conventions (4-space indent, `lf` line endings, charset UTF-8). Manual validation — no automated tests.

## Risks

- **JaCoCo 95% threshold on greenfield code**: This is a high bar for initial scaffolding. Mitigation: the health check endpoint + tests provide enough coverage to meet the threshold. Future tickets adding complex business logic may need to invest in test coverage from the start.
- **Kotlin 1.9.23 compatibility with Spring Boot 3.3.12**: Spring Boot 3.3.x officially supports Kotlin 1.9.x, but transitive dependency conflicts could arise. Mitigation: lock plugin versions explicitly and use Spring's dependency management BOM.
- **Ktlint version ambiguity**: Spec cites "11.3.2" but Ktlint versioning is 1.x. If this is a custom fork or internal build, implementation will fail. Mitigation: plan assumes 1.1.1; if build fails, consult with reporter.
- **Test database strategy**: `@SpringBootTest` attempting to connect to Postgres when it's not running would break tests. Mitigation: use H2 in-memory database for tests (via `application-test.yml` profile) and reserve Postgres for local runtime only.
- **Dockerfile build context size**: If the repository accumulates large build artifacts, Docker build may be slow or fail. Mitigation: `.dockerignore` (out of scope here, but worth noting) should exclude `.git/`, `build/`, `.gradle/`, etc.

## Out-of-Plan (deferred)

- **Kafka / Zookeeper infrastructure**: Spec lists this as "if needed" — deferred until a future ticket requires message broker integration.
- **Database schema or migrations**: Explicitly out-of-scope per spec. Flyway or Liquibase configuration deferred to future work.
- **CI/CD pipeline**: Plan cannot modify `.github/workflows/` per constraints. GitHub Actions workflow for running `./gradlew build` on PR can be added in a follow-up ticket.
- **Production application properties**: Only local dev properties (Postgres connection for Docker Compose, H2 for tests) are included. Environment-specific config (staging, prod) deferred.
- **API documentation (Swagger/OpenAPI)**: No business logic endpoints exist yet. Swagger setup deferred until API surface is defined.
- **Advanced observability**: Spring Boot Actuator is included with default endpoints (`/actuator/health`, `/actuator/info`). Custom metrics, distributed tracing (e.g., Micrometer + Zipkin) deferred.
- **Security configuration**: No authentication or authorization is configured. Deferred to future tickets when security requirements are defined.
- **Pre-commit hooks**: Ktlint and Detekt run as part of `./gradlew build`, but Git pre-commit hooks are not configured. Developers must run build locally before pushing. Hook setup could be added via Husky or similar in a follow-up.
