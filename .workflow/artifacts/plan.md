---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-5
job_id: wtr-5-tdo4bz
---

# WTR-5 — Implementation plan

## Approach

This plan secures the Web Transaction API with JWT-based OAuth2 using Spring Security's Resource Server support, following a defense-in-depth strategy with both HTTP-level and method-level authorization. The implementation adds JWT validation, scope-based access control (`read:web-transaction` for GET, `write:web-transaction` for POST/PUT), and operational endpoints via Spring Boot Actuator.

The architecture follows Spring Security best practices:
- **SecurityConfiguration** — HTTP security with JWT decoder and public/protected path rules
- **ConditionalSecurityConfiguration** — Disables security in local/test profiles via `security.enabled=false`
- **Method-level security** — `@PreAuthorize` annotations on controller methods enforce scope checks
- **Actuator endpoints** — `/actuator/health` and `/actuator/info` exposed without authentication
- **Git build info** — Generated via Spring Boot Gradle plugin (`spring-boot-gradle-plugin` with `git-properties`)

**Resolving spec ambiguities:**
- **Issuer configuration:** Use placeholder issuer URI `https://auth.example.com/oauth2/default` in main config; document that real issuer URIs should be set via environment-specific profiles (application-dev.yml, application-staging.yml, application-prod.yml not created in this plan — deployment concern)
- **Multi-issuer support:** Single issuer per environment (Spring Security's default JwtDecoder supports one issuer; multi-issuer requires custom configuration out of scope)
- **Audience validation:** Use literal `https://web-transaction-api` as audience claim validation (can be overridden per environment via property)
- **Scope protection:** Method-level `@PreAuthorize("hasAuthority('SCOPE_read:web-transaction')")` on GET methods, `@PreAuthorize("hasAuthority('SCOPE_write:web-transaction')")` on POST/PUT
- **Error response format:** Keep current format (error/details only) per existing GlobalExceptionHandler — no timestamp/path/status added (YAGNI)
- **Git build info:** Use `spring-boot-gradle-plugin`'s built-in git-properties task (adds git commit/branch to /actuator/info)

The custom `/health` endpoint in HealthController will be **deleted** — Spring Actuator's `/actuator/health` is the standard operational endpoint and already configured in application.yml.

Security is conditionally enabled: when `security.enabled=false` (local/test profiles), the SecurityConfiguration is not loaded, and all endpoints are accessible. When enabled (default), JWT validation is enforced.

GlobalExceptionHandler already handles `EntityNotFoundException` (404), `MethodArgumentNotValidException` (400 with details), and `HttpMessageNotReadableException` (400) — no changes needed. Added handler for `AccessDeniedException` (403) to match OAuth2 authorization failures.

Tests use Spring Security Test's `@WithMockUser` with scopes for authenticated scenarios and verify 401/403 responses for unauthorized/forbidden cases. Security is disabled in test profile via `security.enabled=false`.

## Files in scope

- `build.gradle.kts` (add Spring Security OAuth2 Resource Server dependencies, enable git-properties generation)
- `src/main/resources/application.yml` (add security configuration, update actuator exposure)
- `src/main/resources/application-local.yml` (disable security for local dev)
- `src/test/resources/application.yml` (disable security for tests)
- `src/test/resources/application-test.yml` (disable security for tests)
- `src/main/kotlin/com/webtransaction/microsite/Application.kt` (add `@EnableMethodSecurity`)
- `src/main/kotlin/com/webtransaction/microsite/config/SecurityConfiguration.kt` (new file)
- `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt` (add `@PreAuthorize` annotations)
- `src/main/kotlin/com/webtransaction/microsite/controller/GlobalExceptionHandler.kt` (add `AccessDeniedException` handler)
- `src/main/kotlin/com/webtransaction/microsite/controller/HealthController.kt` (DELETE this file — replaced by actuator)
- `src/test/kotlin/com/webtransaction/microsite/controller/HealthControllerTests.kt` (DELETE this file)
- `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt` (new file)
- `src/test/kotlin/com/webtransaction/microsite/controller/ActuatorEndpointsTests.kt` (new file)

## Plan Steps

### Step 1: Add Spring Security OAuth2 Resource Server dependencies and configure git-properties
- Test mode: `test-after`
- Files: `build.gradle.kts`
- Test strategy: Run `./gradlew build` and verify dependencies resolve (`org.springframework.boot:spring-boot-starter-oauth2-resource-server`, `org.springframework.security:spring-security-test`). Verify git.properties is generated in build/resources/main via `./gradlew processResources`. No new automated tests — dependency resolution verification.

### Step 2: Configure security properties and disable for local/test profiles
- Test mode: `test-after`
- Files: `src/main/resources/application.yml`, `src/main/resources/application-local.yml`, `src/test/resources/application.yml`, `src/test/resources/application-test.yml`
- Test strategy: Verify application starts with security enabled (default profile) via `./gradlew bootRun` and requires JWT. Verify application starts with security disabled via `SPRING_PROFILES_ACTIVE=local ./gradlew bootRun` and endpoints are public. Run existing test suite with `./gradlew test` and confirm tests pass (security disabled in test profile). Manual verification — no new automated tests.

### Step 3: Create SecurityConfiguration with JWT decoder and path authorization
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/config/SecurityConfiguration.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/ActuatorEndpointsTests.kt`
- Test strategy: Write actuator endpoint tests using `@SpringBootTest` with `webEnvironment = RANDOM_PORT` and security enabled via `@TestPropertySource(properties = ["security.enabled=true"])`. Test `/actuator/health` returns 200 without JWT (permitAll). Test `/actuator/info` returns 200 without JWT and includes git info. Test `/v1/webtransaction/**` returns 401 without JWT. Coverage: 100% on SecurityConfiguration conditional loading (via integration test exercising both enabled/disabled states).

### Step 4: Enable method-level security and add scope-based authorization to controller
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/Application.kt`, `src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt`
- Test strategy: Write security tests using `@WebMvcTest` with `GlobalExceptionHandler` and security enabled. Use `@WithMockUser(authorities = ["SCOPE_read:web-transaction"])` to test GET methods return 200. Use `@WithMockUser(authorities = ["SCOPE_write:web-transaction"])` to test POST/PUT return 201/200. Test GET with write-only scope returns 403. Test POST with read-only scope returns 403. Test unauthenticated request returns 401. Coverage: 100% on controller authorization paths.

### Step 5: Add AccessDeniedException handler to GlobalExceptionHandler
- Test mode: `tdd`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/GlobalExceptionHandler.kt`, `src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt`
- Test strategy: Extend security tests to verify `AccessDeniedException` (thrown when scope check fails) returns 403 with JSON body `{ "error": "Access denied" }`. Test via authenticated request with insufficient scope. Coverage: 100% on new exception handler.

### Step 6: Delete custom HealthController and update actuator exposure configuration
- Test mode: `test-after`
- Files: `src/main/kotlin/com/webtransaction/microsite/controller/HealthController.kt` (DELETE), `src/test/kotlin/com/webtransaction/microsite/controller/HealthControllerTests.kt` (DELETE), `src/main/resources/application.yml`
- Test strategy: Run `./gradlew test` and verify no tests reference custom HealthController. Run actuator endpoint tests from Step 3 to confirm `/actuator/health` and `/actuator/info` work. Manual verification with curl against running app. Coverage: actuator endpoints validated via tests in Step 3.

### Step 7: Integration verification with security enabled
- Test mode: `test-after`
- Files: All files in scope
- Test strategy: Run `./gradlew build` and verify all tests pass. Run `./gradlew jacocoTestCoverageVerification` and confirm ≥95% coverage. Run `./gradlew ktlintCheck detekt` and verify zero violations. Start application with security enabled and test with curl: (1) GET without JWT returns 401, (2) POST with JWT but no scope returns 403, (3) GET with JWT + `read:web-transaction` scope returns 200, (4) POST with JWT + `write:web-transaction` scope returns 201, (5) `/actuator/health` without JWT returns 200, (6) `/actuator/info` without JWT returns 200 with git commit hash.

## Risks

- **JWT validation in tests**: Mocking JWT validation with `@WithMockUser` bypasses real decoder logic. Mitigation: Integration test in Step 7 manually tests with real JWT (generated via test issuer or manually crafted) to verify decoder configuration.
- **Scope claim format**: OAuth2 providers encode scopes differently (space-delimited string vs array). Mitigation: Spring Security's default `JwtGrantedAuthoritiesConverter` handles standard `scope` claim (space-delimited); document that custom claim extraction (e.g., Azure AD `scp`) requires custom converter.
- **Issuer placeholder**: Default issuer URI is example.com placeholder. Mitigation: Document in application.yml comment that issuer must be overridden per environment; application will fail to start if issuer is unreachable (fail-fast behavior).
- **Actuator security**: `/actuator/health` and `/actuator/info` are public; sensitive endpoints (e.g., /actuator/env) not exposed per management.endpoints.web.exposure.include. Mitigation: Explicitly list only health and info in exposure config.
- **Method security overhead**: `@PreAuthorize` on every controller method. Mitigation: Standard Spring Security pattern; no performance concern for REST endpoints (auth happens once per request).
- **Test profile confusion**: Multiple test profiles (`test`, `application.yml` in test/resources). Mitigation: Consolidate security.enabled=false in both src/test/resources/application.yml and application-test.yml to ensure security is disabled regardless of active profile in tests.

## Out-of-Plan (deferred)

- **Multi-issuer support**: Single issuer per environment. Multi-issuer (e.g., Auth0 + Cognito) requires custom `JwtDecoder` bean with issuer validation logic — future ticket.
- **Audience validation**: Basic audience claim check via `spring.security.oauth2.resourceserver.jwt.audiences` property. Custom audience validation logic (multiple audiences, dynamic audience) deferred.
- **Custom actuator metrics**: Only /health and /info exposed. Custom metrics (e.g., transaction count, reconciliation status distribution) out of scope.
- **Database health indicator**: Actuator's default health shows only UP/DOWN; database connection health check via `management.health.db.enabled=true` deferred (requires DB config validation).
- **CORS configuration**: Not added in this plan. If frontend needs CORS, add `CorsConfiguration` in SecurityConfiguration in future ticket.
- **Integration tests with live JWT issuer**: Tests use `@WithMockUser`; end-to-end test with real OAuth2 flow (token acquisition + validation) deferred to E2E test suite.
- **Tenant isolation**: Authorization is scope-based only; data-level filtering (e.g., user can only access their own transactions) out of scope.
- **Rate limiting**: No rate limiting or throttling added; deferred to API gateway layer.
- **Audit logging**: No audit trail of authentication/authorization events; Spring Security's default logs authentication failures, but structured audit logging deferred.
- **Environment-specific issuer config**: application-dev.yml, application-staging.yml, application-prod.yml not created; deployment concern for infrastructure team.
- **JWT claim extraction**: Assumes standard `scope` claim; custom claim mapping (e.g., roles from `groups` claim) deferred.
- **Security headers**: Spring Security defaults enabled (X-Frame-Options, X-Content-Type-Options, etc.); custom CSP or HSTS config deferred.
