# Draft spec — WTR-1: Add NMI checksum validation to the parser

## Problem
The NMI parser currently accepts any 10-11 digit string without validating the checksum digit against the AEMO standard Luhn-like algorithm. This causes downstream services in the reconciliation pipeline to fail non-deterministically when invalid NMIs are processed.

## Goal
Add explicit checksum validation to the NMI parser so that invalid National Metering Identifiers are rejected before entering the reconciliation pipeline.

## Non-Goals
- Modifying downstream services that currently fail on invalid NMIs
- Changing the NMI format or structure beyond validation
- Retroactively validating or cleaning existing NMI data already in the system

## Users / Surfaces affected
- **NMI parser module** — the component that will receive the new validation logic
- **Reconciliation pipeline** — will no longer receive invalid NMIs
- **Upstream callers** — will receive explicit validation failures (return false) instead of downstream non-deterministic errors

## Acceptance Criteria
- Valid 10-digit NMIs continue to pass validation
- Invalid checksums return false (no exception thrown)
- 11-digit NMIs (with checksum suffix) validate against the suffix digit

## Open Questions
1. What is the exact specification of the "AEMO standard Luhn-like algorithm"? Is there a reference document or existing implementation?
2. Where is the NMI parser located in the codebase (file path and function/class name)?
3. Should the validation apply to both 10-digit and 11-digit NMIs, or only 11-digit ones?
4. For 10-digit NMIs without a checksum suffix, how should validation work? Should we calculate the expected checksum and compare, or are 10-digit NMIs always valid?
5. What should the function signature look like — does it currently return a boolean, or does it need to be refactored?
6. Are there any existing test cases or sample valid/invalid NMIs we should use for verification?
7. Should there be any logging when an invalid NMI is rejected, or silent failure?

## Out-of-Scope
- Fixing or updating downstream services that previously handled invalid NMIs
- Migrating or cleaning existing invalid NMI data in the database
- Performance optimization of the parser beyond adding this validation step
- Adding validation for other NMI format issues beyond checksum (e.g., prefix validation, jurisdiction codes)
