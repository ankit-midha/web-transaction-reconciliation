---
generated_by: agentic-sdlc/plan@v1
jira_key: WTR-1
job_id: wtr-1-pvhfyh
---

# WTR-1 — Implementation plan

## Approach

This plan implements NMI checksum validation using the AEMO standard Luhn-like algorithm (also known as Modulus 10, Double Add Double). The algorithm will be implemented as a standalone validation function that can be integrated into the existing NMI parser module.

For 11-digit NMIs, the implementation will extract and validate against the provided checksum digit. For 10-digit NMIs, the implementation will calculate the expected checksum and accept the NMI as valid (since the absence of a checksum digit is not an error state per the spec).

The validation will follow TDD principles, with comprehensive test coverage for valid NMIs, invalid checksums, edge cases (all zeros, all nines, boundary conditions), and both 10-digit and 11-digit formats.

## Files in scope

- `src/nmi_parser.py` — main NMI parser module containing the validation function
- `src/nmi_checksum.py` — new module containing the AEMO Luhn-like checksum algorithm
- `tests/test_nmi_parser.py` — tests for the parser integration
- `tests/test_nmi_checksum.py` — tests for the checksum algorithm
- `README.md` — documentation update for the new validation feature

## Plan Steps

### Step 1: Implement AEMO Luhn-like checksum algorithm
- Test mode: `tdd`
- Files: `src/nmi_checksum.py`, `tests/test_nmi_checksum.py`
- Test strategy: Write tests first covering:
  - Known valid NMI checksums from AEMO documentation
  - Invalid checksums (off by 1, off by 5)
  - Edge cases: all zeros, all nines, single digit differences
  - Both 10-digit (calculate checksum) and 11-digit (validate against provided) formats
  - Empty string and None inputs

### Step 2: Integrate checksum validation into NMI parser
- Test mode: `tdd`
- Files: `src/nmi_parser.py`, `tests/test_nmi_parser.py`
- Test strategy: Write tests verifying:
  - Parser returns true for valid NMIs with correct checksums
  - Parser returns false for invalid checksums (no exception thrown)
  - Parser behavior unchanged for non-checksum validation (format, length)
  - Integration with existing parser logic (if any)
  - 10-digit NMIs continue to pass validation
  - 11-digit NMIs validate against suffix digit

### Step 3: Add documentation and examples
- Test mode: `test-after`
- Files: `README.md`
- Test strategy: Manual verification that:
  - README includes explanation of NMI checksum validation
  - Examples of valid and invalid NMIs are provided
  - Usage instructions are clear
  - No broken links or formatting issues

## Risks

- **Algorithm specification uncertainty**: The spec references "AEMO standard Luhn-like algorithm" but doesn't provide the exact formula. Implementation will assume the standard Modulus 10 Double Add Double algorithm used by AEMO for NMIs. If the actual algorithm differs, the implementation will need to be adjusted.
  - *Mitigation*: Step 1 tests will use known valid NMIs from AEMO documentation to verify correctness.

- **Unclear 10-digit behavior**: The spec asks "should we calculate the expected checksum and compare, or are 10-digit NMIs always valid?" but doesn't answer. Plan assumes 10-digit NMIs are valid (no checksum to validate).
  - *Mitigation*: Implementation will be structured to easily change this behavior if needed.

- **Missing codebase context**: This is a demonstration repository without the actual NMI parser code. File paths and function signatures are assumed based on typical Python project structure.
  - *Mitigation*: Implement phase will create the necessary files from scratch if they don't exist.

- **No existing test infrastructure**: If no test framework is configured, tests may not run.
  - *Mitigation*: Plan assumes pytest; if not present, tests can be adapted to unittest or another framework.

## Out-of-Plan (deferred)

- **Logging rejected NMIs**: The spec asks "should there be any logging when an invalid NMI is rejected, or silent failure?" This plan opts for silent failure (return false) to keep the validation function pure and side-effect free. Logging can be added by callers if needed.

- **Retroactive validation**: Explicitly out of scope per the spec. Existing invalid NMIs in the database will not be cleaned up.

- **Downstream service fixes**: Explicitly out of scope per the spec. Services that currently fail on invalid NMIs will not be modified.

- **Additional NMI format validation**: Validation beyond checksum (e.g., jurisdiction code prefixes, specific format rules) is explicitly out of scope.

- **Performance optimization**: No performance testing or optimization beyond the basic implementation.
