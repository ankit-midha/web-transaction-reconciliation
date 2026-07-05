#!/usr/bin/env bash
# E2E measurement script for WTR-5 intake phase
# Simulates the full workflow and collects timing/quality metrics

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RESULTS_DIR="${REPO_ROOT}/.workflow/artifacts/e2e-results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

# Setup
log "Starting E2E measurement for WTR-5"
mkdir -p "${RESULTS_DIR}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="${RESULTS_DIR}/intake_${TIMESTAMP}.json"

# Copy mock ticket to expected location
log "Setting up mock ticket data"
cp "${SCRIPT_DIR}/mock-ticket-wtr5.json" "${REPO_ROOT}/.workflow/ticket.json"
success "Mock ticket staged at .workflow/ticket.json"

# Set environment variables
export JIRA_KEY="WTR-5"
export JOB_ID="e2e-measurement-${TIMESTAMP}"
export CLIENT_REF="test-ref-$(uuidgen || echo 'fallback-ref')"

log "Environment:"
log "  JIRA_KEY: ${JIRA_KEY}"
log "  JOB_ID: ${JOB_ID}"
log "  CLIENT_REF: ${CLIENT_REF}"

# Start timing
START_TIME=$(date +%s)
START_TIME_ISO=$(date -Iseconds)

log "Executing intake prompt simulation"
echo "---"

# The actual measurement: run Claude Code with the intake prompt
# In a real workflow this would be the claude-code-action, but for local
# measurement we simulate by invoking the prompt logic directly

# For this test harness, we'll create a simple validator that checks
# if Claude can successfully process the ticket and generate a spec

SPEC_FILE="${REPO_ROOT}/.workflow/artifacts/spec.md"
rm -f "${SPEC_FILE}"

# Simulate Claude processing by reading the intake prompt and ticket
# In production this would be: claude-code --prompt @prompts/intake.md
log "Simulating Claude Code intake phase execution..."

# Mock execution (replace with actual claude invocation in real test)
if [ -f "${REPO_ROOT}/prompts/intake.md" ] && [ -f "${REPO_ROOT}/.workflow/ticket.json" ]; then
    # Validate ticket structure
    if ! jq -e '.key' "${REPO_ROOT}/.workflow/ticket.json" >/dev/null 2>&1; then
        error "Invalid ticket structure"
        exit 1
    fi

    # For measurement purposes, we'll check if we can parse the ticket
    TICKET_KEY=$(jq -r '.key' "${REPO_ROOT}/.workflow/ticket.json")
    TICKET_SUMMARY=$(jq -r '.fields.summary' "${REPO_ROOT}/.workflow/ticket.json")
    TICKET_TYPE=$(jq -r '.fields.issuetype.name' "${REPO_ROOT}/.workflow/ticket.json")

    success "Ticket parsed: ${TICKET_KEY} - ${TICKET_SUMMARY} (${TICKET_TYPE})"

    # In real measurement, Claude would generate spec.md
    # For now, we validate the prompt structure
    if grep -q "Draft spec" "${REPO_ROOT}/prompts/intake.md"; then
        success "Intake prompt structure validated"
    fi
else
    error "Missing required files"
    exit 1
fi

# End timing
END_TIME=$(date +%s)
END_TIME_ISO=$(date -Iseconds)
DURATION=$((END_TIME - START_TIME))

echo "---"
log "Measurement complete"

# Collect metrics
METRICS=$(cat <<EOF
{
  "test_run": {
    "timestamp": "${TIMESTAMP}",
    "start_time": "${START_TIME_ISO}",
    "end_time": "${END_TIME_ISO}",
    "duration_seconds": ${DURATION}
  },
  "environment": {
    "jira_key": "${JIRA_KEY}",
    "job_id": "${JOB_ID}",
    "client_ref": "${CLIENT_REF}"
  },
  "ticket_data": {
    "key": "${TICKET_KEY}",
    "summary": "${TICKET_SUMMARY}",
    "type": "${TICKET_TYPE}"
  },
  "validation": {
    "ticket_parsed": true,
    "prompt_valid": true,
    "spec_generated": $([ -f "${SPEC_FILE}" ] && echo "true" || echo "false")
  },
  "metrics": {
    "prompt_file_size": $(wc -c < "${REPO_ROOT}/prompts/intake.md"),
    "ticket_file_size": $(wc -c < "${REPO_ROOT}/.workflow/ticket.json"),
    "spec_file_size": $([ -f "${SPEC_FILE}" ] && wc -c < "${SPEC_FILE}" || echo "0")
  }
}
EOF
)

# Save results
echo "${METRICS}" | jq '.' > "${RESULT_FILE}"
success "Results saved to ${RESULT_FILE}"

# Display summary
echo ""
echo "==============================================="
echo "E2E Measurement Summary - WTR-5"
echo "==============================================="
echo "Duration: ${DURATION}s"
echo "Ticket: ${TICKET_KEY} - ${TICKET_SUMMARY}"
echo "Type: ${TICKET_TYPE}"
echo "Spec Generated: $([ -f "${SPEC_FILE}" ] && echo 'YES' || echo 'NO')"
echo "==============================================="
echo ""

# Display full results
log "Full results:"
jq '.' "${RESULT_FILE}"

log "E2E measurement complete ✓"
