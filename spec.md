# Draft spec — WTR-5: OAuth2 security + global exception handler + actuator health

## Problem
The Web Transaction Store API currently lacks authentication/authorization and standardized error handling. Protected endpoints are publicly accessible, validation errors return inconsistent responses, and operational endpoints (/health, /info) are not exposed.

## Goal
Secure all transaction endpoints with JWT-based OAuth2 using scoped access control (read/write), implement consistent exception handling across all endpoints, and expose Spring Actuator health/info endpoints for operational monitoring.

## Non-Goals
- Frontend/client-side JWT handling or token acquisition flows
- Custom JWT issuer implementation (relying on external identity providers)
- Database health checks or custom actuator metrics beyond basic /health and /info
- Performance optimization or rate limiting

## Users / Surfaces affected
**Users:** API consumers (authenticated services, client applications) and operations teams (for monitoring)

**Surfaces:**
- All existing REST endpoints in the Web Transaction Store API (GET, POST, PUT operations)
- New endpoints: `/health` and `/info` (unauthenticated)
- Security configuration class (to be created)
- Global exception handler class (to be created, `GlobalExceptionHandler`)
- Application properties files (security.enabled, JWT issuer configs per environment)

## Acceptance Criteria
- Unauthenticated GET request to any protected transaction endpoint returns 401 Unauthorized
- Authenticated request with valid JWT but insufficient scope (e.g., `read:web-transaction` attempting POST) returns 403 Forbidden
- Authenticated request with valid JWT and `read:web-transaction` scope can successfully GET transactions
- Authenticated request with valid JWT and `write:web-transaction` scope can successfully POST/PUT transactions
- `EntityNotFoundException` returns 404 with JSON body: `{ "error": "<message>" }`
- `MethodArgumentNotValidException` (validation errors) returns 400 with JSON body: `{ "error": "Validation failed", "details": { "<field>": "<message>" } }`
- `HttpMessageNotReadableException` (malformed JSON, invalid enum values) returns 400 with sanitized error message
- `/health` endpoint is accessible without JWT and returns Spring Actuator health response
- `/info` endpoint is accessible without JWT and returns application metadata including git build information
- Security is disabled in local and test profiles via `security.enabled=false` property
- Method-level security annotations are enabled via `@EnableMethodSecurity(prePostEnabled = true)`

## Open Questions
1. **Spec §3.4 reference:** Where is "spec §3.4" that defines the issuer lists for dev/staging/prod environments? What document/location should be consulted for the exact issuer URIs per environment?
2. **Multi-issuer configuration:** Should the dev/staging/prod environments support multiple JWT issuers simultaneously (e.g., Auth0 + Cognito), or one issuer per environment? If multiple, what is the priority/fallback order?
3. **Audience validation:** Is the audience value `https://web-transaction-api` literal, or does it vary per environment (e.g., `https://dev.web-transaction-api`)?
4. **Protected endpoint definition:** Which specific REST controller endpoints exist today that need scope protection? Should the scope checks be applied at the controller method level or via HTTP method filters?
5. **Error response format:** Should the error responses include additional fields like `timestamp`, `path`, or `status` code, or strictly the `error` (and `details` for validation) fields as specified?
6. **Git build info source:** How should git commit/branch information be populated in `/info`? Via Spring Boot Maven/Gradle plugin auto-generation, or custom build metadata injection?

## Out-of-Scope
- Authentication endpoint (`/auth`, `/login`) — assuming JWT tokens are acquired externally
- Token refresh logic or session management
- CORS configuration (unless required for OAuth2 flows)
- Authorization beyond scope-based checks (e.g., tenant isolation, data-level permissions)
- Custom actuator endpoints beyond `/health` and `/info`
- Integration tests with live JWT issuer (assuming mocked JWT validation in tests)

---
_Reply on this ticket to refine. When you're happy, comment `APPROVED` (uppercase, standalone) and the workflow will move to the Plan phase._  
_Job: wtr-5-r3k041 · Ref: wtr-5-r3k041:intake:1_
