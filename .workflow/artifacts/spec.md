# Draft spec — WTR-6: Test suite with 95% JaCoCo coverage

## Problem
The Web Transaction Store service currently lacks comprehensive test coverage. The service needs both unit and integration tests to reach 95% code coverage across all JaCoCo metrics (instruction, line, method, class) to ensure reliability and maintainability.

## Goal
Achieve and verify 95% JaCoCo coverage across all four counters (instruction, line, method, class) with a complete test suite of 51 tests (37 unit + 14 functional) that all pass successfully.

## Non-Goals
- Performance or load testing
- End-to-end testing across multiple services
- Manual testing procedures or QA handoff documentation
- Test data generation frameworks or test fixtures beyond what's needed for the specified tests

## Users / Surfaces affected
**Components tested:**
- `Controller` layer (REST endpoints)
- `Service` layer (business logic)
- Exception handler (global error handling)
- DTOs (data transfer objects)
- Entity classes (JPA entities)
- Configuration classes (HikariCP, datasource setup)
- Health endpoints

**Test infrastructure:**
- Testcontainers integration (Postgres 15.4)
- Environment-specific configuration files (`application-{local,test,dev,staging,prod}.yml`)
- JaCoCo reporting plugin
- Gradle test task

## Acceptance Criteria
- `./gradlew test` completes successfully with all tests passing
- JaCoCo HTML/XML report shows ≥95% coverage on all four metrics: instruction, line, method, class
- Total of 51 tests execute (37 unit + 14 functional)
- **Unit tests breakdown (37 total):**
  - Controller: 6 tests covering method delegation and exception propagation
  - Service: 9 tests covering CRUD operations, payload handling, not-found scenarios
  - Exception handler: 6 tests covering 404, 400 validation, 400 enum/deserialisation errors
  - DTOs: 8 tests covering defaults, copy constructors, equality, toString
  - Entity: 3 tests covering constructor defaults and field setters
  - Config: 4 tests covering HikariDataSource creation and connection string handling
  - Health: 1 test verifying health endpoint returns UP
- **Functional tests (14 total):**
  - Full HTTP lifecycle: create → read (by id + by reference) → update → read
  - Validation failures at controller boundary
  - 404 responses for missing id/reference
  - Security enabled/disabled toggle behavior
- Environment configurations present for all profiles (local, test, dev, staging, prod) with:
  - Database URL and credentials via environment variables
  - Flyway migration toggles per environment
  - Actuator endpoint exposure rules per environment
  - `security.enabled` flags

## Out-of-Scope
- Mutation testing or coverage quality analysis beyond the four JaCoCo metrics
- CI/CD pipeline configuration for running tests
- Test parallelization or test execution time optimization
- Mocking strategy documentation or test architecture guidelines
- Code changes to improve testability (e.g., refactoring for dependency injection) — tests must work with the existing service design
