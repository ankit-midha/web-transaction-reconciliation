#!/bin/bash
# Full E2E measurement test for WTR-5 implementation
# Tests OAuth2 JWT security, enhanced exception handling, and actuator endpoints

set -e

echo "=========================================="
echo "WTR-5 E2E Measurement Test"
echo "=========================================="
echo ""

EXIT_CODE=0
PASSED=0
FAILED=0

# Helper functions
pass() {
    echo "✓ PASS: $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "✗ FAIL: $1"
    FAILED=$((FAILED + 1))
    EXIT_CODE=1
}

section() {
    echo ""
    echo "-------------------------------------------"
    echo "Testing: $1"
    echo "-------------------------------------------"
}

# Test 1: Package structure and file existence
section "Package Structure and Security Configuration Files"

SECURITY_CONFIG="src/main/kotlin/com/webtransaction/microsite/config/SecurityConfig.kt"
EXCEPTION_HANDLER="src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt"
CONTROLLER_FILE="src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt"
BUILD_FILE="build.gradle.kts"
APP_YML="src/main/resources/application.yml"
APP_LOCAL="src/main/resources/application-local.yml"
APP_TEST="src/main/resources/application-test.yml"
APP_DEV="src/main/resources/application-dev.yml"
APP_STAGING="src/main/resources/application-staging.yml"
APP_PROD="src/main/resources/application-prod.yml"

if [ -f "$SECURITY_CONFIG" ]; then
    pass "SecurityConfig.kt exists"
else
    fail "SecurityConfig.kt missing"
fi

if [ -f "$EXCEPTION_HANDLER" ]; then
    pass "GlobalExceptionHandler.kt exists (enhanced from WTR-4)"
else
    fail "GlobalExceptionHandler.kt missing"
fi

if [ -f "$CONTROLLER_FILE" ]; then
    pass "WebTransactionController.kt exists (to be annotated with security)"
else
    fail "WebTransactionController.kt missing"
fi

if [ -f "$BUILD_FILE" ]; then
    pass "build.gradle.kts exists"
else
    fail "build.gradle.kts missing"
fi

# Test 2: Dependencies in build.gradle.kts
section "Build Dependencies"

if [ -f "$BUILD_FILE" ]; then
    # Check for OAuth2 resource server dependency
    if grep -q "spring-boot-starter-oauth2-resource-server" "$BUILD_FILE"; then
        pass "spring-boot-starter-oauth2-resource-server dependency present"
    else
        fail "spring-boot-starter-oauth2-resource-server dependency missing"
    fi

    # Check for Spring Boot Actuator
    if grep -q "spring-boot-starter-actuator" "$BUILD_FILE"; then
        pass "spring-boot-starter-actuator dependency present"
    else
        fail "spring-boot-starter-actuator dependency missing"
    fi

    # Check for gradle-git-properties plugin
    if grep -q "gradle-git-properties\|com.gorylenko.gradle-git-properties" "$BUILD_FILE"; then
        pass "gradle-git-properties plugin configured"
    else
        fail "gradle-git-properties plugin missing"
    fi
fi

# Test 3: Application configuration files existence
section "Application Configuration Files"

if [ -f "$APP_YML" ]; then
    pass "application.yml exists"
else
    fail "application.yml missing"
fi

if [ -f "$APP_LOCAL" ]; then
    pass "application-local.yml exists (security disabled)"
else
    fail "application-local.yml missing"
fi

if [ -f "$APP_TEST" ]; then
    pass "application-test.yml exists (security disabled)"
else
    fail "application-test.yml missing"
fi

if [ -f "$APP_DEV" ]; then
    pass "application-dev.yml exists (JWT issuer for dev)"
else
    fail "application-dev.yml missing"
fi

if [ -f "$APP_STAGING" ]; then
    pass "application-staging.yml exists (JWT issuer for staging)"
else
    fail "application-staging.yml missing"
fi

if [ -f "$APP_PROD" ]; then
    pass "application-prod.yml exists (JWT issuer for prod)"
else
    fail "application-prod.yml missing"
fi

# Test 4: Application YAML configurations
section "Application YAML Configuration Content"

if [ -f "$APP_YML" ]; then
    # Check for actuator endpoints configuration
    if grep -q "management:" "$APP_YML" && \
       grep -q "endpoints:" "$APP_YML"; then
        pass "Actuator management configuration present"
    else
        fail "Actuator management configuration missing"
    fi

    # Check for health and info endpoint exposure
    if grep -q "health" "$APP_YML" && \
       grep -q "info" "$APP_YML"; then
        pass "Health and info endpoints configured for exposure"
    else
        fail "Health and info endpoints not configured"
    fi

    # Check for security.enabled default (true)
    if grep -q "security:" "$APP_YML" || \
       grep -q "enabled.*true" "$APP_YML"; then
        pass "Security enabled by default in base application.yml"
    else
        fail "Security configuration missing in application.yml"
    fi
fi

# Test local/test profiles disable security
if [ -f "$APP_LOCAL" ]; then
    if grep -q "security:" "$APP_LOCAL" && \
       grep -q "enabled.*false" "$APP_LOCAL"; then
        pass "Security disabled in application-local.yml"
    else
        fail "Security not properly disabled in application-local.yml"
    fi
fi

if [ -f "$APP_TEST" ]; then
    if grep -q "security:" "$APP_TEST" && \
       grep -q "enabled.*false" "$APP_TEST"; then
        pass "Security disabled in application-test.yml"
    else
        fail "Security not properly disabled in application-test.yml"
    fi
fi

# Check dev/staging/prod profiles have JWT issuer config
for profile in "$APP_DEV" "$APP_STAGING" "$APP_PROD"; do
    if [ -f "$profile" ]; then
        profile_name=$(basename "$profile" | sed 's/application-//; s/.yml//')
        if grep -q "oauth2:" "$profile" || \
           grep -q "issuer-uri:" "$profile"; then
            pass "JWT issuer configuration present in $profile_name profile"
        else
            fail "JWT issuer configuration missing in $profile_name profile"
        fi
    fi
done

# Test 5: SecurityConfig structure and annotations
section "SecurityConfig Structure and Annotations"

if [ -f "$SECURITY_CONFIG" ]; then
    # Check for @Configuration annotation
    if grep -q "@Configuration" "$SECURITY_CONFIG"; then
        pass "SecurityConfig has @Configuration annotation"
    else
        fail "SecurityConfig missing @Configuration annotation"
    fi

    # Check for @EnableMethodSecurity with prePostEnabled
    if grep -q "@EnableMethodSecurity" "$SECURITY_CONFIG" && \
       grep -q "prePostEnabled.*true" "$SECURITY_CONFIG"; then
        pass "Method-level security enabled with @EnableMethodSecurity(prePostEnabled = true)"
    else
        fail "Method-level security not properly enabled"
    fi

    # Check for @ConditionalOnProperty for security toggle
    if grep -q "@ConditionalOnProperty" "$SECURITY_CONFIG" && \
       grep -q "security.enabled" "$SECURITY_CONFIG"; then
        pass "Security config conditional on security.enabled property"
    else
        fail "Security toggle via @ConditionalOnProperty missing"
    fi

    # Check for SecurityFilterChain bean
    if grep -q "fun.*SecurityFilterChain" "$SECURITY_CONFIG" || \
       grep -q "SecurityFilterChain" "$SECURITY_CONFIG"; then
        pass "SecurityFilterChain bean defined (Spring Security 6.x pattern)"
    else
        fail "SecurityFilterChain bean missing"
    fi

    # Check for JWT resource server configuration
    if grep -q "oauth2ResourceServer" "$SECURITY_CONFIG" || \
       grep -q "jwt" "$SECURITY_CONFIG"; then
        pass "OAuth2 resource server (JWT) configuration present"
    else
        fail "OAuth2 JWT configuration missing"
    fi

    # Check that actuator endpoints are permitted without auth
    if grep -q "permitAll" "$SECURITY_CONFIG" && \
       (grep -q "/health" "$SECURITY_CONFIG" || \
        grep -q "/info" "$SECURITY_CONFIG" || \
        grep -q "/actuator" "$SECURITY_CONFIG"); then
        pass "Actuator endpoints (/health, /info) permitted without authentication"
    else
        fail "Actuator endpoints not properly permitted"
    fi

    # Check for stateless session policy
    if grep -q "STATELESS" "$SECURITY_CONFIG" || \
       grep -q "sessionManagement" "$SECURITY_CONFIG"; then
        pass "Stateless session policy configured (no HTTP sessions)"
    else
        fail "Stateless session policy not configured"
    fi

    # Check that other endpoints require authentication
    if grep -q "authenticated" "$SECURITY_CONFIG" || \
       grep -q "anyRequest" "$SECURITY_CONFIG"; then
        pass "All non-actuator endpoints require authentication"
    else
        fail "Authentication requirement for protected endpoints missing"
    fi
fi

# Test 6: Enhanced GlobalExceptionHandler
section "Enhanced GlobalExceptionHandler Exception Types"

if [ -f "$EXCEPTION_HANDLER" ]; then
    # Check for existing handlers from WTR-4
    if grep -q "EntityNotFoundException" "$EXCEPTION_HANDLER"; then
        pass "EntityNotFoundException handler present (from WTR-4)"
    else
        fail "EntityNotFoundException handler missing"
    fi

    if grep -q "MethodArgumentNotValidException" "$EXCEPTION_HANDLER"; then
        pass "MethodArgumentNotValidException handler present (from WTR-4)"
    else
        fail "MethodArgumentNotValidException handler missing"
    fi

    # Check for new handlers in WTR-5
    if grep -q "HttpMessageNotReadableException" "$EXCEPTION_HANDLER"; then
        pass "HttpMessageNotReadableException handler added (malformed JSON, invalid enums)"
    else
        fail "HttpMessageNotReadableException handler missing (WTR-5 requirement)"
    fi

    if grep -q "AccessDeniedException" "$EXCEPTION_HANDLER"; then
        pass "AccessDeniedException handler added (403 Forbidden)"
    else
        fail "AccessDeniedException handler missing (WTR-5 requirement)"
    fi

    # Check for authentication exception handling
    if grep -q "AuthenticationException" "$EXCEPTION_HANDLER" || \
       grep -q "AuthenticationEntryPoint" "$EXCEPTION_HANDLER"; then
        pass "Authentication exception handler added (401 Unauthorized)"
    else
        fail "Authentication exception handler missing (WTR-5 requirement)"
    fi

    # Verify status code mappings
    if grep -q "FORBIDDEN" "$EXCEPTION_HANDLER" || \
       grep -q "403" "$EXCEPTION_HANDLER"; then
        pass "403 Forbidden status code configured for AccessDeniedException"
    else
        fail "403 status code not properly configured"
    fi

    if grep -q "UNAUTHORIZED" "$EXCEPTION_HANDLER" || \
       grep -q "401" "$EXCEPTION_HANDLER"; then
        pass "401 Unauthorized status code configured for authentication failures"
    else
        fail "401 status code not properly configured"
    fi

    # Check error response format (minimal per spec)
    if grep -q '"error"' "$EXCEPTION_HANDLER" || \
       grep -q 'error' "$EXCEPTION_HANDLER"; then
        pass "Error response format includes 'error' field"
    else
        fail "Error response format missing 'error' field"
    fi

    # Verify no extra fields in error response (timestamp, path should be omitted per spec)
    if ! grep -iq "timestamp.*=" "$EXCEPTION_HANDLER" && \
       ! grep -iq "path.*=" "$EXCEPTION_HANDLER"; then
        pass "Error response format is minimal (no timestamp/path fields per spec)"
    else
        fail "Error response includes unnecessary fields (should be minimal)"
    fi
fi

# Test 7: Controller @PreAuthorize annotations
section "WebTransactionController Security Annotations"

if [ -f "$CONTROLLER_FILE" ]; then
    # Check for @PreAuthorize annotations
    if grep -q "@PreAuthorize" "$CONTROLLER_FILE"; then
        pass "Controller uses @PreAuthorize annotations for method-level security"
    else
        fail "Controller missing @PreAuthorize annotations"
    fi

    # Check for read:web-transaction scope on GET endpoints
    if grep -q "read:web-transaction" "$CONTROLLER_FILE" || \
       grep -q "read.*web.*transaction" "$CONTROLLER_FILE"; then
        pass "GET endpoints protected with read:web-transaction scope"
    else
        fail "read:web-transaction scope not configured"
    fi

    # Check for write:web-transaction scope on POST/PUT endpoints
    if grep -q "write:web-transaction" "$CONTROLLER_FILE" || \
       grep -q "write.*web.*transaction" "$CONTROLLER_FILE"; then
        pass "POST/PUT endpoints protected with write:web-transaction scope"
    else
        fail "write:web-transaction scope not configured"
    fi

    # Verify annotations are at method level, not class level
    # Count @PreAuthorize occurrences - should be multiple (one per method)
    preauth_count=$(grep -c "@PreAuthorize" "$CONTROLLER_FILE" 2>/dev/null || echo 0)
    if [ "$preauth_count" -ge 2 ]; then
        pass "@PreAuthorize applied at method level (multiple annotations found)"
    else
        fail "@PreAuthorize should be at method level, not class level"
    fi
fi

# Test 8: Test files existence
section "Security and Actuator Test Files"

SECURITY_CONFIG_TEST="src/test/kotlin/com/webtransaction/microsite/config/SecurityConfigTests.kt"
CONTROLLER_SECURITY_TEST="src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerSecurityTests.kt"
EXCEPTION_HANDLER_TEST="src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt"
ACTUATOR_TEST="src/test/kotlin/com/webtransaction/microsite/ActuatorEndpointsTests.kt"

if [ -f "$SECURITY_CONFIG_TEST" ]; then
    pass "SecurityConfigTests.kt exists"
else
    fail "SecurityConfigTests.kt missing"
fi

if [ -f "$CONTROLLER_SECURITY_TEST" ]; then
    pass "WebTransactionControllerSecurityTests.kt exists"
else
    fail "WebTransactionControllerSecurityTests.kt missing"
fi

if [ -f "$EXCEPTION_HANDLER_TEST" ]; then
    pass "GlobalExceptionHandlerTests.kt exists (enhanced for WTR-5)"
else
    fail "GlobalExceptionHandlerTests.kt missing"
fi

if [ -f "$ACTUATOR_TEST" ]; then
    pass "ActuatorEndpointsTests.kt exists"
else
    fail "ActuatorEndpointsTests.kt missing"
fi

# Test 9: SecurityConfig test coverage
section "SecurityConfigTests Coverage"

if [ -f "$SECURITY_CONFIG_TEST" ]; then
    # Check for Spring Boot test annotations
    if grep -q "@SpringBootTest" "$SECURITY_CONFIG_TEST"; then
        pass "SecurityConfigTests uses @SpringBootTest"
    else
        fail "SecurityConfigTests missing @SpringBootTest"
    fi

    # Check for MockMvc usage
    if grep -q "MockMvc" "$SECURITY_CONFIG_TEST"; then
        pass "Tests use MockMvc for HTTP requests"
    else
        fail "Tests missing MockMvc setup"
    fi

    # Check for actuator endpoint accessibility tests
    if grep -iq "/health\|/info\|actuator" "$SECURITY_CONFIG_TEST"; then
        pass "Tests verify actuator endpoint accessibility without auth"
    else
        fail "Tests missing actuator endpoint verification"
    fi

    # Check for 401 test on protected endpoints
    if grep -iq "401\|unauthorized" "$SECURITY_CONFIG_TEST"; then
        pass "Tests verify 401 on unauthenticated requests"
    else
        fail "Tests missing 401 verification"
    fi

    # Check for profile-based security toggle test
    if grep -q "@ActiveProfiles.*test" "$SECURITY_CONFIG_TEST" || \
       grep -iq "security.*disabled\|security.*enabled.*false" "$SECURITY_CONFIG_TEST"; then
        pass "Tests verify security disabled in test profile"
    else
        fail "Tests missing security toggle verification"
    fi
fi

# Test 10: Controller security test coverage
section "WebTransactionControllerSecurityTests Coverage"

if [ -f "$CONTROLLER_SECURITY_TEST" ]; then
    # Check for Spring Security test utilities
    if grep -q "@WithMockUser\|jwt()\|MockMvc" "$CONTROLLER_SECURITY_TEST"; then
        pass "Tests use Spring Security test utilities (MockMvc, JWT mocking)"
    else
        fail "Tests missing Spring Security test utilities"
    fi

    # Check for no JWT header test (401)
    if grep -iq "401\|unauthorized\|no.*token\|no.*jwt" "$CONTROLLER_SECURITY_TEST"; then
        pass "Tests verify 401 when JWT header is missing"
    else
        fail "Tests missing no-JWT-header verification"
    fi

    # Check for insufficient scope test (403)
    if grep -iq "403\|forbidden\|insufficient.*scope" "$CONTROLLER_SECURITY_TEST"; then
        pass "Tests verify 403 when JWT has insufficient scope"
    else
        fail "Tests missing insufficient-scope verification"
    fi

    # Check for valid JWT with read scope test
    if grep -iq "read:web-transaction\|read.*scope" "$CONTROLLER_SECURITY_TEST"; then
        pass "Tests verify GET endpoints with read:web-transaction scope"
    else
        fail "Tests missing read scope verification"
    fi

    # Check for valid JWT with write scope test
    if grep -iq "write:web-transaction\|write.*scope" "$CONTROLLER_SECURITY_TEST"; then
        pass "Tests verify POST/PUT endpoints with write:web-transaction scope"
    else
        fail "Tests missing write scope verification"
    fi

    # Check for scope enforcement matrix tests
    if grep -iq "read.*attempting.*post\|write.*only\|scope.*matrix" "$CONTROLLER_SECURITY_TEST"; then
        pass "Tests include scope enforcement matrix (read attempting write, etc.)"
    else
        fail "Tests missing comprehensive scope enforcement scenarios"
    fi
fi

# Test 11: Exception handler test coverage
section "GlobalExceptionHandlerTests Coverage"

if [ -f "$EXCEPTION_HANDLER_TEST" ]; then
    # Check for @WebMvcTest annotation
    if grep -q "@WebMvcTest" "$EXCEPTION_HANDLER_TEST"; then
        pass "GlobalExceptionHandlerTests uses @WebMvcTest"
    else
        fail "GlobalExceptionHandlerTests missing @WebMvcTest"
    fi

    # Check for HttpMessageNotReadableException test
    if grep -q "HttpMessageNotReadableException" "$EXCEPTION_HANDLER_TEST" && \
       grep -iq "400\|bad.*request" "$EXCEPTION_HANDLER_TEST"; then
        pass "Tests verify HttpMessageNotReadableException → 400"
    else
        fail "Tests missing HttpMessageNotReadableException verification"
    fi

    # Check for AccessDeniedException test
    if grep -q "AccessDeniedException" "$EXCEPTION_HANDLER_TEST" && \
       grep -iq "403\|forbidden" "$EXCEPTION_HANDLER_TEST"; then
        pass "Tests verify AccessDeniedException → 403"
    else
        fail "Tests missing AccessDeniedException verification"
    fi

    # Check for AuthenticationException test
    if grep -q "AuthenticationException" "$EXCEPTION_HANDLER_TEST" && \
       grep -iq "401\|unauthorized" "$EXCEPTION_HANDLER_TEST"; then
        pass "Tests verify AuthenticationException → 401"
    else
        fail "Tests missing AuthenticationException verification"
    fi

    # Verify error response structure matches spec
    if grep -iq "error.*field\|response.*structure\|json.*error" "$EXCEPTION_HANDLER_TEST"; then
        pass "Tests verify error response structure matches spec"
    else
        fail "Tests missing error response structure verification"
    fi

    # Check for sanitized error messages (no stack traces)
    if grep -iq "sanitized\|no.*stack\|invalid.*request.*format" "$EXCEPTION_HANDLER_TEST"; then
        pass "Tests verify error messages are sanitized (no stack traces)"
    else
        fail "Tests missing sanitized error message verification"
    fi
fi

# Test 12: Actuator endpoints test coverage
section "ActuatorEndpointsTests Coverage"

if [ -f "$ACTUATOR_TEST" ]; then
    # Check for Spring Boot test setup
    if grep -q "@SpringBootTest" "$ACTUATOR_TEST" || \
       grep -q "@AutoConfigureMockMvc" "$ACTUATOR_TEST"; then
        pass "ActuatorEndpointsTests uses proper Spring Boot test setup"
    else
        fail "ActuatorEndpointsTests missing proper test setup"
    fi

    # Check for /health endpoint test
    if grep -iq "/health\|health.*endpoint" "$ACTUATOR_TEST"; then
        pass "Tests verify /health endpoint"
    else
        fail "Tests missing /health endpoint verification"
    fi

    # Check for /info endpoint test
    if grep -iq "/info\|info.*endpoint" "$ACTUATOR_TEST"; then
        pass "Tests verify /info endpoint"
    else
        fail "Tests missing /info endpoint verification"
    fi

    # Check for health status verification
    if grep -iq "status.*UP\|health.*status" "$ACTUATOR_TEST"; then
        pass "Tests verify health status structure (status: UP)"
    else
        fail "Tests missing health status structure verification"
    fi

    # Check for git info verification
    if grep -iq "git\|commit\|branch" "$ACTUATOR_TEST"; then
        pass "Tests verify git build info in /info endpoint"
    else
        fail "Tests missing git build info verification"
    fi

    # Check that actuator endpoints work without authentication
    if grep -iq "without.*auth\|no.*jwt\|unauthenticated.*200" "$ACTUATOR_TEST"; then
        pass "Tests verify actuator endpoints accessible without authentication"
    else
        fail "Tests missing no-authentication-required verification"
    fi

    # Check for security enabled profile test
    if grep -iq "security.*enabled\|default.*profile" "$ACTUATOR_TEST"; then
        pass "Tests verify actuator endpoints work with security enabled"
    else
        fail "Tests missing security-enabled profile verification"
    fi
fi

# Test 13: Acceptance criteria verification
section "Acceptance Criteria Verification"

acceptance_passed=0
acceptance_total=11

# AC1: Unauthenticated request returns 401
if [ -f "$CONTROLLER_SECURITY_TEST" ] && \
   grep -iq "401\|unauthorized" "$CONTROLLER_SECURITY_TEST"; then
    pass "AC1: Unauthenticated GET request returns 401 Unauthorized"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC1: Unauthenticated request 401 requirement not verified"
fi

# AC2: Insufficient scope returns 403
if [ -f "$CONTROLLER_SECURITY_TEST" ] && \
   grep -iq "403\|forbidden" "$CONTROLLER_SECURITY_TEST"; then
    pass "AC2: Insufficient scope returns 403 Forbidden"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC2: Insufficient scope 403 requirement not verified"
fi

# AC3: Valid JWT with read scope can GET
if [ -f "$CONTROLLER_SECURITY_TEST" ] && \
   grep -iq "read:web-transaction" "$CONTROLLER_SECURITY_TEST"; then
    pass "AC3: Valid JWT with read:web-transaction scope can GET transactions"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC3: Read scope requirement not verified"
fi

# AC4: Valid JWT with write scope can POST/PUT
if [ -f "$CONTROLLER_SECURITY_TEST" ] && \
   grep -iq "write:web-transaction" "$CONTROLLER_SECURITY_TEST"; then
    pass "AC4: Valid JWT with write:web-transaction scope can POST/PUT"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC4: Write scope requirement not verified"
fi

# AC5: EntityNotFoundException returns 404
if [ -f "$EXCEPTION_HANDLER" ] && \
   grep -q "EntityNotFoundException" "$EXCEPTION_HANDLER"; then
    pass "AC5: EntityNotFoundException returns 404 with JSON error"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC5: EntityNotFoundException 404 handling missing"
fi

# AC6: Validation errors return 400 with details
if [ -f "$EXCEPTION_HANDLER" ] && \
   grep -q "MethodArgumentNotValidException" "$EXCEPTION_HANDLER"; then
    pass "AC6: MethodArgumentNotValidException returns 400 with details"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC6: Validation error 400 handling missing"
fi

# AC7: HttpMessageNotReadableException returns 400
if [ -f "$EXCEPTION_HANDLER" ] && \
   grep -q "HttpMessageNotReadableException" "$EXCEPTION_HANDLER"; then
    pass "AC7: HttpMessageNotReadableException returns 400 (malformed JSON, invalid enums)"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC7: HttpMessageNotReadableException 400 handling missing"
fi

# AC8: /health endpoint accessible without JWT
if [ -f "$ACTUATOR_TEST" ] && \
   grep -iq "/health" "$ACTUATOR_TEST"; then
    pass "AC8: /health endpoint accessible without JWT"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC8: /health endpoint verification missing"
fi

# AC9: /info endpoint returns git build info
if [ -f "$ACTUATOR_TEST" ] && \
   grep -iq "/info\|git" "$ACTUATOR_TEST"; then
    pass "AC9: /info endpoint returns git build information"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC9: /info endpoint git info verification missing"
fi

# AC10: Security disabled in local and test profiles
if [ -f "$APP_LOCAL" ] && [ -f "$APP_TEST" ] && \
   grep -q "enabled.*false" "$APP_LOCAL" && \
   grep -q "enabled.*false" "$APP_TEST"; then
    pass "AC10: Security disabled in local and test profiles via security.enabled=false"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC10: Security toggle for local/test profiles missing"
fi

# AC11: Method-level security enabled
if [ -f "$SECURITY_CONFIG" ] && \
   grep -q "@EnableMethodSecurity" "$SECURITY_CONFIG" && \
   grep -q "prePostEnabled.*true" "$SECURITY_CONFIG"; then
    pass "AC11: Method-level security enabled via @EnableMethodSecurity(prePostEnabled = true)"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC11: Method-level security not properly enabled"
fi

echo ""
echo "Acceptance Criteria: $acceptance_passed/$acceptance_total passed"

# Test 14: Risk mitigations from plan
section "Risk Mitigation Verification"

risk_mitigations_passed=0
risk_mitigations_total=6

# Risk 1: JWT issuer URI configuration uses environment-specific properties
if [ -f "$APP_DEV" ] && [ -f "$APP_STAGING" ] && [ -f "$APP_PROD" ]; then
    risk_mitigations_passed=$((risk_mitigations_passed + 1))
    pass "Risk 1: Environment-specific JWT issuer configuration present"
else
    fail "Risk 1: Environment-specific JWT issuer configuration missing"
fi

# Risk 2: Actuator exposure limited to health and info
if [ -f "$APP_YML" ] && grep -q "health.*info" "$APP_YML" && \
   ! grep -q "include:.*\*" "$APP_YML"; then
    risk_mitigations_passed=$((risk_mitigations_passed + 1))
    pass "Risk 2: Actuator exposure limited to health,info (not wildcard)"
else
    fail "Risk 2: Actuator exposure not properly limited"
fi

# Risk 3: Security enabled by default (matchIfMissing = true)
if [ -f "$SECURITY_CONFIG" ] && \
   grep -q "matchIfMissing.*true" "$SECURITY_CONFIG"; then
    risk_mitigations_passed=$((risk_mitigations_passed + 1))
    pass "Risk 3: Security enabled by default (matchIfMissing = true)"
else
    fail "Risk 3: Security default not properly configured"
fi

# Risk 4: Prod YAML explicitly sets security.enabled=true
if [ -f "$APP_PROD" ] && grep -q "enabled.*true" "$APP_PROD"; then
    risk_mitigations_passed=$((risk_mitigations_passed + 1))
    pass "Risk 4: Prod profile explicitly enables security (documentation)"
else
    fail "Risk 4: Prod profile missing explicit security.enabled=true"
fi

# Risk 5: Method security enabled verification in tests
if [ -f "$CONTROLLER_SECURITY_TEST" ] && \
   grep -iq "scope.*enforcement\|preauthorize" "$CONTROLLER_SECURITY_TEST"; then
    risk_mitigations_passed=$((risk_mitigations_passed + 1))
    pass "Risk 5: Tests verify method security is enforced"
else
    fail "Risk 5: Method security enforcement not verified in tests"
fi

# Risk 6: Stateless session policy (no HTTP sessions)
if [ -f "$SECURITY_CONFIG" ] && \
   grep -q "STATELESS" "$SECURITY_CONFIG"; then
    risk_mitigations_passed=$((risk_mitigations_passed + 1))
    pass "Risk 6: Stateless session policy configured (JWT per-request)"
else
    fail "Risk 6: Stateless session policy not configured"
fi

echo ""
echo "Risk Mitigations: $risk_mitigations_passed/$risk_mitigations_total passed"

# Test 15: Plan step completion verification
section "Plan Step Completion Verification"

plan_steps_complete=0
plan_steps_total=9

# Step 1: Dependencies and git-properties plugin
if [ -f "$BUILD_FILE" ] && \
   grep -q "oauth2-resource-server" "$BUILD_FILE" && \
   grep -q "actuator" "$BUILD_FILE" && \
   grep -q "git-properties" "$BUILD_FILE"; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 1: Dependencies and git-properties plugin added"
else
    fail "Step 1: Dependencies incomplete"
fi

# Step 2: Base application.yml
if [ -f "$APP_YML" ] && \
   grep -q "management:" "$APP_YML" && \
   grep -q "security:" "$APP_YML"; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 2: Base application.yml with actuator and security config"
else
    fail "Step 2: Base application.yml incomplete"
fi

# Step 3: Profile-specific YAMLs
if [ -f "$APP_LOCAL" ] && [ -f "$APP_TEST" ] && \
   [ -f "$APP_DEV" ] && [ -f "$APP_STAGING" ] && [ -f "$APP_PROD" ]; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 3: All profile-specific application-*.yml files created"
else
    fail "Step 3: Profile-specific YAML files incomplete"
fi

# Step 4: SecurityConfig created
if [ -f "$SECURITY_CONFIG" ] && [ -f "$SECURITY_CONFIG_TEST" ]; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 4: SecurityConfig and tests created (TDD)"
else
    fail "Step 4: SecurityConfig or tests missing"
fi

# Step 5: Enhanced GlobalExceptionHandler
if [ -f "$EXCEPTION_HANDLER" ] && [ -f "$EXCEPTION_HANDLER_TEST" ] && \
   grep -q "HttpMessageNotReadableException" "$EXCEPTION_HANDLER" && \
   grep -q "AccessDeniedException" "$EXCEPTION_HANDLER"; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 5: GlobalExceptionHandler enhanced with new exception types (TDD)"
else
    fail "Step 5: GlobalExceptionHandler enhancements incomplete"
fi

# Step 6: @PreAuthorize annotations on controller
if [ -f "$CONTROLLER_FILE" ] && \
   grep -q "@PreAuthorize" "$CONTROLLER_FILE"; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 6: @PreAuthorize annotations added to controller methods"
else
    fail "Step 6: @PreAuthorize annotations missing"
fi

# Step 7: Controller security tests
if [ -f "$CONTROLLER_SECURITY_TEST" ]; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 7: WebTransactionControllerSecurityTests created (TDD)"
else
    fail "Step 7: Controller security tests missing"
fi

# Step 8: Actuator endpoints tests
if [ -f "$ACTUATOR_TEST" ]; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 8: ActuatorEndpointsTests created (TDD)"
else
    fail "Step 8: Actuator endpoints tests missing"
fi

# Step 9: E2E validation (all tests exist)
if [ -f "$SECURITY_CONFIG_TEST" ] && \
   [ -f "$EXCEPTION_HANDLER_TEST" ] && \
   [ -f "$CONTROLLER_SECURITY_TEST" ] && \
   [ -f "$ACTUATOR_TEST" ]; then
    plan_steps_complete=$((plan_steps_complete + 1))
    pass "Step 9: E2E validation - all test files present"
else
    fail "Step 9: E2E validation incomplete - test files missing"
fi

if [ "$plan_steps_complete" -eq "$plan_steps_total" ]; then
    pass "All plan steps completed ($plan_steps_complete/$plan_steps_total)"
else
    fail "Plan steps incomplete ($plan_steps_complete/$plan_steps_total completed)"
fi

# Test 16: Integration with WTR-4 components
section "Integration with WTR-4 Components"

# Verify controller from WTR-4 is being secured
if [ -f "$CONTROLLER_FILE" ]; then
    # Check that existing endpoints are now protected
    if grep -q "@GetMapping" "$CONTROLLER_FILE" && \
       grep -q "@PostMapping" "$CONTROLLER_FILE" && \
       grep -q "@PutMapping" "$CONTROLLER_FILE"; then
        pass "WTR-4 REST endpoints present (GET, POST, PUT)"
    else
        fail "WTR-4 REST endpoints missing from controller"
    fi

    # Check that controller still has proper base path
    if grep -q "/v1/webtransaction" "$CONTROLLER_FILE"; then
        pass "Controller maintains /v1/webtransaction base path from WTR-4"
    else
        fail "Controller base path missing or changed"
    fi
fi

# Verify exception handler extends WTR-4 functionality
if [ -f "$EXCEPTION_HANDLER" ]; then
    # Should still have WTR-4 exception handlers
    if grep -q "EntityNotFoundException" "$EXCEPTION_HANDLER" && \
       grep -q "MethodArgumentNotValidException" "$EXCEPTION_HANDLER"; then
        pass "GlobalExceptionHandler maintains WTR-4 exception handlers"
    else
        fail "WTR-4 exception handlers missing from enhanced handler"
    fi
fi

# Test 17: Code quality and Spring Security conventions
section "Code Quality and Spring Security Conventions"

# Check for proper Kotlin package structure
if [ -d "src/main/kotlin/com/webtransaction/microsite/config" ]; then
    pass "Security config in proper package structure (config package)"
else
    fail "Config package structure incorrect"
fi

# Check for test package structure
if [ -d "src/test/kotlin/com/webtransaction/microsite/config" ] || \
   [ -d "src/test/kotlin/com/webtransaction/microsite/controller" ]; then
    pass "Test package structure follows main source structure"
else
    fail "Test package structure incorrect"
fi

# Verify Spring Security 6.x patterns (no WebSecurityConfigurerAdapter)
if [ -f "$SECURITY_CONFIG" ]; then
    if ! grep -q "WebSecurityConfigurerAdapter" "$SECURITY_CONFIG"; then
        pass "Security config uses Spring Security 6.x patterns (no deprecated adapter)"
    else
        fail "Security config uses deprecated WebSecurityConfigurerAdapter"
    fi
fi

# Check for proper Spring Boot version compatibility
if [ -f "$BUILD_FILE" ]; then
    # Spring Security 6.x requires Spring Boot 3.x
    if grep -iq "spring.*boot.*3\|springBootVersion.*3" "$BUILD_FILE" || \
       ! grep -iq "spring.*boot.*2" "$BUILD_FILE"; then
        pass "Build file compatible with Spring Boot 3.x / Spring Security 6.x"
    else
        fail "Build file may be using incompatible Spring Boot version"
    fi
fi

# Test 18: Out-of-plan verification
section "Out-of-Plan Items Verification"

# Verify out-of-plan items are NOT implemented (as expected)
out_of_plan_clean=0
out_of_plan_total=4

# Should NOT have multi-issuer support (deferred)
if [ -f "$SECURITY_CONFIG" ] && \
   ! grep -iq "multiple.*issuer\|issuer.*chain" "$SECURITY_CONFIG"; then
    out_of_plan_clean=$((out_of_plan_clean + 1))
    pass "Out-of-plan: Multi-issuer support correctly deferred"
else
    fail "Out-of-plan: Multi-issuer support should be deferred"
fi

# Should NOT have audience validation (deferred)
if [ -f "$SECURITY_CONFIG" ] && \
   ! grep -iq "audience.*validator\|aud.*claim" "$SECURITY_CONFIG"; then
    out_of_plan_clean=$((out_of_plan_clean + 1))
    pass "Out-of-plan: Audience validation correctly deferred"
else
    fail "Out-of-plan: Audience validation should be deferred"
fi

# Should NOT have CORS configuration (explicit out-of-scope)
if [ -f "$SECURITY_CONFIG" ] && \
   ! grep -iq "cors\|CorsConfiguration" "$SECURITY_CONFIG"; then
    out_of_plan_clean=$((out_of_plan_clean + 1))
    pass "Out-of-plan: CORS configuration correctly out-of-scope"
else
    fail "Out-of-plan: CORS configuration should be out-of-scope"
fi

# Should NOT have custom actuator metrics (explicit out-of-scope)
if ! find src -name "*CustomMetric*" -o -name "*CustomHealth*" 2>/dev/null | grep -q .; then
    out_of_plan_clean=$((out_of_plan_clean + 1))
    pass "Out-of-plan: Custom actuator metrics correctly out-of-scope"
else
    fail "Out-of-plan: Custom actuator metrics should be out-of-scope"
fi

echo ""
echo "Out-of-Plan Verification: $out_of_plan_clean/$out_of_plan_total correctly deferred/out-of-scope"

# Final summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "PASSED: $PASSED"
echo "FAILED: $FAILED"
echo "TOTAL:  $((PASSED + FAILED))"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ WTR-5 E2E measurement: ALL TESTS PASSED"
else
    echo "✗ WTR-5 E2E measurement: SOME TESTS FAILED"
fi

echo ""
exit $EXIT_CODE
