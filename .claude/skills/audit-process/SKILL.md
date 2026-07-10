---
name: audit-process
description: Exhaustive adversarial audit of a project's end-to-end workflows — dead ends, missing transitions, broken journeys, re-run/idempotency gaps, and agent-ergonomics failures — written to docs/audits/.
disable-model-invocation: true
---

Perform a process-level audit of this codebase's end-to-end workflows — not a line-by-line code review, but an examination of whether the processes the product promises actually compose into complete, walkable journeys. Find holes, dead ends, missing transitions, and steps where a user or agent gets stranded.

This document is your task spec — execute it to the letter, not as reference to summarize or improve. Stay strictly within the scope it defines: make no change it doesn't authorize beyond throwaway workspaces, and do not commit, push, or touch git state. You are not done until the Output/stop criteria are met exactly as written.

# Role
Act as a product-minded staff engineer walking every documented journey twice: once as a first-time human user following only the docs, once as an autonomous agent chaining commands via exit codes, structured output, or documented machine-readable surfaces. No loyalty to the current flows.

# Scope
Discover and walk the project's real user/developer/agent workflows. Start from the reader-facing docs and public entry points, then verify against code and command behavior. Include, when present:
- Onboarding: clean checkout/install -> health/preflight -> first successful local run -> required configuration -> green ready state.
- Primary lifecycle: create/import/ingest/initialize -> inspect/list/status -> modify/answer/approve/reject/apply -> terminal or durable state.
- Re-run lifecycle: run the same mutating command twice; re-run after input changes; run out of order; run after partial prior state.
- Output lifecycle: preview/dry-run -> apply/commit/write -> re-apply/idempotency -> cleanup/archive/delete, where supported.
- Publication/export/deploy/release lifecycle, only when safe to exercise locally without external mutation.
- Side processes: discovery/cache/index/state files, generated artifacts, validation, health/doctor/preflight, troubleshooting and recovery.
- Cross-process coherence: enumerate every persistent state a record/artifact/workflow item can occupy and check there is a documented command or API that moves each state forward.

Before judging, create a process coverage inventory:
- Docs, help text, scripts, package commands, CLIs, APIs, and config surfaces used to discover workflows.
- Throwaway workspaces/fixtures created and their initial state.
- Processes fully walked, partially walked, blocked, or intentionally skipped.
- Commands not run because they were unsafe, missing dependencies, or required external services.

# Command safety
Run mutating commands only inside throwaway workspaces, temp directories, or clearly isolated local fixtures. Do not run destructive, publishing, deploy, migration, credential-mutating, network-writing, or external-service-mutating commands against maintainer data or real external systems. If a useful check is unsafe or needs credentials, mark it BLOCKED and state the exact command you would have run.

For concurrency checks, snapshot the relevant workspace files before and after, use throwaway workspaces only, and report whether corruption/state drift was observed. Do not run concurrency tests against maintainer data.

# Evidence and severity
Evidence labels:
- CONFIRMED: reproduced through an exact command sequence or verified from persisted state/output.
- PLAUSIBLE: traced in code/docs but not fully reproduced.
- BLOCKED: missing dependency, credential, fixture, platform, external service, or unsafe command boundary.
- NOT REPRODUCED: investigated and discarded or contradicted by evidence.

Severity scale:
- Critical: data loss, state corruption, unsafe publication/export/deploy, or impossible core workflow.
- High: user/agent stranded in a primary process, broken documented journey, wrong exit/structured-output contract for automation.
- Medium: incomplete lifecycle, inconsistent retry/second-call behavior, missing recovery path with workaround.
- Low: confusing docs/help, local ergonomics, naming, or minor process polish.

# Hunt for
- Dead ends: states with no exit command/API, fixable today only by hand-editing state files or private internals.
- Missing processes: steps that README, docs, specs, quickstarts, examples, or help text promise but no command/API implements.
- Re-run/second-call semantics: every mutating command run twice, out of order, and against a half-completed prior run.
- Agent ergonomics: exit-code semantics per flow; can an agent distinguish "my operation failed" from "unrelated warning elsewhere"? Are JSON/structured-output contracts stable? Do help text and actual flags match? Is error output parseable?
- Docs/process drift: walk the documented flows command-by-command against reality.
- Concurrency: two safe local invocations against the same throwaway workspace for workflows that claim or imply shared-state safety.
- Recovery: partial failure, interrupted command, invalid input, missing dependency, corrupt local state, or deleted generated file. Is there a documented recovery path?

# Method
- Build real throwaway workspaces or fixtures. Keep all generated state local and disposable.
- For each process, record: initial state -> command(s)/API calls -> expected transition -> observed transition -> persisted files or external surfaces changed -> exit code/stdout/stderr/structured-output contract.
- Every finding needs the exact command sequence to reproduce and the resulting state/output.
- Try to disprove each finding before reporting; discard what does not survive.
- If this overlaps a codebase/docs audit, keep only findings where end-to-end workflow evidence adds unique value; otherwise cross-reference the likely audit area.

# Output
Write the full report to `docs/audits/process-audit-<YYYY-MM-DD>.md`, where `<YYYY-MM-DD>` is today's date. Create the directory if missing. Leave it uncommitted (the maintainer owns git).
Every finding = stable ID within this report (P1, P2... severity order); a fixing agent cites these.
Sections, top-heavy (summary + map first, detail last):
1. Summary table: ID | severity | process | one-line issue | evidence label.
2. Process map: real workflow/state machine (states, transitions, owning command/API); mark dead ends + unreachable states.
3. Process coverage accounting: workflows walked, fixtures used, commands run, commands blocked, blind spots.
4. Gaps/errors by process, severity order. Each: ID, file:line or command sequence, concrete stranded-user scenario, evidence label, recommended direction.
5. Missing-process backlog: command/API/flag/doc needed per documented journey to complete end-to-end; prioritize by unblocking value.
6. What held up: short list of flows or transitions that survived second-call/regression checks.
7. Open questions: maintainer-only.

Your chat reply = short exec summary only: counts by severity/evidence + top 3-5 findings + report path. Rest lives in the file.

Thorough over brief. Spend effort where flows break; one line where they hold.
