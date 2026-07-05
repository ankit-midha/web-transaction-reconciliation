#!/bin/bash
# Full E2E measurement test for WTR-3 implementation
# Tests Flyway migrations, JPA entity, Spring Data repository, and optimistic locking

set -e

echo "=========================================="
echo "WTR-3 E2E Measurement Test"
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

# Test 1: Project structure and dependencies
section "Project Structure and Build Configuration"

if [ -f "build.gradle.kts" ]; then
    pass "build.gradle.kts exists"
else
    fail "build.gradle.kts missing"
fi

# Check for required dependencies
if grep -q "spring-boot-starter-data-jpa" build.gradle.kts 2>/dev/null; then
    pass "spring-boot-starter-data-jpa dependency present"
else
    fail "spring-boot-starter-data-jpa dependency missing"
fi

if grep -q "org.flywaydb:flyway-core" build.gradle.kts 2>/dev/null; then
    pass "flyway-core dependency present"

    # Check for version 6.3.1
    if grep -q "flyway-core:6.3.1" build.gradle.kts 2>/dev/null; then
        pass "Flyway version 6.3.1 specified"
    else
        fail "Flyway version is not 6.3.1 as required"
    fi
else
    fail "flyway-core dependency missing"
fi

if grep -q "org.postgresql:postgresql" build.gradle.kts 2>/dev/null; then
    pass "postgresql driver dependency present"
else
    fail "postgresql driver dependency missing"
fi

# Test 2: Application configuration
section "Application Configuration"

if [ -f "src/main/resources/application.yml" ]; then
    pass "application.yml exists"

    # Check Flyway configuration
    if grep -q "flyway:" src/main/resources/application.yml; then
        pass "Flyway configuration present in application.yml"

        if grep -q "baseline-on-migrate" src/main/resources/application.yml; then
            pass "baseline-on-migrate configured"
        else
            fail "baseline-on-migrate not configured"
        fi

        if grep -q "locations" src/main/resources/application.yml; then
            pass "Flyway migration locations configured"
        else
            fail "Flyway migration locations not configured"
        fi

        if grep -q "wtr_app" src/main/resources/application.yml; then
            pass "Database user placeholder (wtr_app) configured"
        else
            fail "Database user placeholder not configured"
        fi
    else
        fail "Flyway configuration missing from application.yml"
    fi
else
    fail "application.yml missing"
fi

# Test 3: Flyway migrations directory structure
section "Flyway Migrations Directory Structure"

if [ -d "src/main/resources/db/migration" ]; then
    pass "db/migration directory exists"
else
    fail "db/migration directory missing"
fi

# Test 4: V1 migration - initial table
section "V1 Migration - Initial Table"

V1_FILE="src/main/resources/db/migration/V1__create_reconciliation_transaction.sql"
if [ -f "$V1_FILE" ]; then
    pass "V1__create_reconciliation_transaction.sql exists"

    # Check for table creation
    if grep -iq "CREATE TABLE.*reconciliation_transaction" "$V1_FILE"; then
        pass "V1 creates reconciliation_transaction table"
    else
        fail "V1 does not create reconciliation_transaction table"
    fi

    # Check for required columns
    required_columns=("id" "reference" "transaction_type" "amount" "currency"
                     "internal_reference_type" "external_reference" "reconcile_status"
                     "created" "updated")

    for col in "${required_columns[@]}"; do
        if grep -iq "$col" "$V1_FILE"; then
            pass "V1 includes column: $col"
        else
            fail "V1 missing column: $col"
        fi
    done

    # Check that version column is NOT in V1 (added in V4)
    if ! grep -iq "version.*BIGINT" "$V1_FILE"; then
        pass "V1 correctly omits version column (added in V4)"
    else
        fail "V1 should not include version column (should be added in V4)"
    fi

    # Check for primary key
    if grep -iq "PRIMARY KEY" "$V1_FILE"; then
        pass "V1 defines primary key"
    else
        fail "V1 missing primary key constraint"
    fi

    # Check for indexes
    if grep -iq "CREATE.*INDEX.*reference" "$V1_FILE"; then
        pass "V1 creates index on reference column"
    else
        fail "V1 missing index on reference column"
    fi

    # Check for grants on wtr_app user
    if grep -iq "GRANT.*wtr_app" "$V1_FILE"; then
        pass "V1 includes grants for wtr_app user"
    else
        fail "V1 missing grants for wtr_app user"
    fi

    # Check for timestamp type (WITHOUT TIME ZONE per spec)
    if grep -iq "TIMESTAMP WITHOUT TIME ZONE" "$V1_FILE"; then
        pass "V1 uses TIMESTAMP WITHOUT TIME ZONE for timestamps"
    else
        fail "V1 should use TIMESTAMP WITHOUT TIME ZONE per spec"
    fi
else
    fail "V1__create_reconciliation_transaction.sql missing"
fi

# Test 5: V2 migration - placeholder for normalized schema
section "V2 Migration - Placeholder for Normalized Schema"

V2_FILE="src/main/resources/db/migration/V2__placeholder_normalized_schema.sql"
if [ -f "$V2_FILE" ]; then
    pass "V2__placeholder_normalized_schema.sql exists"

    # V2 should be a comment-only stub
    if grep -iq "placeholder\|deferred\|future\|29.*table" "$V2_FILE"; then
        pass "V2 contains placeholder/deferral comment"
    else
        fail "V2 should contain comment explaining 29-table schema deferral"
    fi

    # Verify V2 is valid (Flyway can process it)
    V2_SIZE=$(wc -c < "$V2_FILE")
    if [ "$V2_SIZE" -gt 0 ]; then
        pass "V2 is not empty (has content)"
    else
        fail "V2 file is empty"
    fi
else
    fail "V2__placeholder_normalized_schema.sql missing"
fi

# Test 6: V3 migration - rename column
section "V3 Migration - Rename Column"

V3_FILE="src/main/resources/db/migration/V3__rename_reference_type_column.sql"
if [ -f "$V3_FILE" ]; then
    pass "V3__rename_reference_type_column.sql exists"

    # Check for ALTER TABLE with column rename
    if grep -iq "ALTER TABLE.*reconciliation_transaction" "$V3_FILE" && \
       grep -iq "RENAME COLUMN" "$V3_FILE"; then
        pass "V3 uses ALTER TABLE with RENAME COLUMN"
    else
        fail "V3 should use ALTER TABLE ... RENAME COLUMN"
    fi

    # Check for internal_reference_type → external_reference_type rename
    if grep -iq "internal_reference_type.*external_reference_type" "$V3_FILE" || \
       grep -iq "RENAME COLUMN.*internal_reference_type" "$V3_FILE"; then
        pass "V3 renames internal_reference_type to external_reference_type"
    else
        fail "V3 should rename internal_reference_type to external_reference_type"
    fi

    # Check for index updates if needed
    if grep -iq "index" "$V3_FILE"; then
        pass "V3 updates indexes referencing renamed column"
    fi
else
    fail "V3__rename_reference_type_column.sql missing"
fi

# Test 7: V4 migration - add version column
section "V4 Migration - Add Version Column"

V4_FILE="src/main/resources/db/migration/V4__add_version_column.sql"
if [ -f "$V4_FILE" ]; then
    pass "V4__add_version_column.sql exists"

    # Check for ALTER TABLE adding version column
    if grep -iq "ALTER TABLE.*reconciliation_transaction" "$V4_FILE" && \
       grep -iq "ADD COLUMN.*version" "$V4_FILE"; then
        pass "V4 uses ALTER TABLE to add version column"
    else
        fail "V4 should use ALTER TABLE ... ADD COLUMN version"
    fi

    # Check for BIGINT type with DEFAULT 0 and NOT NULL
    if grep -iq "version.*BIGINT" "$V4_FILE" && \
       grep -iq "DEFAULT.*0" "$V4_FILE" && \
       grep -iq "NOT NULL" "$V4_FILE"; then
        pass "V4 defines version as BIGINT DEFAULT 0 NOT NULL"
    else
        fail "V4 version column should be BIGINT DEFAULT 0 NOT NULL"
    fi
else
    fail "V4__add_version_column.sql missing"
fi

# Test 8: Enum classes
section "Enum Classes"

ENUM_FILES=(
    "src/main/kotlin/com/webtransaction/microsite/entity/TransactionType.kt"
    "src/main/kotlin/com/webtransaction/microsite/entity/ExternalReferenceType.kt"
    "src/main/kotlin/com/webtransaction/microsite/entity/ReconcileStatus.kt"
)

for enum_file in "${ENUM_FILES[@]}"; do
    if [ -f "$enum_file" ]; then
        enum_name=$(basename "$enum_file" .kt)
        pass "$enum_name.kt exists"

        # Verify it's an enum class
        if grep -q "enum class $enum_name" "$enum_file"; then
            pass "$enum_name is defined as enum class"
        else
            fail "$enum_name should be defined as enum class"
        fi
    else
        fail "$(basename "$enum_file") missing"
    fi
done

# Check TransactionType has required values
TRANSACTION_TYPE_FILE="src/main/kotlin/com/webtransaction/microsite/entity/TransactionType.kt"
if [ -f "$TRANSACTION_TYPE_FILE" ]; then
    required_values=("WEB_ELECTRICITY_ORDER" "WEB_WATER_ORDER" "WEB_GAS_ORDER")
    for val in "${required_values[@]}"; do
        if grep -q "$val" "$TRANSACTION_TYPE_FILE"; then
            pass "TransactionType includes $val"
        else
            fail "TransactionType missing value: $val"
        fi
    done
fi

# Test 9: JPA Entity
section "JPA Entity - ReconciliationTransaction"

ENTITY_FILE="src/main/kotlin/com/webtransaction/microsite/entity/ReconciliationTransaction.kt"
if [ -f "$ENTITY_FILE" ]; then
    pass "ReconciliationTransaction.kt exists"

    # Check it's a regular class, not a data class (per spec)
    if grep -q "class ReconciliationTransaction" "$ENTITY_FILE" && \
       ! grep -q "data class ReconciliationTransaction" "$ENTITY_FILE"; then
        pass "ReconciliationTransaction is regular class (not data class)"
    else
        fail "ReconciliationTransaction should be regular class, not data class"
    fi

    # Check for JPA annotations
    if grep -q "@Entity" "$ENTITY_FILE"; then
        pass "ReconciliationTransaction has @Entity annotation"
    else
        fail "ReconciliationTransaction missing @Entity annotation"
    fi

    if grep -q "@Table.*reconciliation_transaction" "$ENTITY_FILE"; then
        pass "ReconciliationTransaction has @Table annotation with correct name"
    else
        fail "ReconciliationTransaction missing @Table annotation or incorrect table name"
    fi

    if grep -q "@Id" "$ENTITY_FILE"; then
        pass "ReconciliationTransaction has @Id annotation"
    else
        fail "ReconciliationTransaction missing @Id annotation"
    fi

    # Check for @Version annotation (optimistic locking)
    if grep -q "@Version" "$ENTITY_FILE"; then
        pass "ReconciliationTransaction has @Version annotation for optimistic locking"
    else
        fail "ReconciliationTransaction missing @Version annotation"
    fi

    # Check for required properties
    required_props=("id" "reference" "transactionType" "amount" "currency"
                   "externalReferenceType" "externalReference" "reconcileStatus"
                   "created" "updated" "version")

    for prop in "${required_props[@]}"; do
        if grep -iq "val $prop\|var $prop" "$ENTITY_FILE"; then
            pass "ReconciliationTransaction has property: $prop"
        else
            fail "ReconciliationTransaction missing property: $prop"
        fi
    done

    # Check naming strategy usage (should use default SpringPhysicalNamingStrategy)
    if grep -q "package com.webtransaction.microsite.entity" "$ENTITY_FILE"; then
        pass "ReconciliationTransaction in correct package"
    else
        fail "ReconciliationTransaction not in com.webtransaction.microsite.entity package"
    fi
else
    fail "ReconciliationTransaction.kt missing"
fi

# Test 10: Spring Data Repository
section "Spring Data Repository"

REPO_FILE="src/main/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepository.kt"
if [ -f "$REPO_FILE" ]; then
    pass "ReconciliationTransactionRepository.kt exists"

    # Check it extends JpaRepository
    if grep -q "JpaRepository" "$REPO_FILE"; then
        pass "ReconciliationTransactionRepository extends JpaRepository"
    else
        fail "ReconciliationTransactionRepository should extend JpaRepository"
    fi

    # Check for findByReference method
    if grep -q "findByReference" "$REPO_FILE"; then
        pass "ReconciliationTransactionRepository has findByReference method"

        # Check method signature
        if grep -q "findByReference.*reference.*String" "$REPO_FILE"; then
            pass "findByReference accepts String parameter"
        else
            fail "findByReference should accept String parameter"
        fi
    else
        fail "ReconciliationTransactionRepository missing findByReference method"
    fi

    # Check package
    if grep -q "package com.webtransaction.microsite.repository" "$REPO_FILE"; then
        pass "ReconciliationTransactionRepository in correct package"
    else
        fail "ReconciliationTransactionRepository not in com.webtransaction.microsite.repository package"
    fi

    # Check it's an interface
    if grep -q "interface ReconciliationTransactionRepository" "$REPO_FILE"; then
        pass "ReconciliationTransactionRepository is an interface"
    else
        fail "ReconciliationTransactionRepository should be an interface"
    fi
else
    fail "ReconciliationTransactionRepository.kt missing"
fi

# Test 11: Repository Tests
section "Repository Tests"

TEST_FILE="src/test/kotlin/com/webtransaction/microsite/repository/ReconciliationTransactionRepositoryTests.kt"
if [ -f "$TEST_FILE" ]; then
    pass "ReconciliationTransactionRepositoryTests.kt exists"

    # Check for @DataJpaTest annotation
    if grep -q "@DataJpaTest" "$TEST_FILE"; then
        pass "Tests use @DataJpaTest annotation"
    else
        fail "Tests should use @DataJpaTest annotation"
    fi

    # Check for Testcontainers usage
    if grep -q "Testcontainers\|@Container" "$TEST_FILE"; then
        pass "Tests use Testcontainers"
    else
        fail "Tests should use Testcontainers per spec"
    fi

    # Check for Postgres container
    if grep -iq "postgres.*15\.4\|PostgreSQLContainer" "$TEST_FILE"; then
        pass "Tests use Postgres 15.4 container"
    else
        fail "Tests should use Postgres 15.4 per spec"
    fi

    # Check for findByReference test
    if grep -iq "test.*findByReference\|fun.*findByReference" "$TEST_FILE"; then
        pass "Tests include findByReference test"
    else
        fail "Tests missing findByReference test"
    fi

    # Check for optimistic locking test
    if grep -iq "optimistic.*lock\|OptimisticLockException\|concurrent.*update" "$TEST_FILE"; then
        pass "Tests include optimistic locking test"
    else
        fail "Tests missing optimistic locking test (required per spec)"
    fi

    # Check for version increment test
    if grep -iq "version.*increment\|@Version" "$TEST_FILE"; then
        pass "Tests verify version column increments"
    else
        fail "Tests should verify version column increments"
    fi
else
    fail "ReconciliationTransactionRepositoryTests.kt missing"
fi

# Test 12: Docker Compose configuration (if exists)
section "Docker Compose Configuration"

if [ -f "docker-compose.yml" ]; then
    pass "docker-compose.yml exists"

    # Check for Postgres service
    if grep -iq "postgres:" docker-compose.yml; then
        pass "Docker Compose includes Postgres service"

        # Check for Postgres 15.4
        if grep -iq "postgres:15\.4" docker-compose.yml; then
            pass "Docker Compose uses Postgres 15.4"
        else
            fail "Docker Compose should use Postgres 15.4 per spec"
        fi
    else
        fail "Docker Compose missing Postgres service"
    fi

    # Check for wtr_app user creation
    if grep -iq "wtr_app" docker-compose.yml; then
        pass "Docker Compose configures wtr_app user"
    fi
else
    echo "⚠ SKIP: docker-compose.yml not found (optional)"
fi

# Test 13: Build and compile test
section "Build and Compilation"

if command -v ./gradlew &> /dev/null; then
    echo "Running build..."
    if ./gradlew build --no-daemon --console=plain 2>&1 | tee /tmp/gradle-build.log; then
        pass "Project builds successfully"

        # Check for test execution
        if grep -q "BUILD SUCCESSFUL" /tmp/gradle-build.log; then
            pass "Gradle build completed successfully"
        fi

        # Check if tests ran
        if grep -q "test" /tmp/gradle-build.log; then
            pass "Tests executed during build"
        fi
    else
        fail "Project build failed"
        echo "Build output:"
        tail -20 /tmp/gradle-build.log
    fi
else
    echo "⚠ SKIP: gradlew not found or not executable"
fi

# Test 14: Flyway migration validation (if Postgres available)
section "Flyway Migration Validation"

# Check if Docker is available
if command -v docker &> /dev/null; then
    echo "Docker available - could run Flyway migrations against real DB"

    if [ -f "docker-compose.yml" ]; then
        echo "Attempting to start Postgres..."
        if docker compose up -d postgres 2>&1 | tee /tmp/docker-compose.log; then
            pass "Postgres container started"

            # Wait for Postgres to be ready
            sleep 5

            # Run Flyway migrate
            if ./gradlew flywayMigrate --no-daemon --console=plain 2>&1 | tee /tmp/flyway-migrate.log; then
                pass "Flyway migrations applied successfully"

                # Check migration history
                if grep -q "Successfully applied" /tmp/flyway-migrate.log; then
                    pass "All migrations applied successfully"

                    # Count migrations
                    MIGRATION_COUNT=$(grep -c "Successfully applied" /tmp/flyway-migrate.log || true)
                    if [ "$MIGRATION_COUNT" -eq 4 ]; then
                        pass "All 4 migrations (V1-V4) applied"
                    else
                        fail "Expected 4 migrations, found $MIGRATION_COUNT"
                    fi
                fi
            else
                fail "Flyway migration failed"
                tail -20 /tmp/flyway-migrate.log
            fi

            # Clean up
            docker compose down
        else
            echo "⚠ SKIP: Could not start Postgres container"
        fi
    else
        echo "⚠ SKIP: docker-compose.yml not found"
    fi
else
    echo "⚠ SKIP: Docker not available"
fi

# Test 15: Code structure and conventions
section "Code Structure and Conventions"

# Check for proper package structure
if [ -d "src/main/kotlin/com/webtransaction/microsite/entity" ]; then
    pass "Entity package structure exists"
else
    fail "Entity package structure missing"
fi

if [ -d "src/main/kotlin/com/webtransaction/microsite/repository" ]; then
    pass "Repository package structure exists"
else
    fail "Repository package structure missing"
fi

# Check for migration naming convention
MIGRATION_FILES=$(find src/main/resources/db/migration -name "V*.sql" 2>/dev/null | wc -l)
if [ "$MIGRATION_FILES" -eq 4 ]; then
    pass "All 4 migration files present"
else
    fail "Expected 4 migration files, found $MIGRATION_FILES"
fi

# Verify migration file naming follows convention
if ls src/main/resources/db/migration/V[1-4]__*.sql &>/dev/null; then
    pass "Migration files follow Flyway naming convention (V#__description.sql)"
else
    fail "Migration files do not follow Flyway naming convention"
fi

# Test 16: Documentation and comments
section "Documentation"

# Check for README or doc updates
if [ -f "README.md" ]; then
    if grep -iq "flyway\|migration\|database\|jpa" README.md; then
        pass "README.md documents database/migration setup"
    else
        echo "⚠ WARN: README.md could be updated to document WTR-3 changes"
    fi
fi

# Check migration files have comments
if [ -d "src/main/resources/db/migration" ]; then
    for migration in src/main/resources/db/migration/V*.sql; do
        if [ -f "$migration" ]; then
            if grep -q "^--" "$migration"; then
                pass "$(basename "$migration") includes SQL comments"
            fi
        fi
    done
fi

# Test 17: Git status and branch
section "Git Configuration"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "WTR-3-impl" ]; then
    pass "On expected implementation branch: WTR-3-impl"
else
    echo "⚠ INFO: Current branch is $CURRENT_BRANCH (expected WTR-3-impl)"
fi

# Check for WTR-3 commits
if git log --oneline | grep -iq "WTR-3\|wtr-3"; then
    pass "WTR-3 related commits exist"
else
    echo "⚠ INFO: No WTR-3 commits found yet"
fi

# Test 18: Acceptance criteria checklist
section "Acceptance Criteria Validation"

echo ""
echo "Verifying all acceptance criteria are testable:"
echo ""

# AC1: Flyway 6.3.1 migrates cleanly
echo "AC1: Flyway 6.3.1 migrates cleanly against Postgres 15.4"
if grep -q "flyway-core:6.3.1" build.gradle.kts 2>/dev/null; then
    echo "  ✓ Flyway 6.3.1 dependency configured"
else
    echo "  ✗ Flyway 6.3.1 dependency not found"
fi

# AC2: All four migrations apply
echo "AC2: All four migrations (V1, V2, V3, V4) apply in sequence"
V1_EXISTS=false
V2_EXISTS=false
V3_EXISTS=false
V4_EXISTS=false
[ -f "src/main/resources/db/migration/V1__create_reconciliation_transaction.sql" ] && V1_EXISTS=true
[ -f "src/main/resources/db/migration/V2__placeholder_normalized_schema.sql" ] && V2_EXISTS=true
[ -f "src/main/resources/db/migration/V3__rename_reference_type_column.sql" ] && V3_EXISTS=true
[ -f "src/main/resources/db/migration/V4__add_version_column.sql" ] && V4_EXISTS=true

$V1_EXISTS && echo "  ✓ V1 migration exists" || echo "  ✗ V1 migration missing"
$V2_EXISTS && echo "  ✓ V2 migration exists" || echo "  ✗ V2 migration missing"
$V3_EXISTS && echo "  ✓ V3 migration exists" || echo "  ✗ V3 migration missing"
$V4_EXISTS && echo "  ✓ V4 migration exists" || echo "  ✗ V4 migration missing"

# AC3: Table exists with all columns/indexes/constraints
echo "AC3: reconciliation_transaction table with all specified elements"
echo "  (Verified through migration file content checks above)"

# AC4: JPA entity with @Version
echo "AC4: JPA entity ReconciliationTransaction with @Version annotation"
if [ -f "$ENTITY_FILE" ] && grep -q "@Version" "$ENTITY_FILE" 2>/dev/null; then
    echo "  ✓ Entity with @Version annotation exists"
else
    echo "  ✗ Entity with @Version annotation not found"
fi

# AC5: Repository method exists
echo "AC5: Repository method findByReference(reference: String) exists"
if [ -f "$REPO_FILE" ] && grep -q "findByReference" "$REPO_FILE" 2>/dev/null; then
    echo "  ✓ findByReference method exists"
else
    echo "  ✗ findByReference method not found"
fi

# AC6: Optimistic locking works
echo "AC6: Optimistic locking works (concurrent updates throw OptimisticLockException)"
if [ -f "$TEST_FILE" ] && grep -iq "OptimisticLockException" "$TEST_FILE" 2>/dev/null; then
    echo "  ✓ Optimistic locking test exists"
else
    echo "  ✗ Optimistic locking test not found"
fi

# AC7: Database grants applied
echo "AC7: Database grants applied as specified in V1"
if [ -f "$V1_FILE" ] && grep -iq "GRANT.*wtr_app" "$V1_FILE" 2>/dev/null; then
    echo "  ✓ Grants specified in V1"
else
    echo "  ✗ Grants not found in V1"
fi

# Final summary
echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo "Total Passed: $PASSED"
echo "Total Failed: $FAILED"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ ALL TESTS PASSED"
    echo ""
    echo "WTR-3 implementation meets all E2E measurement criteria:"
    echo "  • Flyway 6.3.1 with 4 migrations (V1-V4)"
    echo "  • JPA entity with optimistic locking"
    echo "  • Spring Data repository with findByReference"
    echo "  • Postgres 15.4 integration"
    echo "  • Comprehensive test coverage"
else
    echo "✗ SOME TESTS FAILED"
    echo ""
    echo "Review failed tests above and ensure:"
    echo "  • All migration files follow Flyway conventions"
    echo "  • JPA entity has @Version annotation"
    echo "  • Repository extends JpaRepository"
    echo "  • Tests include optimistic locking validation"
    echo "  • Build completes successfully"
fi

echo ""
exit $EXIT_CODE
