---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-4
job_id: wtr-4-xt19q0
---

# WTR-4 — Implementation plan

## Approach

This plan delivers a REST API for the Web Transaction Store with four endpoints (POST create, GET by ID, GET by reference, PUT by reference), implementing the controller-service-repository pattern standard in Spring Boot applications. Building on WTR-3's JPA entity and repository foundation, this ticket adds the web layer and service layer with validation.

To resolve the spec's open questions, this plan makes the following decisions aligned with Spring Boot conventions:

- **PUT 404 behavior**: Returns 404 if the reference doesn't exist (REST convention: PUT on non-existent resource is an error).
- **Enum values**: Re-use the enums from WTR-3 (`TransactionType`, `ExternalReferenceType`, `ReconcileStatus`). WTR-3 defined these with initial values — this plan assumes they exist.
- **Reference uniqueness**: Treat `reference` as a lookup key (not enforced unique in DB per WTR-3, but typically only one record per reference in practice). GET by reference returns the first match; if multiple exist, this is a data quality issue outside this ticket's scope.
- **Enum validation response code**: Return 400 (Bad Request) for invalid enum values — these are client input errors, same as missing required fields.
- **Timestamp format**: ISO-8601 with timezone (e.g., `2026-07-05T14:23:01Z`) — Spring Boot's Jackson defaults serialize `Instant` / `LocalDateTime` this way.
- **Exception handler**: Create a `@RestControllerAdvice` class to map `EntityNotFoundException` → 404, `MethodArgumentNotValidException` → 400 with field details, and other exceptions to 500.
- **Payload optionality**: `originalPayload` is required on create (cannot be null). `reconcilePayload` is optional (can be null initially, populated later via PUT).

The service layer wraps the repository with domain validation: enum deserialization, length checks (delegated to Bean Validation), and existence checks (throwing `EntityNotFoundException` when a reference is not found). The controller delegates all business logic to the service, keeping controller methods thin (single responsibility: HTTP marshalling).

DTOs use Kotlin data classes with Jackson annotations for JSON serialization. JSONB fields (`originalPayload`, `reconcilePayload`) map to `Map<String, Any?>` in Kotlin, serialized by Jackson's `ObjectMapper` to preserve nested structure. The repository layer (from WTR-3) already handles Postgres JSONB via Hibernate's `@JdbcTypeCode(SqlTypes.JSON)`.

Dependencies: `spring-boot-starter-web` (already implicit in Spring Boot starters), `spring-boot-starter-validation` for Bean Validation (`@Valid`, `@NotBlank`, `@Size`). No new Gradle dependencies required beyond what WTR-3 added.

Package structure (aligning with WTR-3's `com.webtransaction.microsite.*`):
- `com.webtransaction.microsite.controller.WebTransactionController`
- `com.webtransaction.microsite.service.WebTransactionService`
- `com.webtransaction.microsite.dto.CreateWebTransactionRequest`
- `com.webtransaction.microsite.dto.UpdateWebTransactionRequest`
- `com.webtransaction.microsite.dto.WebTransactionResponse`
- `com.webtransaction.microsite.exception.EntityNotFoundException`
- `com.webtransaction.microsite.exception.GlobalExceptionHandler`

## Files in scope

- `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`
- `src/main/kotlin/com/webtransaction/microsite/service/WebTransactionService.kt`
- `src/main/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequest.kt`
- `src/main/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequest.kt`
- `src/main/kotlin/com/webtransaction/microsite/dto/WebTransactionResponse.kt`
- `src/main/kotlin/com/webtransaction/microsite/exception/EntityNotFoundException.kt`
- `src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt`
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt`

## Plan Steps

### Step 1: Create EntityNotFoundException
- Test mode: `test-after`
- Files: `src/main/kotlin/com/webtransaction/microsite/exception/EntityNotFoundException.kt`
- Test strategy: No standalone test for this exception class. Verified in Step 7 (service layer tests) where it is thrown and caught. Simple runtime exception extending `RuntimeException` with a message parameter.

### Step 2: Create GlobalExceptionHandler
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- Test strategy: Write controller tests that trigger exceptions (`EntityNotFoundException`, `MethodArgumentNotValidException`, generic exceptions) and verify response structure and status codes. `@RestControllerAdvice` handler must map: `EntityNotFoundException` → 404 with `{"error": "..."}`, `MethodArgumentNotValidException` → 400 with `{"error": "...", "details": {"field": "message"}}`, other exceptions → 500 with `{"error": "Internal server error"}`.

### Step 3: Create DTOs
- Test mode: `test-after`
- Files: `src/main/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequest.kt`, `src/main/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequest.kt`, `src/main/kotlin/com/webtransaction/microsite/dto/WebTransactionResponse.kt`
- Test strategy: DTOs are Kotlin data classes with Bean Validation annotations (`@NotBlank`, `@Size`, `@NotNull`). No standalone tests — validation is exercised via controller tests in Step 8. Verify structure: `CreateWebTransactionRequest` has all entity fields except `id`/`version`/timestamps. `UpdateWebTransactionRequest` has only `reconcileStatus` and `externalReferenceNumber`. `WebTransactionResponse` mirrors entity structure with ISO-8601 timestamps.

### Step 4: Create WebTransactionService — create operation
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/service/WebTransactionService.kt`, `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt`
- Test strategy: Write `WebTransactionServiceTests` using `@MockBean` for the repository (from WTR-3). Test `createTransaction(request: CreateWebTransactionRequest): WebTransactionResponse` maps DTO → entity, saves via repository, returns response DTO. Verify JSONB fields (`originalPayload`, `reconcilePayload`) preserve nested map structure. Verify enum values are correctly mapped. Test must cover happy path and invalid enum values (should throw IllegalArgumentException, which triggers 400 via exception handler).

### Step 5: Create WebTransactionService — read operations
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/service/WebTransactionService.kt`, `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt` (extend from Step 4)
- Test strategy: Add `getTransactionById(id: Long): WebTransactionResponse` and `getTransactionByReference(reference: String): WebTransactionResponse`. Both throw `EntityNotFoundException` when not found. Tests mock repository methods (`findById`, `findByReference` from WTR-3) and verify exception is thrown for missing entities, response DTO is returned for found entities.

### Step 6: Create WebTransactionService — update operation
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/service/WebTransactionService.kt`, `src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt` (extend from Step 5)
- Test strategy: Add `updateTransactionByReference(reference: String, request: UpdateWebTransactionRequest): WebTransactionResponse`. Method fetches entity by reference (throws `EntityNotFoundException` if not found), updates only `reconcileStatus` and `externalReferenceNumber` fields, saves, returns response DTO. Test verifies partial update (other fields unchanged), exception thrown for missing reference, optimistic locking version increments.

### Step 7: Create WebTransactionController — POST endpoint
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt`
- Test strategy: Write `WebTransactionControllerTests` using `@WebMvcTest(WebTransactionController::class)` with `@MockBean` for service. Test `POST /v1/webtransaction` returns 201 with response body. Verify `@Valid` triggers 400 for missing required fields, violating `@Size` constraints (reference > 100 chars, externalReferenceNumber > 255 chars), and invalid enum values. Verify JSONB fields round-trip correctly in request/response.

### Step 8: Create WebTransactionController — GET endpoints
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt` (extend from Step 7)
- Test strategy: Add `GET /v1/webtransaction/{id}` and `GET /v1/webtransaction/reference/{reference}`. Both return 200 with response body when found, 404 when not found (service throws `EntityNotFoundException`, caught by `GlobalExceptionHandler`). Tests verify path variable binding, 404 response structure matches `{"error": "..."}`.

### Step 9: Create WebTransactionController — PUT endpoint
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt` (extend from Step 8)
- Test strategy: Add `PUT /v1/webtransaction/reference/{reference}`. Returns 200 with updated response body. Test verifies partial update (only `reconcileStatus` and `externalReferenceNumber` fields change), 404 when reference not found, 400 for validation errors on update DTO.

### Step 10: End-to-end validation coverage
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt` (extend from Step 9)
- Test strategy: Add comprehensive edge-case tests: empty JSONB maps, null reconcilePayload on create, deeply nested JSONB structures (3+ levels), Unicode characters in string fields, boundary values for length constraints (reference exactly 100 chars, externalReferenceNumber exactly 255 chars). Verify all acceptance criteria are covered: 201/200/404/400 codes, error response structure, JSONB round-trip, field length limits, enum validation.

## Risks

- **JSONB mapping in DTOs**: Kotlin `Map<String, Any?>` serialization to Postgres JSONB via Jackson and Hibernate may have edge cases (e.g., null values in nested maps, type coercion). Mitigation: Step 10 tests deeply nested structures and null values explicitly.
- **Reference non-uniqueness**: If multiple records share the same reference (allowed per WTR-3 schema), `findByReference` returns only the first match. This could be unexpected behavior. Mitigation: document this limitation in code comments; defer uniqueness constraint to a future schema migration if needed.
- **Enum value mismatches**: If WTR-3's enum values don't match the spec's expected values, tests will fail. Mitigation: Step 4 tests verify enum mapping; if mismatches exist, update enums in WTR-3 retrospectively (out of scope for this plan, but flagged as a risk).
- **Optimistic locking on PUT**: Concurrent updates may trigger `OptimisticLockException`. This plan does not add retry logic or special handling. Mitigation: exception handler maps `OptimisticLockException` → 409 Conflict (added to `GlobalExceptionHandler` in Step 2).
- **ISO-8601 timestamp serialization**: If WTR-3's entity uses `LocalDateTime` without timezone, serialization may not include `Z` suffix. Mitigation: verify in Step 10 tests; if needed, configure Jackson's `ObjectMapper` to serialize with UTC timezone.

## Out-of-Plan (deferred)

- **Integration tests with live database**: Spec explicitly defers this. Controller tests use `@WebMvcTest` (no database), service tests use `@MockBean` for repository.
- **Swagger/OpenAPI documentation**: Out-of-scope per spec. No `@Operation` or `@ApiResponse` annotations added.
- **Authentication/authorization**: Out-of-scope per spec. No `@PreAuthorize` or security filters.
- **Bulk operations**: POST/PUT handle single transactions only. Batch endpoints deferred.
- **DELETE endpoint**: Out-of-scope per spec.
- **Pagination**: GET by reference returns single record; no list endpoints in this ticket.
- **Audit logging**: No `@CreatedBy` / `@LastModifiedBy` annotations or audit tables.
- **Rate limiting**: No `@RateLimiter` or throttling middleware.
- **Soft delete**: No `deleted` flag or logical delete support.
- **Retry logic for optimistic locking**: 409 response returned; client must retry.
- **Repository query optimization**: Assumes `findByReference` from WTR-3 is efficient (indexed). No query tuning in this ticket.
- **DTO-to-entity mapping library**: Uses manual mapping in service layer (no MapStruct or ModelMapper). Simple field-by-field assignment keeps the implementation transparent.
