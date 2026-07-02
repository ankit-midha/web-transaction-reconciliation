# web-transaction-reconciliation

Target repo for the merged-SDLC agent orchestrator (see sibling
[`personal-agentic-poc`](../personal-agentic-poc)). This repo is what the agent clones,
opens PRs on, and pushes `<JIRA-KEY>-plan` / `<JIRA-KEY>-impl` branches to when a Jira
ticket in the "Web Transaction Reconciliation" project transitions to READY FOR BUILD.

## How it plumbs together

```
Jira ticket transitions to READY FOR BUILD
  → Jira Automation web request (X-JIRA-Secret)
  → deployed webhook Lambda (merged-webhook)
  → phase dispatcher decides light-lane
  → GitHub REST workflow_dispatch on this repo's agent.yml
  → this repo's agent.yml runs, reads the phase prompt, calls Claude, edits files
  → commits + PR back to this repo
```

## Files

- `.github/workflows/agent.yml` — the composite-action entry point the orchestrator triggers.
  Currently a **stub** that just echoes the inputs and posts an audit comment on Jira —
  proves the workflow_dispatch loop closes. Replace with the real prompt+Claude wiring
  from [`personal-agentic-poc/scaffold/action.yml`](../personal-agentic-poc/scaffold/action.yml)
  once the target agent is ready.
- `.workflow/artifacts/` — where the agent will land `spec.md`, `plan.md`, `verify.md`
  (empty for now; populated per-ticket by later phase runs).

## Prerequisites (one-off)

1. Create the repo on GitHub as `ankit-midha/web-transaction-reconciliation`.
2. Grant the deployed webhook a way to `workflow_dispatch` on this repo — the simplest
   is to store a fine-grained personal access token with
   `Actions: Read and write` + `Contents: Read and write` on this repo in AWS Secrets
   Manager under `merged/github-pat` (used by the dispatcher's `GhaLane`).
3. Push this repo up:
   ```bash
   cd ../web-transaction-reconciliation
   git init && git branch -M main
   git add . && git commit -m "chore: initial scaffold"
   gh repo create ankit-midha/web-transaction-reconciliation --public --push --source .
   ```
