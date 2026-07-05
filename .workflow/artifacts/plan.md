---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-6
job_id: wtr-6-58kyda
---

# WTR-6 — Implementation plan

## Approach

This plan builds a comprehensive test suite achieving ≥95% JaCoCo coverage across all four metrics (instruction, line, method, class) for the Web Transaction Store service. Building on WTR-3 (data layer), WTR-4 (REST layer), and WTR-5 (security + exception handling), this ticket adds 37 unit tests and 14 functional integration tests to verify all components work correctly in isolation and together.

The test strategy follows Spring Boot testing best practices:
- **Unit tests** use `@WebMvcTest`, `@DataJpaTest`, or plain JUnit with mocked dependencies to test single components in isolation (fast, focused)
- **Functional tests** use `@SpringBootTest` with Testcontainers (Postgres 15.4) to test full HTTP request/response cycles against a real database (slow, comprehensive)

Key decisions resolving spec open questions:

**Coverage scope (spec Q3):** Target 95% across all production code in `src/main/kotlin/com/webtransaction/microsite/*`. Exclude: main application class (`*Application.kt`), generated code, and Spring Boot auto-configuration classes. JaCoCo verification rule explicitly lists exclusions.

**Testcontainers version (spec Q4):** Use 1.21.4 as specified. This version is added as a new `testImplementation` dependency (not currently in use). Requires explicit Docker image tag: `postgres:15.4-alpine`.

**Security toggle (spec Q5):** References WTR-5's `security.enabled` property. Functional tests verify behavior with `@ActiveProfiles("test")` (security disabled) and default profile (security enabled via JWT). Security-related tests already exist from WTR-5; this plan focuses on coverage of other components.

**Flyway migrations (spec Q6):** Already exist from WTR-3. Tests use `spring.flyway.enabled=true` in test profile to ensure schema is applied via Testcontainers.

**Environment variables (spec Q7):** Use `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` as established in prior WTR tickets. Application YAML files reference these via `${DB_URL}` syntax.

**Existing codebase (spec Q1):** Service implementation exists from WTR-3/4/5. This is pure test-after work — no production code changes except environment configuration files.

Test breakdown (37 unit + 14 functional = 51 total):

**Unit tests (37):**
1. `WebTransactionControllerTests.kt` (6 tests): Verify controller delegates to service, propagates exceptions, maps DTOs. Mock service layer. Test: create, getById, getByReference, update, service throws EntityNotFoundException → controller propagates, validation exception → propagates.
2. `WebTransactionServiceTests.kt` (9 tests): Verify service CRUD logic, entity↔DTO mapping, not-found handling. Mock repository layer. Test: create (saves entity, returns response DTO), getById (found/not-found), getByReference (found/not-found), update (found/not-found, merges fields), payload null handling (defaults applied).
3. `GlobalExceptionHandlerTests.kt` (6 tests): Verify exception handler returns correct HTTP status and JSON structure for each exception type. Test: EntityNotFoundException→404, MethodArgumentNotValidException→400 with details, HttpMessageNotReadableException→400, AccessDeniedException→403, AuthenticationException→401, generic Exception→500.
4. `CreateWebTransactionRequestTests.kt` (3 tests): DTO defaults, copy constructor, equals/hashCode.
5. `UpdateWebTransactionRequestTests.kt` (2 tests): DTO defaults, null field handling.
6. `WebTransactionResponseTests.kt` (3 tests): DTO mapping from entity, equals/hashCode, toString.
7. `WebTransactionEntityTests.kt` (3 tests): Entity constructor defaults (e.g., created/updated timestamps, version=0), field setters update values, JPA annotations present (verified via reflection or integration test).
8. `DataSourceConfigTests.kt` (4 tests): HikariDataSource bean created with correct properties, connection pool size configured, connection URL parsed correctly, credentials set from environment variables.
9. `HealthEndpointTests.kt` (1 test): GET /health returns 200 with `{"status":"UP"}` (Spring Actuator default).

**Functional tests (14):**
10. `WebTransactionFunctionalTests.kt` (14 tests using Testcontainers + `@SpringBootTest`):
    - Create transaction (POST /transactions) → 201, verify response body
    - Get by ID (GET /transactions/{id}) → 200, verify response
    - Get by reference (GET /transactions/reference/{ref}) → 200
    - Update transaction (PUT /transactions/{id}) → 200, verify updated fields
    - Full lifecycle: create → getById → update → getById → verify changes persisted
    - Get non-existent ID → 404
    - Get non-existent reference → 404
    - Create with invalid payload (missing required field) → 400 with validation details
    - Create with invalid enum value → 400 with deserialization error
    - Update non-existent ID → 404
    - Security enabled (default profile): unauthenticated request → 401
    - Security enabled: authenticated request with correct scope → 200/201
    - Security disabled (test profile): unauthenticated request → 200/201
    - Database persistence: create transaction, restart app context (clear EntityManager cache), retrieve by ID → verify same data

JaCoCo configuration in `build.gradle.kts`:
- Apply `jacoco` plugin
- `jacocoTestReport` task: enable HTML and XML reports (for CI/IDE integration)
- `jacocoTestCoverageVerification` task: set `minimum = 0.95` for all four counters (INSTRUCTION, LINE, METHOD, CLASS). Exclude `*Application.kt`, `*Config.kt` (if pure delegation), and Kotlin data class synthetic methods.
- Bind `check` task to `jacocoTestCoverageVerification` so builds fail if coverage < 95%

Environment configuration files (created/updated):
- `src/main/resources/application-local.yml`: `security.enabled=false`, `flyway.enabled=false` (assumes local schema exists), datasource points to localhost Postgres
- `src/main/resources/application-test.yml`: `security.enabled=false`, `flyway.enabled=true`, datasource uses Testcontainers dynamic URL (overridden by `@DynamicPropertySource` in tests)
- `src/main/resources/application-dev.yml`: `security.enabled=true`, `flyway.enabled=true`, datasource from `${DB_URL}` env var, JWT issuer URI for dev
- `src/main/resources/application-staging.yml`: similar to dev, different JWT issuer
- `src/main/resources/application-prod.yml`: similar to dev/staging, prod JWT issuer, stricter actuator exposure (only `/health`)

Test utilities and base classes:
- `TestDataBuilder.kt` (optional, if needed for test data creation): Factory methods for creating valid DTO/entity instances with sensible defaults. Reduces test boilerplate.
- `AbstractFunctionalTest.kt` (base class for functional tests): Sets up `@SpringBootTest`, `@Testcontainers`, Postgres container, `@DynamicPropertySource` to inject Testcontainers JDBC URL. Subclasses extend this to reuse container across test methods (Testcontainers singleton pattern).

Package structure (all under `src/test/kotlin/com/webtransaction/microsite/`):
- `controller/WebTransactionControllerTests.kt`
- `service/WebTransactionServiceTests.kt`
- `exception/GlobalExceptionHandlerTests.kt`
- `dto/CreateWebTransactionRequestTests.kt`, `UpdateWebTransactionRequestTests.kt`, `WebTransactionResponseTests.kt`
- `entity/WebTransactionEntityTests.kt`
- `config/DataSourceConfigTests.kt`
- `health/HealthEndpointTests.kt`
- `functional/WebTransactionFunctionalTests.kt`
- `testutil/TestDataBuilder.kt` (optional)
- `testutil/AbstractFunctionalTest.kt` (optional, if Testcontainers base class needed)

Dependencies added to `build.gradle.kts`:
- `testImplementation("org.testcontainers:postgresql:1.21.4")`
- `testImplementation("org.testcontainers:junit-jupiter:1.21.4")`
- `testImplementation("io.mockk:mockk:1.13.8")` (Kotlin-friendly mocking, alternative to Mockito)
- Ensure existing: `spring-boot-starter-test`, `spring-security-test` (from WTR-5)

Test execution strategy: `./gradlew test` runs all tests. Unit tests execute first (fast), functional tests last (slow due to Testcontainers startup). JaCoCo aggregates coverage across all test types. After tests pass, `jacocoTestCoverageVerification` checks ≥95% threshold.

## Files in scope

- `build.gradle.kts` (add JaCoCo plugin, Testcontainers dependencies, coverage verification)
- `src/main/resources/application-local.yml` (new)
- `src/main/resources/application-test.yml` (new or update from WTR-5)
- `src/main/resources/application-dev.yml` (update from WTR-5)
- `src/main/resources/application-staging.yml` (update from WTR-5)
- `src/main/resources/application-prod.yml` (update from WTR-5)
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequestTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequestTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/dto/WebTransactionResponseTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/entity/WebTransactionEntityTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/config/DataSourceConfigTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/health/HealthEndpointTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/functional/WebTransactionFunctionalTests.kt` (new)

## Plan Steps

### Step 1: Configure JaCoCo plugin and Testcontainers dependencies in build.gradle.kts
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: No direct test. Verify by running `./gradlew test` and `./gradlew jacocoTestReport` successfully after all tests are written. JaCoCo report HTML generated at `build/reports/jacoco/test/html/index.html`. Coverage verification runs as part of `./gradlew check`.

### Step 2: Create environment-specific application YAML files
- Test mode: `test-after`
- Files: `src/main/resources/application-local.yml`, `application-test.yml`, `application-dev.yml`, `application-staging.yml`, `application-prod.yml`
- Test strategy: Configuration validated when Spring Boot application starts. Functional tests use test profile (security disabled, Flyway enabled). Unit tests do not load full application context, so config is not exercised by unit tests. Verify manually that each profile's properties are syntactically correct (YAML parsing succeeds).

### Step 3: Write WebTransactionController unit tests
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- Test strategy: Use `@WebMvcTest(WebTransactionController::class)` to load only the controller layer. Mock `WebTransactionService` with `@MockBean`. Use `MockMvc` to perform HTTP requests. Verify: (1) POST /transactions calls service.create(), returns 201, response body matches DTO; (2) GET /transactions/{id} calls service.getById(), returns 200; (3) GET /transactions/reference/{ref} calls service.getByReference(), returns 200; (4) PUT /transactions/{id} calls service.update(), returns 200; (5) service throws EntityNotFoundException → controller returns 404 (via GlobalExceptionHandler); (6) validation error → controller returns 400 (via GlobalExceptionHandler). Use MockK `every { ... } returns ...` and `verify { ... }` to mock and assert service calls.

### Step 4: Write WebTransactionService unit tests
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt`
- Test strategy: Plain JUnit test (no Spring Boot test slice annotation). Mock `WebTransactionRepository` using MockK. Instantiate service with mocked repository. Verify: (1) create() converts CreateRequest DTO to entity, calls repository.save(), returns ResponseDTO with generated ID; (2) getById() with existing ID calls repository.findById(), returns ResponseDTO; (3) getById() with non-existent ID throws EntityNotFoundException; (4) getByReference() with existing ref calls repository.findByReference(), returns ResponseDTO; (5) getByReference() with non-existent ref throws EntityNotFoundException; (6) update() with existing ID calls repository.findById(), updates entity fields, saves, returns ResponseDTO; (7) update() with non-existent ID throws EntityNotFoundException; (8) create() with null optional fields applies defaults (verify entity has expected default values); (9) update() with null fields in UpdateRequest does not overwrite existing entity values (partial update logic).

### Step 5: Write GlobalExceptionHandler unit tests
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt`
- Test strategy: Use `@WebMvcTest` with a test controller that throws exceptions on demand. Handler is auto-registered by Spring Boot. Use `MockMvc` to trigger exceptions and verify response status + JSON body structure. Tests: (1) EntityNotFoundException → 404, body `{"error":"<message>"}`; (2) MethodArgumentNotValidException (from @Valid) → 400, body `{"error":"Validation failed","details":{"field":"message"}}`; (3) HttpMessageNotReadableException (malformed JSON) → 400, body `{"error":"Invalid request format"}` (sanitized message); (4) AccessDeniedException → 403, body `{"error":"Forbidden"}`; (5) AuthenticationException → 401, body `{"error":"Unauthorized"}`; (6) generic Exception → 500, body `{"error":"Internal server error"}` (no stack trace leak).

### Step 6: Write DTO unit tests (CreateWebTransactionRequest, UpdateWebTransactionRequest, WebTransactionResponse)
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequestTests.kt`, `UpdateWebTransactionRequestTests.kt`, `WebTransactionResponseTests.kt`
- Test strategy: Plain JUnit tests (no Spring context). Verify: (1) CreateRequest: default values applied (e.g., if optional fields not set), copy constructor works, equals/hashCode contract; (2) UpdateRequest: null fields allowed (partial update), default behavior; (3) Response: DTO correctly maps from entity (test mapping logic if custom, or just verify fields set), equals/hashCode, toString includes all fields (useful for debugging).

### Step 7: Write WebTransactionEntity unit tests
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/entity/WebTransactionEntityTests.kt`
- Test strategy: Plain JUnit tests. Verify: (1) Entity constructor sets default values (created/updated timestamps via JPA `@PrePersist`/`@PreUpdate`, version=0); (2) Field setters update entity state; (3) JPA annotations present (use reflection to check `@Entity`, `@Table`, `@Id`, `@Version` annotations exist — or defer annotation verification to functional test where Hibernate validates schema).

### Step 8: Write DataSourceConfig unit tests
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/config/DataSourceConfigTests.kt`
- Test strategy: Use `@SpringBootTest` with minimal context (only config classes). Inject `DataSource` bean. Verify: (1) Bean is HikariDataSource instance; (2) Connection pool size configured (via HikariCP properties); (3) JDBC URL matches expected format (from application.yml or environment variable); (4) Connection succeeds (call `dataSource.connection.isValid(1)`). Use `@TestPropertySource` to override properties if needed.

### Step 9: Write Health endpoint unit test
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/health/HealthEndpointTests.kt`
- Test strategy: Use `@SpringBootTest` with `MOCK` web environment and `MockMvc`. Test: GET /actuator/health returns 200, JSON body contains `{"status":"UP"}` (Spring Actuator default). No authentication required (per WTR-5 security config, actuator endpoints are public).

### Step 10: Write functional integration tests with Testcontainers
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/functional/WebTransactionFunctionalTests.kt`
- Test strategy: Use `@SpringBootTest(webEnvironment = RANDOM_PORT)` with `@Testcontainers` and `@Container` for PostgreSQL 15.4. Use `TestRestTemplate` or `WebTestClient` for HTTP calls. Use `@DynamicPropertySource` to inject Testcontainers JDBC URL into Spring context. Flyway runs migrations on startup. Tests: (1) POST /transactions (create) → 201, verify response DTO; (2) GET /transactions/{id} → 200, verify data; (3) GET /transactions/reference/{ref} → 200; (4) PUT /transactions/{id} → 200, verify update; (5) Full lifecycle: create → read → update → read → assert updated; (6) GET non-existent ID → 404; (7) GET non-existent ref → 404; (8) POST invalid payload → 400; (9) POST invalid enum → 400; (10) PUT non-existent ID → 404; (11) Security enabled (use `@ActiveProfiles("dev")` to enable security): unauthenticated GET → 401; (12) Security enabled: authenticated GET with JWT → 200 (mock JWT via Spring Security test utilities); (13) Security disabled (use `@ActiveProfiles("test")`): unauthenticated GET → 200; (14) Persistence test: create entity, clear EntityManager cache (or restart context if using `@DirtiesContext`), query by ID → verify same data.

### Step 11: Run full test suite and verify JaCoCo coverage ≥95%
- Test mode: `test-after`
- Files: All test files from Steps 3-10
- Test strategy: Run `./gradlew clean test jacocoTestReport jacocoTestCoverageVerification`. Verify: (1) All 51 tests pass (37 unit + 14 functional); (2) JaCoCo HTML report at `build/reports/jacoco/test/html/index.html` shows ≥95% coverage on instruction, line, method, and class counters; (3) Coverage verification task passes (does not fail build). If coverage < 95%, identify uncovered lines via HTML report, add tests to cover missing branches/paths. Iterate until threshold met.

## Risks

- **Testcontainers Docker dependency**: Functional tests require Docker daemon running on test executor (developer machine, CI agent). If Docker unavailable, tests fail with container startup error. Mitigation: Document Docker prerequisite in README. CI pipeline must have Docker service enabled. Use Testcontainers Cloud (if available) or embedded database (H2) as fallback — but spec requires Postgres 15.4, so fallback is out-of-scope.
- **Testcontainers startup time**: Postgres container takes ~5-10 seconds to start, slowing functional test suite. 14 functional tests may take 30+ seconds total. Mitigation: Use Testcontainers singleton pattern (reuse container across all functional tests in same JVM). `@Testcontainers` with `@Container` at class level starts container once per test class.
- **Coverage threshold too aggressive**: 95% coverage on all four metrics is strict. Some code may be difficult to test (e.g., private utility methods, exception handling in framework code). Risk: Threshold not achievable without refactoring production code (violates spec out-of-scope constraint: no code changes to improve testability). Mitigation: JaCoCo exclusions for main class, config classes (if pure delegation), and Kotlin data class synthetic methods. If still < 95%, document rationale and propose threshold adjustment (e.g., 93% realistic baseline).
- **Flaky functional tests**: Testcontainers, database state, and timing can cause intermittent failures. Mitigation: Use `@DirtiesContext` or `@Transactional` with rollback to ensure test isolation. Avoid hardcoded IDs (rely on generated IDs from database). Use `Awaitility` or polling for async operations if needed (though this service appears synchronous).
- **Security tests conflict with existing WTR-5 tests**: WTR-5 already has `SecurityConfigTests`, `WebTransactionControllerSecurityTests`. This plan adds functional security tests (enabled/disabled toggle). Risk: Duplicate test coverage or conflicting assumptions. Mitigation: Review WTR-5 tests before writing Step 10; ensure functional tests complement (not duplicate) existing security unit tests.
- **JaCoCo excludes too much code**: If exclusions (main class, config) are too broad, actual coverage may be lower than reported. Mitigation: Be surgical with exclusions — only exclude classes that are framework boilerplate or untestable. Verify exclusion patterns in `jacocoTestCoverageVerification` rule match intended files.

## Out-of-Plan (deferred)

- **Production code changes**: Spec explicitly states "tests must work with the existing service design." No refactoring for testability (e.g., extracting interfaces, adding @VisibleForTesting methods). If existing code is untestable, this is a blocker — escalate rather than modify production code.
- **Mutation testing**: Spec non-goal. Tools like PIT mutation testing could verify test quality (do tests catch injected bugs?), but this is deferred.
- **Test execution time optimization**: No parallelization (e.g., JUnit parallel execution, Gradle parallel test workers). Tests run sequentially. If test suite exceeds acceptable duration (e.g., >2 minutes), optimization is deferred to future ticket.
- **Custom JaCoCo reports**: Default HTML/XML reports are sufficient. Custom report formats (e.g., CSV, integration with SonarQube) are out-of-scope.
- **CI/CD integration**: Spec non-goal. Assumes developer runs `./gradlew test` locally. CI pipeline configuration (GitHub Actions, Jenkins) to run tests and publish JaCoCo reports is deferred.
- **Test data builders**: Optional utility (`TestDataBuilder.kt`) is in-scope only if it significantly reduces boilerplate. If tests are readable without it, defer creation.
- **Testcontainers alternatives**: Spec requires Testcontainers (Postgres 15.4). Alternatives like H2 in-memory, embedded Postgres (pg_embed), or db-rider are out-of-scope.
- **Performance assertions**: Functional tests verify correctness, not performance (e.g., response time < 100ms). Performance testing is spec non-goal.
- **Additional test slices**: Only `@WebMvcTest`, `@DataJpaTest` (if needed), and `@SpringBootTest` are used. Other slices like `@JsonTest`, `@RestClientTest` are deferred unless needed to reach coverage threshold.
- **Integration with WTR-7+ work**: This plan is self-contained for WTR-6. If future tickets add features, tests will need updating — that is deferred to those tickets.
- **Test code quality rules**: No checkstyle/ktlint rules enforced on test code. Test code conventions (naming, structure) follow Spring Boot defaults but are not formally enforced.
