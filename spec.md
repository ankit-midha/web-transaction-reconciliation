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

## Open Questions
1. **Existing codebase:** Does the Web Transaction Store service already exist with endpoints/entities/services in place, or is this part of greenfield development where the code and tests are being built together?
2. **"spec §6" reference:** The ticket mentions "37 total per spec §6" — is there a separate specification document that defines the test breakdown, or is the ticket description itself the authoritative spec?
3. **Coverage scope:** Should the 95% coverage target apply to *all* production code, or are there exclusions (e.g., generated code, configuration classes, main application class)?
4. **Testcontainers version:** The ticket specifies Testcontainers 1.21.4 — is this version already in use, or is this a new dependency being added?
5. **Security feature:** What does "security enabled/disabled toggles" refer to? Is this Spring Security, a custom auth mechanism, or something else?
6. **Flyway migrations:** Are database migrations already defined, or do they need to be created as part of this work?
7. **Environment variable names:** Are there established naming conventions for the DB URL/creds environment variables (e.g., `DB_URL`, `DATABASE_URL`, `POSTGRES_HOST`)?

## Out-of-Scope
- Mutation testing or coverage quality analysis beyond the four JaCoCo metrics
- CI/CD pipeline configuration for running tests
- Test parallelization or test execution time optimization
- Mocking strategy documentation or test architecture guidelines
- Code changes to improve testability (e.g., refactoring for dependency injection) — tests must work with the existing service design

---
_Reply on this ticket to refine. When you're happy, comment `APPROVED` (uppercase, standalone) and the workflow will move to the Plan phase._  
_Job: wtr-6-58kyda · Ref: wtr-6-58kyda:intake:1_
