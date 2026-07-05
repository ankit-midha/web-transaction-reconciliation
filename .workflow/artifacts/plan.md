---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-6
job_id: wtr-6-dkuzkh
---

# WTR-6 — Implementation plan

## Approach

This plan delivers comprehensive test coverage (≥95% JaCoCo across instruction, line, method, class metrics) for the Web Transaction Store service through 51 tests spanning unit tests (37) and functional integration tests (14). Building on the foundation from WTR-3 (JPA entities, repository) and WTR-4 (REST endpoints, DTOs, service layer), this ticket focuses exclusively on testing infrastructure.

The test strategy follows Spring Boot best practices:

- **Unit tests** use `@WebMvcTest` for controllers (MockMvc, no full context), `@MockBean` for service layer tests (mocked repository), and plain JUnit for DTOs/entities/exceptions. These tests are fast, isolated, and focused on single-unit behavior.
- **Functional tests** use `@SpringBootTest` with Testcontainers to spin up a real Postgres 15.4 database, exercising the full stack (HTTP → controller → service → repository → database). These verify end-to-end behavior including transaction boundaries, validation, and error responses.

To resolve the spec's open questions:

- **Existing codebase**: Assumes WTR-3 and WTR-4 are implemented (entity, repository, controller, service, DTOs exist). This plan only adds tests and configuration, no production code changes unless required for testability (e.g., exposing health endpoint).
- **Coverage scope**: 95% target applies to all production code under `src/main/kotlin/com/webtransaction/microsite/*` excluding the application main class (`WebTransactionMicrositeApplication.kt`). Generated code and third-party libraries are excluded by JaCoCo filters.
- **Testcontainers version**: Uses Testcontainers 1.21.4 (pinned in Gradle dependencies). This version is compatible with Postgres 15.4 and Spring Boot 3.x.
- **Security feature**: `security.enabled` flag in `application.yml` toggles Spring Security on/off. Functional tests verify both modes: security disabled (default for test profile) allows unauthenticated access; security enabled (tested explicitly) requires authentication headers.
- **Flyway migrations**: Assumes migrations exist under `src/main/resources/db/migration/` from WTR-3. Test profile uses `spring.flyway.enabled=true` to apply migrations on Testcontainers startup. Other profiles toggle Flyway based on environment (local=true, dev=true, staging=false, prod=false — migrations applied via separate deployment process).
- **Environment variable names**: Standardizes on `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` for database credentials. `SECURITY_ENABLED` for security toggle. Each profile's `application-{profile}.yml` references these via `${DB_URL:default-value}` syntax.

The JaCoCo plugin configuration in `build.gradle.kts` generates both HTML (human-readable, opened in browser) and XML (machine-readable, for CI integration) reports. Coverage verification task (`jacocoTestCoverageVerification`) enforces the 95% floor across all four counters, failing the build if below threshold.

Package structure aligns with WTR-4:
- Production code: `src/main/kotlin/com/webtransaction/microsite/` (controller, service, dto, entity, exception, config)
- Test code: `src/test/kotlin/com/webtransaction/microsite/` (mirrors production structure)
- Configuration: `src/main/resources/application-{profile}.yml`

Dependencies added:
- `org.testcontainers:postgresql:1.21.4` (functional tests)
- `org.testcontainers:junit-jupiter:1.21.4` (JUnit 5 integration)
- `org.springframework.boot:spring-boot-starter-test` (already implicit)
- `io.mockk:mockk:1.13.8` (Kotlin-friendly mocking, alternative to Mockito)

## Files in scope

- `build.gradle.kts` (add JaCoCo plugin, Testcontainers dependencies)
- `src/main/resources/application-local.yml`
- `src/main/resources/application-test.yml`
- `src/main/resources/application-dev.yml`
- `src/main/resources/application-staging.yml`
- `src/main/resources/application-prod.yml`
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequestTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequestTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/dto/WebTransactionResponseTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/entity/WebTransactionEntityTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/config/DataSourceConfigTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/health/HealthEndpointTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/functional/WebTransactionFunctionalTests.kt`

## Plan Steps

### Step 1: Configure Gradle build with JaCoCo and Testcontainers dependencies
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: No automated test for Gradle config itself. Verification happens in Step 11 when `./gradlew test jacocoTestReport` runs successfully. Add `id("jacoco")` plugin, configure `jacocoTestReport` task to generate HTML+XML reports to `build/reports/jacoco/test/`. Add `jacocoTestCoverageVerification` task with 95% floor on all four counters. Add Testcontainers dependencies (postgresql, junit-jupiter) and MockK to `testImplementation`.

### Step 2: Create environment-specific application YAML files
- Test mode: `test-after`
- Files: `src/main/resources/application-{local,test,dev,staging,prod}.yml`
- Test strategy: No automated test for YAML syntax. Functional tests in Step 10 implicitly validate `application-test.yml` loads correctly. Each profile must define: `spring.datasource.url=${DB_URL:jdbc:postgresql://localhost:5432/webtransaction_{profile}}`, `spring.datasource.username=${DB_USERNAME:postgres}`, `spring.datasource.password=${DB_PASSWORD:password}`, `spring.flyway.enabled={true|false}`, `management.endpoints.web.exposure.include={health|health,info,metrics}`, `security.enabled=${SECURITY_ENABLED:false}`.

### Step 3: Write unit tests for WebTransactionController (6 tests)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- Test strategy: Use `@WebMvcTest(WebTransactionController::class)` with `@MockBean` for `WebTransactionService`. Tests: (1) POST creates transaction, returns 201, response body matches service output; (2) GET by ID delegates to service, returns 200; (3) GET by reference delegates to service, returns 200; (4) PUT by reference delegates to service, returns 200; (5) GET by ID when service throws `EntityNotFoundException`, returns 404 via `GlobalExceptionHandler`; (6) POST with invalid request triggers validation, returns 400 with field errors. Verify controller methods are thin (no business logic, only HTTP marshalling).

### Step 4: Write unit tests for WebTransactionService (9 tests)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt`
- Test strategy: Use `@MockBean` for `WebTransactionRepository` (from WTR-3). Tests: (1) `createTransaction` maps DTO to entity, saves via repository, returns response DTO; (2) `getTransactionById` found case, returns DTO; (3) `getTransactionById` not found, throws `EntityNotFoundException`; (4) `getTransactionByReference` found case, returns DTO; (5) `getTransactionByReference` not found, throws `EntityNotFoundException`; (6) `updateTransactionByReference` found case, updates only `reconcileStatus` and `externalReferenceNumber`, returns DTO; (7) `updateTransactionByReference` not found, throws `EntityNotFoundException`; (8) JSONB `originalPayload` preserves nested map structure; (9) JSONB `reconcilePayload` handles null values correctly.

### Step 5: Write unit tests for GlobalExceptionHandler (6 tests)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt`
- Test strategy: Instantiate `GlobalExceptionHandler` directly (no Spring context). Tests: (1) `EntityNotFoundException` returns 404 with `{"error": "Entity not found"}` structure; (2) `MethodArgumentNotValidException` returns 400 with `{"error": "...", "details": {"field": "message"}}` structure; (3) Generic `Exception` returns 500 with `{"error": "Internal server error"}`; (4) `OptimisticLockException` returns 409 Conflict; (5) Invalid enum deserialization error returns 400; (6) Empty request body (null payload) returns 400. Verify response entity status codes and body structure match acceptance criteria.

### Step 6: Write unit tests for DTOs (8 tests total — 3 CreateRequest, 3 UpdateRequest, 2 Response)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequestTests.kt`, `src/test/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequestTests.kt`, `src/test/kotlin/com/webtransaction/microsite/dto/WebTransactionResponseTests.kt`
- Test strategy: Plain JUnit tests (no Spring context). **CreateRequest**: (1) default constructor initializes all fields; (2) copy constructor creates independent copy; (3) `equals`/`hashCode` work correctly for data class semantics. **UpdateRequest**: (4) default constructor; (5) copy constructor; (6) `equals`/`hashCode`. **Response**: (7) `toString` includes all fields; (8) timestamp fields serialize to ISO-8601 format (verify via Jackson `ObjectMapper`).

### Step 7: Write unit tests for WebTransactionEntity (3 tests)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/entity/WebTransactionEntityTests.kt`
- Test strategy: Plain JUnit tests. Tests: (1) no-arg constructor initializes `id` to null, `version` to 0, timestamps to null (JPA defaults); (2) all-args constructor sets fields correctly; (3) field setters update values (verify `copy` method for data class). Verify JPA annotations (`@Entity`, `@Table`, `@Id`, `@Version`, `@Column`) are present (reflection-based assertions).

### Step 8: Write unit tests for DataSourceConfig (4 tests)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/config/DataSourceConfigTests.kt`
- Test strategy: Use `@SpringBootTest` with overridden properties to test different DB URL formats. Tests: (1) Postgres URL with host/port/database creates `HikariDataSource` with correct JDBC URL; (2) connection pool properties (max-pool-size, connection-timeout) applied from YAML; (3) invalid DB URL throws `DataSourceConfigurationException` during context load; (4) missing DB credentials throws exception. Verify `HikariDataSource` bean is created and injectable.

### Step 9: Write unit test for Health endpoint (1 test)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/health/HealthEndpointTests.kt`
- Test strategy: Use `@WebMvcTest` to test Spring Boot Actuator `/actuator/health` endpoint. Test: GET `/actuator/health` returns 200 with `{"status": "UP"}` body. No custom health indicator needed — Spring Boot's default health check suffices.

### Step 10: Write functional integration tests (14 tests)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/functional/WebTransactionFunctionalTests.kt`
- Test strategy: Use `@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)` with `@Testcontainers` and `@Container` for `PostgreSQLContainer("postgres:15.4")`. Tests: (1) POST create transaction → (2) GET by ID returns created record → (3) GET by reference returns same record → (4) PUT update by reference changes `reconcileStatus` → (5) GET by ID shows updated values. (6) POST with missing required field returns 400. (7) POST with `reference` > 100 chars returns 400. (8) POST with invalid enum value returns 400. (9) GET by non-existent ID returns 404. (10) GET by non-existent reference returns 404. (11) PUT to non-existent reference returns 404. (12) Deeply nested JSONB structure (3 levels) round-trips correctly. (13) Security disabled mode: unauthenticated request succeeds. (14) Security enabled mode: unauthenticated request returns 401 (test with `security.enabled=true` override).

### Step 11: Verify JaCoCo coverage meets 95% threshold
- Test mode: `test-after`
- Files: None (verification step)
- Test strategy: Run `./gradlew clean test jacocoTestReport jacocoTestCoverageVerification` locally. Open `build/reports/jacoco/test/html/index.html` and verify all four counters (instruction, line, method, class) show ≥95%. If below threshold, identify uncovered lines via HTML report (red highlighting), add missing test cases to relevant test files (Steps 3-10), and re-run. Iterate until threshold met. Final verification: `./gradlew test` exits 0, all 51 tests pass.

## Risks

- **Testcontainers performance**: Spinning up Postgres container adds ~5-10 seconds per test class using `@Testcontainers`. Mitigation: use singleton container pattern (one container shared across all functional tests) via `@Testcontainers(parallel = false)` and `@ClassRule` static field. If still slow, split functional tests into separate Gradle task (`functionalTest`) to run independently.
- **Coverage threshold too strict**: 95% across *all* metrics (instruction, line, method, class) may be difficult if production code has unreachable branches (e.g., defensive null checks, enum exhaustiveness). Mitigation: Step 11 iterates on adding tests; if specific lines are truly untestable, add JaCoCo exclusion rules (e.g., `excludeClasses = ["*.WebTransactionMicrositeApplication"]`).
- **Security toggle behavior ambiguity**: Spec mentions "security enabled/disabled toggles" but doesn't specify implementation details. If Spring Security is not configured, test 14 will fail. Mitigation: assume minimal Spring Security setup exists (e.g., `SecurityConfig.kt` with `@ConditionalOnProperty("security.enabled")`); if missing, mark test 14 as pending (`@Disabled`) and flag in out-of-plan section.
- **Flyway migration dependency**: If migrations don't exist or are broken, functional tests will fail during Testcontainers startup. Mitigation: Step 10 assumes WTR-3 delivered migrations; if missing, this blocks functional tests. Escalate as a dependency issue, not solvable within this ticket's scope.
- **MockK vs Mockito**: Using MockK (Kotlin-native mocking) instead of Mockito improves readability but requires different syntax (`every { ... } returns ...` instead of `when(...).thenReturn(...)`). Risk: team unfamiliarity. Mitigation: Step 3-5 establish MockK patterns; if team prefers Mockito, switch in Step 1 (change dependency to `mockito-kotlin`).
- **Environment YAML property resolution**: If environment variables (`DB_URL`, `DB_USERNAME`, etc.) are not set and defaults are invalid (e.g., `localhost:5432` unreachable), tests fail. Mitigation: `application-test.yml` uses Testcontainers JDBC URL syntax (`jdbc:tc:postgresql:15.4:///webtransaction`) to auto-start container, bypassing need for manual env vars in CI.

## Out-of-Plan (deferred)

- **Performance testing**: Load testing, stress testing, latency profiling — out-of-scope per spec.
- **Mutation testing**: Tools like PIT (Pitest) to verify test quality by mutating code — deferred.
- **CI/CD integration**: GitHub Actions workflow to run tests on PR, publish JaCoCo report to PR comment — deferred (assumes CI exists but not modified here).
- **Test parallelization**: Gradle `maxParallelForks` tuning, JUnit parallel execution — deferred unless build time exceeds 2 minutes.
- **Contract testing**: Pact/Spring Cloud Contract for API consumer-driven contracts — out-of-scope.
- **Chaos engineering tests**: Testcontainers failure injection (network partitions, database crashes) — deferred.
- **Security testing**: OWASP dependency scanning, penetration testing — out-of-scope per spec.
- **Testability refactors**: If production code is hard to test (e.g., tight coupling, no dependency injection), this plan works with existing design rather than refactoring. Only exception: if 95% coverage is mathematically impossible without refactors, flag specific classes/methods in Step 11 and propose minimal changes (e.g., extract method to make testable).
- **Test data builders**: Fluent builder pattern for DTOs/entities (e.g., `WebTransactionBuilder.aTransaction().withReference("ref").build()`) — deferred unless test duplication becomes severe (>5 tests with identical setup).
- **Custom JaCoCo exclusions**: Only exclude main application class; if other classes (e.g., generated code, framework glue) need exclusion, defer to separate ticket for coverage policy definition.
