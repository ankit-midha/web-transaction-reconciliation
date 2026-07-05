---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-5
job_id: wtr-5-b6qs89
---

# WTR-5 — Implementation plan

## Approach

This plan secures the Web Transaction Store API with OAuth2 JWT authentication, implements consistent exception handling, and exposes Spring Actuator endpoints for operational monitoring. Building on WTR-4's REST API foundation, this ticket adds the security and observability layers standard in production Spring Boot services.

The implementation follows Spring Security 6.x conventions with resource server configuration for JWT validation. OAuth2 scopes (`read:web-transaction`, `write:web-transaction`) control access: read scope permits GET operations, write scope permits POST/PUT operations. The security configuration validates JWT signatures against a configured issuer URI (externally managed identity provider), extracts scopes from the `scope` claim, and enforces method-level authorization via `@PreAuthorize` annotations.

To resolve the spec's open questions, this plan makes the following decisions aligned with Spring Boot and OAuth2 best practices:

- **Issuer configuration**: Single issuer per environment via `spring.security.oauth2.resourceserver.jwt.issuer-uri` property. Default to `https://auth.example.com` (placeholder). Actual issuer URIs will be set via environment-specific application-{env}.yml files or environment variables (e.g., `JWT_ISSUER_URI`). Multi-issuer support deferred as out-of-scope.
- **Audience validation**: Audience claim (`aud`) validation enabled with fixed value `web-transaction-api` (no environment prefix). Configured via `spring.security.oauth2.resourceserver.jwt.audiences` property.
- **Protected endpoints**: Apply scope checks at controller method level using `@PreAuthorize("hasAuthority('SCOPE_read:web-transaction')")` for GET methods and `@PreAuthorize("hasAuthority('SCOPE_write:web-transaction')")` for POST/PUT methods. This provides fine-grained control and makes authorization explicit in code.
- **Error response format**: Strict `{ "error": "..." }` format (no timestamp/path/status fields). Keeps responses lightweight and focused. Custom `@RestControllerAdvice` handler formats all exceptions consistently.
- **Git build info**: Use Spring Boot Actuator's built-in git information support via `spring-boot-maven-plugin` (or `gradle-git-properties` plugin for Gradle). Generates `git.properties` file at build time, automatically exposed at `/info` when `management.info.git.mode=full`.

The global exception handler (`GlobalExceptionHandler`) centralizes error response formatting for all controller exceptions: `EntityNotFoundException` → 404, `MethodArgumentNotValidException` → 400 with field-level details, `HttpMessageNotReadableException` → 400 with sanitized message (to avoid leaking stack traces), `AccessDeniedException` → 403, generic exceptions → 500. This handler is a `@RestControllerAdvice` class that intercepts exceptions before they reach the default Spring error handler, ensuring consistent JSON structure.

Spring Actuator endpoints (`/actuator/health`, `/actuator/info`) are exposed via `management.endpoints.web.exposure.include=health,info` and explicitly permitted in the security configuration (no JWT required). The `/health` endpoint returns simple UP/DOWN status by default. The `/info` endpoint exposes git commit hash, branch, and build time (sourced from `git.properties`).

Security is conditionally disabled in local and test profiles via `@ConditionalOnProperty(name = "security.enabled", havingValue = "true", matchIfMissing = true)`. When `security.enabled=false` (set in `application-local.yml` and `application-test.yml`), the security filter chain is not registered, allowing unauthenticated access for local development and unit tests.

Dependencies: `spring-boot-starter-security`, `spring-boot-starter-oauth2-resource-server` (for JWT validation), `spring-boot-starter-actuator` (for health/info endpoints). Assume Gradle Kotlin DSL; dependencies added to `build.gradle.kts`.

Package structure (extending WTR-4's `com.webtransaction.microsite.*`):
- `com.webtransaction.microsite.config.SecurityConfig` — OAuth2 resource server configuration
- `com.webtransaction.microsite.exception.GlobalExceptionHandler` — extends WTR-4's exception handler with 401/403 handling
- Controller method annotations — add `@PreAuthorize` to existing `WebTransactionController` methods
- `src/main/resources/application.yml` — security properties (issuer URI, audience)
- `src/main/resources/application-local.yml` — `security.enabled=false`
- `src/main/resources/application-test.yml` — `security.enabled=false`

## Files in scope

- `build.gradle.kts` — add security and actuator dependencies
- `src/main/kotlin/com/webtransaction/microsite/config/SecurityConfig.kt`
- `src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt` — extend from WTR-4
- `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt` — add @PreAuthorize annotations
- `src/main/resources/application.yml`
- `src/main/resources/application-local.yml`
- `src/main/resources/application-test.yml`
- `src/test/kotlin/com/webtransaction/microsite/config/SecurityConfigTests.kt`
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt`

## Plan Steps

### Step 1: Add security and actuator dependencies
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: No standalone test for dependency addition. Verified in Step 3+ when security classes compile and tests reference Spring Security annotations. Add `spring-boot-starter-security`, `spring-boot-starter-oauth2-resource-server`, `spring-boot-starter-actuator` to `dependencies` block. Add `spring-security-test` to `testImplementation`.

### Step 2: Create application properties files
- Test mode: `test-after`
- Files: `src/main/resources/application.yml`, `src/main/resources/application-local.yml`, `src/main/resources/application-test.yml`
- Test strategy: No standalone test for properties files. Verified in Step 6 when integration tests load profiles and security is conditionally disabled. `application.yml` sets `spring.security.oauth2.resourceserver.jwt.issuer-uri` (placeholder `https://auth.example.com`), `spring.security.oauth2.resourceserver.jwt.audiences=web-transaction-api`, `management.endpoints.web.exposure.include=health,info`, `management.info.git.mode=full`, `security.enabled=true`. `application-local.yml` and `application-test.yml` set `security.enabled=false`.

### Step 3: Create SecurityConfig
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/config/SecurityConfig.kt`, `src/test/kotlin/com/webtransaction/microsite/config/SecurityConfigTests.kt`
- Test strategy: Write `SecurityConfigTests` using `@SpringBootTest` and `@TestPropertySource` to verify security filter chain is registered when `security.enabled=true` and skipped when `security.enabled=false`. Use `MockMvc` to test that `/actuator/health` and `/actuator/info` are accessible without JWT (return 200), while `/v1/webtransaction/**` returns 401 without JWT. `SecurityConfig` is a `@Configuration` class annotated with `@ConditionalOnProperty(name = "security.enabled", havingValue = "true", matchIfMissing = true)` and `@EnableMethodSecurity(prePostEnabled = true)`. Defines a `SecurityFilterChain` bean with `oauth2ResourceServer { jwt {} }` configuration and permits `/actuator/health`, `/actuator/info` while requiring authentication for all other requests.

### Step 4: Update GlobalExceptionHandler for security exceptions
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt` (extend from WTR-4)
- Test strategy: Extend WTR-4's `GlobalExceptionHandler` to handle `AccessDeniedException` (403 Forbidden) and `AuthenticationException` (401 Unauthorized). Write tests in `SecurityConfigTests` that trigger these exceptions via MockMvc and verify response structure matches `{ "error": "<message>" }`. Also add handler for `HttpMessageNotReadableException` (400 Bad Request) with sanitized message (spec requirement for malformed JSON/invalid enum values).

### Step 5: Add @PreAuthorize annotations to controller methods
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt`
- Test strategy: Write `WebTransactionControllerSecurityTests` using `@WebMvcTest` with `@WithMockUser` (from `spring-security-test`) to simulate JWT tokens with different scopes. Test that GET endpoints require `SCOPE_read:web-transaction` authority, POST/PUT endpoints require `SCOPE_write:web-transaction` authority. Verify 403 responses when scope is insufficient, 200/201 when scope is sufficient. Annotate `WebTransactionController` GET methods with `@PreAuthorize("hasAuthority('SCOPE_read:web-transaction')")` and POST/PUT methods with `@PreAuthorize("hasAuthority('SCOPE_write:web-transaction')")`.

### Step 6: Test actuator endpoints accessibility
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/config/SecurityConfigTests.kt` (extend from Step 3)
- Test strategy: Add tests to `SecurityConfigTests` verifying `/actuator/health` returns 200 with `{"status":"UP"}` structure and `/actuator/info` returns 200 with git metadata (if `git.properties` exists; mock or stub this file in test resources). Both endpoints must be accessible without JWT authentication. Test uses `MockMvc` with no `Authorization` header.

### Step 7: Test security disabled in test profile
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/config/SecurityConfigTests.kt` (extend from Step 6)
- Test strategy: Add test class with `@ActiveProfiles("test")` verifying all endpoints (including `/v1/webtransaction/**`) are accessible without JWT when `security.enabled=false`. Use MockMvc to verify 200 responses for GET/POST requests with no `Authorization` header. This ensures existing WTR-4 controller tests (which do not mock JWTs) continue to pass after security is added.

### Step 8: Test 401/403 error response structure
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt` (extend from Step 5)
- Test strategy: Add tests verifying unauthenticated requests (no JWT) return 401 with `{ "error": "Unauthorized" }` and authenticated requests with insufficient scope return 403 with `{ "error": "Access denied" }`. Use MockMvc with no `Authorization` header (401 case) and `@WithMockUser` with wrong scope (403 case). Verify JSON response structure matches spec (no extra fields).

### Step 9: Test HttpMessageNotReadableException handling
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt` (extend from Step 8)
- Test strategy: Add test sending malformed JSON (e.g., `{"reference": 123}` where reference is a string field) to POST endpoint. Verify 400 response with `{ "error": "Malformed JSON request" }` (sanitized message, no stack trace). Test invalid enum value (e.g., `{"transactionType": "INVALID"}`) returns 400. Extend `GlobalExceptionHandler` to catch `HttpMessageNotReadableException` and return 400 with sanitized error message.

### Step 10: Integration test with mocked JWT validation
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt` (extend from Step 9)
- Test strategy: Add comprehensive integration test using `@SpringBootTest` with `@AutoConfigureMockMvc` and custom `JwtDecoder` bean (mocked via `@TestConfiguration`) that returns a valid `Jwt` object with scopes in the `scope` claim. Test end-to-end flow: mock JWT with `read:web-transaction` scope can GET but cannot POST (403), mock JWT with `write:web-transaction` scope can POST/PUT but cannot GET (403 — or can GET if write implies read; clarify in implementation), mock JWT with both scopes can perform all operations. Verify all acceptance criteria: 401 without JWT, 403 with insufficient scope, 200/201 with sufficient scope, error response formats, actuator endpoints accessible without JWT.

## Risks

- **JWT issuer URI placeholder**: `application.yml` uses placeholder `https://auth.example.com` which will fail in real deployments. Mitigation: document that environment-specific `JWT_ISSUER_URI` environment variable must be set in deployment configs (K8s ConfigMap, AWS SSM Parameter Store, etc.). Flag this requirement in deployment docs.
- **Scope claim format variation**: Different OAuth2 providers format scopes differently (space-delimited string `scope: "read:web-transaction write:web-transaction"` vs. array `scope: ["read:web-transaction", "write:web-transaction"]`). Spring Security's `JwtGrantedAuthoritiesConverter` handles both by default, but custom converters may be needed for non-standard claims. Mitigation: Step 10 tests use standard format; if real issuer uses custom format, add custom `JwtAuthenticationConverter` bean in SecurityConfig.
- **Audience claim validation failure**: If the OAuth2 provider does not include `aud` claim or uses a different audience value, JWT validation will fail. Mitigation: make audience validation optional via property `spring.security.oauth2.resourceserver.jwt.audiences` (can be empty list to disable). Document this configuration option.
- **Actuator endpoint exposure in production**: Exposing `/actuator/info` may leak git commit hash and build metadata. Mitigation: this is standard practice for operational visibility; if sensitive, restrict actuator endpoints to internal network via infrastructure (e.g., K8s NetworkPolicy). Flag this in security review.
- **Method security performance overhead**: `@PreAuthorize` evaluates SpEL expressions on every request, adding ~1-5ms latency per call. Mitigation: acceptable for this use case (transactional API, not high-throughput streaming). If performance becomes an issue, consider moving to URL-based authorization in `SecurityFilterChain`.
- **Test profile security bypass**: `security.enabled=false` in test profile means integration tests do not validate JWT validation logic. Mitigation: Step 10 includes integration test with mocked `JwtDecoder` that runs with security enabled, verifying JWT flow end-to-end.

## Out-of-Plan (deferred)

- **Multi-issuer support**: Only one issuer per environment. Supporting multiple issuers (e.g., Auth0 + Cognito) requires custom `JwtDecoder` bean with issuer validation logic. Deferred.
- **Custom JWT claims extraction**: Scope extraction assumes standard `scope` claim. If provider uses custom claim (e.g., `permissions`, `roles`), custom `JwtAuthenticationConverter` required. Deferred.
- **Token refresh logic**: Out-of-scope per spec. Clients must obtain new JWT from identity provider when token expires.
- **CORS configuration**: Not required for OAuth2 resource server (CORS is typically handled by API gateway or frontend proxy). If needed, add `@CrossOrigin` or CORS filter. Deferred.
- **Data-level authorization**: Scope-based checks only (read/write). Tenant isolation, row-level security, or user-specific data filtering not implemented. Deferred.
- **Database health checks**: Actuator `/health` returns simple UP/DOWN. No database connectivity check or custom health indicators. Can be added via custom `HealthIndicator` bean if needed. Deferred.
- **Custom actuator metrics**: Only `/health` and `/info` exposed. Custom metrics (request counts, latency percentiles) not implemented. Deferred.
- **Rate limiting**: No throttling or rate limit enforcement at application level. Assumed to be handled by API gateway (e.g., AWS API Gateway, Kong). Deferred.
- **Integration tests with live identity provider**: Tests use mocked `JwtDecoder`. Live OAuth2 flow testing (with real Auth0/Cognito) deferred to E2E test suite outside application codebase.
- **Session management**: Stateless JWT validation only. No session store, no logout endpoint. Deferred.
- **Authorization audit logging**: No logging of authorization decisions (who accessed what, when). Can be added via custom Spring Security event listeners. Deferred.
- **Git properties plugin configuration**: Assumes `git.properties` file is generated at build time. Requires Gradle plugin (`com.gorylenko.gradle-git-properties`) configuration in `build.gradle.kts`. If not already configured, add plugin in this step or defer to build pipeline setup. For this plan, assume plugin is added in Step 1 (dependency step), but if out-of-scope for implementation phase, document as deployment prerequisite.
