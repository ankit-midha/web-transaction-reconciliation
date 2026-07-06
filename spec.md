# Draft spec — WTR-3: Database schema — Flyway V1-V4 + JPA entity + repository

## Problem
The Web Transaction Reconciliation system needs a persistence layer for tracking transaction reconciliation state. Currently there is no database schema or JPA mapping to store reconciliation transaction records.

## Goal
Deliver a working database schema with Flyway migrations (V1-V4) and a fully-mapped JPA entity (`ReconciliationTransaction`) backed by a Spring Data repository, allowing the application to persist and query reconciliation transactions against Postgres 15.4 with optimistic locking support.

## Non-Goals
- Implementation of business logic that uses the repository (service layer, controllers, reconciliation workflows)
- The 29-table 3NF normalized schema described in V2 (this ticket delivers only a placeholder/stub)
- Data migration from any existing system
- Performance tuning beyond the specified indexes

## Users / Surfaces affected
- **Module**: `src/main/resources/db/migration` — Flyway migration scripts
- **Module**: JPA entity classes (Kotlin) — `ReconciliationTransaction`, enums `TransactionType`, `ExternalReferenceType`, `ReconcileStatus`
- **Module**: Spring Data repository interface — `ReconciliationTransactionRepository`
- **Surface**: Postgres 15.4 database — table `reconciliation_transaction` with indexes

## Acceptance Criteria
- Flyway 6.3.1 migrates cleanly against an empty Postgres 15.4 database
- All four migrations (V1, V2, V3, V4) apply in sequence without error
- The `reconciliation_transaction` table exists with all specified columns, indexes, and constraints after V4
- JPA entity `ReconciliationTransaction` maps to the table with `@Version` annotation
- Repository method `findByReference(reference: String)` exists and is callable
- Optimistic locking works: concurrent updates to the same row throw `OptimisticLockException`
- Database grants are applied as specified in V1

## Open Questions
1. **V1 grants**: Which database user/role should receive the grants? Should this be parameterized or hardcoded?
2. **V2 placeholder**: Should V2 contain an empty file, a comment-only stub, or a minimal skeleton (e.g., one placeholder table)? What is acceptable to keep Flyway happy?
3. **V3 column rename**: The migration renames `internal_reference_type` → `external_reference_type`, but V1 already creates `external_reference_type`. Is V3 a no-op for the rename, or should V1 create `internal_reference_type` instead?
4. **V4 version column**: V4 adds a `version` column, but V1 already includes `version BIGINT DEFAULT 0`. Is V4 a no-op for the version column, or should V1 omit it?
5. **Kotlin entity**: Should `ReconciliationTransaction` be a Kotlin `data class` or a regular `class`? (JPA entities as data classes have caveats around proxying and lazy loading.)
6. **TransactionType enum values**: The ticket lists `WEB_ELECTRICITY_ORDER etc.` — what is the full list of enum values?
7. **Repository package**: Where should `ReconciliationTransactionRepository` live? (e.g., `com.example.repository`, or another package structure?)
8. **Timezone for timestamps**: Should `created` and `updated` use `TIMESTAMP` (no timezone) or `TIMESTAMPTZ` (with timezone)?

## Out-of-Scope
- Unit or integration tests for the repository (acceptance criterion focuses on Flyway + locking behavior, not test coverage)
- Audit logging or triggers on the `reconciliation_transaction` table
- Liquibase or other migration tooling (Flyway 6.3.1 is specified)
- Read replicas, partitioning, or other database topology concerns

---
_Reply on this ticket to refine. When you're happy, comment `APPROVED` (uppercase, standalone) and the workflow will move to the Plan phase._  
_Job: wtr-3-gpd35f · Ref: wtr-3-gpd35f:intake:1_
