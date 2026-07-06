# Draft spec — WTR-2: Project scaffolding — Gradle + Docker Compose + JDK 17

## Problem
The web-transaction-microsite Spring Boot service does not exist yet. A foundational project structure is needed with the correct tech stack, build tooling, linting configuration, code coverage enforcement, local development infrastructure, and containerization setup.

## Goal
A buildable, containerizable Spring Boot skeleton with enforced code quality gates, local Postgres infrastructure, and standard project files that can serve as the foundation for the Web Transaction Store service.

## Non-Goals
- Implementing any business logic or API endpoints for the Web Transaction Store
- Setting up CI/CD pipelines (configuration files may be added, but integration with CI systems is not in scope)
- Deploying the service to any environment beyond local Docker Compose
- Implementing database migrations or schema definitions

## Users / Surfaces affected
**Developers** working on the Web Transaction Store service will interact with:
- Gradle build scripts (`settings.gradle.kts`, `build.gradle.kts`)
- Local development environment via `docker compose up`
- Code quality tools (Ktlint, Detekt, JaCoCo) during build and pre-commit
- Dockerfile for local testing of containerized builds

This is a greenfield project — no existing modules are affected.

## Acceptance Criteria
- `gradlew build` succeeds locally without errors
- `docker compose up` brings up a healthy Postgres 15.4 instance (and Zookeeper/Kafka if included)
- `ktlint` runs as part of the build with zero violations
- `detekt` runs as part of the build with zero violations
- JaCoCo enforces 95% minimum coverage across instruction, line, method, and class metrics (build fails below threshold)
- Multi-stage Dockerfile builds successfully and produces a runnable image based on Corretto 17 Alpine
- Repository includes:
  - Kotlin 1.9.23 source structure
  - Spring Boot 3.3.12 dependencies
  - Gradle wrapper (`gradlew`, `gradlew.bat`) checked in
  - `.editorconfig` with reasonable defaults
  - `.gitignore` appropriate for Gradle/Kotlin/IntelliJ projects
  - `README.md` with setup instructions

## Open Questions
1. **Gradle DSL preference**: Should the build use Groovy DSL or Kotlin DSL? (Deliverables mention "Groovy or Kotlin DSL" — which is preferred?)
2. **Kafka inclusion**: Should the Docker Compose file include Zookeeper + Kafka from the start, or only Postgres 15.4? (Ticket says "if needed" — is it needed for this initial scaffold?)
3. **Project structure**: Should this follow a specific package naming convention (e.g., `com.example.webtransaction`, `com.<org>.wts`) or is that defined elsewhere?
4. **Spring Boot starters**: Beyond the base Spring Boot 3.3.12 BOM, which starters should be included initially? (e.g., `spring-boot-starter-web`, `spring-boot-starter-data-jpa`, `spring-boot-starter-actuator`?)
5. **JaCoCo 95% threshold**: Since this is an empty skeleton with no business logic, how should the 95% threshold be met initially? Should there be a minimal "hello world" controller/test, or should the threshold be lowered for this ticket and raised in later stories?
6. **Ktlint version discrepancy**: Ticket specifies Ktlint 11.3.2, but the latest stable Ktlint release is 1.x (as of early 2025). Should this be Ktlint 1.1.1 or similar, or is 11.3.2 correct?

## Out-of-Scope
- Application properties configuration for external environments (production, staging)
- Authentication, authorization, or security configuration
- API documentation tooling (Swagger/OpenAPI)
- Observability instrumentation (logging, metrics, tracing beyond Spring Boot defaults)
- Database schema or Flyway/Liquibase migration setup
- Integration with external services or message brokers beyond local Docker Compose
