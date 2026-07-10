---
name: audit-docs
description: Exhaustive adversarial audit of a project's documentation as a product — drift from the code, buried leads, oversized docs that need splitting, and prose that should be a diagram — written to docs/audits/.
disable-model-invocation: true
---

Audit this project's documentation as a first-class artifact — checking that it tells the truth about the code, that each reader-facing guide leads with what matters and defers detail, that oversized documents are split so detail has room to breathe, and that architecture is shown as drawn processes rather than prose. Treat the docs as the product a reader actually consumes.

This document is your task spec — execute it to the letter, not as reference to summarize or improve. Stay strictly within the scope it defines: make no change it doesn't authorize, and do not commit, push, or touch git state. You are not done until the Output/stop criteria are met exactly as written.

# Role
Act simultaneously as: a docs lead who owns information architecture; a skeptical newcomer with only the docs and a terminal; a returning maintainer six months later hunting for one specific fact; and an autonomous agent that must act using the docs as its only spec. No loyalty to the current structure, file layout, or headings.

# Scope
Read every reader-facing surface in full — do not sample silently:
- README, docs/**, specs/**/quickstart.md, ADRs/decision records, CONTRIBUTING/onboarding.
- Doc-bearing code: public docstrings, module headers, CLI `--help`, config-file comments, example scripts.
- Every diagram already present. Inspect source and rendered output when the local toolchain makes rendering safe and available; otherwise mark render verification BLOCKED.

Build the current documentation map: which document exists, what it claims to cover, who it's for, and how a reader is expected to find it.

Before judging, classify each document by mode:
- tutorial
- how-to
- reference
- explanation
- ADR/decision record
- runbook/troubleshooting
- generated/reference surface

Apply inverted-pyramid expectations primarily to guides, how-tos, runbooks, and onboarding docs. Judge ADRs by context/decision/consequences, and reference docs by completeness, scanability, and single-source-of-truth discipline.

# Command safety
For accuracy checks, prefer read-only commands and local throwaway examples. Do not run destructive, publishing, deploy, migration, credential-mutating, network-writing, or external-service-mutating commands unless the repo explicitly documents them as safe local checks and they can be run without secrets. If a useful check is unsafe or needs credentials, mark it BLOCKED and state the exact command you would have run.

# Evidence and severity
Evidence labels:
- CONFIRMED: verified against exact code, docs, command output, or rendered artifact.
- PLAUSIBLE: strong documentation/code mismatch identified but not fully reproduced.
- BLOCKED: missing dependency, credential, fixture, renderer, platform, or unsafe command boundary.
- NOT REPRODUCED: investigated and discarded or contradicted by evidence.

Severity scale:
- Critical: docs lead users/agents into data loss, security exposure, broken publication/deploy, or impossible core workflow.
- High: wrong public command/API/config behavior, broken onboarding, or missing contract for a primary surface.
- Medium: misleading structure, stale secondary example, scattered source of truth, or missing troubleshooting with workaround.
- Low: local clarity, naming, navigation, formatting, or polish.

# Hunt for
1. Drift / inaccuracy (primary) — any claim the code no longer honors: renamed/removed commands, flags, env vars, paths, file formats, defaults; examples that don't run; output samples that no longer match; docs describing behavior the code has since changed. And the inverse: real public behavior, params, errors, side effects, and exit codes that no document mentions.
2. Inverted-pyramid violations — documents that bury the point. Guides/how-tos/runbooks should open with a one-paragraph "what this is / when you'd reach for it" plus the 20% that answers 80% of questions; reference tables, edge cases, and rationale belong later. Flag docs that front-load setup minutiae or history before the reader learns what the thing even is.
3. Sizing / decomposition — documents grown large enough that concerns collide and detail can't breathe: recommend the split (which sections become their own documents, what each is named, how they link back). Also the reverse: scattered fragments that should merge, and detail suppressed only because there was no room for it.
4. Architecture shown as drawn process — places where flow, lifecycle, or component interaction is explained in prose that a diagram would carry far better. Identify the key processes with no diagram, and diagrams that are now stale. Prefer Mermaid (flowchart for control flow, sequence for cross-component calls, stateDiagram for lifecycles, C4/component for structure).
5. Usefulness / audience fit — does each document serve a real reader task, or does it exist because someone felt obliged? Are the four modes (tutorial / how-to / reference / explanation) mixed into one document to nobody's benefit? Does it answer "why," not just "what"? Can a newcomer get from zero to first success on the docs alone?
6. Coverage — public surfaces (CLI, API, config, env, formats, exit codes, error taxonomy) with no documentation; missing troubleshooting/runbook; non-obvious design decisions with no ADR.
7. Single source of truth — the same fact stated in N places that will inevitably drift; pick the canonical home and make the rest link to it. Terminology and naming that shift document to document for the same concept.
8. Findability / navigation — given a real question, can the reader route to the right document without already knowing where it lives? Missing index/map, orphan documents, dead cross-links.

# Method (verify, don't assert)
- For every accuracy claim, check it against reality when safe: run the example, confirm the flag/command/path exists, diff the sample output. Mark evidence honestly.
- For each drift finding, include: document claim -> source of truth checked -> observed reality -> reader impact.
- For structure findings, state the concrete reader task that the current shape defeats, then the shape that serves it — no taste-only "would read cleaner."
- Try to disprove each finding first; discard what doesn't survive.
- If this overlaps a codebase/process audit, keep only findings where documentation evidence adds unique value; otherwise cross-reference the likely audit area.

# Output
Write the full report to `docs/audits/docs-audit-<YYYY-MM-DD>.md`, where `<YYYY-MM-DD>` is today's date. Create the directory if missing. Leave it uncommitted (the maintainer owns git).
Every finding = stable ID within this report (D1, D2... severity order); a fixing agent cites these.
Sections, top-heavy (summary + map first, detail last) — practice the pyramid you preach:
1. Summary table: ID | severity | document | one-line issue | evidence label.
2. Doc map: current vs proposed. Proposed tree = purpose + audience per doc + the splits/merges from hunt #3; a maintainer executes it directly.
3. Coverage accounting: documents/surfaces read fully, skimmed, excluded, commands/render checks run, blind spots.
4. Drift verification: each accuracy finding + exact check run or BLOCKED reason + result.
5. Findings by hunt category, severity order. Each: ID, document (file:line or heading), concrete reader scenario it breaks, evidence label, recommended direction.
6. Diagram backlog: processes/architecture needing a picture, value order; for the top 3-5 draft minimal Mermaid skeletons, naming target doc + location.
7. Missing-docs backlog: doc/section/example/diagram needed for full coverage + onboarding; prioritize by unblocking value.
8. What held up: short list of important docs or routes that already lead with the truth.
9. Open questions: maintainer-only.

Your chat reply = short exec summary only: counts by severity/evidence + top 3-5 findings + report path. Rest lives in the file.

Thorough over brief. Spend effort where the docs mislead, bury, or go silent; one line where they already lead with the truth.
