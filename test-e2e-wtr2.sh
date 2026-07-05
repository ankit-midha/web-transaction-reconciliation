#!/bin/bash
# Full E2E measurement test for WTR-2 implementation
# Tests all components of the merged-SDLC agent workflow

set -e

echo "=========================================="
echo "WTR-2 E2E Measurement Test"
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

# Test 1: GitHub Actions workflow structure
section "GitHub Actions Workflow Structure"

if [ -f ".github/workflows/agent.yml" ]; then
    pass "agent.yml exists"
else
    fail "agent.yml missing"
fi

# Validate YAML syntax using Python
if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/agent.yml'))" 2>/dev/null; then
    pass "agent.yml is valid YAML"
else
    fail "agent.yml has YAML syntax errors"
fi

# Check required workflow inputs
if grep -q "workflow_dispatch:" .github/workflows/agent.yml; then
    pass "workflow_dispatch trigger configured"
else
    fail "workflow_dispatch trigger missing"
fi

if grep -q "phase:" .github/workflows/agent.yml && \
   grep -q "job_id:" .github/workflows/agent.yml && \
   grep -q "jira_key:" .github/workflows/agent.yml; then
    pass "Required workflow inputs defined (phase, job_id, jira_key)"
else
    fail "Missing required workflow inputs"
fi

# Test 2: Concurrency configuration
section "Concurrency Configuration"

if grep -q "concurrency:" .github/workflows/agent.yml && \
   grep -q "cancel-in-progress: false" .github/workflows/agent.yml; then
    pass "Concurrency configured correctly (serialized per ticket+phase)"
else
    fail "Concurrency configuration incorrect or missing"
fi

# Test 3: OIDC permissions
section "OIDC and AWS Integration"

if grep -q "id-token: write" .github/workflows/agent.yml; then
    pass "OIDC id-token permission granted"
else
    fail "OIDC id-token permission missing"
fi

if grep -q "aws-actions/configure-aws-credentials@v4" .github/workflows/agent.yml; then
    pass "AWS credentials action configured"
else
    fail "AWS credentials action missing"
fi

if grep -q "role-to-assume:" .github/workflows/agent.yml; then
    pass "IAM role assumption configured"
else
    fail "IAM role assumption missing"
fi

# Test 4: Jira integration
section "Jira API Integration"

if grep -q "JIRA_BASE_URL" .github/workflows/agent.yml && \
   grep -q "JIRA_EMAIL" .github/workflows/agent.yml && \
   grep -q "JIRA_API_TOKEN" .github/workflows/agent.yml; then
    pass "Jira authentication environment variables defined"
else
    fail "Jira authentication variables incomplete"
fi

# Check Jira fetch step
if grep -q "Fetch Jira ticket" .github/workflows/agent.yml && \
   grep -q "/rest/api/3/issue/" .github/workflows/agent.yml; then
    pass "Jira ticket fetch step configured (REST v3)"
else
    fail "Jira ticket fetch step missing or incorrect"
fi

# Check Jira comment post step
if grep -q "Post spec to Jira ticket" .github/workflows/agent.yml && \
   grep -q "/rest/api/3/issue/.*/comment" .github/workflows/agent.yml; then
    pass "Jira comment post step configured"
else
    fail "Jira comment post step missing"
fi

# Test 5: Claude Code integration
section "Claude Code Action Integration"

if grep -q "anthropics/claude-code-action@v1" .github/workflows/agent.yml; then
    pass "claude-code-action@v1 referenced"
else
    fail "claude-code-action missing"
fi

if grep -q "CLAUDE_CODE_USE_BEDROCK" .github/workflows/agent.yml; then
    pass "Bedrock mode enabled"
else
    fail "Bedrock mode not enabled"
fi

if grep -q "BEDROCK_MODEL_ID" .github/workflows/agent.yml || \
   grep -q "ANTHROPIC_MODEL" .github/workflows/agent.yml; then
    pass "Model ID configuration present"
else
    fail "Model ID configuration missing"
fi

# Check allowed tools
if grep -q "allowed-tools.*Read,Write,Edit,Bash" .github/workflows/agent.yml; then
    pass "Tool restrictions configured"
else
    fail "Tool restrictions missing or incorrect"
fi

# Check max turns
if grep -q "max-turns" .github/workflows/agent.yml; then
    pass "max-turns limit configured"
else
    fail "max-turns limit missing"
fi

# Test 6: Prompts directory
section "Prompts and Instructions"

if [ -d "prompts" ]; then
    pass "prompts/ directory exists"
else
    fail "prompts/ directory missing"
fi

if [ -f "prompts/intake.md" ]; then
    pass "prompts/intake.md exists"
else
    fail "prompts/intake.md missing"
fi

# Validate intake prompt structure
if grep -q "# Intake phase" prompts/intake.md && \
   grep -q "\.workflow/ticket\.json" prompts/intake.md && \
   grep -q "\.workflow/artifacts/spec\.md" prompts/intake.md; then
    pass "intake.md has correct structure and file references"
else
    fail "intake.md missing required content"
fi

# Test 7: Workflow artifacts directory
section "Workflow Artifacts"

if [ -d ".workflow/artifacts" ]; then
    pass ".workflow/artifacts/ directory exists"
else
    fail ".workflow/artifacts/ directory missing"
fi

if [ -f ".workflow/artifacts/.gitkeep" ]; then
    pass ".gitkeep present to preserve empty directory"
else
    fail ".gitkeep missing in artifacts directory"
fi

# Test 8: Spec artifact validation
section "Spec Artifact Output"

if [ -f ".workflow/artifacts/spec.md" ]; then
    pass "spec.md artifact exists"

    # Validate spec structure
    if grep -q "# Draft spec" .workflow/artifacts/spec.md && \
       grep -q "## Problem" .workflow/artifacts/spec.md && \
       grep -q "## Goal" .workflow/artifacts/spec.md && \
       grep -q "## Acceptance Criteria" .workflow/artifacts/spec.md; then
        pass "spec.md has required sections"
    else
        fail "spec.md missing required sections"
    fi

    # Check it's not empty
    SPEC_SIZE=$(wc -c < .workflow/artifacts/spec.md)
    if [ "$SPEC_SIZE" -gt 500 ]; then
        pass "spec.md has substantial content (${SPEC_SIZE} bytes)"
    else
        fail "spec.md appears too small (${SPEC_SIZE} bytes)"
    fi
else
    fail "spec.md artifact missing"
fi

# Test 9: Plan artifact validation
section "Plan Artifact Output"

if [ -f ".workflow/artifacts/plan.md" ]; then
    pass "plan.md artifact exists"

    # Validate plan structure
    if grep -q "# WTR-2 — Implementation plan" .workflow/artifacts/plan.md && \
       grep -q "## Approach" .workflow/artifacts/plan.md && \
       grep -q "## Files in scope" .workflow/artifacts/plan.md && \
       grep -q "## Plan Steps" .workflow/artifacts/plan.md; then
        pass "plan.md has required sections"
    else
        fail "plan.md missing required sections"
    fi

    # Check frontmatter
    if grep -q "generated_by:" .workflow/artifacts/plan.md && \
       grep -q "jira_key:" .workflow/artifacts/plan.md; then
        pass "plan.md has valid frontmatter"
    else
        fail "plan.md missing frontmatter"
    fi

    PLAN_SIZE=$(wc -c < .workflow/artifacts/plan.md)
    if [ "$PLAN_SIZE" -gt 1000 ]; then
        pass "plan.md has substantial content (${PLAN_SIZE} bytes)"
    else
        fail "plan.md appears too small (${PLAN_SIZE} bytes)"
    fi
else
    fail "plan.md artifact missing"
fi

# Test 10: Documentation
section "Documentation"

if [ -f "README.md" ]; then
    pass "README.md exists"

    if grep -q "agent.yml" README.md && \
       grep -q "intake" README.md && \
       grep -q "Bedrock" README.md; then
        pass "README.md documents the workflow"
    else
        fail "README.md incomplete"
    fi
else
    fail "README.md missing"
fi

if [ -f "CLAUDE.md" ]; then
    pass "CLAUDE.md exists"

    if grep -q "Post-Implementation Workflow" CLAUDE.md; then
        pass "CLAUDE.md has post-implementation workflow instructions"
    else
        fail "CLAUDE.md missing workflow instructions"
    fi
else
    fail "CLAUDE.md missing"
fi

# Test 11: Git configuration
section "Git Configuration"

# Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "WTR-2-impl" ]; then
    pass "On expected branch: WTR-2-impl"
else
    fail "Unexpected branch: $CURRENT_BRANCH (expected WTR-2-impl)"
fi

# Check commit history
if git log --oneline | grep -q "WTR-2"; then
    pass "WTR-2 related commits exist"
else
    fail "No WTR-2 commits found in history"
fi

# Verify clean working tree (should be clean per CLAUDE.md workflow)
if [ -z "$(git status --porcelain)" ]; then
    pass "Working tree is clean"
else
    fail "Working tree has uncommitted changes"
fi

# Test 12: Phase stub validation
section "Phase Implementation Status"

# Check that other phases are stubbed
if grep -q "other-phases-stub:" .github/workflows/agent.yml; then
    pass "Stub job exists for unimplemented phases"
else
    fail "Missing stub job for unimplemented phases"
fi

if grep -q "phase.*!=.*'intake'" .github/workflows/agent.yml; then
    pass "Phase routing logic present"
else
    fail "Phase routing logic missing"
fi

# Test 13: Security checks
section "Security Configuration"

# Check no hardcoded secrets
if ! grep -rE "(api[_-]?key|secret|password|token).*=.*['\"][a-zA-Z0-9]{20,}['\"]" .github/workflows/agent.yml; then
    pass "No hardcoded secrets detected in workflow"
else
    fail "Potential hardcoded secrets found in workflow"
fi

# Check secrets are properly masked
if grep -q "secrets\.\|vars\." .github/workflows/agent.yml; then
    pass "Workflow uses GitHub secrets/vars properly"
else
    fail "Workflow may not be using secrets/vars correctly"
fi

# Test 14: Atlassian Document Format handling
section "Atlassian Document Format (ADF) Handling"

if grep -q "Atlassian Document Format" prompts/intake.md; then
    pass "Intake prompt mentions ADF format"
else
    fail "Intake prompt doesn't mention ADF handling"
fi

if grep -q "version:1,type:\"doc\"" .github/workflows/agent.yml; then
    pass "Jira comment post uses ADF structure"
else
    fail "Jira comment post may not use correct ADF structure"
fi

# Test 15: Error handling
section "Error Handling"

# Check for spec validation
if grep -q "if \[ ! -f .workflow/artifacts/spec.md \]" .github/workflows/agent.yml; then
    pass "Spec artifact validation present"
else
    fail "No validation for spec artifact existence"
fi

# Check for error reporting
if grep -q "::error::" .github/workflows/agent.yml; then
    pass "GitHub Actions error annotation used"
else
    fail "No error annotations found"
fi

# Check for jq validation
if grep -q "jq -e" .github/workflows/agent.yml; then
    pass "JSON validation with jq present"
else
    fail "No JSON validation found"
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
else
    echo "✗ SOME TESTS FAILED"
fi

echo ""
exit $EXIT_CODE
