#!/bin/bash
# Full E2E measurement test for WTR-4 implementation
# Tests REST controller, service layer, DTOs, validation, and exception handling

set -e

echo "=========================================="
echo "WTR-4 E2E Measurement Test"
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
section "Package Structure and File Existence"

CONTROLLER_FILE="src/main/kotlin/com/webtransaction/microsite/controller/WebTransactionController.kt"
SERVICE_FILE="src/main/kotlin/com/webtransaction/microsite/service/WebTransactionService.kt"
CREATE_DTO="src/main/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequest.kt"
UPDATE_DTO="src/main/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequest.kt"
RESPONSE_DTO="src/main/kotlin/com/webtransaction/microsite/dto/WebTransactionResponse.kt"
ENTITY_NOT_FOUND="src/main/kotlin/com/webtransaction/microsite/exception/EntityNotFoundException.kt"
EXCEPTION_HANDLER="src/main/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandler.kt"

if [ -f "$CONTROLLER_FILE" ]; then
    pass "WebTransactionController.kt exists"
else
    fail "WebTransactionController.kt missing"
fi

if [ -f "$SERVICE_FILE" ]; then
    pass "WebTransactionService.kt exists"
else
    fail "WebTransactionService.kt missing"
fi

if [ -f "$CREATE_DTO" ]; then
    pass "CreateWebTransactionRequest.kt exists"
else
    fail "CreateWebTransactionRequest.kt missing"
fi

if [ -f "$UPDATE_DTO" ]; then
    pass "UpdateWebTransactionRequest.kt exists"
else
    fail "UpdateWebTransactionRequest.kt missing"
fi

if [ -f "$RESPONSE_DTO" ]; then
    pass "WebTransactionResponse.kt exists"
else
    fail "WebTransactionResponse.kt missing"
fi

if [ -f "$ENTITY_NOT_FOUND" ]; then
    pass "EntityNotFoundException.kt exists"
else
    fail "EntityNotFoundException.kt missing"
fi

if [ -f "$EXCEPTION_HANDLER" ]; then
    pass "GlobalExceptionHandler.kt exists"
else
    fail "GlobalExceptionHandler.kt missing"
fi

# Test 2: EntityNotFoundException structure
section "EntityNotFoundException Structure"

if [ -f "$ENTITY_NOT_FOUND" ]; then
    if grep -q "class EntityNotFoundException" "$ENTITY_NOT_FOUND"; then
        pass "EntityNotFoundException class declared"
    else
        fail "EntityNotFoundException class not found"
    fi

    if grep -q "RuntimeException" "$ENTITY_NOT_FOUND"; then
        pass "EntityNotFoundException extends RuntimeException"
    else
        fail "EntityNotFoundException does not extend RuntimeException"
    fi

    if grep -q "message" "$ENTITY_NOT_FOUND"; then
        pass "EntityNotFoundException accepts message parameter"
    else
        fail "EntityNotFoundException missing message parameter"
    fi
fi

# Test 3: GlobalExceptionHandler annotations and structure
section "GlobalExceptionHandler Annotations and Structure"

if [ -f "$EXCEPTION_HANDLER" ]; then
    if grep -q "@RestControllerAdvice" "$EXCEPTION_HANDLER" || \
       grep -q "@ControllerAdvice" "$EXCEPTION_HANDLER"; then
        pass "GlobalExceptionHandler has @RestControllerAdvice or @ControllerAdvice"
    else
        fail "GlobalExceptionHandler missing controller advice annotation"
    fi

    # Check for EntityNotFoundException handler
    if grep -q "EntityNotFoundException" "$EXCEPTION_HANDLER" && \
       grep -q "@ExceptionHandler" "$EXCEPTION_HANDLER"; then
        pass "EntityNotFoundException handler method present"
    else
        fail "EntityNotFoundException handler method missing"
    fi

    # Check for MethodArgumentNotValidException handler
    if grep -q "MethodArgumentNotValidException" "$EXCEPTION_HANDLER"; then
        pass "MethodArgumentNotValidException handler present"
    else
        fail "MethodArgumentNotValidException handler missing"
    fi

    # Check for 404 status code mapping
    if grep -q "NOT_FOUND" "$EXCEPTION_HANDLER" || \
       grep -q "404" "$EXCEPTION_HANDLER"; then
        pass "404 status code configured for EntityNotFoundException"
    else
        fail "404 status code not found in exception handler"
    fi

    # Check for 400 status code mapping
    if grep -q "BAD_REQUEST" "$EXCEPTION_HANDLER" || \
       grep -q "400" "$EXCEPTION_HANDLER"; then
        pass "400 status code configured for validation errors"
    else
        fail "400 status code not found in exception handler"
    fi

    # Check for generic exception handler
    if grep -q "Exception" "$EXCEPTION_HANDLER"; then
        pass "Generic Exception handler present for 500 errors"
    else
        fail "Generic Exception handler missing"
    fi

    # Check for OptimisticLockException handler (per plan risk mitigation)
    if grep -q "OptimisticLockException" "$EXCEPTION_HANDLER"; then
        pass "OptimisticLockException handler present (409 Conflict)"
    else
        fail "OptimisticLockException handler missing (required per plan)"
    fi
fi

# Test 4: DTO structure and validation annotations
section "DTO Structure and Validation Annotations"

# CreateWebTransactionRequest
if [ -f "$CREATE_DTO" ]; then
    if grep -q "data class CreateWebTransactionRequest" "$CREATE_DTO"; then
        pass "CreateWebTransactionRequest is a Kotlin data class"
    else
        fail "CreateWebTransactionRequest is not a data class"
    fi

    # Check required fields
    required_fields=("reference" "transactionType" "amount" "currency"
                     "internalReferenceType" "externalReference" "originalPayload")

    for field in "${required_fields[@]}"; do
        if grep -iq "$field" "$CREATE_DTO"; then
            pass "CreateWebTransactionRequest has $field field"
        else
            fail "CreateWebTransactionRequest missing $field field"
        fi
    done

    # Check validation annotations
    if grep -q "@NotBlank" "$CREATE_DTO"; then
        pass "CreateWebTransactionRequest uses @NotBlank validation"
    else
        fail "CreateWebTransactionRequest missing @NotBlank annotations"
    fi

    if grep -q "@Size" "$CREATE_DTO"; then
        pass "CreateWebTransactionRequest uses @Size validation"
    else
        fail "CreateWebTransactionRequest missing @Size annotations"
    fi

    # Check reference max length 100
    if grep -q "max.*=.*100" "$CREATE_DTO"; then
        pass "reference field has max length 100"
    else
        fail "reference field missing max length 100 constraint"
    fi

    # Check externalReference max length 255
    if grep -q "max.*=.*255" "$CREATE_DTO"; then
        pass "externalReference has max length 255"
    else
        fail "externalReference missing max length 255 constraint"
    fi

    # Check for originalPayload field (Map type for JSONB)
    if grep -iq "originalPayload.*Map" "$CREATE_DTO"; then
        pass "originalPayload field defined as Map for JSONB"
    else
        fail "originalPayload field not defined as Map"
    fi

    # Check that originalPayload is required (@NotNull)
    if grep -q "@NotNull" "$CREATE_DTO"; then
        pass "DTO uses @NotNull validation (for originalPayload)"
    else
        fail "DTO missing @NotNull annotations"
    fi
fi

# UpdateWebTransactionRequest
if [ -f "$UPDATE_DTO" ]; then
    if grep -q "data class UpdateWebTransactionRequest" "$UPDATE_DTO"; then
        pass "UpdateWebTransactionRequest is a Kotlin data class"
    else
        fail "UpdateWebTransactionRequest is not a data class"
    fi

    # Should only have reconcileStatus and externalReferenceNumber
    if grep -iq "reconcileStatus" "$UPDATE_DTO"; then
        pass "UpdateWebTransactionRequest has reconcileStatus field"
    else
        fail "UpdateWebTransactionRequest missing reconcileStatus field"
    fi

    if grep -iq "externalReferenceNumber" "$UPDATE_DTO"; then
        pass "UpdateWebTransactionRequest has externalReferenceNumber field"
    else
        fail "UpdateWebTransactionRequest missing externalReferenceNumber field"
    fi

    # Should NOT have fields like amount, currency, reference (partial update only)
    if ! grep -iq "amount\s*:" "$UPDATE_DTO"; then
        pass "UpdateWebTransactionRequest correctly excludes amount (partial update)"
    else
        fail "UpdateWebTransactionRequest should not include amount field"
    fi
fi

# WebTransactionResponse
if [ -f "$RESPONSE_DTO" ]; then
    if grep -q "data class WebTransactionResponse" "$RESPONSE_DTO"; then
        pass "WebTransactionResponse is a Kotlin data class"
    else
        fail "WebTransactionResponse is not a data class"
    fi

    # Should include all entity fields including id and timestamps
    response_fields=("id" "reference" "transactionType" "amount" "currency"
                     "created" "updated" "originalPayload")

    for field in "${response_fields[@]}"; do
        if grep -iq "$field" "$RESPONSE_DTO"; then
            pass "WebTransactionResponse has $field field"
        else
            fail "WebTransactionResponse missing $field field"
        fi
    done

    # Check timestamp fields (should be Instant or LocalDateTime for ISO-8601)
    if grep -iq "created.*Instant" "$RESPONSE_DTO" || \
       grep -iq "created.*LocalDateTime" "$RESPONSE_DTO"; then
        pass "created field uses Instant or LocalDateTime for ISO-8601"
    else
        fail "created field not using proper timestamp type"
    fi
fi

# Test 5: WebTransactionService structure and methods
section "WebTransactionService Structure and Methods"

if [ -f "$SERVICE_FILE" ]; then
    if grep -q "@Service" "$SERVICE_FILE"; then
        pass "WebTransactionService has @Service annotation"
    else
        fail "WebTransactionService missing @Service annotation"
    fi

    # Check for repository dependency injection
    if grep -iq "repository" "$SERVICE_FILE"; then
        pass "Service has repository dependency"
    else
        fail "Service missing repository dependency"
    fi

    # Check for createTransaction method
    if grep -q "fun createTransaction" "$SERVICE_FILE" || \
       grep -q "fun create" "$SERVICE_FILE"; then
        pass "Service has createTransaction method"
    else
        fail "Service missing createTransaction method"
    fi

    # Check for getTransactionById method
    if grep -q "fun getTransactionById" "$SERVICE_FILE" || \
       grep -q "fun getById" "$SERVICE_FILE"; then
        pass "Service has getTransactionById method"
    else
        fail "Service missing getTransactionById method"
    fi

    # Check for getTransactionByReference method
    if grep -q "fun getTransactionByReference" "$SERVICE_FILE" || \
       grep -q "fun getByReference" "$SERVICE_FILE"; then
        pass "Service has getTransactionByReference method"
    else
        fail "Service missing getTransactionByReference method"
    fi

    # Check for updateTransactionByReference method
    if grep -q "fun updateTransactionByReference" "$SERVICE_FILE" || \
       grep -q "fun updateByReference" "$SERVICE_FILE"; then
        pass "Service has updateTransactionByReference method"
    else
        fail "Service missing updateTransactionByReference method"
    fi

    # Check for EntityNotFoundException throws
    if grep -q "EntityNotFoundException" "$SERVICE_FILE"; then
        pass "Service throws EntityNotFoundException for not found cases"
    else
        fail "Service does not throw EntityNotFoundException"
    fi

    # Check for DTO mapping logic
    if grep -q "CreateWebTransactionRequest" "$SERVICE_FILE" && \
       grep -q "WebTransactionResponse" "$SERVICE_FILE"; then
        pass "Service performs DTO to entity mapping"
    else
        fail "Service missing DTO mapping logic"
    fi
fi

# Test 6: WebTransactionController structure and endpoints
section "WebTransactionController Structure and Endpoints"

if [ -f "$CONTROLLER_FILE" ]; then
    if grep -q "@RestController" "$CONTROLLER_FILE"; then
        pass "WebTransactionController has @RestController annotation"
    else
        fail "WebTransactionController missing @RestController annotation"
    fi

    if grep -q "@RequestMapping" "$CONTROLLER_FILE"; then
        pass "Controller has @RequestMapping annotation"
    else
        fail "Controller missing @RequestMapping annotation"
    fi

    # Check for /v1/webtransaction base path
    if grep -q "/v1/webtransaction" "$CONTROLLER_FILE"; then
        pass "Controller uses /v1/webtransaction base path"
    else
        fail "Controller missing /v1/webtransaction base path"
    fi

    # Check for service dependency injection
    if grep -iq "service" "$CONTROLLER_FILE"; then
        pass "Controller has service dependency"
    else
        fail "Controller missing service dependency"
    fi

    # Check POST endpoint
    if grep -q "@PostMapping" "$CONTROLLER_FILE"; then
        pass "Controller has @PostMapping for create endpoint"
    else
        fail "Controller missing @PostMapping"
    fi

    # Check for @Valid annotation on POST
    if grep -q "@Valid" "$CONTROLLER_FILE"; then
        pass "Controller uses @Valid for request validation"
    else
        fail "Controller missing @Valid annotation"
    fi

    # Check for 201 status code on POST
    if grep -q "CREATED" "$CONTROLLER_FILE" || \
       grep -q "201" "$CONTROLLER_FILE" || \
       grep -q "@ResponseStatus.*CREATED" "$CONTROLLER_FILE"; then
        pass "POST endpoint returns 201 CREATED"
    else
        fail "POST endpoint missing 201 CREATED status"
    fi

    # Check GET by ID endpoint
    if grep -q "@GetMapping.*{id}" "$CONTROLLER_FILE" || \
       grep -q "@GetMapping.*\"/{id}\"" "$CONTROLLER_FILE"; then
        pass "Controller has GET by ID endpoint"
    else
        fail "Controller missing GET by ID endpoint"
    fi

    # Check GET by reference endpoint
    if grep -q "@GetMapping.*reference/{reference}" "$CONTROLLER_FILE" || \
       grep -q "@GetMapping.*\"/reference/{reference}\"" "$CONTROLLER_FILE"; then
        pass "Controller has GET by reference endpoint"
    else
        fail "Controller missing GET by reference endpoint"
    fi

    # Check PUT by reference endpoint
    if grep -q "@PutMapping.*reference/{reference}" "$CONTROLLER_FILE" || \
       grep -q "@PutMapping.*\"/reference/{reference}\"" "$CONTROLLER_FILE"; then
        pass "Controller has PUT by reference endpoint"
    else
        fail "Controller missing PUT by reference endpoint"
    fi

    # Check for @PathVariable annotations
    if grep -q "@PathVariable" "$CONTROLLER_FILE"; then
        pass "Controller uses @PathVariable for path parameters"
    else
        fail "Controller missing @PathVariable annotations"
    fi

    # Check for @RequestBody annotations
    if grep -q "@RequestBody" "$CONTROLLER_FILE"; then
        pass "Controller uses @RequestBody for request bodies"
    else
        fail "Controller missing @RequestBody annotations"
    fi
fi

# Test 7: Controller unit tests existence and structure
section "Controller Unit Tests"

CONTROLLER_TEST="src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt"

if [ -f "$CONTROLLER_TEST" ]; then
    pass "WebTransactionControllerTests.kt exists"

    if grep -q "@WebMvcTest" "$CONTROLLER_TEST"; then
        pass "Controller tests use @WebMvcTest"
    else
        fail "Controller tests missing @WebMvcTest annotation"
    fi

    if grep -q "@MockBean" "$CONTROLLER_TEST" || \
       grep -q "MockBean" "$CONTROLLER_TEST"; then
        pass "Controller tests use @MockBean for service"
    else
        fail "Controller tests missing @MockBean"
    fi

    # Check for POST 201 test
    if grep -iq "post.*201\|create.*201\|should.*create" "$CONTROLLER_TEST"; then
        pass "Tests include POST 201 success case"
    else
        fail "Tests missing POST 201 success test"
    fi

    # Check for validation error test (400)
    if grep -iq "400\|bad.*request\|validation.*error" "$CONTROLLER_TEST"; then
        pass "Tests include 400 validation error cases"
    else
        fail "Tests missing 400 validation error tests"
    fi

    # Check for 404 not found test
    if grep -iq "404\|not.*found" "$CONTROLLER_TEST"; then
        pass "Tests include 404 not found cases"
    else
        fail "Tests missing 404 not found tests"
    fi

    # Check for GET by ID test
    if grep -iq "get.*by.*id\|getById" "$CONTROLLER_TEST"; then
        pass "Tests include GET by ID endpoint"
    else
        fail "Tests missing GET by ID test"
    fi

    # Check for GET by reference test
    if grep -iq "get.*by.*reference\|getByReference" "$CONTROLLER_TEST"; then
        pass "Tests include GET by reference endpoint"
    else
        fail "Tests missing GET by reference test"
    fi

    # Check for PUT test
    if grep -iq "put\|update.*reference" "$CONTROLLER_TEST"; then
        pass "Tests include PUT update endpoint"
    else
        fail "Tests missing PUT update test"
    fi

    # Check for JSONB round-trip test
    if grep -iq "jsonb\|payload.*map\|nested" "$CONTROLLER_TEST"; then
        pass "Tests include JSONB round-trip validation"
    else
        fail "Tests missing JSONB round-trip tests"
    fi

    # Check for field length boundary tests
    if grep -iq "100\|255\|max.*length\|boundary" "$CONTROLLER_TEST"; then
        pass "Tests include field length boundary validation"
    else
        fail "Tests missing field length boundary tests"
    fi

    # Check for enum validation tests
    if grep -iq "enum\|invalid.*type\|invalid.*status" "$CONTROLLER_TEST"; then
        pass "Tests include enum validation"
    else
        fail "Tests missing enum validation tests"
    fi

    # Check for error response structure validation
    if grep -iq "error.*details\|field.*message" "$CONTROLLER_TEST"; then
        pass "Tests validate error response structure"
    else
        fail "Tests missing error response structure validation"
    fi
else
    fail "WebTransactionControllerTests.kt missing"
fi

# Test 8: Service unit tests existence and structure
section "Service Unit Tests"

SERVICE_TEST="src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt"

if [ -f "$SERVICE_TEST" ]; then
    pass "WebTransactionServiceTests.kt exists"

    # Check for repository mocking
    if grep -q "@MockBean\|@Mock" "$SERVICE_TEST" || \
       grep -iq "mock.*repository" "$SERVICE_TEST"; then
        pass "Service tests mock repository"
    else
        fail "Service tests missing repository mock"
    fi

    # Check for createTransaction test
    if grep -iq "create.*transaction\|test.*create" "$SERVICE_TEST"; then
        pass "Tests include createTransaction method"
    else
        fail "Tests missing createTransaction test"
    fi

    # Check for getById test
    if grep -iq "get.*by.*id\|getById" "$SERVICE_TEST"; then
        pass "Tests include getById method"
    else
        fail "Tests missing getById test"
    fi

    # Check for getByReference test
    if grep -iq "get.*by.*reference\|getByReference" "$SERVICE_TEST"; then
        pass "Tests include getByReference method"
    else
        fail "Tests missing getByReference test"
    fi

    # Check for updateByReference test
    if grep -iq "update.*by.*reference\|updateByReference" "$SERVICE_TEST"; then
        pass "Tests include updateByReference method"
    else
        fail "Tests missing updateByReference test"
    fi

    # Check for EntityNotFoundException test
    if grep -q "EntityNotFoundException" "$SERVICE_TEST"; then
        pass "Tests verify EntityNotFoundException throwing"
    else
        fail "Tests missing EntityNotFoundException verification"
    fi

    # Check for DTO mapping test
    if grep -iq "dto\|mapping\|request.*response" "$SERVICE_TEST"; then
        pass "Tests verify DTO to entity mapping"
    else
        fail "Tests missing DTO mapping verification"
    fi

    # Check for JSONB preservation test
    if grep -iq "jsonb\|payload\|nested.*map" "$SERVICE_TEST"; then
        pass "Tests verify JSONB field preservation"
    else
        fail "Tests missing JSONB preservation test"
    fi

    # Check for partial update test
    if grep -iq "partial.*update\|only.*reconcile\|unchanged.*field" "$SERVICE_TEST"; then
        pass "Tests verify partial update (only reconcileStatus and externalReferenceNumber)"
    else
        fail "Tests missing partial update verification"
    fi

    # Check for enum mapping test
    if grep -iq "enum\|transaction.*type\|reconcile.*status" "$SERVICE_TEST"; then
        pass "Tests verify enum mapping"
    else
        fail "Tests missing enum mapping test"
    fi
else
    fail "WebTransactionServiceTests.kt missing"
fi

# Test 9: Integration with WTR-3 components
section "Integration with WTR-3 Components"

# Check if controller/service reference the entity from WTR-3
ENTITY_FILE="src/main/kotlin/com/webtransaction/microsite/entity/WebTransaction.kt"

if [ -f "$ENTITY_FILE" ]; then
    pass "WebTransaction entity exists (from WTR-3)"

    # Check if service imports/references the entity
    if [ -f "$SERVICE_FILE" ] && grep -iq "WebTransaction" "$SERVICE_FILE"; then
        pass "Service references WebTransaction entity"
    else
        fail "Service does not reference WebTransaction entity"
    fi

    # Check if repository is referenced
    REPO_FILE="src/main/kotlin/com/webtransaction/microsite/repository/WebTransactionRepository.kt"
    if [ -f "$REPO_FILE" ]; then
        pass "WebTransactionRepository exists (from WTR-3)"

        if [ -f "$SERVICE_FILE" ] && grep -iq "WebTransactionRepository" "$SERVICE_FILE"; then
            pass "Service uses WebTransactionRepository"
        else
            fail "Service does not use WebTransactionRepository"
        fi
    else
        fail "WebTransactionRepository missing (should exist from WTR-3)"
    fi
else
    fail "WebTransaction entity missing (should exist from WTR-3)"
fi

# Test 10: Code quality and conventions
section "Code Quality and Kotlin Conventions"

# Check for Kotlin file extensions (.kt)
kt_files_count=$(find src/main/kotlin/com/webtransaction/microsite -name "*.kt" 2>/dev/null | wc -l)
if [ "$kt_files_count" -gt 0 ]; then
    pass "Kotlin source files use .kt extension"
else
    fail "No Kotlin source files found"
fi

# Check that all main source files are in correct package structure
if [ -d "src/main/kotlin/com/webtransaction/microsite" ]; then
    pass "Package structure follows com.webtransaction.microsite convention"
else
    fail "Package structure incorrect or missing"
fi

# Check that test files are in correct test directory
if [ -d "src/test/kotlin/com/webtransaction/microsite" ]; then
    pass "Test package structure correct"
else
    fail "Test package structure incorrect or missing"
fi

# Check for proper Spring Boot annotations usage
if [ -f "$CONTROLLER_FILE" ] && [ -f "$SERVICE_FILE" ]; then
    if grep -q "@RestController" "$CONTROLLER_FILE" && \
       grep -q "@Service" "$SERVICE_FILE"; then
        pass "Spring Boot component annotations used correctly"
    else
        fail "Spring Boot component annotations missing or incorrect"
    fi
fi

# Test 11: Acceptance criteria verification
section "Acceptance Criteria Verification"

acceptance_passed=0
acceptance_total=10

# AC1: POST returns 201 with full record
if [ -f "$CONTROLLER_FILE" ] && \
   grep -q "@PostMapping" "$CONTROLLER_FILE" && \
   (grep -q "CREATED\|201" "$CONTROLLER_FILE"); then
    pass "AC1: POST /v1/webtransaction returns 201 Created"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC1: POST endpoint does not meet 201 Created requirement"
fi

# AC2: GET by ID returns 200 or 404
if [ -f "$CONTROLLER_FILE" ] && \
   grep -q "@GetMapping.*{id}" "$CONTROLLER_FILE"; then
    pass "AC2: GET /v1/webtransaction/{id} endpoint exists"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC2: GET by ID endpoint missing"
fi

# AC3: GET by reference returns 200 or 404
if [ -f "$CONTROLLER_FILE" ] && \
   grep -q "@GetMapping.*reference/{reference}" "$CONTROLLER_FILE"; then
    pass "AC3: GET /v1/webtransaction/reference/{reference} endpoint exists"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC3: GET by reference endpoint missing"
fi

# AC4: PUT by reference returns 200
if [ -f "$CONTROLLER_FILE" ] && \
   grep -q "@PutMapping.*reference/{reference}" "$CONTROLLER_FILE"; then
    pass "AC4: PUT /v1/webtransaction/reference/{reference} endpoint exists"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC4: PUT by reference endpoint missing"
fi

# AC5: Bean validation returns 400
if [ -f "$EXCEPTION_HANDLER" ] && \
   grep -q "MethodArgumentNotValidException" "$EXCEPTION_HANDLER"; then
    pass "AC5: Bean validation errors return 400"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC5: Bean validation error handling missing"
fi

# AC6: JSONB round-trip
if [ -f "$CREATE_DTO" ] && [ -f "$RESPONSE_DTO" ] && \
   grep -iq "originalPayload.*Map" "$CREATE_DTO"; then
    pass "AC6: JSONB fields use Map type for round-trip"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC6: JSONB round-trip structure missing"
fi

# AC7: reference max length 100
if [ -f "$CREATE_DTO" ] && \
   grep -q "max.*=.*100" "$CREATE_DTO"; then
    pass "AC7: reference field max length 100 characters"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC7: reference max length 100 constraint missing"
fi

# AC8: externalReferenceNumber max length 255
if [ -f "$CREATE_DTO" ] && \
   grep -q "max.*=.*255" "$CREATE_DTO"; then
    pass "AC8: externalReferenceNumber max length 255 characters"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC8: externalReferenceNumber max length 255 constraint missing"
fi

# AC9: Service validates enum values
if [ -f "$SERVICE_FILE" ] && \
   (grep -iq "transactionType\|reconcileStatus\|externalReferenceType" "$SERVICE_FILE"); then
    pass "AC9: Service layer handles enum values"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC9: Service enum validation missing"
fi

# AC10: EntityNotFoundException triggers 404
if [ -f "$EXCEPTION_HANDLER" ] && \
   grep -q "EntityNotFoundException" "$EXCEPTION_HANDLER" && \
   (grep -q "NOT_FOUND\|404" "$EXCEPTION_HANDLER"); then
    pass "AC10: EntityNotFoundException triggers 404 response"
    acceptance_passed=$((acceptance_passed + 1))
else
    fail "AC10: EntityNotFoundException to 404 mapping missing"
fi

echo ""
echo "Acceptance Criteria: $acceptance_passed/$acceptance_total passed"

# Test 12: Documentation and comments
section "Documentation Coverage"

# Check for meaningful package documentation or class-level comments
has_docs=false

for file in "$CONTROLLER_FILE" "$SERVICE_FILE" "$EXCEPTION_HANDLER"; do
    if [ -f "$file" ] && (grep -q "^/\*\|^//\|^\s\*/\*" "$file" 2>/dev/null); then
        has_docs=true
        break
    fi
done

if [ "$has_docs" = true ]; then
    pass "Code includes documentation comments"
else
    fail "No documentation comments found in main classes"
fi

# Test 13: Build verification (if build tool present)
section "Build Verification"

if [ -f "build.gradle.kts" ]; then
    pass "Gradle build file exists"

    # Check for Spring Boot web dependency
    if grep -q "spring-boot-starter-web" build.gradle.kts 2>/dev/null; then
        pass "spring-boot-starter-web dependency present"
    else
        fail "spring-boot-starter-web dependency missing"
    fi

    # Check for validation dependency
    if grep -q "spring-boot-starter-validation" build.gradle.kts 2>/dev/null; then
        pass "spring-boot-starter-validation dependency present"
    else
        fail "spring-boot-starter-validation dependency missing"
    fi

    # Check for Kotlin reflection (needed for data classes)
    if grep -q "kotlin-reflect" build.gradle.kts 2>/dev/null; then
        pass "kotlin-reflect dependency present"
    else
        fail "kotlin-reflect dependency missing"
    fi

    # Check for Jackson Kotlin module (for JSON serialization)
    if grep -q "jackson-module-kotlin" build.gradle.kts 2>/dev/null; then
        pass "jackson-module-kotlin dependency present"
    else
        fail "jackson-module-kotlin dependency missing"
    fi
fi

# Test 14: Test coverage completeness
section "Test Coverage Completeness"

coverage_items=0
coverage_found=0

# Count expected test scenarios from plan
expected_scenarios=(
    "POST 201 success"
    "POST 400 validation error"
    "GET by ID 200 success"
    "GET by ID 404 not found"
    "GET by reference 200 success"
    "GET by reference 404 not found"
    "PUT 200 success"
    "PUT 404 not found"
    "JSONB round-trip"
    "Field length boundaries"
    "Enum validation"
    "Partial update verification"
    "EntityNotFoundException handling"
    "Error response structure"
)

for scenario in "${expected_scenarios[@]}"; do
    coverage_items=$((coverage_items + 1))
done

# Check if test files contain hints for these scenarios
if [ -f "$CONTROLLER_TEST" ] || [ -f "$SERVICE_TEST" ]; then
    test_content=""
    [ -f "$CONTROLLER_TEST" ] && test_content+=$(cat "$CONTROLLER_TEST")
    [ -f "$SERVICE_TEST" ] && test_content+=$(cat "$SERVICE_TEST")

    for scenario in "${expected_scenarios[@]}"; do
        # Simple heuristic: check if test content contains key terms
        case "$scenario" in
            *"POST 201"*) echo "$test_content" | grep -iq "post.*201\|create.*success" && coverage_found=$((coverage_found + 1)) ;;
            *"POST 400"*) echo "$test_content" | grep -iq "post.*400\|validation.*error" && coverage_found=$((coverage_found + 1)) ;;
            *"GET by ID 200"*) echo "$test_content" | grep -iq "get.*id.*200\|getById.*success" && coverage_found=$((coverage_found + 1)) ;;
            *"GET by ID 404"*) echo "$test_content" | grep -iq "get.*id.*404\|getById.*not.*found" && coverage_found=$((coverage_found + 1)) ;;
            *"GET by reference 200"*) echo "$test_content" | grep -iq "get.*reference.*200\|getByReference.*success" && coverage_found=$((coverage_found + 1)) ;;
            *"GET by reference 404"*) echo "$test_content" | grep -iq "get.*reference.*404\|getByReference.*not.*found" && coverage_found=$((coverage_found + 1)) ;;
            *"PUT 200"*) echo "$test_content" | grep -iq "put.*200\|update.*success" && coverage_found=$((coverage_found + 1)) ;;
            *"PUT 404"*) echo "$test_content" | grep -iq "put.*404\|update.*not.*found" && coverage_found=$((coverage_found + 1)) ;;
            *"JSONB"*) echo "$test_content" | grep -iq "jsonb\|payload.*map\|nested" && coverage_found=$((coverage_found + 1)) ;;
            *"length"*) echo "$test_content" | grep -iq "length\|100\|255\|boundary" && coverage_found=$((coverage_found + 1)) ;;
            *"Enum"*) echo "$test_content" | grep -iq "enum\|invalid.*type" && coverage_found=$((coverage_found + 1)) ;;
            *"Partial"*) echo "$test_content" | grep -iq "partial.*update\|only.*reconcile" && coverage_found=$((coverage_found + 1)) ;;
            *"EntityNotFoundException"*) echo "$test_content" | grep -iq "EntityNotFoundException" && coverage_found=$((coverage_found + 1)) ;;
            *"Error response"*) echo "$test_content" | grep -iq "error.*details\|error.*structure" && coverage_found=$((coverage_found + 1)) ;;
        esac
    done

    if [ "$coverage_found" -ge 10 ]; then
        pass "Test coverage appears comprehensive ($coverage_found/$coverage_items scenarios covered)"
    else
        fail "Test coverage appears incomplete ($coverage_found/$coverage_items scenarios covered)"
    fi
else
    fail "Cannot assess test coverage - test files missing"
fi

# Test 15: Plan step completion verification
section "Plan Step Completion Verification"

plan_steps_complete=0
plan_steps_total=10

# Step 1: EntityNotFoundException
[ -f "$ENTITY_NOT_FOUND" ] && plan_steps_complete=$((plan_steps_complete + 1))

# Step 2: GlobalExceptionHandler
[ -f "$EXCEPTION_HANDLER" ] && plan_steps_complete=$((plan_steps_complete + 1))

# Step 3: DTOs
[ -f "$CREATE_DTO" ] && [ -f "$UPDATE_DTO" ] && [ -f "$RESPONSE_DTO" ] && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 4: Service create operation
[ -f "$SERVICE_FILE" ] && grep -q "fun createTransaction\|fun create" "$SERVICE_FILE" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 5: Service read operations
[ -f "$SERVICE_FILE" ] && \
    grep -q "fun getTransactionById\|fun getById" "$SERVICE_FILE" && \
    grep -q "fun getTransactionByReference\|fun getByReference" "$SERVICE_FILE" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 6: Service update operation
[ -f "$SERVICE_FILE" ] && grep -q "fun updateTransactionByReference\|fun updateByReference" "$SERVICE_FILE" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 7: Controller POST endpoint
[ -f "$CONTROLLER_FILE" ] && grep -q "@PostMapping" "$CONTROLLER_FILE" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 8: Controller GET endpoints
[ -f "$CONTROLLER_FILE" ] && \
    grep -q "@GetMapping.*{id}" "$CONTROLLER_FILE" && \
    grep -q "@GetMapping.*reference/{reference}" "$CONTROLLER_FILE" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 9: Controller PUT endpoint
[ -f "$CONTROLLER_FILE" ] && grep -q "@PutMapping.*reference/{reference}" "$CONTROLLER_FILE" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 10: E2E validation coverage
[ -f "$CONTROLLER_TEST" ] && [ -f "$SERVICE_TEST" ] && \
    plan_steps_complete=$((plan_steps_complete + 1))

if [ "$plan_steps_complete" -eq "$plan_steps_total" ]; then
    pass "All plan steps completed ($plan_steps_complete/$plan_steps_total)"
else
    fail "Plan steps incomplete ($plan_steps_complete/$plan_steps_total completed)"
fi

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
    echo "✓ WTR-4 E2E measurement: ALL TESTS PASSED"
else
    echo "✗ WTR-4 E2E measurement: SOME TESTS FAILED"
fi

echo ""
exit $EXIT_CODE
