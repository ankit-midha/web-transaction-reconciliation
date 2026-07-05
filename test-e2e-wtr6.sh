#!/bin/bash
# Full E2E measurement test for WTR-6 implementation
# Tests comprehensive test coverage (≥95% JaCoCo), unit tests, functional tests, and configuration

set -e

echo "=========================================="
echo "WTR-6 E2E Measurement Test"
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

# Test 1: Build Configuration - JaCoCo Plugin
section "Build Configuration - JaCoCo Plugin"

if [ -f "build.gradle.kts" ]; then
    pass "build.gradle.kts exists"
else
    fail "build.gradle.kts missing"
fi

if grep -q "id(\"jacoco\")" build.gradle.kts 2>/dev/null; then
    pass "JaCoCo plugin applied"
else
    fail "JaCoCo plugin not applied"
fi

if grep -q "jacocoTestReport" build.gradle.kts 2>/dev/null; then
    pass "jacocoTestReport task configured"

    # Check for HTML and XML reports
    if grep -q "html.required.set(true)" build.gradle.kts 2>/dev/null; then
        pass "HTML report enabled"
    else
        fail "HTML report not enabled"
    fi

    if grep -q "xml.required.set(true)" build.gradle.kts 2>/dev/null; then
        pass "XML report enabled"
    else
        fail "XML report not enabled"
    fi
else
    fail "jacocoTestReport task not configured"
fi

if grep -q "jacocoTestCoverageVerification" build.gradle.kts 2>/dev/null; then
    pass "jacocoTestCoverageVerification task configured"

    # Check for 95% threshold
    if grep -E "minimum.*0\.95|minimum.*0\.9[5-9]" build.gradle.kts 2>/dev/null; then
        pass "95% coverage threshold configured"
    else
        fail "95% coverage threshold not configured"
    fi

    # Check all four counters (instruction, line, method, class)
    counter_count=0
    for counter in "INSTRUCTION" "LINE" "METHOD" "CLASS"; do
        if grep -q "$counter" build.gradle.kts 2>/dev/null; then
            counter_count=$((counter_count + 1))
        fi
    done

    if [ "$counter_count" -eq 4 ]; then
        pass "All four coverage counters configured (instruction, line, method, class)"
    else
        fail "Not all four coverage counters configured (found $counter_count/4)"
    fi
else
    fail "jacocoTestCoverageVerification task not configured"
fi

# Test 2: Testcontainers Dependencies
section "Testcontainers Dependencies"

if grep -q "testcontainers:postgresql" build.gradle.kts 2>/dev/null; then
    pass "Testcontainers PostgreSQL dependency present"

    # Check version 1.21.4
    if grep -q "testcontainers:postgresql:1.21.4" build.gradle.kts 2>/dev/null; then
        pass "Testcontainers PostgreSQL version 1.21.4 specified"
    else
        fail "Testcontainers PostgreSQL version is not 1.21.4"
    fi
else
    fail "Testcontainers PostgreSQL dependency missing"
fi

if grep -q "testcontainers:junit-jupiter" build.gradle.kts 2>/dev/null; then
    pass "Testcontainers JUnit Jupiter dependency present"

    if grep -q "testcontainers:junit-jupiter:1.21.4" build.gradle.kts 2>/dev/null; then
        pass "Testcontainers JUnit Jupiter version 1.21.4 specified"
    else
        fail "Testcontainers JUnit Jupiter version is not 1.21.4"
    fi
else
    fail "Testcontainers JUnit Jupiter dependency missing"
fi

if grep -q "io.mockk:mockk" build.gradle.kts 2>/dev/null; then
    pass "MockK dependency present"

    if grep -q "io.mockk:mockk:1.13.8" build.gradle.kts 2>/dev/null; then
        pass "MockK version 1.13.8 specified"
    else
        fail "MockK version is not 1.13.8"
    fi
else
    fail "MockK dependency missing (optional - Mockito is acceptable alternative)"
fi

# Test 3: Environment-Specific Application YAML Files
section "Environment-Specific Application YAML Files"

yaml_profiles=("local" "test" "dev" "staging" "prod")

for profile in "${yaml_profiles[@]}"; do
    yaml_file="src/main/resources/application-${profile}.yml"

    if [ -f "$yaml_file" ]; then
        pass "application-${profile}.yml exists"

        # Check for datasource configuration
        if grep -q "spring.datasource" "$yaml_file" || grep -q "datasource:" "$yaml_file"; then
            pass "application-${profile}.yml: datasource configuration present"
        else
            fail "application-${profile}.yml: datasource configuration missing"
        fi

        # Check for DB_URL placeholder
        if grep -q "DB_URL" "$yaml_file"; then
            pass "application-${profile}.yml: DB_URL environment variable placeholder present"
        else
            fail "application-${profile}.yml: DB_URL environment variable placeholder missing"
        fi

        # Check for Flyway configuration
        if grep -q "flyway" "$yaml_file"; then
            pass "application-${profile}.yml: Flyway configuration present"
        else
            fail "application-${profile}.yml: Flyway configuration missing"
        fi

        # Check for security configuration
        if grep -q "security" "$yaml_file"; then
            pass "application-${profile}.yml: security configuration present"
        else
            fail "application-${profile}.yml: security configuration missing"
        fi
    else
        fail "application-${profile}.yml missing"
    fi
done

# Test 4: Controller Unit Tests (WebTransactionControllerTests.kt)
section "Controller Unit Tests - WebTransactionControllerTests.kt"

controller_test_file="src/test/kotlin/com/webtransaction/microsite/controller/WebTransactionControllerTests.kt"

if [ -f "$controller_test_file" ]; then
    pass "WebTransactionControllerTests.kt exists"

    # Check for @WebMvcTest annotation
    if grep -q "@WebMvcTest" "$controller_test_file"; then
        pass "Uses @WebMvcTest annotation"
    else
        fail "@WebMvcTest annotation missing"
    fi

    # Check for @MockBean for service
    if grep -q "@MockBean" "$controller_test_file"; then
        pass "@MockBean annotation present (for service layer)"
    else
        fail "@MockBean annotation missing"
    fi

    # Check for required test methods (6 tests per plan)
    test_count=0

    if grep -iq "test.*post.*create\|create.*transaction.*test" "$controller_test_file"; then
        test_count=$((test_count + 1))
        pass "POST create transaction test present"
    else
        fail "POST create transaction test missing"
    fi

    if grep -iq "test.*get.*by.*id\|get.*transaction.*by.*id.*test" "$controller_test_file"; then
        test_count=$((test_count + 1))
        pass "GET by ID test present"
    else
        fail "GET by ID test missing"
    fi

    if grep -iq "test.*get.*by.*reference\|get.*transaction.*by.*reference.*test" "$controller_test_file"; then
        test_count=$((test_count + 1))
        pass "GET by reference test present"
    else
        fail "GET by reference test missing"
    fi

    if grep -iq "test.*put.*update\|update.*transaction.*test" "$controller_test_file"; then
        test_count=$((test_count + 1))
        pass "PUT update by reference test present"
    else
        fail "PUT update by reference test missing"
    fi

    if grep -iq "test.*404\|not.*found.*test\|entity.*not.*found" "$controller_test_file"; then
        test_count=$((test_count + 1))
        pass "404 EntityNotFoundException test present"
    else
        fail "404 EntityNotFoundException test missing"
    fi

    if grep -iq "test.*validation\|test.*400\|invalid.*request" "$controller_test_file"; then
        test_count=$((test_count + 1))
        pass "400 validation error test present"
    else
        fail "400 validation error test missing"
    fi

    if [ "$test_count" -ge 6 ]; then
        pass "All 6 required controller tests present"
    else
        fail "Only $test_count/6 controller tests found"
    fi
else
    fail "WebTransactionControllerTests.kt missing"
fi

# Test 5: Service Unit Tests (WebTransactionServiceTests.kt)
section "Service Unit Tests - WebTransactionServiceTests.kt"

service_test_file="src/test/kotlin/com/webtransaction/microsite/service/WebTransactionServiceTests.kt"

if [ -f "$service_test_file" ]; then
    pass "WebTransactionServiceTests.kt exists"

    # Check for @MockBean for repository
    if grep -q "@MockBean\|@Mock" "$service_test_file"; then
        pass "Mock annotation present for repository"
    else
        fail "Mock annotation missing for repository"
    fi

    # Check for required test methods (9 tests per plan)
    service_test_count=0

    if grep -iq "test.*create.*transaction\|create.*test" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "createTransaction test present"
    else
        fail "createTransaction test missing"
    fi

    if grep -iq "test.*get.*by.*id.*found\|get.*transaction.*by.*id.*success" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "getTransactionById found case test present"
    else
        fail "getTransactionById found case test missing"
    fi

    if grep -iq "test.*get.*by.*id.*not.*found\|get.*transaction.*by.*id.*throws" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "getTransactionById not found case test present"
    else
        fail "getTransactionById not found case test missing"
    fi

    if grep -iq "test.*get.*by.*reference.*found" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "getTransactionByReference found case test present"
    else
        fail "getTransactionByReference found case test missing"
    fi

    if grep -iq "test.*get.*by.*reference.*not.*found" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "getTransactionByReference not found case test present"
    else
        fail "getTransactionByReference not found case test missing"
    fi

    if grep -iq "test.*update.*found\|update.*transaction.*success" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "updateTransactionByReference found case test present"
    else
        fail "updateTransactionByReference found case test missing"
    fi

    if grep -iq "test.*update.*not.*found\|update.*transaction.*throws" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "updateTransactionByReference not found case test present"
    else
        fail "updateTransactionByReference not found case test missing"
    fi

    if grep -iq "test.*jsonb.*original\|original.*payload.*test" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "JSONB originalPayload test present"
    else
        fail "JSONB originalPayload test missing"
    fi

    if grep -iq "test.*jsonb.*reconcile\|reconcile.*payload.*test" "$service_test_file"; then
        service_test_count=$((service_test_count + 1))
        pass "JSONB reconcilePayload null handling test present"
    else
        fail "JSONB reconcilePayload null handling test missing"
    fi

    if [ "$service_test_count" -ge 9 ]; then
        pass "All 9 required service tests present"
    else
        fail "Only $service_test_count/9 service tests found"
    fi
else
    fail "WebTransactionServiceTests.kt missing"
fi

# Test 6: GlobalExceptionHandler Unit Tests
section "GlobalExceptionHandler Unit Tests"

exception_handler_test_file="src/test/kotlin/com/webtransaction/microsite/exception/GlobalExceptionHandlerTests.kt"

if [ -f "$exception_handler_test_file" ]; then
    pass "GlobalExceptionHandlerTests.kt exists"

    # Check for required test methods (6 tests per plan)
    exception_test_count=0

    if grep -iq "test.*entity.*not.*found.*404\|404.*test" "$exception_handler_test_file"; then
        exception_test_count=$((exception_test_count + 1))
        pass "EntityNotFoundException 404 test present"
    else
        fail "EntityNotFoundException 404 test missing"
    fi

    if grep -iq "test.*validation.*400\|method.*argument.*not.*valid" "$exception_handler_test_file"; then
        exception_test_count=$((exception_test_count + 1))
        pass "MethodArgumentNotValidException 400 test present"
    else
        fail "MethodArgumentNotValidException 400 test missing"
    fi

    if grep -iq "test.*generic.*exception.*500\|internal.*server.*error" "$exception_handler_test_file"; then
        exception_test_count=$((exception_test_count + 1))
        pass "Generic Exception 500 test present"
    else
        fail "Generic Exception 500 test missing"
    fi

    if grep -iq "test.*optimistic.*lock.*409\|409.*conflict" "$exception_handler_test_file"; then
        exception_test_count=$((exception_test_count + 1))
        pass "OptimisticLockException 409 test present"
    else
        fail "OptimisticLockException 409 test missing"
    fi

    if grep -iq "test.*invalid.*enum\|enum.*deserialization" "$exception_handler_test_file"; then
        exception_test_count=$((exception_test_count + 1))
        pass "Invalid enum deserialization 400 test present"
    else
        fail "Invalid enum deserialization 400 test missing"
    fi

    if grep -iq "test.*empty.*request.*body\|null.*payload" "$exception_handler_test_file"; then
        exception_test_count=$((exception_test_count + 1))
        pass "Empty request body 400 test present"
    else
        fail "Empty request body 400 test missing"
    fi

    if [ "$exception_test_count" -ge 6 ]; then
        pass "All 6 required exception handler tests present"
    else
        fail "Only $exception_test_count/6 exception handler tests found"
    fi
else
    fail "GlobalExceptionHandlerTests.kt missing"
fi

# Test 7: DTO Unit Tests (3 files, 8 tests total)
section "DTO Unit Tests"

dto_test_count=0
total_dto_tests=0

# CreateWebTransactionRequestTests (3 tests)
create_dto_test="src/test/kotlin/com/webtransaction/microsite/dto/CreateWebTransactionRequestTests.kt"
if [ -f "$create_dto_test" ]; then
    pass "CreateWebTransactionRequestTests.kt exists"
    dto_test_count=$((dto_test_count + 1))

    if grep -iq "test.*constructor\|default.*constructor" "$create_dto_test"; then
        pass "CreateRequest: default constructor test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi

    if grep -iq "test.*copy\|copy.*constructor" "$create_dto_test"; then
        pass "CreateRequest: copy constructor test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi

    if grep -iq "test.*equals\|test.*hashcode" "$create_dto_test"; then
        pass "CreateRequest: equals/hashCode test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi
else
    fail "CreateWebTransactionRequestTests.kt missing"
fi

# UpdateWebTransactionRequestTests (3 tests)
update_dto_test="src/test/kotlin/com/webtransaction/microsite/dto/UpdateWebTransactionRequestTests.kt"
if [ -f "$update_dto_test" ]; then
    pass "UpdateWebTransactionRequestTests.kt exists"
    dto_test_count=$((dto_test_count + 1))

    if grep -iq "test.*constructor\|default.*constructor" "$update_dto_test"; then
        pass "UpdateRequest: default constructor test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi

    if grep -iq "test.*copy\|copy.*constructor" "$update_dto_test"; then
        pass "UpdateRequest: copy constructor test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi

    if grep -iq "test.*equals\|test.*hashcode" "$update_dto_test"; then
        pass "UpdateRequest: equals/hashCode test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi
else
    fail "UpdateWebTransactionRequestTests.kt missing"
fi

# WebTransactionResponseTests (2 tests)
response_dto_test="src/test/kotlin/com/webtransaction/microsite/dto/WebTransactionResponseTests.kt"
if [ -f "$response_dto_test" ]; then
    pass "WebTransactionResponseTests.kt exists"
    dto_test_count=$((dto_test_count + 1))

    if grep -iq "test.*tostring\|to.*string" "$response_dto_test"; then
        pass "Response: toString test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi

    if grep -iq "test.*iso.*8601\|timestamp.*serialization" "$response_dto_test"; then
        pass "Response: ISO-8601 timestamp serialization test present"
        total_dto_tests=$((total_dto_tests + 1))
    fi
else
    fail "WebTransactionResponseTests.kt missing"
fi

if [ "$dto_test_count" -eq 3 ]; then
    pass "All 3 DTO test files present"
else
    fail "Only $dto_test_count/3 DTO test files found"
fi

if [ "$total_dto_tests" -ge 8 ]; then
    pass "All 8 DTO tests present"
else
    fail "Only $total_dto_tests/8 DTO tests found"
fi

# Test 8: Entity Unit Tests (WebTransactionEntityTests.kt)
section "Entity Unit Tests - WebTransactionEntityTests.kt"

entity_test_file="src/test/kotlin/com/webtransaction/microsite/entity/WebTransactionEntityTests.kt"

if [ -f "$entity_test_file" ]; then
    pass "WebTransactionEntityTests.kt exists"

    entity_test_count=0

    if grep -iq "test.*no.*arg.*constructor\|default.*constructor" "$entity_test_file"; then
        entity_test_count=$((entity_test_count + 1))
        pass "Entity: no-arg constructor test present"
    else
        fail "Entity: no-arg constructor test missing"
    fi

    if grep -iq "test.*all.*args.*constructor\|primary.*constructor" "$entity_test_file"; then
        entity_test_count=$((entity_test_count + 1))
        pass "Entity: all-args constructor test present"
    else
        fail "Entity: all-args constructor test missing"
    fi

    if grep -iq "test.*setters\|test.*copy\|field.*update" "$entity_test_file"; then
        entity_test_count=$((entity_test_count + 1))
        pass "Entity: field setter/copy test present"
    else
        fail "Entity: field setter/copy test missing"
    fi

    if grep -iq "@Entity\|@Table\|@Id\|@Version" "$entity_test_file"; then
        pass "Entity: JPA annotation verification test present"
    fi

    if [ "$entity_test_count" -ge 3 ]; then
        pass "All 3 required entity tests present"
    else
        fail "Only $entity_test_count/3 entity tests found"
    fi
else
    fail "WebTransactionEntityTests.kt missing"
fi

# Test 9: DataSourceConfig Unit Tests
section "DataSourceConfig Unit Tests"

datasource_test_file="src/test/kotlin/com/webtransaction/microsite/config/DataSourceConfigTests.kt"

if [ -f "$datasource_test_file" ]; then
    pass "DataSourceConfigTests.kt exists"

    # Check for @SpringBootTest annotation
    if grep -q "@SpringBootTest" "$datasource_test_file"; then
        pass "Uses @SpringBootTest annotation"
    else
        fail "@SpringBootTest annotation missing"
    fi

    datasource_test_count=0

    if grep -iq "test.*postgres.*url\|jdbc.*url.*test" "$datasource_test_file"; then
        datasource_test_count=$((datasource_test_count + 1))
        pass "Postgres URL format test present"
    else
        fail "Postgres URL format test missing"
    fi

    if grep -iq "test.*connection.*pool\|hikari.*config" "$datasource_test_file"; then
        datasource_test_count=$((datasource_test_count + 1))
        pass "Connection pool properties test present"
    else
        fail "Connection pool properties test missing"
    fi

    if grep -iq "test.*invalid.*url\|invalid.*db.*url" "$datasource_test_file"; then
        datasource_test_count=$((datasource_test_count + 1))
        pass "Invalid DB URL test present"
    else
        fail "Invalid DB URL test missing"
    fi

    if grep -iq "test.*missing.*credentials\|missing.*db.*credentials" "$datasource_test_file"; then
        datasource_test_count=$((datasource_test_count + 1))
        pass "Missing DB credentials test present"
    else
        fail "Missing DB credentials test missing"
    fi

    if [ "$datasource_test_count" -ge 4 ]; then
        pass "All 4 required DataSourceConfig tests present"
    else
        fail "Only $datasource_test_count/4 DataSourceConfig tests found"
    fi
else
    fail "DataSourceConfigTests.kt missing"
fi

# Test 10: Health Endpoint Unit Test
section "Health Endpoint Unit Test"

health_test_file="src/test/kotlin/com/webtransaction/microsite/health/HealthEndpointTests.kt"

if [ -f "$health_test_file" ]; then
    pass "HealthEndpointTests.kt exists"

    # Check for @WebMvcTest annotation
    if grep -q "@WebMvcTest" "$health_test_file"; then
        pass "Uses @WebMvcTest annotation"
    else
        fail "@WebMvcTest annotation missing"
    fi

    if grep -iq "test.*health\|/actuator/health" "$health_test_file"; then
        pass "Health endpoint GET test present"
    else
        fail "Health endpoint GET test missing"
    fi

    if grep -iq "\"UP\"\|status.*up" "$health_test_file"; then
        pass "Health endpoint verifies UP status"
    else
        fail "Health endpoint UP status verification missing"
    fi
else
    fail "HealthEndpointTests.kt missing"
fi

# Test 11: Functional Integration Tests (14 tests)
section "Functional Integration Tests - WebTransactionFunctionalTests.kt"

functional_test_file="src/test/kotlin/com/webtransaction/microsite/functional/WebTransactionFunctionalTests.kt"

if [ -f "$functional_test_file" ]; then
    pass "WebTransactionFunctionalTests.kt exists"

    # Check for @SpringBootTest annotation
    if grep -q "@SpringBootTest" "$functional_test_file"; then
        pass "Uses @SpringBootTest annotation"
    else
        fail "@SpringBootTest annotation missing"
    fi

    # Check for Testcontainers annotations
    if grep -q "@Testcontainers" "$functional_test_file"; then
        pass "@Testcontainers annotation present"
    else
        fail "@Testcontainers annotation missing"
    fi

    if grep -q "@Container" "$functional_test_file"; then
        pass "@Container annotation present"
    else
        fail "@Container annotation missing"
    fi

    # Check for Postgres 15.4 container
    if grep -q "postgres:15.4\|PostgreSQLContainer" "$functional_test_file"; then
        pass "Postgres 15.4 container configuration present"
    else
        fail "Postgres 15.4 container configuration missing"
    fi

    functional_test_count=0

    # 14 tests per plan
    test_patterns=(
        "test.*post.*create|create.*transaction.*functional"
        "test.*get.*by.*id.*created|retrieve.*by.*id"
        "test.*get.*by.*reference.*created|retrieve.*by.*reference"
        "test.*put.*update|update.*by.*reference"
        "test.*get.*updated|verify.*update"
        "test.*missing.*required.*field|400.*missing"
        "test.*reference.*max.*length|400.*length"
        "test.*invalid.*enum|400.*enum"
        "test.*get.*non.*existent.*id|404.*by.*id"
        "test.*get.*non.*existent.*reference|404.*by.*reference"
        "test.*put.*non.*existent|404.*update"
        "test.*jsonb.*nested|jsonb.*roundtrip"
        "test.*security.*disabled|unauthenticated.*success"
        "test.*security.*enabled|401.*unauthorized"
    )

    for pattern in "${test_patterns[@]}"; do
        if grep -Eiq "$pattern" "$functional_test_file"; then
            functional_test_count=$((functional_test_count + 1))
        fi
    done

    if [ "$functional_test_count" -ge 14 ]; then
        pass "All 14 required functional tests present"
    else
        fail "Only $functional_test_count/14 functional tests found"
    fi
else
    fail "WebTransactionFunctionalTests.kt missing"
fi

# Test 12: Package Structure Verification
section "Package Structure Verification"

base_src_path="src/main/kotlin/com/webtransaction/microsite"
base_test_path="src/test/kotlin/com/webtransaction/microsite"

# Production packages
if [ -d "$base_src_path/controller" ]; then
    pass "Production controller package exists"
else
    fail "Production controller package missing"
fi

if [ -d "$base_src_path/service" ]; then
    pass "Production service package exists"
else
    fail "Production service package missing"
fi

if [ -d "$base_src_path/dto" ]; then
    pass "Production dto package exists"
else
    fail "Production dto package missing"
fi

if [ -d "$base_src_path/entity" ]; then
    pass "Production entity package exists"
else
    fail "Production entity package missing"
fi

if [ -d "$base_src_path/exception" ]; then
    pass "Production exception package exists"
else
    fail "Production exception package missing"
fi

if [ -d "$base_src_path/config" ]; then
    pass "Production config package exists"
else
    fail "Production config package missing"
fi

# Test packages
if [ -d "$base_test_path/controller" ]; then
    pass "Test controller package exists"
else
    fail "Test controller package missing"
fi

if [ -d "$base_test_path/service" ]; then
    pass "Test service package exists"
else
    fail "Test service package missing"
fi

if [ -d "$base_test_path/dto" ]; then
    pass "Test dto package exists"
else
    fail "Test dto package missing"
fi

if [ -d "$base_test_path/functional" ]; then
    pass "Test functional package exists"
else
    fail "Test functional package missing"
fi

# Test 13: Build and Test Execution
section "Build and Test Execution"

if [ -f "./gradlew" ]; then
    pass "Gradle wrapper present"

    # Try to run tests (optional - may fail if implementation incomplete)
    if ./gradlew test --dry-run > /dev/null 2>&1; then
        pass "Gradle test task can be dry-run"
    else
        fail "Gradle test task dry-run failed"
    fi
else
    fail "Gradle wrapper missing"
fi

# Test 14: JaCoCo Report Generation
section "JaCoCo Report Generation"

if [ -f "./gradlew" ]; then
    # Check if jacocoTestReport task exists
    if ./gradlew tasks --all 2>/dev/null | grep -q "jacocoTestReport"; then
        pass "jacocoTestReport task is available"
    else
        fail "jacocoTestReport task not available"
    fi

    # Check if jacocoTestCoverageVerification task exists
    if ./gradlew tasks --all 2>/dev/null | grep -q "jacocoTestCoverageVerification"; then
        pass "jacocoTestCoverageVerification task is available"
    else
        fail "jacocoTestCoverageVerification task not available"
    fi
fi

# Test 15: Test Count Verification (51 tests per plan)
section "Test Count Verification"

# Count @Test annotations in all test files
test_annotation_count=0

if [ -d "src/test/kotlin" ]; then
    test_annotation_count=$(find src/test/kotlin -name "*Test*.kt" -type f -exec grep -h "@Test" {} + 2>/dev/null | wc -l)

    if [ "$test_annotation_count" -ge 51 ]; then
        pass "Expected test count present: $test_annotation_count tests (≥51 required)"
    elif [ "$test_annotation_count" -gt 0 ]; then
        fail "Only $test_annotation_count tests found (51 required per plan)"
    else
        fail "No @Test annotations found"
    fi
else
    fail "Test directory src/test/kotlin not found"
fi

# Test 16: Acceptance Criteria Validation
section "Acceptance Criteria Validation"

# AC1: JaCoCo plugin configured with 95% threshold
if grep -q "jacoco" build.gradle.kts 2>/dev/null && grep -Eq "minimum.*0\.95" build.gradle.kts 2>/dev/null; then
    pass "AC1: JaCoCo plugin configured with 95% threshold"
else
    fail "AC1: JaCoCo plugin with 95% threshold not fully configured"
fi

# AC2: Testcontainers dependencies (1.21.4)
if grep -q "testcontainers.*1.21.4" build.gradle.kts 2>/dev/null; then
    pass "AC2: Testcontainers 1.21.4 dependencies present"
else
    fail "AC2: Testcontainers 1.21.4 dependencies missing"
fi

# AC3: Environment-specific YAML files (5 profiles)
yaml_count=0
for profile in "local" "test" "dev" "staging" "prod"; do
    if [ -f "src/main/resources/application-${profile}.yml" ]; then
        yaml_count=$((yaml_count + 1))
    fi
done

if [ "$yaml_count" -eq 5 ]; then
    pass "AC3: All 5 environment-specific YAML files present"
else
    fail "AC3: Only $yaml_count/5 environment-specific YAML files found"
fi

# AC4: Unit tests for controller (6 tests)
if [ -f "$controller_test_file" ]; then
    pass "AC4: Controller unit tests file exists"
else
    fail "AC4: Controller unit tests file missing"
fi

# AC5: Unit tests for service (9 tests)
if [ -f "$service_test_file" ]; then
    pass "AC5: Service unit tests file exists"
else
    fail "AC5: Service unit tests file missing"
fi

# AC6: GlobalExceptionHandler tests (6 tests)
if [ -f "$exception_handler_test_file" ]; then
    pass "AC6: GlobalExceptionHandler tests file exists"
else
    fail "AC6: GlobalExceptionHandler tests file missing"
fi

# AC7: DTO unit tests (8 tests across 3 files)
if [ -f "$create_dto_test" ] && [ -f "$update_dto_test" ] && [ -f "$response_dto_test" ]; then
    pass "AC7: All 3 DTO test files present"
else
    fail "AC7: Not all DTO test files present"
fi

# AC8: Entity unit tests (3 tests)
if [ -f "$entity_test_file" ]; then
    pass "AC8: Entity unit tests file exists"
else
    fail "AC8: Entity unit tests file missing"
fi

# AC9: DataSourceConfig tests (4 tests)
if [ -f "$datasource_test_file" ]; then
    pass "AC9: DataSourceConfig tests file exists"
else
    fail "AC9: DataSourceConfig tests file missing"
fi

# AC10: Functional integration tests with Testcontainers (14 tests)
if [ -f "$functional_test_file" ]; then
    pass "AC10: Functional integration tests file exists"
else
    fail "AC10: Functional integration tests file missing"
fi

# Test 17: Plan Step Completion (11 steps)
section "Plan Step Completion Verification"

# Step 1: JaCoCo and Testcontainers in build.gradle.kts
if grep -q "jacoco" build.gradle.kts 2>/dev/null && grep -q "testcontainers" build.gradle.kts 2>/dev/null; then
    pass "Step 1: Gradle build configured with JaCoCo and Testcontainers"
else
    fail "Step 1: Gradle build configuration incomplete"
fi

# Step 2: Environment-specific YAML files
if [ "$yaml_count" -eq 5 ]; then
    pass "Step 2: Environment-specific application YAML files created"
else
    fail "Step 2: Environment-specific YAML files incomplete"
fi

# Step 3: WebTransactionController tests
if [ -f "$controller_test_file" ]; then
    pass "Step 3: WebTransactionController unit tests written"
else
    fail "Step 3: WebTransactionController unit tests missing"
fi

# Step 4: WebTransactionService tests
if [ -f "$service_test_file" ]; then
    pass "Step 4: WebTransactionService unit tests written"
else
    fail "Step 4: WebTransactionService unit tests missing"
fi

# Step 5: GlobalExceptionHandler tests
if [ -f "$exception_handler_test_file" ]; then
    pass "Step 5: GlobalExceptionHandler unit tests written"
else
    fail "Step 5: GlobalExceptionHandler unit tests missing"
fi

# Step 6: DTO tests
if [ -f "$create_dto_test" ] && [ -f "$update_dto_test" ] && [ -f "$response_dto_test" ]; then
    pass "Step 6: DTO unit tests written (3 files)"
else
    fail "Step 6: DTO unit tests incomplete"
fi

# Step 7: Entity tests
if [ -f "$entity_test_file" ]; then
    pass "Step 7: WebTransactionEntity unit tests written"
else
    fail "Step 7: WebTransactionEntity unit tests missing"
fi

# Step 8: DataSourceConfig tests
if [ -f "$datasource_test_file" ]; then
    pass "Step 8: DataSourceConfig unit tests written"
else
    fail "Step 8: DataSourceConfig unit tests missing"
fi

# Step 9: Health endpoint test
if [ -f "$health_test_file" ]; then
    pass "Step 9: Health endpoint unit test written"
else
    fail "Step 9: Health endpoint unit test missing"
fi

# Step 10: Functional integration tests
if [ -f "$functional_test_file" ]; then
    pass "Step 10: Functional integration tests written"
else
    fail "Step 10: Functional integration tests missing"
fi

# Step 11: JaCoCo coverage verification (check if tasks available)
if ./gradlew tasks --all 2>/dev/null | grep -q "jacocoTestCoverageVerification"; then
    pass "Step 11: JaCoCo coverage verification task configured"
else
    fail "Step 11: JaCoCo coverage verification task not available"
fi

# Test 18: Code Quality and Conventions
section "Code Quality and Conventions"

# Check for Kotlin file extensions
kotlin_src_count=$(find src/main/kotlin -name "*.kt" -type f 2>/dev/null | wc -l)
kotlin_test_count=$(find src/test/kotlin -name "*.kt" -type f 2>/dev/null | wc -l)

if [ "$kotlin_src_count" -gt 0 ]; then
    pass "Kotlin source files present ($kotlin_src_count files)"
else
    fail "No Kotlin source files found"
fi

if [ "$kotlin_test_count" -gt 0 ]; then
    pass "Kotlin test files present ($kotlin_test_count files)"
else
    fail "No Kotlin test files found"
fi

# Check for proper test naming convention
if find src/test/kotlin -name "*Tests.kt" -type f 2>/dev/null | grep -q .; then
    pass "Test files follow naming convention (*Tests.kt)"
else
    fail "Test files do not follow naming convention (*Tests.kt)"
fi

# Test 19: Git Branch Verification
section "Git Branch Verification"

current_branch=$(git branch --show-current 2>/dev/null)

if echo "$current_branch" | grep -iq "wtr-6\|wtr6"; then
    pass "On WTR-6 related branch: $current_branch"
else
    fail "Not on WTR-6 related branch (current: $current_branch)"
fi

# Check for WTR-6 related commits
if git log --all --oneline | grep -iq "wtr-6\|wtr6"; then
    pass "WTR-6 related commits exist in history"
else
    fail "No WTR-6 related commits found in history"
fi

# Test 20: Integration with WTR-3 and WTR-4
section "Integration with WTR-3 and WTR-4 Components"

# Check for WTR-3 entity
if [ -f "$base_src_path/entity/ReconciliationTransaction.kt" ] || [ -f "$base_src_path/entity/WebTransactionEntity.kt" ]; then
    pass "WTR-3 entity present"
else
    fail "WTR-3 entity missing (required dependency)"
fi

# Check for WTR-3 repository
if [ -f "$base_src_path/repository/ReconciliationTransactionRepository.kt" ] || [ -f "$base_src_path/repository/WebTransactionRepository.kt" ]; then
    pass "WTR-3 repository present"
else
    fail "WTR-3 repository missing (required dependency)"
fi

# Check for WTR-4 controller
if [ -f "$base_src_path/controller/WebTransactionController.kt" ]; then
    pass "WTR-4 controller present"
else
    fail "WTR-4 controller missing (required dependency)"
fi

# Check for WTR-4 service
if [ -f "$base_src_path/service/WebTransactionService.kt" ]; then
    pass "WTR-4 service present"
else
    fail "WTR-4 service missing (required dependency)"
fi

# Check for WTR-4 DTOs
if [ -f "$base_src_path/dto/CreateWebTransactionRequest.kt" ] || [ -d "$base_src_path/dto" ]; then
    pass "WTR-4 DTOs present"
else
    fail "WTR-4 DTOs missing (required dependency)"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "PASSED: $PASSED"
echo "FAILED: $FAILED"
echo "TOTAL:  $((PASSED + FAILED))"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ All tests passed!"
else
    echo "✗ Some tests failed. See details above."
fi

exit $EXIT_CODE
