---
name: audit-codebase
description: Exhaustive adversarial audit of a codebase's implementation — defects, design incoherences, unintended affordances, doc drift, and expectation-vs-reality gaps — written to docs/audits/.
disable-model-invocation: true
---

Perform an exhaustive, adversarial audit of this entire codebase — surfacing not just defects but design incoherences, unexpected affordances, doc drift, and mismatches between what the code invites you to do and what it actually does.

This document is your task spec — execute it to the letter, not as reference to summarize or improve. Stay strictly within the scope it defines: make no change it doesn't authorize, and do not commit, push, or touch git state. You are not done until the Output/stop criteria are met exactly as written.

# Role
Act simultaneously as senior staff engineer, skeptical first-time API consumer, and adversarial reviewer. No loyalty to the current design. Understand the system deeply enough to challenge it, not merely validate it.

# Scope
Read the codebase in full — do not sample silently. Build a model of:
- Entry points and real (not documented) execution paths.
- Module boundaries and the contracts between them (explicit and implied).
- Data models, invariants, and where they're actually enforced vs. assumed.
- External surfaces: APIs, CLIs, config, env vars, file formats, network calls.
- The docs/onboarding path a newcomer would actually follow.

Before judging, create a scope inventory:
- Repo type, package managers, major entry points, public surfaces.
- Generated/vendor/build directories excluded and why.
- Test/fixture/example directories read, skimmed, or treated as evidence.
- Commands used to enumerate files and public surfaces.
- Known blind spots.

# Command safety
Prefer read-only inspection and commands that run in local throwaway state. Do not run destructive, publishing, deploy, migration, credential-mutating, network-writing, or external-service-mutating commands unless the repo explicitly documents them as safe local checks and they can be run without secrets. If a useful check is unsafe or needs credentials, mark it BLOCKED and state the exact command you would have run.

# Evidence and severity
Evidence labels:
- CONFIRMED: reproduced, traced end-to-end, or verified against exact code/docs/command output.
- PLAUSIBLE: strong path identified but not fully reproduced.
- BLOCKED: missing dependency, credential, fixture, platform, or unsafe command boundary.
- NOT REPRODUCED: investigated and discarded or contradicted by evidence.

Severity scale:
- Critical: data loss, security exposure, corruption, or impossible core workflow.
- High: wrong public behavior, broken contract, serious safety/DX trap.
- Medium: inconsistent behavior with workaround or limited blast radius.
- Low: clarity, maintainability, naming, or local polish.

# Hunt for (go beyond bugs)
1. Correctness — logic errors, races, off-by-one, unhandled edges, silently swallowed failures, wrong error propagation.
2. Alternative/unintended paths — second call? concurrent calls? empty/null/huge input? partial failure mid-op? retries? the "holding it wrong" path?
3. Incoherences — names that lie about behavior, two modules solving one problem differently, config honored here and ignored there, duplicated sources of truth that can drift, dead code, contradictory defaults.
4. Affordance mismatches — "I expected to do X this way but can't, or it does something else." Where does the API shape promise a capability the code doesn't deliver? Where is the easy path also the dangerous one?
5. Missing functionality — things a reasonable user expects (validation, idempotency, cleanup, observability, cancellation, timeouts) but that are absent.
6. Boundary & safety — leaky abstractions, invariants in the wrong layer, trust in unvalidated input crossing a boundary; injection, path traversal, unbounded growth, resource leaks, missing authz, exposed secrets — only where real. For security findings, include source -> trust boundary -> sink -> exploit/failure scenario; do not report generic concerns without that chain.
7. Documentation — README/docstrings/comments that are wrong, stale, or contradict the code; undocumented public behavior, params, errors, or side effects; examples that wouldn't run; missing "why" behind non-obvious decisions.
8. Developer experience — can a newcomer build, run, test, and debug from the docs alone? Confusing errors, silent misconfig, missing types/CI/tests, setup footguns, high-friction workflows.

# Method (adversarial, then verify)
- Per area, state how it SHOULD behave, then read to confirm or refute. Flag every expectation-vs-reality gap.
- Trace the top critical paths end-to-end, quoting the lines that matter. Check every doc example/command against the code when safe.
- Every finding needs a concrete scenario: specific inputs/state -> the wrong or surprising result. No vague "could be improved."
- Try to disprove each finding first; discard findings that don't survive scrutiny.
- If this overlaps a docs/process audit, keep only findings where codebase structure or implementation evidence adds unique value; otherwise cross-reference the likely audit area.

# Output
Write the full report to `docs/audits/codebase-audit-<YYYY-MM-DD>.md`, where `<YYYY-MM-DD>` is today's date. Create the directory if missing. Leave it uncommitted (the maintainer owns git).
Every finding = stable ID within this report (C1, C2... severity order); a fixing agent cites these.
Sections, top-heavy (summary + map first, detail last):
1. Summary table: ID | severity | area | one-line issue | file:line | evidence label.
2. System map: architecture, real execution paths, key invariants — so the maintainer can check your understanding.
3. Coverage accounting: files/dirs read fully, skimmed, excluded, commands run, blind spots.
4. Findings by hunt category, severity order. Each: ID, file:line, one-line issue, concrete failure/surprise scenario (inputs/state -> wrong result), evidence label, recommended direction.
5. Design tensions: 3-5 deepest structural issues (the approach is wrong, not a line); each with the alternative you'd weigh.
6. Expectation gaps: short "expected X, found Y" list for affordance/docs/DX.
7. What held up: short list of important paths/contracts that survived scrutiny.
8. Open questions: what code alone can't resolve; maintainer answers.

Your chat reply = short exec summary only: counts by severity/evidence + top 3-5 findings + report path. Rest lives in the file.

Be thorough over brief. Prioritize insight density and specificity over reassurance. Where something is sound, say so once and move on — spend your effort where it isn't.
