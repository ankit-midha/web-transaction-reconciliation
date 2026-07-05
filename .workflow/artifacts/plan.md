---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-5
job_id: wtr-5-r3k041
---

# WTR-5 — Implementation plan

## Approach

This plan adds OAuth2 JWT-based security, enhances exception handling, and exposes Spring Actuator endpoints to the Web Transaction Store API. Building on WTR-4's REST controller foundation, this ticket secures all transaction endpoints with scope-based authorization (`read:web-transaction`, `write:web-transaction`), standardizes error responses across all exception types, and enables operational monitoring via `/health` and `/info`.

To resolve the spec's open questions, this plan makes the following decisions aligned with Spring Boot and OAuth2 best practices:

- **JWT issuer configuration**: Use Spring Security's `spring.security.oauth2.resourceserver.jwt.issuer-uri` property with environment-specific values in `application-{profile}.yml` files. The plan assumes a single issuer per environment (dev/staging/prod). Multi-issuer support is deferred (can be added via custom `JwtDecoder` bean if needed).
- **Audience validation**: Not enforced by default in Spring Security's JWT validation. If required, add custom `JwtDecoder` with audience claim validation — deferred to out-of-plan unless explicitly required by identity provider.
- **Scope checking strategy**: Apply `@PreAuthorize` annotations at controller method level for fine-grained control. GET endpoints require `read:web-transaction` scope, POST/PUT require `write:web-transaction` scope. This is explicit and auditable.
- **Error response format**: Use minimal format per spec: `{"error": "..."}` for simple errors, `{"error": "...", "details": {...}}` for validation errors. No `timestamp` or `path` fields to keep responses concise. Status codes convey HTTP semantics.
- **Git build info**: Use Spring Boot Actuator's built-in git info integration via `spring-boot-maven-plugin` or `gradle-git-properties` plugin (assumes Gradle based on Kotlin usage). Plugin auto-generates `git.properties` at build time, exposed via `/info`.
- **Security toggle**: Use custom `security.enabled` property (defaults to `true`). When `false`, security configuration is skipped entirely via `@ConditionalOnProperty`. Local and test profiles set `security.enabled=false`.
- **Exception handler enhancements**: Extend WTR-4's `GlobalExceptionHandler` to handle `HttpMessageNotReadableException` (malformed JSON, invalid enums) → 400. Add `AccessDeniedException` → 403 and authentication exceptions → 401. Ensure validation error format matches spec exactly.

The security configuration uses Spring Security 6.x `SecurityFilterChain` bean pattern (no `WebSecurityConfigurerAdapter` — deprecated). JWT validation is delegated to `spring-boot-starter-oauth2-resource-server` with minimal custom configuration. Method-level security is enabled via `@EnableMethodSecurity(prePostEnabled = true)` on the security config class.

Actuator endpoints are exposed via `management.endpoints.web.exposure.include=health,info` in `application.yml`. Security configuration explicitly permits `/health` and `/info` without authentication. All other `/actuator/*` endpoints remain secured/disabled.

Package structure (extending WTR-4's `com.webtransaction.microsite.*`):
- `com.webtransaction.microsite.config.SecurityConfig` (new)
- `com.webtransaction.microsite.exception.GlobalExceptionHandler` (enhance existing from WTR-4)
- `src/main/resources/application.yml` (add actuator config)
- `src/main/resources/application-local.yml` (new — `security.enabled=false`)
- `src/main/resources/application-test.yml` (new — `security.enabled=false`)
- `src/main/resources/application-dev.yml` (new — JWT issuer for dev)
- `src/main/resources/application-staging.yml` (new — JWT issuer for staging)
- `src/main/resources/application-prod.yml` (new — JWT issuer for prod)
- Modify `WebTransactionController.kt` to add `@PreAuthorize` annotations

Dependencies to add in `build.gradle.kts`:
- `spring-boot-starter-oauth2-resource-server` (JWT validation)
- `spring-boot-starter-actuator` (health/info endpoints)
- `com.gorylenko.gradle-git-properties` plugin (git info generation)

Test strategy: Spring Security test support (`@WithMockUser`) for unit tests. Mock JWT claims with appropriate scopes. Integration tests with `@AutoConfigureMockMvc` and `MockMvc` perform requests with/without JWT headers. Actuator endpoints tested via direct HTTP calls (no auth required). Exception handler tested by triggering each exception type and verifying response structure.

## Files in scope

- `build.gradle.kts` (add dependencies and git-properties plugin)
- `src/main/kotlin/com/webtransaction/microsite/config/SecurityConfig.kt` (new)
- `src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt` (enhance existing)
- `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt` (add @PreAuthorize annotations)
- `src/main/resources/application.yml` (add actuator and security config)
- `src/main/resources/application-local.yml` (new)
- `src/main/resources/application-test.yml` (new)
- `src/main/resources/application-dev.yml` (new)
- `src/main/resources/application-staging.yml` (new)
- `src/main/resources/application-prod.yml` (new)
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/config/SecurityConfigTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt` (new)
- `src/test/kotlin/com/webtransaction/microsite/ActuatorEndpointsTests.kt` (new)

## Plan Steps

### Step 1: Add dependencies and git-properties plugin to build.gradle.kts
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: No direct test. Verify by running `./gradlew build` successfully after changes. Plugin generates `build/resources/main/git.properties` at build time.

### Step 2: Create base application.yml with actuator and security defaults
- Test mode: `test-after`
- Files: `src/main/resources/application.yml`
- Test strategy: No direct test. Configuration is validated when Spring Boot application starts. Verify actuator config: `management.endpoints.web.exposure.include=health,info` and `security.enabled=true` (default).

### Step 3: Create profile-specific application-*.yml files
- Test mode: `test-after`
- Files: `src/main/resources/application-local.yml`, `application-test.yml`, `application-dev.yml`, `application-staging.yml`, `application-prod.yml`
- Test strategy: No direct test. Profile-specific properties override base `application.yml`. Local/test profiles disable security. Dev/staging/prod profiles define JWT issuer URIs (placeholders initially — actual URIs to be provided via environment variables or external config in real deployments).

### Step 4: Create SecurityConfig with JWT validation and permit-all for actuator
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/config/SecurityConfig.kt`, `src/test/kotlin/com/webtransaction/microsite/config/SecurityConfigTests.kt`
- Test strategy: Write `SecurityConfigTests` using `@SpringBootTest` with `webEnvironment = MOCK` and `MockMvc`. Test: `/health` and `/info` accessible without auth (200), transaction endpoints require auth (401 without JWT), security disabled when `security.enabled=false` (all endpoints accessible). Use `@ActiveProfiles("test")` to verify security-disabled behavior. Use Spring Security test utilities to mock JWT tokens with scopes. Verify `@ConditionalOnProperty("security.enabled", havingValue = "true", matchIfMissing = true)` annotation on config class.

### Step 5: Enhance GlobalExceptionHandler for additional exception types
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt`, `src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt`
- Test strategy: Write `GlobalExceptionHandlerTests` using `@WebMvcTest` with a test controller that throws exceptions. Test new handlers: `HttpMessageNotReadableException` → 400 with `{"error": "Invalid request format"}` (sanitized message, no stack trace), `AccessDeniedException` → 403 with `{"error": "Forbidden"}`, `AuthenticationException` → 401 with `{"error": "Unauthorized"}`. Re-verify existing handlers from WTR-4 still work: `EntityNotFoundException` → 404, `MethodArgumentNotValidException` → 400 with details. Ensure response bodies match spec format exactly (no extra fields).

### Step 6: Add @PreAuthorize annotations to WebTransactionController methods
- Test mode: `test-after`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`
- Test strategy: No new standalone test file. Security enforcement is verified in Step 7 (controller security tests). Annotations: `@PreAuthorize("hasAuthority('read:web-transaction')")` on GET endpoints, `@PreAuthorize("hasAuthority('write:web-transaction')")` on POST/PUT endpoints. Controller class must NOT have `@PreAuthorize` (would apply to all methods) — only method-level annotations.

### Step 7: Create WebTransactionControllerSecurityTests for scope enforcement
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt`
- Test strategy: Write integration tests using `@SpringBootTest` with `webEnvironment = RANDOM_PORT` and `TestRestTemplate` or `@AutoConfigureMockMvc` with `MockMvc`. Mock the service layer. Test matrix: (1) No JWT header → 401 on all protected endpoints, (2) Valid JWT with `read:web-transaction` scope → 200 on GET, 403 on POST/PUT, (3) Valid JWT with `write:web-transaction` scope → 201/200 on POST/PUT, 403 on GET (write-only scenario — though typically write implies read), (4) Valid JWT with both scopes → all endpoints accessible. Use Spring Security's `@WithMockUser` or `jwt()` DSL in `MockMvc` to inject JWT claims. Verify response status codes and error body structure.

### Step 8: Create ActuatorEndpointsTests for /health and /info
- Test mode: `tdd`
- Files: `src/test/kotlin/com/webtransaction/microsite/ActuatorEndpointsTests.kt`
- Test strategy: Write tests using `@SpringBootTest` with `MockMvc`. Test: (1) `GET /health` returns 200 with `{"status": "UP"}` structure (Spring Actuator default), accessible without auth, (2) `GET /info` returns 200 with JSON body containing `git.commit.id`, `git.branch`, `git.commit.time` fields (verify git.properties content is exposed), accessible without auth. Test with security enabled (main profile) to confirm actuator endpoints are not blocked by security config.

### Step 9: End-to-end validation — security enabled and disabled profiles
- Test mode: `tdd`
- Files: All test files from Steps 4, 5, 7, 8
- Test strategy: Run full test suite with `@ActiveProfiles("test")` (security disabled) and default profile (security enabled). Verify: (1) Test profile allows all requests without JWT, (2) Default profile enforces JWT and scopes as specified. Add edge cases: JWT with wrong audience (should still pass if audience validation not enabled — note this in test comments), expired JWT (401), JWT with no scopes (403 on all protected endpoints), malformed Authorization header (401). Ensure all acceptance criteria are covered.

## Risks

- **JWT issuer URI unavailability**: If the configured issuer URI is unreachable or returns 404 during application startup, Spring Security fails to initialize and the app won't start. Mitigation: Use environment-specific placeholder URIs in YAML, override with actual values via environment variables at deployment time. Document this in code comments.
- **Scope claim format mismatch**: OAuth2 providers encode scopes differently — some use `scope` claim as space-delimited string (`"read:web-transaction write:web-transaction"`), others use `scp` or `permissions` array. Spring Security defaults to `scope` claim. If provider uses different format, custom `JwtAuthenticationConverter` is needed. Mitigation: Step 7 tests will catch this early; plan assumes standard `scope` claim. Document deviation handling in out-of-plan.
- **Actuator exposure in prod**: Accidentally exposing all actuator endpoints (not just `/health` and `/info`) leaks sensitive internal metrics. Mitigation: Explicitly list `health,info` in `management.endpoints.web.exposure.include`, not `*`. Add test in Step 8 to verify other actuator endpoints (e.g., `/actuator/env`, `/actuator/beans`) return 404 or 401.
- **Security disabled in prod**: If `security.enabled=false` is mistakenly set in prod profile, all endpoints become public. Mitigation: Default is `true` (`matchIfMissing = true` in `@ConditionalOnProperty`), so explicit override is required to disable. Prod YAML file explicitly sets `security.enabled=true` as documentation (even though it's the default).
- **CORS preflight failures**: If frontend clients send CORS preflight requests (OPTIONS), JWT is typically not included in OPTIONS. Spring Security blocks OPTIONS by default. Mitigation: Out-of-scope per spec. If needed later, add `.authorizeHttpRequests { it.requestMatchers(HttpMethod.OPTIONS, "/**").permitAll() }` to security config.
- **Method security not enabled**: If `@EnableMethodSecurity(prePostEnabled = true)` is missing from `SecurityConfig`, `@PreAuthorize` annotations are silently ignored (no enforcement). Mitigation: Step 7 tests explicitly verify scope enforcement; test failure indicates missing annotation. Add test comment documenting this risk.

## Out-of-Plan (deferred)

- **Multi-issuer support**: Spec open question #2 mentions potential for multiple issuers (Auth0 + Cognito). Spring Security supports this via custom `JwtDecoder` that chains multiple `NimbusJwtDecoder` instances. Deferred — requires knowing exact issuer list and priority order.
- **Audience claim validation**: Spec open question #3 asks about audience validation. Spring Security's default JWT decoder does not validate `aud` claim. Custom `JwtDecoder` with `OAuth2TokenValidator` is needed. Deferred — implement if identity provider requires audience validation.
- **CORS configuration**: Spec explicitly out-of-scope. If frontend clients need CORS, add `CorsConfigurationSource` bean in `SecurityConfig` with `allowedOrigins`, `allowedMethods`, `allowedHeaders`.
- **Token refresh endpoint**: Out-of-scope per spec. Assuming external identity provider handles token issuance and refresh.
- **Tenant isolation or row-level security**: Out-of-scope per spec. Authorization is scope-based only, not data-filtered. All authenticated users with correct scope can access all transactions.
- **Rate limiting**: Out-of-scope per spec. No throttling or quota enforcement on endpoints.
- **Custom actuator metrics**: Out-of-scope per spec. Only `/health` and `/info` exposed. No custom metrics (e.g., request count, response time) or custom health indicators (e.g., database connectivity check).
- **Integration tests with live JWT issuer**: Spec explicitly defers this. Tests use mocked JWT claims via Spring Security test support. No real OAuth2 server or test identity provider.
- **Database health indicator**: Spec non-goal mentions "database health checks" are excluded. Default Spring Actuator `/health` includes database health if datasource is configured — this plan leaves default behavior (will show DB health if datasource exists). No custom database health checks added.
- **Non-standard scope claim formats**: If identity provider uses `scp`, `permissions`, or other non-standard claim names, custom `JwtAuthenticationConverter` is required to map claims to `GrantedAuthority` objects. Deferred — plan assumes standard `scope` claim per OAuth2 spec.
- **JWT signing algorithm constraints**: Plan assumes issuer uses RS256 (RSA signature). If issuer uses HS256 (HMAC), `JwtDecoder` configuration must change (shared secret instead of public key). Deferred — RS256 is OAuth2 best practice for public clients.
- **Session management**: Spec out-of-scope mentions no session management. This plan is stateless (JWT per-request). No HTTP sessions created. `SessionCreationPolicy.STATELESS` is set in security config.
- **Role-based access control (RBAC)**: Only scope-based checks implemented. No role hierarchy or role-to-permission mapping. If roles are needed (e.g., `ROLE_ADMIN` can bypass scopes), custom `JwtAuthenticationConverter` with role extraction logic is required. Deferred.
