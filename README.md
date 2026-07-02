# web-transaction-reconciliation

Target repo for the merged-SDLC agent orchestrator (see sibling
[`personal-agentic-poc`](../personal-agentic-poc)). This repo is what the agent clones,
opens PRs on, and pushes `<JIRA-KEY>-plan` / `<JIRA-KEY>-impl` branches to when a Jira
ticket in the "Web Transaction Reconciliation" project transitions to READY FOR BUILD.

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
