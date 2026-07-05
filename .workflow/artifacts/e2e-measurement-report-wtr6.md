# WTR-6 E2E Measurement Report

**Generated:** 2026-07-05  
**Jira Key:** WTR-6  
**Job ID:** wtr-6-dkuzkh  
**Branch:** WTR-6-impl  

---

## Executive Summary

This report documents the comprehensive E2E measurement suite for WTR-6 (Comprehensive test coverage ≥95% JaCoCo for Web Transaction Store service). The test suite validates all acceptance criteria and implementation requirements specified in the WTR-6 plan, including 51 tests (37 unit tests + 14 functional tests) across controller, service, exception handler, DTO, entity, configuration, and end-to-end integration testing.

**Baseline Status (Pre-Implementation):**
- **Total Tests:** ~80 verification points
- **Passed:** 2-3 (Git configuration tests)
- **Failed:** ~77 (Implementation not yet complete)
- **Skipped:** 0

**Expected Post-Implementation Status:**
- **Total Tests:** 51 automated tests + 80 structural verification points
- **Expected Passed:** All tests pass, JaCoCo coverage ≥95% across instruction, line, method, class
- **Build Status:** `./gradlew test jacocoTestReport jacocoTestCoverageVerification` exits successfully

---

## Test Coverage Overview

The E2E measurement suite covers **20 distinct test sections** across the following domains:

### 1. Build Configuration - JaCoCo Plugin (8 tests)
Validates Gradle configuration for JaCoCo test coverage reporting:
- ✓ `build.gradle.kts` exists
- ✓ JaCoCo plugin applied: `id("jacoco")`
- ✓ `jacocoTestReport` task configured
- ✓ HTML report enabled (`html.required.set(true)`)
- ✓ XML report enabled (`xml.required.set(true)`)
- ✓ `jacocoTestCoverageVerification` task configured
- ✓ 95% coverage threshold configured across all counters
- ✓ All four coverage counters present: `INSTRUCTION`, `LINE`, `METHOD`, `CLASS`

**Coverage Details:**
- HTML report location: `build/reports/jacoco/test/html/index.html`
- XML report location: `build/reports/jacoco/test/jacocoTestReport.xml`
- Verification enforces minimum 0.95 (95%) on each counter
- Build fails if coverage drops below threshold

### 2. Testcontainers Dependencies (6 tests)
Validates dependencies for functional integration testing:
- ✓ `testcontainers:postgresql:1.21.4` dependency present
- ✓ `testcontainers:junit-jupiter:1.21.4` dependency present
- ✓ `io.mockk:mockk:1.13.8` dependency present (or Mockito as alternative)

**Why these versions:**
- Testcontainers 1.21.4: Latest stable compatible with Spring Boot 3.x and Postgres 15.4
- MockK 1.13.8: Kotlin-native mocking library for better DSL and coroutines support

### 3. Environment-Specific Application YAML Files (25 tests)
Validates configuration files for all 5 deployment environments:

**Profiles tested:** `local`, `test`, `dev`, `staging`, `prod`

For each profile (5 × 5 = 25 checks):
- ✓ `application-{profile}.yml` file exists
- ✓ Datasource configuration present (`spring.datasource`)
- ✓ `DB_URL` environment variable placeholder configured
- ✓ Flyway configuration present (`spring.flyway.enabled`)
- ✓ Security configuration present (`security.enabled`)

**Environment Variable Mapping:**
- `DB_URL`: JDBC connection string (e.g., `jdbc:postgresql://localhost:5432/webtransaction_local`)
- `DB_USERNAME`: Database user (default: `postgres`)
- `DB_PASSWORD`: Database password (default: `password`)
- `SECURITY_ENABLED`: Toggle for Spring Security (default: `false` for test/local)

**Flyway Toggle Pattern:**
- `local`: `enabled: true` (apply migrations on startup)
- `test`: `enabled: true` (Testcontainers applies migrations automatically)
- `dev`: `enabled: true` (development database)
- `staging`: `enabled: false` (migrations applied via CI/CD pipeline)
- `prod`: `enabled: false` (migrations applied via controlled deployment process)

### 4. Controller Unit Tests - WebTransactionControllerTests.kt (8+ tests)
Validates controller layer with `@WebMvcTest` (MockMvc, no full Spring context):

**Tests (minimum 6 per plan):**
1. ✓ POST `/v1/webtransaction` creates transaction → returns 201 with response body
2. ✓ GET `/v1/webtransaction/{id}` delegates to service → returns 200
3. ✓ GET `/v1/webtransaction/reference/{reference}` delegates to service → returns 200
4. ✓ PUT `/v1/webtransaction/reference/{reference}` delegates to service → returns 200
5. ✓ GET by ID when service throws `EntityNotFoundException` → returns 404
6. ✓ POST with invalid request body triggers Bean Validation → returns 400 with field errors

**Verification Points:**
- ✓ `@WebMvcTest(WebTransactionController::class)` annotation present
- ✓ `@MockBean` for `WebTransactionService` present
- ✓ Controller methods are thin (no business logic, only HTTP marshalling)
- ✓ Status codes match REST conventions (201 Created, 200 OK, 404 Not Found, 400 Bad Request)

### 5. Service Unit Tests - WebTransactionServiceTests.kt (10+ tests)
Validates service layer business logic with mocked repository:

**Tests (minimum 9 per plan):**
1. ✓ `createTransaction` maps DTO → entity, saves via repository, returns response DTO
2. ✓ `getTransactionById` found case → returns DTO
3. ✓ `getTransactionById` not found → throws `EntityNotFoundException`
4. ✓ `getTransactionByReference` found case → returns DTO
5. ✓ `getTransactionByReference` not found → throws `EntityNotFoundException`
6. ✓ `updateTransactionByReference` found case → updates `reconcileStatus` + `externalReferenceNumber`, returns DTO
7. ✓ `updateTransactionByReference` not found → throws `EntityNotFoundException`
8. ✓ JSONB `originalPayload` preserves nested map structure (3 levels deep)
9. ✓ JSONB `reconcilePayload` handles null values correctly

**Verification Points:**
- ✓ `@MockBean` or `@Mock` for `WebTransactionRepository` present
- ✓ Service layer contains business logic (validation, mapping, error handling)
- ✓ JSONB fields serialize/deserialize correctly (no data loss)

### 6. GlobalExceptionHandler Unit Tests (7+ tests)
Validates exception handling with correct HTTP status codes and response structure:

**Tests (minimum 6 per plan):**
1. ✓ `EntityNotFoundException` → returns 404 with `{"error": "Entity not found"}`
2. ✓ `MethodArgumentNotValidException` → returns 400 with `{"error": "...", "details": {"field": "message"}}`
3. ✓ Generic `Exception` → returns 500 with `{"error": "Internal server error"}`
4. ✓ `OptimisticLockException` → returns 409 Conflict
5. ✓ Invalid enum deserialization error → returns 400
6. ✓ Empty request body (null payload) → returns 400

**Verification Points:**
- ✓ Response entity status codes match HTTP conventions
- ✓ Response body structure includes error message and optional details
- ✓ No exception stack traces leaked to client (production safety)

### 7. DTO Unit Tests (11+ tests across 3 files)
Validates Data Transfer Objects (request/response POJOs):

**CreateWebTransactionRequestTests.kt (3 tests):**
1. ✓ Default constructor initializes all fields
2. ✓ Copy constructor creates independent copy (mutation does not affect original)
3. ✓ `equals` / `hashCode` work correctly for data class semantics

**UpdateWebTransactionRequestTests.kt (3 tests):**
4. ✓ Default constructor initializes all fields
5. ✓ Copy constructor creates independent copy
6. ✓ `equals` / `hashCode` work correctly

**WebTransactionResponseTests.kt (2 tests):**
7. ✓ `toString` includes all fields (debugging)
8. ✓ Timestamp fields serialize to ISO-8601 format (e.g., `2026-07-05T12:34:56.789Z`)

**Verification Points:**
- ✓ DTOs use Kotlin `data class` for automatic `equals`, `hashCode`, `copy`
- ✓ Jackson `ObjectMapper` serializes timestamps correctly
- ✓ No business logic in DTOs (pure data containers)

### 8. Entity Unit Tests - WebTransactionEntityTests.kt (5+ tests)
Validates JPA entity structure and annotations:

**Tests (minimum 3 per plan):**
1. ✓ No-arg constructor initializes `id` to null, `version` to 0, timestamps to null (JPA defaults)
2. ✓ All-args constructor sets fields correctly
3. ✓ Field setters update values (verify `copy` method for data class)

**JPA Annotation Verification (reflection-based):**
- ✓ `@Entity` annotation present
- ✓ `@Table(name = "reconciliation_transaction")` annotation present
- ✓ `@Id` annotation on primary key field
- ✓ `@Version` annotation for optimistic locking (from WTR-3)

**Verification Points:**
- ✓ Entity is regular `class`, NOT `data class` (JPA best practice — avoids issues with proxies)
- ✓ All required properties present (11 properties total from WTR-3 spec)

### 9. DataSourceConfig Unit Tests (5+ tests)
Validates database connection configuration with different scenarios:

**Tests (minimum 4 per plan):**
1. ✓ Postgres URL with host/port/database creates `HikariDataSource` with correct JDBC URL
2. ✓ Connection pool properties applied from YAML (`max-pool-size`, `connection-timeout`)
3. ✓ Invalid DB URL throws `DataSourceConfigurationException` during context load
4. ✓ Missing DB credentials throws exception

**Verification Points:**
- ✓ Uses `@SpringBootTest` with overridden properties for testing
- ✓ `HikariDataSource` bean is created and injectable
- ✓ Environment variables resolve correctly (e.g., `${DB_URL:default}`)

### 10. Health Endpoint Unit Test (2+ tests)
Validates Spring Boot Actuator health check:

**Test (1 per plan):**
1. ✓ GET `/actuator/health` returns 200 with `{"status": "UP"}` body

**Verification Points:**
- ✓ Uses `@WebMvcTest` to test actuator endpoint
- ✓ No custom health indicator needed (Spring Boot default health check suffices)
- ✓ Health endpoint exposed via `management.endpoints.web.exposure.include=health`

### 11. Functional Integration Tests - WebTransactionFunctionalTests.kt (16+ tests)
Validates full-stack behavior with real Postgres database via Testcontainers:

**Tests (minimum 14 per plan):**

**Happy Path (5 tests):**
1. ✓ POST create transaction
2. ✓ GET by ID returns created record
3. ✓ GET by reference returns same record
4. ✓ PUT update by reference changes `reconcileStatus`
5. ✓ GET by ID shows updated values

**Validation Errors (3 tests):**
6. ✓ POST with missing required field → returns 400
7. ✓ POST with `reference` > 100 chars → returns 400
8. ✓ POST with invalid enum value → returns 400

**Not Found Cases (3 tests):**
9. ✓ GET by non-existent ID → returns 404
10. ✓ GET by non-existent reference → returns 404
11. ✓ PUT to non-existent reference → returns 404

**JSONB Round-Trip (1 test):**
12. ✓ Deeply nested JSONB structure (3 levels) round-trips correctly

**Security Toggle (2 tests):**
13. ✓ Security disabled mode: unauthenticated request succeeds
14. ✓ Security enabled mode: unauthenticated request returns 401 Unauthorized

**Verification Points:**
- ✓ Uses `@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)`
- ✓ Uses `@Testcontainers` and `@Container` for `PostgreSQLContainer("postgres:15.4")`
- ✓ Flyway migrations apply automatically on Testcontainers startup
- ✓ Tests verify HTTP status codes, response bodies, and database state

**Performance Consideration:**
- Testcontainers startup adds ~5-10 seconds per test class
- Mitigation: Use singleton container pattern (one container shared across all functional tests)
- Alternative: `@ClassRule` static field + `@Testcontainers(parallel = false)`

### 12. Package Structure Verification (10 tests)
Validates proper package organization per Spring Boot conventions:

**Production Packages:**
- ✓ `src/main/kotlin/com/webtransaction/microsite/controller` exists
- ✓ `src/main/kotlin/com/webtransaction/microsite/service` exists
- ✓ `src/main/kotlin/com/webtransaction/microsite/dto` exists
- ✓ `src/main/kotlin/com/webtransaction/microsite/entity` exists
- ✓ `src/main/kotlin/com/webtransaction/microsite/exception` exists
- ✓ `src/main/kotlin/com/webtransaction/microsite/config` exists

**Test Packages (mirror production structure):**
- ✓ `src/test/kotlin/com/webtransaction/microsite/controller` exists
- ✓ `src/test/kotlin/com/webtransaction/microsite/service` exists
- ✓ `src/test/kotlin/com/webtransaction/microsite/dto` exists
- ✓ `src/test/kotlin/com/webtransaction/microsite/functional` exists

### 13. Build and Test Execution (2 tests)
Validates Gradle build and test execution:

- ✓ Gradle wrapper (`./gradlew`) present
- ✓ Gradle test task can be dry-run (`./gradlew test --dry-run`)

**Full Build Command:**
```bash
./gradlew clean test jacocoTestReport jacocoTestCoverageVerification
```

**Expected Output:**
- All 51 tests pass
- JaCoCo HTML report generated: `build/reports/jacoco/test/html/index.html`
- JaCoCo XML report generated: `build/reports/jacoco/test/jacocoTestReport.xml`
- Coverage verification passes (≥95% across all counters)

### 14. JaCoCo Report Generation (2 tests)
Validates JaCoCo tasks are available:

- ✓ `jacocoTestReport` task available (`./gradlew tasks --all` lists it)
- ✓ `jacocoTestCoverageVerification` task available

**Report Interpretation:**
- **HTML Report:** Open `build/reports/jacoco/test/html/index.html` in browser
  - Green highlighting: covered lines
  - Red highlighting: uncovered lines
  - Yellow highlighting: partially covered branches
- **XML Report:** For CI integration (e.g., GitHub Actions, Jenkins)

**Coverage Threshold:**
- **Instruction Coverage:** ≥95% (bytecode instructions executed)
- **Line Coverage:** ≥95% (source lines executed)
- **Method Coverage:** ≥95% (methods invoked)
- **Class Coverage:** ≥95% (classes loaded)

### 15. Test Count Verification (2 tests)
Validates expected number of tests (51 per plan):

- ✓ Count `@Test` annotations in all test files
- ✓ Verify count ≥51 (37 unit tests + 14 functional tests)

**Breakdown:**
- Controller: 6 tests
- Service: 9 tests
- GlobalExceptionHandler: 6 tests
- DTOs: 8 tests (3 CreateRequest + 3 UpdateRequest + 2 Response)
- Entity: 3 tests
- DataSourceConfig: 4 tests
- Health: 1 test
- Functional: 14 tests
- **Total:** 51 tests

### 16. Acceptance Criteria Validation (10 tests)
Systematic validation of all acceptance criteria from the spec:

1. **AC1:** JaCoCo plugin configured with 95% threshold ✓
2. **AC2:** Testcontainers 1.21.4 dependencies present ✓
3. **AC3:** All 5 environment-specific YAML files present ✓
4. **AC4:** Unit tests for controller (6 tests) ✓
5. **AC5:** Unit tests for service (9 tests) ✓
6. **AC6:** GlobalExceptionHandler tests (6 tests) ✓
7. **AC7:** DTO unit tests (8 tests across 3 files) ✓
8. **AC8:** Entity unit tests (3 tests) ✓
9. **AC9:** DataSourceConfig tests (4 tests) ✓
10. **AC10:** Functional integration tests with Testcontainers (14 tests) ✓

### 17. Plan Step Completion Verification (11 tests)
Validates all 11 implementation steps from the plan:

1. **Step 1:** Gradle build configured with JaCoCo and Testcontainers ✓
2. **Step 2:** Environment-specific application YAML files created (5 files) ✓
3. **Step 3:** WebTransactionController unit tests written (6 tests) ✓
4. **Step 4:** WebTransactionService unit tests written (9 tests) ✓
5. **Step 5:** GlobalExceptionHandler unit tests written (6 tests) ✓
6. **Step 6:** DTO unit tests written (8 tests across 3 files) ✓
7. **Step 7:** WebTransactionEntity unit tests written (3 tests) ✓
8. **Step 8:** DataSourceConfig unit tests written (4 tests) ✓
9. **Step 9:** Health endpoint unit test written (1 test) ✓
10. **Step 10:** Functional integration tests written (14 tests) ✓
11. **Step 11:** JaCoCo coverage verification task configured ✓

### 18. Code Quality and Conventions (4 tests)
Validates Kotlin best practices and naming conventions:

- ✓ Kotlin source files present (`.kt` extension)
- ✓ Kotlin test files present (`.kt` extension)
- ✓ Test files follow naming convention (`*Tests.kt`)
- ✓ Package structure aligns with Spring Boot conventions

**Best Practices Checked:**
- Regular `class` for JPA entities (not `data class`)
- `data class` for DTOs (automatic `equals`, `hashCode`, `copy`)
- MockK DSL for Kotlin-native mocking syntax
- Bean Validation annotations on DTOs (`@NotNull`, `@Size`, etc.)

### 19. Git Branch Verification (2 tests)
Validates working on correct branch:

- ✓ On WTR-6 related branch (e.g., `WTR-6-feat/comprehensive-test-coverage`)
- ✓ WTR-6 related commits exist in git history

**Expected Branch Name Format:**
```
WTR-6-<type>/<short-kebab-summary>
```
Example: `WTR-6-test/comprehensive-test-coverage`

### 20. Integration with WTR-3 and WTR-4 Components (5 tests)
Validates dependencies on prior tickets are present:

**WTR-3 Components (Database schema + JPA entity + repository):**
- ✓ Entity present: `ReconciliationTransaction.kt` or `WebTransactionEntity.kt`
- ✓ Repository present: `ReconciliationTransactionRepository.kt` or `WebTransactionRepository.kt`

**WTR-4 Components (REST API endpoints + DTOs + service layer):**
- ✓ Controller present: `WebTransactionController.kt`
- ✓ Service present: `WebTransactionService.kt`
- ✓ DTOs present: `CreateWebTransactionRequest.kt`, etc.

**Note:** WTR-6 tests assume WTR-3 and WTR-4 production code exists. If missing, functional tests will fail during Testcontainers startup or service layer instantiation.

---

## Test Execution Details

### Command
```bash
./test-e2e-wtr6.sh
```

### Expected Output (Pre-Implementation)
```
==========================================
WTR-6 E2E Measurement Test
==========================================

-------------------------------------------
Testing: Build Configuration - JaCoCo Plugin
-------------------------------------------
✗ FAIL: JaCoCo plugin not applied
✗ FAIL: jacocoTestReport task not configured
...

-------------------------------------------
Test Summary
-------------------------------------------
PASSED: 2-3
FAILED: ~77
TOTAL:  ~80

✗ Some tests failed. See details above.
```

### Expected Output (Post-Implementation)
```
==========================================
WTR-6 E2E Measurement Test
==========================================

-------------------------------------------
Testing: Build Configuration - JaCoCo Plugin
-------------------------------------------
✓ PASS: build.gradle.kts exists
✓ PASS: JaCoCo plugin applied
✓ PASS: jacocoTestReport task configured
...

-------------------------------------------
Test Summary
-------------------------------------------
PASSED: ~80
FAILED: 0
TOTAL:  ~80

✓ All tests passed!
```

### Full Build Verification
After E2E measurement passes, run full build to verify coverage:

```bash
./gradlew clean test jacocoTestReport jacocoTestCoverageVerification
```

**Success Criteria:**
1. All 51 tests pass (`BUILD SUCCESSFUL`)
2. JaCoCo HTML report shows ≥95% coverage: `open build/reports/jacoco/test/html/index.html`
3. Coverage verification task passes (no threshold violations)

**If Coverage Below 95%:**
1. Open HTML report and identify red/yellow highlighted lines
2. Add missing test cases to relevant test files (Steps 3-10 from plan)
3. Rerun `./gradlew test jacocoTestReport`
4. Iterate until threshold met

**Coverage Exclusions:**
- Main application class: `WebTransactionMicrositeApplication.kt` (excluded via JaCoCo filter)
- Generated code: Excluded automatically by JaCoCo
- Third-party libraries: Not included in coverage calculation

---

## Risk Coverage Analysis

### Risk 1: Testcontainers Performance
**Mitigation Validated:**
- E2E measurement checks for singleton container pattern (`@Container` static field)
- Functional tests use `@ClassRule` or `@TestInstance(PER_CLASS)` to share container
- Expected startup time: ~5-10 seconds for entire functional test suite (not per test)

**Fallback:**
- If still slow, separate functional tests into `functionalTest` Gradle task
- Run unit tests (fast) frequently, functional tests (slow) on CI only

### Risk 2: Coverage Threshold Too Strict
**Mitigation Validated:**
- E2E measurement verifies JaCoCo exclusion rules exist
- Main application class excluded: `*.WebTransactionMicrositeApplication`
- Unreachable branches (defensive null checks, enum exhaustiveness) identified via HTML report

**If 95% Unattainable:**
- Step 11 of plan includes iteration loop: identify uncovered lines → add tests → rerun
- Last resort: Add JaCoCo exclusion for specific untestable code (document reason)

### Risk 3: Security Toggle Behavior Ambiguity
**Mitigation Validated:**
- E2E measurement checks for `security.enabled` property in YAML files
- Functional test 14 verifies 401 Unauthorized when `security.enabled=true`

**If Spring Security Not Configured:**
- Test 14 marked as `@Disabled` (documented in test code)
- Flagged as out-of-plan issue (requires separate ticket for security implementation)

### Risk 4: Flyway Migration Dependency
**Mitigation Validated:**
- E2E measurement checks for `src/main/resources/db/migration/` directory
- Functional tests depend on WTR-3 migrations (V1-V4) being present
- Testcontainers applies migrations automatically via `spring.flyway.enabled=true`

**If Migrations Missing:**
- Functional tests fail during Testcontainers startup with `FlywayException`
- Escalate as dependency blocker (not solvable within WTR-6 scope)

### Risk 5: MockK vs Mockito Syntax
**Mitigation Validated:**
- E2E measurement checks for MockK dependency in `build.gradle.kts`
- Unit tests (Steps 3-5) establish MockK patterns: `every { ... } returns ...`

**If Team Prefers Mockito:**
- Switch dependency in Step 1: `mockito-kotlin` instead of `mockk`
- Adjust test syntax: `when(...).thenReturn(...)` instead of `every { ... } returns ...`

### Risk 6: Environment YAML Property Resolution
**Mitigation Validated:**
- E2E measurement verifies each YAML file has `${DB_URL:default}` syntax
- `application-test.yml` uses Testcontainers JDBC URL: `jdbc:tc:postgresql:15.4:///webtransaction`
- No manual env vars needed in CI (Testcontainers auto-starts container)

**For Non-Test Profiles:**
- Local/dev: Set env vars manually (`.env` file or IDE run configuration)
- Staging/prod: CI/CD pipeline injects secrets via Kubernetes ConfigMap or AWS Secrets Manager

---

## Coverage Heatmap (Expected Post-Implementation)

| Component                  | Instruction | Line | Method | Class |
|----------------------------|-------------|------|--------|-------|
| Controller                 | 98%         | 98%  | 100%   | 100%  |
| Service                    | 97%         | 97%  | 100%   | 100%  |
| GlobalExceptionHandler     | 96%         | 96%  | 100%   | 100%  |
| DTOs                       | 95%         | 95%  | 95%    | 100%  |
| Entity                     | 95%         | 95%  | 90%    | 100%  |
| Config (DataSourceConfig)  | 96%         | 96%  | 100%   | 100%  |
| **Overall**                | **≥95%**    | **≥95%** | **≥95%** | **≥95%** |

**Why Some Components Exceed 95%:**
- Controller/Service: Well-structured, minimal branches, high testability
- GlobalExceptionHandler: Exception paths explicitly tested (6 tests)
- DTOs: Simple POJOs, no business logic

**Why Some Components Near 95%:**
- Entity: JPA no-arg constructor may not be explicitly invoked (JPA uses reflection)
- DTOs: Auto-generated methods (`equals`, `hashCode`, `toString`) may have unreachable branches

---

## Continuous Integration Recommendations

### GitHub Actions Workflow (Example)

```yaml
name: Test and Coverage

on:
  pull_request:
  push:
    branches: [main, master, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Run tests and generate coverage report
        run: ./gradlew clean test jacocoTestReport jacocoTestCoverageVerification

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: build/reports/jacoco/test/jacocoTestReport.xml
          flags: unittests
          fail_ci_if_error: true

      - name: Comment PR with coverage report
        uses: madrapps/jacoco-report@v1.6.1
        with:
          paths: build/reports/jacoco/test/jacocoTestReport.xml
          token: ${{ secrets.GITHUB_TOKEN }}
          min-coverage-overall: 95
          min-coverage-changed-files: 95
```

**Benefits:**
- Automatic test execution on every PR
- Coverage report posted as PR comment
- Build fails if coverage drops below 95%
- Trend tracking via Codecov integration

---

## Maintenance Guidelines

### When to Update Tests (WTR-6+)

**Scenario 1: New REST Endpoint Added**
- Add 3-5 controller unit tests (happy path + error cases)
- Add 2-3 service unit tests (business logic)
- Add 1-2 functional tests (end-to-end)
- Rerun JaCoCo to verify coverage still ≥95%

**Scenario 2: DTO Field Added**
- Update DTO test to verify new field serialization
- Update functional test to include new field in request/response

**Scenario 3: New Exception Type**
- Add 1 GlobalExceptionHandler test for new exception → HTTP status mapping

**Scenario 4: Environment Configuration Change**
- Update corresponding `application-{profile}.yml` file
- Rerun functional tests to verify configuration loads correctly

### Test Maintenance Checklist

- [ ] All new production code has corresponding unit test (class-level coverage)
- [ ] All new REST endpoints have controller + service + functional tests
- [ ] JaCoCo coverage remains ≥95% (`./gradlew jacocoTestCoverageVerification`)
- [ ] Functional tests run in <30 seconds (singleton Testcontainers container)
- [ ] No flaky tests (rerun 3 times, all pass)
- [ ] Test names follow convention: `test<Action><Condition><ExpectedResult>`

---

## Conclusion

The WTR-6 E2E measurement suite provides comprehensive validation of test coverage infrastructure, including:

- **80+ structural verification points** (Gradle config, YAML files, package structure)
- **51 automated tests** (37 unit + 14 functional)
- **95% JaCoCo coverage enforcement** across instruction, line, method, class
- **Full-stack integration testing** with Testcontainers (real Postgres 15.4 database)
- **Validation of all 10 acceptance criteria** and 11 plan steps

**Next Steps:**
1. Run `./test-e2e-wtr6.sh` to establish baseline (expected: 2-3 passing, ~77 failing)
2. Implement WTR-6 according to plan (Steps 1-11)
3. Rerun `./test-e2e-wtr6.sh` to verify all checks pass
4. Run `./gradlew test jacocoTestReport jacocoTestCoverageVerification` to confirm 95% coverage
5. Open `build/reports/jacoco/test/html/index.html` to review coverage heatmap

**Success Criteria Met When:**
- ✅ `./test-e2e-wtr6.sh` exits 0 (all ~80 tests pass)
- ✅ `./gradlew test` exits 0 (all 51 tests pass)
- ✅ JaCoCo HTML report shows ≥95% across all counters
- ✅ `./gradlew jacocoTestCoverageVerification` exits 0 (no threshold violations)

---

_This measurement suite ensures WTR-6 implementation is complete, tested, and maintainable per industry best practices (Spring Boot, JaCoCo, Testcontainers, MockK)._
