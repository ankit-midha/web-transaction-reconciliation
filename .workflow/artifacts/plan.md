---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-6
job_id: wtr-6-jacmm2
---

# WTR-6 — Implementation plan

## Approach

The codebase already has a substantial test suite in place with 40 @Test methods across 6 test classes. However, the spec requires 51 tests (37 unit + 14 functional) to achieve 95% JaCoCo coverage across all four metrics. Analysis shows the current suite is missing 11 tests and lacks environment-specific configuration files for dev, staging, and prod profiles.

The implementation will follow a test-after approach since the production code is already complete and stable. The primary tasks are: (1) add missing unit tests for DTOs, Entity, Config, and ExceptionHandler components that aren't fully covered; (2) fix compilation issues in existing security tests; (3) create missing environment-specific YAML config files; (4) run the full test suite and verify 95% coverage is achieved.

The test gap analysis reveals: Controller tests (20 current, need 6 unit), Service tests (9 complete), Repository/Functional tests (9 current, part of 14 functional), Security/Actuator tests (4 functional), Entity/DTO/Config tests (0 current, need 15 total), ExceptionHandler tests (0 dedicated, need 6). The missing 11 tests break down as: 8 DTO tests, 3 Entity tests, 4 Config tests, 6 ExceptionHandler tests (21 needed minus already-covered via controller tests).

## Files in scope

### Test files to create:
- `src/test/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequestTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequestTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/dto/WebTransactionResponseTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/domain/WebTransactionTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/controller/GlobalExceptionHandlerTests.kt`

### Test files to modify:
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt` (fix compilation errors)

### Configuration files to create:
- `src/main/resources/application-dev.yml`
- `src/main/resources/application-staging.yml`
- `src/main/resources/application-prod.yml`

### Build configuration to verify:
- `build.gradle.kts` (verify JaCoCo configuration is correct)

## Plan Steps

### Step 1: Fix existing security test compilation errors
- Test mode: `test-after`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt`
- Test strategy: Fix type mismatches in WebTransaction instantiation (originalPayload and reconcilePayload expect Map<String,Any?> but tests pass String, field names created/updated vs createdAt/updatedAt, externalReferenceType expects enum not String). Run tests to verify all 8 security tests pass.

### Step 2: Add DTO unit tests
- Test mode: `test-after`
- Files: 
  - `src/test/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequestTests.kt`
  - `src/test/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequestTests.kt`
  - `src/test/kotlin/com/webtransaction/microsite/dto/WebTransactionResponseTests.kt`
- Test strategy: Add 8 tests total covering data class behavior (equals/hashCode contract, copy constructor with all fields, copy with partial fields, toString format, null handling for optional fields, companion factory method for Response DTO). These tests verify DTO contracts remain stable.

### Step 3: Add Entity unit tests
- Test mode: `test-after`
- Files: `src/test/kotlin/com/webtransaction/microsite/domain/WebTransactionTests.kt`
- Test strategy: Add 3 tests covering entity construction with default values (id, created, updated all default to null), field mutability (mutable fields can be updated, immutable cannot), and data class equality excluding audit fields. These tests verify JPA entity contracts.

### Step 4: Add ExceptionHandler unit tests
- Test mode: `test-after`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/GlobalExceptionHandlerTests.kt`
- Test strategy: Add 6 tests covering each @ExceptionHandler method in isolation: EntityNotFoundException→404, MethodArgumentNotValidException→400 with field details, HttpMessageNotReadableException→400 with enum vs malformed detection, AccessDeniedException→403, generic Exception→500. Use direct method invocation rather than full Spring context.

### Step 5: Create environment-specific configuration files
- Test mode: `test-after`
- Files:
  - `src/main/resources/application-dev.yml`
  - `src/main/resources/application-staging.yml`
  - `src/main/resources/application-prod.yml`
- Test strategy: Each file references environment variables for DB credentials (DB_URL, DB_USERNAME, DB_PASSWORD), sets security.enabled=true, configures Flyway migrations appropriately (enabled=true for dev/staging, disabled for prod assumes pre-run migrations), and exposes actuator endpoints per environment (dev: all, staging: health+info+metrics, prod: health only). Verify by loading each profile in ApplicationTests with @ActiveProfiles.

### Step 6: Run full test suite and verify coverage
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: Execute `./gradlew clean test jacocoTestReport jacocoTestCoverageVerification` and verify (1) all 51 tests pass, (2) JaCoCo HTML report shows ≥95% for INSTRUCTION, LINE, METHOD, CLASS counters. If coverage is below 95%, identify uncovered code paths and add targeted tests or adjust JaCoCo exclusions for framework code (Application.kt, SecurityConfiguration conditional bean).

## Risks

1. **Coverage exclusions needed**: The spec requires 95% across all code but doesn't specify exclusions. Application.kt main() method and SecurityConfiguration conditional beans may not be testable without integration tests. Mitigation: Use JaCoCo exclusions for these framework-level classes if coverage verification fails.

2. **Enum/DTO test count ambiguity**: The spec breakdown lists "DTOs: 8 tests" but there are 3 DTO classes. It's unclear if this means 8 total or 8 per class. Implementation assumes 8 total distributed across the 3 DTOs (3+2+3 split). Mitigation: If coverage is insufficient, add more DTO tests.

3. **Config tests without HikariCP**: The spec mentions "Config: 4 tests covering HikariDataSource creation" but the current build.gradle.kts doesn't show HikariCP explicit config—it's autoconfigured by Spring Boot. Implementation will test DataSource bean existence and connection properties rather than direct HikariDataSource creation. Mitigation: Verify with JaCoCo if autoconfiguration classes need coverage.

4. **Security test environment**: WebTransactionControllerSecurityTests uses @TestPropertySource(security.enabled=false) but tests OAuth2 scopes, which seems contradictory. Implementation will verify the test intent and potentially split into two test classes (one for security disabled, one for enabled with mock JWT). Mitigation: Check if tests pass after fixing type errors.

5. **Functional vs unit test boundary**: The spec divides tests into 37 unit + 14 functional but existing tests don't clearly map to this split. Repository tests use @DataJpaTest (functional), Controller tests use @WebMvcTest (unit), Security tests use @SpringBootTest (functional). Current count: ~26 unit (Controller + Service), ~14 functional (Repository + Security + Actuator + ApplicationTests). Mitigation: Ensure the new tests bring the total to 51 regardless of unit/functional classification.

## Out-of-Plan (deferred)

1. **Testcontainers integration**: The spec mentions Testcontainers (Postgres 15.4) but the current test suite uses H2 in-memory database. Adding Testcontainers would require modifying existing repository tests and adding the dependency, which goes beyond "tests must work with existing service design." Deferred unless coverage cannot be achieved with H2.

2. **Flyway migration verification**: The spec mentions Flyway toggles per environment but no migration files exist in the repo (no `src/main/resources/db/migration` directory). Creating migration files is out of scope for a test-focused ticket. The config files will include Flyway properties but actual migrations are deferred.

3. **DataSource/HikariCP config class**: The spec expects "Config: 4 tests covering HikariDataSource creation and connection string handling" but no custom configuration class exists—Spring Boot autoconfigures HikariCP. Creating a custom config class purely to test it is code-to-test-the-test. Deferred; will test what exists (SecurityConfiguration, if coverage demands it) or skip this category.

4. **Additional environment configs**: The spec lists dev, staging, prod config files but doesn't specify test coverage requirements for them. They'll be created as config-only files without dedicated tests. Their correctness will be implicitly verified if ApplicationTests can load each profile without errors.

5. **CI/CD integration**: Explicitly out-of-scope per the spec. The Gradle tasks will be runnable locally but no GitHub Actions workflow or pipeline config will be added.
