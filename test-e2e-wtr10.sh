#!/bin/bash
# Full E2E measurement test for WTR-10 implementation
# Tests production-readiness infrastructure: WireMock stubs, deployment configs, and documentation

set -e

echo "=========================================="
echo "WTR-10 E2E Measurement Test"
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

# File paths
WTS_README="web-transaction-microsite/README.md"
WTS_ADR="web-transaction-microsite/docs/adr/001-fire-and-forget-design.md"
WTS_MICROSITE_YAML="web-transaction-microsite/microsite.yaml"
WTS_DOCKERFILE="web-transaction-microsite/Dockerfile"
ORDERS_CHANGELOG="orders-microsite/CHANGELOG.md"
ORDERS_MICROSITE_YAML="orders-microsite/microsite.yaml"
WIREMOCK_POST_201="orders-microsite/tests/wiremock/mappings/wts-post-201-success.json"
WIREMOCK_PUT_200="orders-microsite/tests/wiremock/mappings/wts-put-200-success.json"
WIREMOCK_POST_500="orders-microsite/tests/wiremock/mappings/wts-post-500-error.json"
WIREMOCK_POST_TIMEOUT="orders-microsite/tests/wiremock/mappings/wts-post-timeout.json"
DOCKER_COMPOSE_E2E="docker-compose.e2e.yml"
GH_WORKFLOW_WTS=".github/workflows/retailx-deploy-wts.yml"
GH_WORKFLOW_ORDERS=".github/workflows/retailx-deploy-orders.yml"

# Test 1: File Existence - Web Transaction Microsite
section "File Existence - Web Transaction Microsite"

if [ -f "$WTS_README" ]; then
    pass "web-transaction-microsite/README.md exists"
else
    fail "web-transaction-microsite/README.md missing"
fi

if [ -f "$WTS_ADR" ]; then
    pass "ADR 001-fire-and-forget-design.md exists"
else
    fail "ADR 001-fire-and-forget-design.md missing"
fi

if [ -f "$WTS_MICROSITE_YAML" ]; then
    pass "web-transaction-microsite/microsite.yaml exists"
else
    fail "web-transaction-microsite/microsite.yaml missing"
fi

if [ -f "$WTS_DOCKERFILE" ]; then
    pass "web-transaction-microsite/Dockerfile exists"
else
    fail "web-transaction-microsite/Dockerfile missing"
fi

# Test 2: File Existence - Orders Microsite
section "File Existence - Orders Microsite"

if [ -f "$ORDERS_CHANGELOG" ]; then
    pass "orders-microsite/CHANGELOG.md exists"
else
    fail "orders-microsite/CHANGELOG.md missing"
fi

if [ -f "$ORDERS_MICROSITE_YAML" ]; then
    pass "orders-microsite/microsite.yaml exists"
else
    fail "orders-microsite/microsite.yaml missing"
fi

# Test 3: File Existence - WireMock Stubs
section "File Existence - WireMock Stubs"

if [ -f "$WIREMOCK_POST_201" ]; then
    pass "WireMock stub: POST 201 success exists"
else
    fail "WireMock stub: POST 201 success missing"
fi

if [ -f "$WIREMOCK_PUT_200" ]; then
    pass "WireMock stub: PUT 200 success exists"
else
    fail "WireMock stub: PUT 200 success missing"
fi

if [ -f "$WIREMOCK_POST_500" ]; then
    pass "WireMock stub: POST 500 error exists"
else
    fail "WireMock stub: POST 500 error missing"
fi

if [ -f "$WIREMOCK_POST_TIMEOUT" ]; then
    pass "WireMock stub: POST timeout exists"
else
    fail "WireMock stub: POST timeout missing"
fi

# Test 4: File Existence - E2E Infrastructure
section "File Existence - E2E Infrastructure"

if [ -f "$DOCKER_COMPOSE_E2E" ]; then
    pass "docker-compose.e2e.yml exists"
else
    fail "docker-compose.e2e.yml missing"
fi

if [ -f "$GH_WORKFLOW_WTS" ]; then
    pass "GitHub workflow: retailx-deploy-wts.yml exists"
else
    fail "GitHub workflow: retailx-deploy-wts.yml missing"
fi

if [ -f "$GH_WORKFLOW_ORDERS" ]; then
    pass "GitHub workflow: retailx-deploy-orders.yml exists"
else
    fail "GitHub workflow: retailx-deploy-orders.yml missing"
fi

# Test 5: README.md Content Structure
section "README.md Content Structure"

if [ -f "$WTS_README" ]; then
    if grep -qi "architecture" "$WTS_README"; then
        pass "README contains Architecture section"
    else
        fail "README missing Architecture section"
    fi

    if grep -qi "local development\|local dev setup" "$WTS_README"; then
        pass "README contains Local Development section"
    else
        fail "README missing Local Development section"
    fi

    if grep -qi "api endpoint" "$WTS_README"; then
        pass "README contains API Endpoints section"
    else
        fail "README missing API Endpoints section"
    fi

    if grep -qi "security scope" "$WTS_README" || grep -q "wts:write\|wts:read" "$WTS_README"; then
        pass "README contains Security Scopes documentation"
    else
        fail "README missing Security Scopes documentation"
    fi

    if grep -qi "deployment" "$WTS_README"; then
        pass "README contains Deployment section"
    else
        fail "README missing Deployment section"
    fi

    if grep -qi "fire-and-forget" "$WTS_README"; then
        pass "README mentions fire-and-forget pattern"
    else
        fail "README missing fire-and-forget pattern mention"
    fi

    if grep -q "POST /v1/webtransaction" "$WTS_README"; then
        pass "README documents POST /v1/webtransaction endpoint"
    else
        fail "README missing POST /v1/webtransaction endpoint"
    fi

    if grep -q "PUT /v1/webtransaction/reference" "$WTS_README"; then
        pass "README documents PUT /v1/webtransaction/reference endpoint"
    else
        fail "README missing PUT /v1/webtransaction/reference endpoint"
    fi

    if grep -q "GET /v1/webtransaction" "$WTS_README"; then
        pass "README documents GET endpoints"
    else
        fail "README missing GET endpoints"
    fi

    if grep -qi "postgres" "$WTS_README"; then
        pass "README mentions PostgreSQL database"
    else
        fail "README missing PostgreSQL database mention"
    fi
fi

# Test 6: ADR Content Structure
section "ADR Content Structure"

if [ -f "$WTS_ADR" ]; then
    if grep -qi "status" "$WTS_ADR"; then
        pass "ADR contains Status field"
    else
        fail "ADR missing Status field"
    fi

    if grep -qi "context" "$WTS_ADR"; then
        pass "ADR contains Context section"
    else
        fail "ADR missing Context section"
    fi

    if grep -qi "decision" "$WTS_ADR"; then
        pass "ADR contains Decision section"
    else
        fail "ADR missing Decision section"
    fi

    if grep -qi "consequences" "$WTS_ADR"; then
        pass "ADR contains Consequences section"
    else
        fail "ADR missing Consequences section"
    fi

    if grep -qi "alternatives\|alternatives considered" "$WTS_ADR"; then
        pass "ADR contains Alternatives section"
    else
        fail "ADR missing Alternatives section"
    fi

    if grep -qi "fire-and-forget" "$WTS_ADR"; then
        pass "ADR mentions fire-and-forget pattern"
    else
        fail "ADR missing fire-and-forget pattern mention"
    fi

    if grep -qi "no retries" "$WTS_ADR"; then
        pass "ADR mentions no retries design"
    else
        fail "ADR missing no retries mention"
    fi

    if grep -qi "data loss\|potential.*loss" "$WTS_ADR"; then
        pass "ADR discusses data loss consequence"
    else
        fail "ADR missing data loss discussion"
    fi

    if grep -qi "resilience\|resilient" "$WTS_ADR"; then
        pass "ADR discusses resilience benefit"
    else
        fail "ADR missing resilience discussion"
    fi
fi

# Test 7: Web Transaction Microsite deployment config
section "Web Transaction Microsite Deployment Config"

if [ -f "$WTS_MICROSITE_YAML" ]; then
    # Check if valid YAML (basic syntax check)
    if python3 -c "import yaml; yaml.safe_load(open('$WTS_MICROSITE_YAML'))" 2>/dev/null || \
       ruby -ryaml -e "YAML.load_file('$WTS_MICROSITE_YAML')" 2>/dev/null; then
        pass "microsite.yaml is valid YAML"
    else
        fail "microsite.yaml is not valid YAML"
    fi

    if grep -q "web-transaction-microsite" "$WTS_MICROSITE_YAML"; then
        pass "microsite.yaml contains service name"
    else
        fail "microsite.yaml missing service name"
    fi

    if grep -qi "ecs-fargate\|ecs" "$WTS_MICROSITE_YAML"; then
        pass "microsite.yaml specifies ECS Fargate platform"
    else
        fail "microsite.yaml missing ECS Fargate platform"
    fi

    if grep -qi "rds-postgres\|postgres" "$WTS_MICROSITE_YAML"; then
        pass "microsite.yaml specifies PostgreSQL database"
    else
        fail "microsite.yaml missing PostgreSQL database"
    fi

    if grep -q "slack\|notifications" "$WTS_MICROSITE_YAML"; then
        pass "microsite.yaml contains Slack notification config"
    else
        fail "microsite.yaml missing Slack notification config"
    fi

    if grep -q "dev" "$WTS_MICROSITE_YAML" && \
       grep -q "staging" "$WTS_MICROSITE_YAML" && \
       grep -q "prod" "$WTS_MICROSITE_YAML"; then
        pass "microsite.yaml defines dev/staging/prod environments"
    else
        fail "microsite.yaml missing dev/staging/prod environments"
    fi

    if grep -qi "parameterStore\|parameter.*store" "$WTS_MICROSITE_YAML"; then
        pass "microsite.yaml references parameter store for secrets"
    else
        fail "microsite.yaml missing parameter store reference"
    fi
fi

# Test 8: Orders Microsite CHANGELOG
section "Orders Microsite CHANGELOG"

if [ -f "$ORDERS_CHANGELOG" ]; then
    if grep -qi "\[unreleased\]" "$ORDERS_CHANGELOG"; then
        pass "CHANGELOG contains [Unreleased] section"
    else
        fail "CHANGELOG missing [Unreleased] section"
    fi

    if grep -qi "web transaction store\|wts integration\|wts" "$ORDERS_CHANGELOG"; then
        pass "CHANGELOG mentions WTS integration"
    else
        fail "CHANGELOG missing WTS integration mention"
    fi

    if grep -qi "fire-and-forget" "$ORDERS_CHANGELOG"; then
        pass "CHANGELOG mentions fire-and-forget pattern"
    else
        fail "CHANGELOG missing fire-and-forget pattern mention"
    fi

    if grep -q "wts.integration.enabled" "$ORDERS_CHANGELOG"; then
        pass "CHANGELOG mentions wts.integration.enabled feature flag"
    else
        fail "CHANGELOG missing feature flag mention"
    fi

    if grep -qi "wiremock\|e2e.*test\|test.*stub" "$ORDERS_CHANGELOG"; then
        pass "CHANGELOG mentions WireMock/E2E test stubs"
    else
        fail "CHANGELOG missing WireMock/E2E test mention"
    fi
fi

# Test 9: Orders Microsite deployment config
section "Orders Microsite Deployment Config"

if [ -f "$ORDERS_MICROSITE_YAML" ]; then
    # Check if valid YAML
    if python3 -c "import yaml; yaml.safe_load(open('$ORDERS_MICROSITE_YAML'))" 2>/dev/null || \
       ruby -ryaml -e "YAML.load_file('$ORDERS_MICROSITE_YAML')" 2>/dev/null; then
        pass "orders-microsite microsite.yaml is valid YAML"
    else
        fail "orders-microsite microsite.yaml is not valid YAML"
    fi

    if grep -q "orders-microsite" "$ORDERS_MICROSITE_YAML"; then
        pass "orders-microsite microsite.yaml contains service name"
    else
        fail "orders-microsite microsite.yaml missing service name"
    fi

    if grep -q "slack\|notifications" "$ORDERS_MICROSITE_YAML"; then
        pass "orders-microsite microsite.yaml contains notification config"
    else
        fail "orders-microsite microsite.yaml missing notification config"
    fi

    if grep -q "wts.integration.enabled" "$ORDERS_MICROSITE_YAML"; then
        pass "orders-microsite microsite.yaml contains wts.integration.enabled flag"
    else
        fail "orders-microsite microsite.yaml missing wts.integration.enabled flag"
    fi

    if grep -qi "featureFlag" "$ORDERS_MICROSITE_YAML"; then
        pass "orders-microsite microsite.yaml has featureFlags section"
    else
        fail "orders-microsite microsite.yaml missing featureFlags section"
    fi

    # Check for environment-specific feature flag values
    if grep -q "dev" "$ORDERS_MICROSITE_YAML" && \
       grep -q "staging" "$ORDERS_MICROSITE_YAML" && \
       grep -q "prod" "$ORDERS_MICROSITE_YAML"; then
        pass "orders-microsite microsite.yaml defines dev/staging/prod environments"
    else
        fail "orders-microsite microsite.yaml missing dev/staging/prod environments"
    fi
fi

# Test 10: WireMock Stub - POST 201 Success
section "WireMock Stub - POST 201 Success"

if [ -f "$WIREMOCK_POST_201" ]; then
    # Check if valid JSON
    if python3 -c "import json; json.load(open('$WIREMOCK_POST_201'))" 2>/dev/null || \
       ruby -rjson -e "JSON.parse(File.read('$WIREMOCK_POST_201'))" 2>/dev/null || \
       jq empty "$WIREMOCK_POST_201" 2>/dev/null; then
        pass "POST 201 stub is valid JSON"
    else
        fail "POST 201 stub is not valid JSON"
    fi

    if grep -q '"method".*:.*"POST"\|"POST"' "$WIREMOCK_POST_201"; then
        pass "POST 201 stub specifies POST method"
    else
        fail "POST 201 stub missing POST method"
    fi

    if grep -q "/v1/webtransaction" "$WIREMOCK_POST_201"; then
        pass "POST 201 stub targets /v1/webtransaction endpoint"
    else
        fail "POST 201 stub missing /v1/webtransaction endpoint"
    fi

    if grep -q '"status".*:.*201\|201' "$WIREMOCK_POST_201"; then
        pass "POST 201 stub returns 201 status"
    else
        fail "POST 201 stub missing 201 status"
    fi

    if grep -qi "application/json" "$WIREMOCK_POST_201"; then
        pass "POST 201 stub sets Content-Type: application/json"
    else
        fail "POST 201 stub missing Content-Type header"
    fi

    if grep -qi "jsonBody\|body" "$WIREMOCK_POST_201"; then
        pass "POST 201 stub contains response body"
    else
        fail "POST 201 stub missing response body"
    fi
fi

# Test 11: WireMock Stub - PUT 200 Success
section "WireMock Stub - PUT 200 Success"

if [ -f "$WIREMOCK_PUT_200" ]; then
    # Check if valid JSON
    if python3 -c "import json; json.load(open('$WIREMOCK_PUT_200'))" 2>/dev/null || \
       ruby -rjson -e "JSON.parse(File.read('$WIREMOCK_PUT_200'))" 2>/dev/null || \
       jq empty "$WIREMOCK_PUT_200" 2>/dev/null; then
        pass "PUT 200 stub is valid JSON"
    else
        fail "PUT 200 stub is not valid JSON"
    fi

    if grep -q '"method".*:.*"PUT"\|"PUT"' "$WIREMOCK_PUT_200"; then
        pass "PUT 200 stub specifies PUT method"
    else
        fail "PUT 200 stub missing PUT method"
    fi

    if grep -q "/v1/webtransaction/reference" "$WIREMOCK_PUT_200"; then
        pass "PUT 200 stub targets /v1/webtransaction/reference endpoint"
    else
        fail "PUT 200 stub missing /v1/webtransaction/reference endpoint"
    fi

    if grep -q '"status".*:.*200\|200' "$WIREMOCK_PUT_200"; then
        pass "PUT 200 stub returns 200 status"
    else
        fail "PUT 200 stub missing 200 status"
    fi

    if grep -qi "reconcileStatus\|reconcile.*status" "$WIREMOCK_PUT_200"; then
        pass "PUT 200 stub response contains reconcileStatus field"
    else
        fail "PUT 200 stub missing reconcileStatus field"
    fi
fi

# Test 12: WireMock Stub - POST 500 Error
section "WireMock Stub - POST 500 Error"

if [ -f "$WIREMOCK_POST_500" ]; then
    # Check if valid JSON
    if python3 -c "import json; json.load(open('$WIREMOCK_POST_500'))" 2>/dev/null || \
       ruby -rjson -e "JSON.parse(File.read('$WIREMOCK_POST_500'))" 2>/dev/null || \
       jq empty "$WIREMOCK_POST_500" 2>/dev/null; then
        pass "POST 500 stub is valid JSON"
    else
        fail "POST 500 stub is not valid JSON"
    fi

    if grep -q '"method".*:.*"POST"\|"POST"' "$WIREMOCK_POST_500"; then
        pass "POST 500 stub specifies POST method"
    else
        fail "POST 500 stub missing POST method"
    fi

    if grep -q '"status".*:.*500\|500' "$WIREMOCK_POST_500"; then
        pass "POST 500 stub returns 500 status"
    else
        fail "POST 500 stub missing 500 status"
    fi

    if grep -qi "internal.*server.*error\|error" "$WIREMOCK_POST_500"; then
        pass "POST 500 stub contains error message"
    else
        fail "POST 500 stub missing error message"
    fi
fi

# Test 13: WireMock Stub - POST Timeout
section "WireMock Stub - POST Timeout"

if [ -f "$WIREMOCK_POST_TIMEOUT" ]; then
    # Check if valid JSON
    if python3 -c "import json; json.load(open('$WIREMOCK_POST_TIMEOUT'))" 2>/dev/null || \
       ruby -rjson -e "JSON.parse(File.read('$WIREMOCK_POST_TIMEOUT'))" 2>/dev/null || \
       jq empty "$WIREMOCK_POST_TIMEOUT" 2>/dev/null; then
        pass "POST timeout stub is valid JSON"
    else
        fail "POST timeout stub is not valid JSON"
    fi

    if grep -q '"method".*:.*"POST"\|"POST"' "$WIREMOCK_POST_TIMEOUT"; then
        pass "POST timeout stub specifies POST method"
    else
        fail "POST timeout stub missing POST method"
    fi

    if grep -q "fixedDelayMilliseconds\|fixedDelay\|delay" "$WIREMOCK_POST_TIMEOUT"; then
        pass "POST timeout stub configures delay"
    else
        fail "POST timeout stub missing delay configuration"
    fi

    # Check for 5000ms (5 seconds) timeout
    if grep -q "5000" "$WIREMOCK_POST_TIMEOUT"; then
        pass "POST timeout stub uses 5000ms (5 second) delay"
    else
        fail "POST timeout stub missing 5000ms delay value"
    fi
fi

# Test 14: Docker Compose E2E Configuration
section "Docker Compose E2E Configuration"

if [ -f "$DOCKER_COMPOSE_E2E" ]; then
    # Check if valid YAML
    if python3 -c "import yaml; yaml.safe_load(open('$DOCKER_COMPOSE_E2E'))" 2>/dev/null || \
       ruby -ryaml -e "YAML.load_file('$DOCKER_COMPOSE_E2E')" 2>/dev/null; then
        pass "docker-compose.e2e.yml is valid YAML"
    else
        fail "docker-compose.e2e.yml is not valid YAML"
    fi

    if grep -q "postgres" "$DOCKER_COMPOSE_E2E"; then
        pass "docker-compose.e2e.yml defines postgres service"
    else
        fail "docker-compose.e2e.yml missing postgres service"
    fi

    if grep -q "web-transaction-microsite" "$DOCKER_COMPOSE_E2E"; then
        pass "docker-compose.e2e.yml defines web-transaction-microsite service"
    else
        fail "docker-compose.e2e.yml missing web-transaction-microsite service"
    fi

    if grep -qi "orders-microsite.*test\|test" "$DOCKER_COMPOSE_E2E"; then
        pass "docker-compose.e2e.yml defines test service"
    else
        fail "docker-compose.e2e.yml missing test service"
    fi

    if grep -q "postgres:14\|postgres:15\|postgres:16" "$DOCKER_COMPOSE_E2E"; then
        pass "docker-compose.e2e.yml uses PostgreSQL 14+ image"
    else
        fail "docker-compose.e2e.yml missing PostgreSQL image version"
    fi

    if grep -q "8080" "$DOCKER_COMPOSE_E2E"; then
        pass "docker-compose.e2e.yml exposes port 8080 for WTS"
    else
        fail "docker-compose.e2e.yml missing port 8080 exposure"
    fi

    if grep -qi "depends_on" "$DOCKER_COMPOSE_E2E"; then
        pass "docker-compose.e2e.yml uses depends_on for service ordering"
    else
        fail "docker-compose.e2e.yml missing depends_on configuration"
    fi
fi

# Test 15: Web Transaction Microsite Dockerfile
section "Web Transaction Microsite Dockerfile"

if [ -f "$WTS_DOCKERFILE" ]; then
    if grep -qi "^FROM" "$WTS_DOCKERFILE"; then
        pass "Dockerfile contains FROM instruction"
    else
        fail "Dockerfile missing FROM instruction"
    fi

    if grep -qi "jre\|jdk\|java\|temurin\|openjdk" "$WTS_DOCKERFILE"; then
        pass "Dockerfile uses Java/JRE base image"
    else
        fail "Dockerfile missing Java/JRE base image"
    fi

    if grep -qi "^COPY.*\.jar" "$WTS_DOCKERFILE"; then
        pass "Dockerfile copies JAR file"
    else
        fail "Dockerfile missing JAR copy instruction"
    fi

    if grep -qi "^EXPOSE" "$WTS_DOCKERFILE"; then
        pass "Dockerfile exposes port"
    else
        fail "Dockerfile missing EXPOSE instruction"
    fi

    if grep -qi "^ENTRYPOINT.*java.*-jar\|^CMD.*java.*-jar" "$WTS_DOCKERFILE"; then
        pass "Dockerfile sets ENTRYPOINT/CMD for Java execution"
    else
        fail "Dockerfile missing ENTRYPOINT/CMD for Java"
    fi
fi

# Test 16: GitHub Workflow - WTS
section "GitHub Workflow - Web Transaction Microsite"

if [ -f "$GH_WORKFLOW_WTS" ]; then
    # Check if valid YAML
    if python3 -c "import yaml; yaml.safe_load(open('$GH_WORKFLOW_WTS'))" 2>/dev/null || \
       ruby -ryaml -e "YAML.load_file('$GH_WORKFLOW_WTS')" 2>/dev/null; then
        pass "WTS workflow is valid YAML"
    else
        fail "WTS workflow is not valid YAML"
    fi

    if grep -q "name:" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow has name field"
    else
        fail "WTS workflow missing name field"
    fi

    if grep -q "on:" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow has trigger configuration"
    else
        fail "WTS workflow missing trigger configuration"
    fi

    if grep -q "push\|workflow_dispatch" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow triggers on push or manual dispatch"
    else
        fail "WTS workflow missing push/dispatch triggers"
    fi

    if grep -q "jobs:" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow defines jobs"
    else
        fail "WTS workflow missing jobs"
    fi

    if grep -qi "build" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow includes build job"
    else
        fail "WTS workflow missing build job"
    fi

    if grep -qi "test" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow includes test job"
    else
        fail "WTS workflow missing test job"
    fi

    if grep -qi "deploy" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow includes deploy job"
    else
        fail "WTS workflow missing deploy job"
    fi

    if grep -qi "docker\|container" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow references Docker build"
    else
        fail "WTS workflow missing Docker build reference"
    fi

    if grep -qi "slack\|notification" "$GH_WORKFLOW_WTS"; then
        pass "WTS workflow includes Slack notification"
    else
        fail "WTS workflow missing Slack notification"
    fi
fi

# Test 17: GitHub Workflow - Orders
section "GitHub Workflow - Orders Microsite"

if [ -f "$GH_WORKFLOW_ORDERS" ]; then
    # Check if valid YAML
    if python3 -c "import yaml; yaml.safe_load(open('$GH_WORKFLOW_ORDERS'))" 2>/dev/null || \
       ruby -ryaml -e "YAML.load_file('$GH_WORKFLOW_ORDERS')" 2>/dev/null; then
        pass "Orders workflow is valid YAML"
    else
        fail "Orders workflow is not valid YAML"
    fi

    if grep -q "name:" "$GH_WORKFLOW_ORDERS"; then
        pass "Orders workflow has name field"
    else
        fail "Orders workflow missing name field"
    fi

    if grep -q "on:" "$GH_WORKFLOW_ORDERS"; then
        pass "Orders workflow has trigger configuration"
    else
        fail "Orders workflow missing trigger configuration"
    fi

    if grep -q "jobs:" "$GH_WORKFLOW_ORDERS"; then
        pass "Orders workflow defines jobs"
    else
        fail "Orders workflow missing jobs"
    fi

    if grep -qi "build" "$GH_WORKFLOW_ORDERS"; then
        pass "Orders workflow includes build job"
    else
        fail "Orders workflow missing build job"
    fi

    if grep -qi "test" "$GH_WORKFLOW_ORDERS"; then
        pass "Orders workflow includes test job"
    else
        fail "Orders workflow missing test job"
    fi

    if grep -qi "deploy" "$GH_WORKFLOW_ORDERS"; then
        pass "Orders workflow includes deploy job"
    else
        fail "Orders workflow missing deploy job"
    fi

    if grep -q "wts.integration.enabled\|feature.*flag" "$GH_WORKFLOW_ORDERS"; then
        pass "Orders workflow references wts.integration.enabled feature flag"
    else
        fail "Orders workflow missing feature flag reference"
    fi
fi

# Test 18: Cross-File Validation
section "Cross-File Validation"

# Check endpoint consistency between README and WireMock stubs
if [ -f "$WTS_README" ] && [ -f "$WIREMOCK_POST_201" ]; then
    readme_has_endpoint=$(grep -q "POST /v1/webtransaction" "$WTS_README" && echo "yes" || echo "no")
    stub_has_endpoint=$(grep -q "/v1/webtransaction" "$WIREMOCK_POST_201" && echo "yes" || echo "no")

    if [ "$readme_has_endpoint" = "yes" ] && [ "$stub_has_endpoint" = "yes" ]; then
        pass "Endpoint URLs consistent between README and WireMock stubs"
    else
        fail "Endpoint URL mismatch between README and WireMock stubs"
    fi
fi

# Check Dockerfile referenced in microsite.yaml exists
if [ -f "$WTS_MICROSITE_YAML" ] && grep -q "Dockerfile" "$WTS_MICROSITE_YAML"; then
    if [ -f "$WTS_DOCKERFILE" ]; then
        pass "Dockerfile referenced in microsite.yaml exists"
    else
        fail "Dockerfile referenced in microsite.yaml does not exist"
    fi
fi

# Check Docker Compose service names match deployment config
if [ -f "$DOCKER_COMPOSE_E2E" ] && [ -f "$WTS_MICROSITE_YAML" ]; then
    if grep -q "web-transaction-microsite" "$DOCKER_COMPOSE_E2E" && \
       grep -q "web-transaction-microsite" "$WTS_MICROSITE_YAML"; then
        pass "Service names consistent between Docker Compose and deployment config"
    else
        fail "Service name mismatch between Docker Compose and deployment config"
    fi
fi

# Check feature flag name consistency between CHANGELOG and deployment config
if [ -f "$ORDERS_CHANGELOG" ] && [ -f "$ORDERS_MICROSITE_YAML" ]; then
    changelog_has_flag=$(grep -q "wts.integration.enabled" "$ORDERS_CHANGELOG" && echo "yes" || echo "no")
    config_has_flag=$(grep -q "wts.integration.enabled" "$ORDERS_MICROSITE_YAML" && echo "yes" || echo "no")

    if [ "$changelog_has_flag" = "yes" ] && [ "$config_has_flag" = "yes" ]; then
        pass "Feature flag name consistent between CHANGELOG and deployment config"
    else
        fail "Feature flag name mismatch between CHANGELOG and deployment config"
    fi
fi

# Check ADR filename follows numbering convention (001-*.md)
if [ -f "$WTS_ADR" ]; then
    if echo "$WTS_ADR" | grep -q "001-.*\.md"; then
        pass "ADR filename follows numbering convention (001-*.md)"
    else
        fail "ADR filename does not follow numbering convention"
    fi
fi

# Check all WireMock stubs target the same base path
if [ -f "$WIREMOCK_POST_201" ] && [ -f "$WIREMOCK_PUT_200" ] && \
   [ -f "$WIREMOCK_POST_500" ] && [ -f "$WIREMOCK_POST_TIMEOUT" ]; then
    base_path_count=$(grep -h "/v1/webtransaction" "$WIREMOCK_POST_201" "$WIREMOCK_PUT_200" \
                      "$WIREMOCK_POST_500" "$WIREMOCK_POST_TIMEOUT" 2>/dev/null | wc -l)

    if [ "$base_path_count" -ge 4 ]; then
        pass "All WireMock stubs target /v1/webtransaction base path"
    else
        fail "WireMock stubs have inconsistent base paths"
    fi
fi

# Test 19: Plan Step Completion Tracking
section "Plan Step Completion Tracking"

plan_steps_total=14
plan_steps_complete=0

# Step 1: Create web-transaction-microsite README
[ -f "$WTS_README" ] && grep -qi "architecture" "$WTS_README" && \
    grep -qi "api endpoint" "$WTS_README" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 2: Create ADR for fire-and-forget design
[ -f "$WTS_ADR" ] && grep -qi "context" "$WTS_ADR" && \
    grep -qi "decision" "$WTS_ADR" && \
    grep -qi "consequences" "$WTS_ADR" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 3: Create web-transaction-microsite deployment config
[ -f "$WTS_MICROSITE_YAML" ] && grep -q "web-transaction-microsite" "$WTS_MICROSITE_YAML" && \
    grep -qi "ecs" "$WTS_MICROSITE_YAML" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 4: Create orders-microsite CHANGELOG entry
[ -f "$ORDERS_CHANGELOG" ] && grep -qi "wts" "$ORDERS_CHANGELOG" && \
    grep -q "wts.integration.enabled" "$ORDERS_CHANGELOG" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 5: Create orders-microsite deployment config
[ -f "$ORDERS_MICROSITE_YAML" ] && grep -q "wts.integration.enabled" "$ORDERS_MICROSITE_YAML" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 6: Create WireMock stub — POST 201 success
[ -f "$WIREMOCK_POST_201" ] && grep -q "POST" "$WIREMOCK_POST_201" && \
    grep -q "201" "$WIREMOCK_POST_201" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 7: Create WireMock stub — PUT 200 success
[ -f "$WIREMOCK_PUT_200" ] && grep -q "PUT" "$WIREMOCK_PUT_200" && \
    grep -q "200" "$WIREMOCK_PUT_200" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 8: Create WireMock stub — POST 500 error
[ -f "$WIREMOCK_POST_500" ] && grep -q "POST" "$WIREMOCK_POST_500" && \
    grep -q "500" "$WIREMOCK_POST_500" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 9: Create WireMock stub — POST timeout
[ -f "$WIREMOCK_POST_TIMEOUT" ] && grep -q "POST" "$WIREMOCK_POST_TIMEOUT" && \
    grep -q "5000" "$WIREMOCK_POST_TIMEOUT" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 10: Create Docker Compose E2E configuration
[ -f "$DOCKER_COMPOSE_E2E" ] && grep -q "postgres" "$DOCKER_COMPOSE_E2E" && \
    grep -q "web-transaction-microsite" "$DOCKER_COMPOSE_E2E" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 11: Create web-transaction-microsite Dockerfile stub
[ -f "$WTS_DOCKERFILE" ] && grep -qi "FROM" "$WTS_DOCKERFILE" && \
    grep -qi "java" "$WTS_DOCKERFILE" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 12: Create RetailX CI workflow for web-transaction-microsite
[ -f "$GH_WORKFLOW_WTS" ] && grep -qi "build" "$GH_WORKFLOW_WTS" && \
    grep -qi "deploy" "$GH_WORKFLOW_WTS" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 13: Create RetailX CI workflow for orders-microsite
[ -f "$GH_WORKFLOW_ORDERS" ] && grep -qi "build" "$GH_WORKFLOW_ORDERS" && \
    grep -qi "deploy" "$GH_WORKFLOW_ORDERS" && \
    plan_steps_complete=$((plan_steps_complete + 1))

# Step 14: End-to-end integration validation (already tested above)
if [ -f "$WTS_README" ] && [ -f "$WTS_ADR" ] && [ -f "$WTS_MICROSITE_YAML" ] && \
   [ -f "$ORDERS_CHANGELOG" ] && [ -f "$ORDERS_MICROSITE_YAML" ] && \
   [ -f "$WIREMOCK_POST_201" ] && [ -f "$WIREMOCK_PUT_200" ] && \
   [ -f "$WIREMOCK_POST_500" ] && [ -f "$WIREMOCK_POST_TIMEOUT" ] && \
   [ -f "$DOCKER_COMPOSE_E2E" ] && [ -f "$WTS_DOCKERFILE" ] && \
   [ -f "$GH_WORKFLOW_WTS" ] && [ -f "$GH_WORKFLOW_ORDERS" ]; then
    plan_steps_complete=$((plan_steps_complete + 1))
fi

if [ "$plan_steps_complete" -eq "$plan_steps_total" ]; then
    pass "All plan steps completed ($plan_steps_complete/$plan_steps_total)"
else
    fail "Plan steps incomplete ($plan_steps_complete/$plan_steps_total completed)"
fi

# Test 20: Directory Structure Validation
section "Directory Structure Validation"

# Check web-transaction-microsite directory structure
if [ -d "web-transaction-microsite" ]; then
    pass "web-transaction-microsite directory exists"
else
    fail "web-transaction-microsite directory missing"
fi

if [ -d "web-transaction-microsite/docs/adr" ]; then
    pass "web-transaction-microsite/docs/adr directory exists"
else
    fail "web-transaction-microsite/docs/adr directory missing"
fi

# Check orders-microsite directory structure
if [ -d "orders-microsite" ]; then
    pass "orders-microsite directory exists"
else
    fail "orders-microsite directory missing"
fi

if [ -d "orders-microsite/tests/wiremock/mappings" ]; then
    pass "orders-microsite/tests/wiremock/mappings directory exists"
else
    fail "orders-microsite/tests/wiremock/mappings directory missing"
fi

# Check GitHub workflows directory
if [ -d ".github/workflows" ]; then
    pass ".github/workflows directory exists"
else
    fail ".github/workflows directory missing"
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
    echo "✓ WTR-10 E2E measurement: ALL TESTS PASSED"
else
    echo "✗ WTR-10 E2E measurement: SOME TESTS FAILED"
fi

echo ""
exit $EXIT_CODE
