---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-4
job_id: wtr-4-drddc7
---

# WTR-4 — Implementation plan

## Approach

This plan implements a RESTful API for Web Transaction management following Spring Boot best practices with a layered architecture: Controller → Service → Repository. The implementation uses JPA for persistence with PostgreSQL's JSONB support via Hibernate's native JSON handling.

The architecture follows standard Spring patterns:
- **Controller layer** handles HTTP concerns (path mapping, status codes, request/response marshalling)
- **Service layer** encapsulates business logic and validation
- **Repository layer** provides data access via Spring Data JPA
- **DTO layer** decouples API contracts from domain entities

**Resolving spec ambiguities:**
- **PUT 404 behavior**: Returns 404 if reference doesn't exist (RESTful convention)
- **Enum definitions**: Create three enums with placeholder values (`PURCHASE`/`REFUND` for transaction type, `ORDER_ID`/`PAYMENT_ID` for reference type, `PENDING`/`COMPLETED`/`FAILED` for reconcile status) — real values can be refined post-implementation
- **Reference uniqueness**: Not enforced as unique in this plan (spec doesn't require it; can be added later if needed)
- **Invalid enum response**: 400 Bad Request (invalid input format)
- **Timestamp format**: ISO-8601 with timezone (Jackson default for `LocalDateTime`)
- **ControllerAdvice**: Created as part of this implementation
- **Payload optionality**: Both `originalPayload` and `reconcilePayload` are optional (`@field:Valid` but not `@field:NotNull`)

The JSONB fields are mapped using `@JvmField @Column(columnDefinition = "jsonb")` with Hibernate's JSON support, ensuring proper serialization/deserialization of nested maps.

All endpoints follow REST conventions:
- POST returns 201 Created with Location header
- GET by ID/reference returns 200 or 404
- PUT returns 200 with updated entity or 404

Test coverage will exceed 95% via comprehensive controller tests (using `@WebMvcTest`), service tests (using mocked repositories), and repository tests (using `@DataJpaTest` with H2).

## Files in scope

- `build.gradle.kts` (add validation dependency)
- `src/main/kotlin/com/webtransaction/microsite/domain/WebTransaction.kt`
- `src/main/kotlin/com/webtransaction/microsite/domain/TransactionType.kt`
- `src/main/kotlin/com/webtransaction/microsite/domain/ExternalReferenceType.kt`
- `src/main/kotlin/com/webtransaction/microsite/domain/ReconcileStatus.kt`
- `src/main/kotlin/com/webtransaction/microsite/repository/WebTransactionRepository.kt`
- `src/main/kotlin/com/webtransaction/microsite/service/WebTransactionService.kt`
- `src/main/kotlin/com/webtransaction/microsite/exception/EntityNotFoundException.kt`
- `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`
- `src/main/kotlin/com/webtransaction/microsite/controller/GlobalExceptionHandler.kt`
- `src/main/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequest.kt`
- `src/main/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequest.kt`
- `src/main/kotlin/com/webtransaction/microsite/dto/WebTransactionResponse.kt`
- `src/main/resources/application.yml` (update JPA settings if needed)
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/repository/WebTransactionRepositoryTests.kt`

## Plan Steps

### Step 1: Add Bean Validation dependency and configure JPA
- Test mode: `test-after`
- Files: `build.gradle.kts`, `src/main/resources/application.yml`
- Test strategy: Run `./gradlew build` and verify `spring-boot-starter-validation` is resolved. Verify existing tests still pass. Manual validation — no new automated tests at this stage.

### Step 2: Create domain entity and enums
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/domain/WebTransaction.kt`, `src/main/kotlin/com/webtransaction/microsite/domain/TransactionType.kt`, `src/main/kotlin/com/webtransaction/microsite/domain/ExternalReferenceType.kt`, `src/main/kotlin/com/webtransaction/microsite/domain/ReconcileStatus.kt`, `src/test/kotlin/com/webtransaction/microsite/repository/WebTransactionRepositoryTests.kt`
- Test strategy: Write repository tests using `@DataJpaTest` with H2 in-memory database. Test entity persistence (save and findById), JSONB field serialization (save map, retrieve, verify structure), and findByReference query. Verify timestamps are auto-populated. Target 100% coverage on entity.

### Step 3: Create repository interface
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/repository/WebTransactionRepository.kt`, `src/test/kotlin/com/webtransaction/microsite/repository/WebTransactionRepositoryTests.kt`
- Test strategy: Extend repository tests to verify `findByReference` returns correct entity or null. Test that repository inherits standard CRUD operations from `JpaRepository`. Coverage: 100% on repository interface methods.

### Step 4: Create service layer with business logic
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/service/WebTransactionService.kt`, `src/main/kotlin/com/webtransaction/microsite/exception/EntityNotFoundException.kt`, `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt`
- Test strategy: Write service tests with mocked repository using `@MockkBean`. Test create (verify save is called, response is mapped), getById (test found and not found cases), getByReference (test found and not found, verify EntityNotFoundException), update (test found, not found, verify only reconcile fields are updated). Coverage: >95% on service, 100% on exception.

### Step 5: Create DTOs with validation annotations
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequest.kt`, `src/main/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequest.kt`, `src/main/kotlin/com/webtransaction/microsite/dto/WebTransactionResponse.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- Test strategy: Write controller tests using `@WebMvcTest` with mocked service. Test validation: missing required fields return 400, field length violations return 400 with details, invalid enum values return 400. Verify DTO-to-entity and entity-to-DTO mapping preserves all fields including JSONB. Coverage: 100% on DTOs (via controller tests exercising all fields).

### Step 6: Create controller with REST endpoints
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- Test strategy: Extend controller tests to verify: POST returns 201 with Location header and response body, GET by ID returns 200 with entity or 404, GET by reference returns 200 or 404, PUT returns 200 with updated entity or 404. Test that validation errors are properly formatted. Coverage: 100% on controller.

### Step 7: Create global exception handler
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/GlobalExceptionHandler.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- Test strategy: Extend controller tests to verify exception handling: EntityNotFoundException returns 404 with message, MethodArgumentNotValidException returns 400 with field errors in `{"error": "...", "details": {"field": "message"}}` structure, other exceptions return 500. Coverage: 100% on exception handler.

### Step 8: Integration verification
- Test mode: `test-after`
- Files: All files in scope
- Test strategy: Run `./gradlew build` and verify all tests pass. Run `./gradlew jacocoTestCoverageVerification` and confirm >95% coverage. Run `./gradlew ktlintCheck detekt` and verify zero violations. Start application with `./gradlew bootRun` and manually test endpoints with curl: create transaction, fetch by ID, fetch by reference, update by reference, verify validation errors. Confirm JSONB round-trips correctly with nested maps.

## Risks

- **JSONB PostgreSQL compatibility with H2 tests**: H2 doesn't natively support JSONB type. Mitigation: H2 can handle JSON columns with columnDefinition override; tests will use H2's JSON support which is compatible enough for unit tests. Real Postgres validation can be done manually.
- **Enum validation in service layer**: If invalid enum string is passed from controller (after JSON deserialization), Jackson will throw before it reaches service. Mitigation: GlobalExceptionHandler catches `HttpMessageNotReadableException` and returns 400.
- **JSONB serialization format**: Hibernate's JSON handling may differ between Postgres and H2. Mitigation: Integration verification step includes manual testing against real Postgres via Docker Compose.
- **95% coverage with DTO classes**: Kotlin data classes generate many methods (equals, hashCode, toString, copy, componentN). Mitigation: Tests will exercise DTO mapping in controller tests, ensuring coverage of primary constructor and key methods.
- **Location header format**: POST endpoint must return URI in Location header. Mitigation: Use `ServletUriComponentsBuilder` to construct proper URI from created entity ID.

## Out-of-Plan (deferred)

- **Database schema creation**: Plan assumes schema already exists (JPA `ddl-auto: validate` in application.yml). If schema doesn't exist, this will fail. Database migration (Flyway/Liquibase) is out of scope per original scaffolding plan.
- **Reference field uniqueness constraint**: Spec doesn't explicitly require uniqueness. If needed, add `@Column(unique = true)` to entity and corresponding migration in future ticket.
- **Bulk operations**: POST/PUT for multiple transactions explicitly out of scope.
- **DELETE endpoint**: Out of scope per spec.
- **Pagination**: GET endpoints return single entities, not lists. List endpoints deferred.
- **Authentication/Authorization**: Endpoints are unauthenticated. Security layer deferred.
- **Audit logging**: No audit trail of creates/updates. Deferred to future observability work.
- **API documentation**: Swagger/OpenAPI annotations deferred.
- **Integration tests with real Postgres**: Only unit tests with H2 in this plan. Full integration tests with Testcontainers deferred.
- **Soft delete**: Hard delete only (though no DELETE endpoint exists yet).
- **Optimistic locking**: No `@Version` field on entity. Concurrent update handling deferred.
- **Custom JSON serialization**: Assumes Jackson defaults are acceptable for JSONB and timestamps. Custom serializers deferred if needed.
