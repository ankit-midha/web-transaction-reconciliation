# web-transaction-reconciliation

Target repo for the merged-SDLC agent orchestrator (see sibling
[`personal-agentic-poc`](../personal-agentic-poc)). This repo is what the agent clones,
opens PRs on, and pushes `<JIRA-KEY>-plan` / `<JIRA-KEY>-impl` branches to when a Jira
ticket in the "Web Transaction Reconciliation" project transitions to READY FOR BUILD.

## NMI Checksum Validation

This repository includes an NMI (National Metering Identifier) parser with integrated checksum validation using the AEMO standard Luhn-like algorithm (Modulus 10, Double Add Double).

### Features

- **Checksum calculation** for 10-digit NMI base identifiers
- **Validation** for both 10-digit and 11-digit NMIs
- **Format validation** ensuring NMIs contain only digits and have correct length
- **Silent failure mode** - invalid NMIs return `False` rather than throwing exceptions

### Usage

```python
from src.nmi_parser import is_valid_nmi, parse_nmi

# Simple validation
is_valid_nmi("1234567890")      # True (10-digit, no checksum)
is_valid_nmi("12345678903")     # True (11-digit with correct checksum)
is_valid_nmi("12345678904")     # False (11-digit with incorrect checksum)
is_valid_nmi("123")             # False (invalid length)

# Detailed parsing
result = parse_nmi("12345678903")
# Returns: {'nmi': '12345678903', 'valid': True, 'has_checksum': True}
```

### NMI Format

- **10-digit NMIs**: Always considered valid (no checksum digit to validate)
- **11-digit NMIs**: The 11th digit is the checksum, validated against the first 10 digits

### Checksum Algorithm

The AEMO Luhn-like algorithm:
1. Starting from the rightmost digit of the 10-digit base, double every second digit
2. If doubling results in a two-digit number, add the digits together
3. Sum all the resulting digits
4. The checksum is `(10 - (sum % 10)) % 10`

### Examples

Valid NMIs:
- `1234567890` (10-digit, no checksum)
- `12345678903` (11-digit, checksum = 3)
- `00000000000` (11-digit, checksum = 0)
- `99999999990` (11-digit, checksum = 0)

Invalid NMIs:
- `12345678904` (incorrect checksum, expected 3)
- `123` (too short)
- `123456789012` (too long)
- `123abc78901` (contains non-digits)

## The intake loop (implemented)

```
Jira ticket transitions to READY FOR BUILD
  → Jira Automation web request (X-JIRA-Secret)
  → deployed webhook Lambda (merged-webhook)
  → PhaseDispatcher fires workflow_dispatch on this repo's agent.yml
  → intake job:
      1. curls ticket.json from Jira REST v3
      2. assumes AWS role via GitHub OIDC (arn:aws:iam::072461290426:role/merged-gha-intake)
      3. runs anthropics/claude-code-action@v1 on Bedrock (Sonnet 4.5)
         with prompts/intake.md
      4. Claude reads ticket.json + writes .workflow/artifacts/spec.md
      5. curls the spec content as a Jira comment
```

## Files

- `.github/workflows/agent.yml` — real workflow with Bedrock + Claude Code (intake phase
  only; other phases stubbed).
- `prompts/intake.md` — the Intake phase prompt Claude reads. Adapted from
  `personal-agentic-poc/scaffold/phases/intake/prompt.md` to work with an on-disk
  ticket.json rather than Atlassian MCP.
- `.workflow/artifacts/` — Claude writes spec.md here per-run.

## Setup (one-off, ~5 minutes)

### 1. Create a Jira API token

- Go to <https://id.atlassian.com/manage-profile/security/api-tokens>
- **Create API token** (label: `merged-arch-poc`)
- Copy the value — you cannot re-view it later.

### 2. Set repo secrets + variables

Repo → **Settings** → **Secrets and variables** → **Actions**. Add:

**Secret**
| Name | Value |
|---|---|
| `JIRA_API_TOKEN` | the token from step 1 |

**Variables**
| Name | Value |
|---|---|
| `JIRA_EMAIL` | your Atlassian login email |
| `JIRA_BASE_URL` | e.g. `https://<your-workspace>.atlassian.net` (no trailing slash) |
| `AWS_ROLE_ARN` | `arn:aws:iam::072461290426:role/merged-gha-intake` |
| `BEDROCK_MODEL_ID` | `au.anthropic.claude-sonnet-4-5-20250929-v1:0` |

Or via `gh` CLI:

```bash
gh secret set JIRA_API_TOKEN --body '<paste-token>' --repo ankit-midha/web-transaction-reconciliation
gh variable set JIRA_EMAIL       --body 'you@example.com'                       --repo ankit-midha/web-transaction-reconciliation
gh variable set JIRA_BASE_URL    --body 'https://<workspace>.atlassian.net'     --repo ankit-midha/web-transaction-reconciliation
gh variable set AWS_ROLE_ARN     --body 'arn:aws:iam::072461290426:role/merged-gha-intake' --repo ankit-midha/web-transaction-reconciliation
gh variable set BEDROCK_MODEL_ID --body 'au.anthropic.claude-sonnet-4-5-20250929-v1:0'     --repo ankit-midha/web-transaction-reconciliation
```

### 3. Fire a real ticket

Create a Jira ticket in the Web Transaction Reconciliation project, drag to
**READY FOR BUILD**. Within ~30 seconds you should see:

- A workflow run under [Actions](../../actions) — `success` in ~1-2 minutes.
- A comment on the Jira ticket from you (the API-token identity), body is the draft spec.
