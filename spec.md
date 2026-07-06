# Draft spec — WTR-4: REST controller — 4 endpoints + DTOs + validation

## Problem
The Web Transaction Store needs REST endpoints to create, retrieve, and update web transaction records. Currently, these endpoints do not exist. External systems (including Sidekick) need to store transaction metadata with JSONB payloads and query/update by reference identifier.

## Goal
Expose four REST endpoints under `/v1/webtransaction` that allow creating transactions, fetching by ID or reference, and updating reconciliation status. All endpoints must validate inputs and return proper HTTP status codes (201/200/404/400).

## Non-Goals
- Bulk operations (batch create/update)
- DELETE endpoint
- Pagination for list endpoints
- Authentication/authorization implementation

## Users / Surfaces affected
**External systems:**
- Sidekick service — will call `GET /v1/webtransaction/reference/{reference}` to retrieve transactions by reference identifier
- Any service creating web transactions — will call `POST /v1/webtransaction`
- Services updating reconciliation — will call `PUT /v1/webtransaction/reference/{reference}`

**New components:**
- `WebTransactionController` — REST controller with 4 endpoints
- `WebTransactionService` — domain layer between controller and repository
- `CreateWebTransactionRequest` DTO
- `UpdateWebTransactionRequest` DTO
- `WebTransactionResponse` DTO
- Repository layer (interfacing with existing DB schema)

## Acceptance Criteria
- `POST /v1/webtransaction` returns 201 Created with full record in response body
- `GET /v1/webtransaction/{id}` returns 200 with record or 404 if not found
- `GET /v1/webtransaction/reference/{reference}` returns 200 with record or 404 if reference doesn't exist
- `PUT /v1/webtransaction/reference/{reference}` returns 200 with updated record, updates only `reconcile_status` and `external_reference_number`
- Bean validation errors return 400 with structure: `{ "error": "...", "details": { "field": "message" } }`
- JSONB fields (`originalPayload`, `reconcilePayload`) round-trip correctly, preserving nested map structure
- `reference` field max length 100 characters
- `externalReferenceNumber` field max length 255 characters
- Service layer validates enum values for `transactionType`, `externalReferenceType`, and `reconcileStatus`
- Service throws `EntityNotFoundException` for missing references, triggering 404 response

## Open Questions
1. Should the PUT endpoint return 404 if the reference doesn't exist, or 200 with a "not found" indicator in the response body?
2. Are there specific enum values defined for `transactionType`, `externalReferenceType`, and `reconcileStatus`, or should these be created as part of this story?
3. Should the `reference` field be unique in the database, or can multiple records share the same reference?
4. What HTTP response code should be returned if enum validation fails in the service layer (invalid enum value passed) — 400 or 422?
5. For the response DTO, should timestamp fields (`created`, `updated`) be formatted in ISO-8601 with timezone, or Unix epoch milliseconds?
6. Is there an existing `@ControllerAdvice` or exception handler that maps `EntityNotFoundException` to 404, or does this need to be created?
7. Should the `originalPayload` and `reconcilePayload` fields be required (`@NotNull`) or optional on create?

## Out-of-Scope
- Integration tests with test database (assumed to be covered separately)
- API documentation generation (Swagger/OpenAPI)
- Rate limiting or throttling
- Audit logging of changes
- Soft delete functionality

---
_Reply on this ticket to refine. When you're happy, comment `APPROVED` (uppercase, standalone) and the workflow will move to the Plan phase._  
_Job: wtr-4-drddc7 · Ref: wtr-4-drddc7:intake:1_
