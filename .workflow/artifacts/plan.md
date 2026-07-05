---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-3
job_id: wtr-3-979qad
---

# WTR-3 — Implementation plan

## Approach

This plan delivers a Flyway-managed database schema for the `reconciliation_transaction` table with four migrations (V1-V4), corresponding JPA entity classes in Kotlin, and a Spring Data repository. The migrations follow an evolutionary approach: V1 creates the initial table, V2 is a placeholder stub for the deferred 29-table normalized schema, V3 demonstrates a column rename, and V4 adds optimistic locking support.

To resolve the spec's open questions, this plan makes the following decisions aligned with standard Spring Boot / Flyway conventions:
- **Package structure**: Following WTR-2's `com.webtransaction.microsite` base, entities live in `com.webtransaction.microsite.entity`, repositories in `com.webtransaction.microsite.repository`.
- **V1 grants**: Apply to database user `wtr_app` (parameterizable via Flyway placeholders in `application.yml`).
- **V2 placeholder**: A comment-only SQL file explaining the deferral — Flyway accepts this.
- **V3 column rename**: V1 creates `internal_reference_type`; V3 renames it to `external_reference_type` to demonstrate schema evolution.
- **V4 version column**: V1 omits the `version` column; V4 adds it, aligning with the JPA `@Version` annotation.
- **Kotlin entity**: Regular `class` (not `data class`) to avoid JPA proxy issues with lazy loading.
- **TransactionType enum**: Initial set `{WEB_ELECTRICITY_ORDER, WEB_WATER_ORDER, WEB_GAS_ORDER}` — extensible.
- **Timestamps**: `TIMESTAMP WITHOUT TIME ZONE` (application controls timezone; aligns with Spring Boot defaults).

The JPA entity uses Hibernate's naming strategy (`SpringPhysicalNamingStrategy`), which maps `camelCase` properties to `snake_case` columns. The repository extends `JpaRepository` with a single query method `findByReference`. Optimistic locking is enforced via `@Version` on the `version` column — concurrent updates trigger `OptimisticLockException`.

Dependencies added to `build.gradle.kts`: `spring-boot-starter-data-jpa`, `org.flywaydb:flyway-core:6.3.1`, `org.postgresql:postgresql`. The Flyway baseline is version 1; all four migrations run on an empty database.

## Files in scope

- `build.gradle.kts`
- `src/main/resources/application.yml`
- `src/main/resources/db/migration/V1__create_reconciliation_transaction.sql`
- `src/main/resources/db/migration/V2__placeholder_normalized_schema.sql`
- `src/main/resources/db/migration/V3__rename_reference_type_column.sql`
- `src/main/resources/db/migration/V4__add_version_column.sql`
- `src/main/kotlin/com/webtransaction/microsite/entity/ReconciliationTransaction.kt`
- `src/main/kotlin/com/webtransaction/microsite/entity/TransactionType.kt`
- `src/main/kotlin/com/webtransaction/microsite/entity/ExternalReferenceType.kt`
- `src/main/kotlin/com/webtransaction/microsite/entity/ReconcileStatus.kt`
- `src/main/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepository.kt`
- `src/test/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepositoryTests.kt`

## Plan Steps

### Step 1: Add Flyway and Postgres dependencies
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: Run `./gradlew build` and verify the build resolves `flyway-core:6.3.1`, `spring-boot-starter-data-jpa`, and `postgresql` without dependency conflicts. Manual validation — existing tests from WTR-2 must still pass.

### Step 2: Configure Flyway in application.yml
- Test mode: `test-after`
- Files: `src/main/resources/application.yml`
- Test strategy: Add Flyway configuration (baseline-on-migrate, locations, placeholders for `wtr_app` user). Verify `./gradlew bootRun` starts without Flyway errors (expects migrations to be added in Step 3). Manual validation.

### Step 3: Create V1 migration — initial table
- Test mode: `test-after`
- Files: `src/main/resources/db/migration/V1__create_reconciliation_transaction.sql`
- Test strategy: Start Postgres via `docker compose up -d`. Run `./gradlew flywayMigrate` and verify V1 applies cleanly. Query `flyway_schema_history` and confirm version 1 exists. Query `reconciliation_transaction` schema and verify columns match spec (including `internal_reference_type`, not `external_reference_type` yet). Verify grants on `wtr_app` user.

### Step 4: Create V2 migration — placeholder for normalized schema
- Test mode: `test-after`
- Files: `src/main/resources/db/migration/V2__placeholder_normalized_schema.sql`
- Test strategy: Run `./gradlew flywayMigrate` and verify V2 applies without error. Verify `flyway_schema_history` shows version 2. The file contains only a comment explaining the 29-table schema is deferred — no schema changes.

### Step 5: Create V3 migration — rename column
- Test mode: `test-after`
- Files: `src/main/resources/db/migration/V3__rename_reference_type_column.sql`
- Test strategy: Run `./gradlew flywayMigrate` and verify V3 applies. Query `reconciliation_transaction` and confirm column `internal_reference_type` no longer exists, `external_reference_type` exists. Verify indexes referencing the old column name are updated.

### Step 6: Create V4 migration — add version column
- Test mode: `test-after`
- Files: `src/main/resources/db/migration/V4__add_version_column.sql`
- Test strategy: Run `./gradlew flywayMigrate` and verify V4 applies. Query `reconciliation_transaction` and confirm `version BIGINT DEFAULT 0 NOT NULL` exists. Insert a test row and verify `version` defaults to 0.

### Step 7: Create enum classes
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/entity/TransactionType.kt`, `src/main/kotlin/com/webtransaction/microsite/entity/ExternalReferenceType.kt`, `src/main/kotlin/com/webtransaction/microsite/entity/ReconcileStatus.kt`
- Test strategy: No standalone tests for enums — they are validated via the entity tests in Step 8. Verify each enum is a Kotlin `enum class` with appropriate values (`TransactionType` has `WEB_ELECTRICITY_ORDER`, `WEB_WATER_ORDER`, `WEB_GAS_ORDER`).

### Step 8: Create JPA entity
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/entity/ReconciliationTransaction.kt`, `src/test/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepositoryTests.kt`
- Test strategy: Write `ReconciliationTransactionRepositoryTests` using `@DataJpaTest` with Testcontainers (Postgres 15.4). Test creates an entity, persists via repository, queries by reference, and verifies all fields map correctly. Verify `@Version` column increments on update. Test must achieve >95% coverage on the entity.

### Step 9: Create Spring Data repository
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepository.kt`, `src/test/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepositoryTests.kt` (extend from Step 8)
- Test strategy: Extend `ReconciliationTransactionRepositoryTests` to verify `findByReference(reference: String)` returns the correct entity. Verify the method returns `null` or empty when reference doesn't exist.

### Step 10: Test optimistic locking
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepositoryTests.kt` (extend from Step 9)
- Test strategy: Add test that simulates concurrent updates: fetch the same entity in two transactions, update both, commit first, then commit second. Verify the second commit throws `OptimisticLockException`. Test must pass to satisfy acceptance criteria.

## Risks

- **Flyway 6.3.1 compatibility with Spring Boot 3.3.12**: Flyway 6.x is older; Spring Boot 3.x typically uses Flyway 9.x. Dependency resolution may force an upgrade, or runtime errors may occur. Mitigation: if Flyway 6.3.1 is unavailable or conflicts, escalate to clarify version requirement — the spec explicitly requests 6.3.1.
- **V1 grants on `wtr_app` user**: If the Postgres Docker Compose setup doesn't create this user, grants will fail. Mitigation: V1 migration includes `CREATE USER IF NOT EXISTS` or equivalent, or the user is pre-created in an init script referenced from `docker-compose.yml`.
- **Column name mismatch (V3)**: If V1 accidentally creates `external_reference_type` instead of `internal_reference_type`, V3's rename will fail. Mitigation: carefully verify V1 column names before writing V3.
- **JaCoCo 95% threshold on JPA entity**: Entities with many fields may not reach 95% coverage without exhaustive tests. Mitigation: Step 8 tests must cover all getters/setters/constructors — use a comprehensive field-check test.
- **Testcontainers performance**: Spinning up Postgres containers in tests can be slow. Mitigation: use `@Testcontainers` with `@Container` and reuse the container across test methods where possible.

## Out-of-Plan (deferred)

- **Service layer / business logic**: Explicitly out-of-scope per spec. No `ReconciliationService` or controller integration in this ticket.
- **29-table normalized schema (V2)**: The spec defers this to a future ticket. V2 is a placeholder only.
- **Data migration from existing systems**: Out-of-scope per spec.
- **Performance tuning beyond specified indexes**: V1 includes indexes on `reference` and `external_reference_type` per standard practice, but no query optimization or partitioning.
- **Audit logging / triggers**: Out-of-scope per spec.
- **CI/CD changes**: No modifications to `.github/workflows/` or CI config per constraint.
- **Repository query methods beyond `findByReference`**: Only the single method specified in acceptance criteria is implemented. Additional query methods (e.g., `findByStatus`, `findByType`) deferred to future tickets.
