# Investigation: Verifier `_knownPreExistingDuplicates` hard-coded set

## Summary
Keep the fn-82 verifier's duplicate exception static; do not derive allowed duplicates from `git show HEAD:protocols.json` for this persistent manual verifier. The real issue is stale-exception hygiene after a future dedupe epic, best addressed by a follow-up static expected-count/self-check rather than a git-derived mutable baseline.

## Symptoms
- `tool/verify_protocols_json.dart` contains a hard-coded `_knownPreExistingDuplicates` set.
- The Flow spec asks for a literal-verbatim verifier commit/static gate, but the static allowance can silently rot if a future task removes or dedupes the gratitude duplicate.
- Proposed improvement: derive allowed duplicate names from `HEAD:protocols.json`; tradeoff is shelling out via `Process.runSync` and weakening the explicitly static gate.

## Background / Prior Research
- Git archaeology: `tool/verify_protocols_json.dart` has no committed history yet; the file is currently untracked on branch `feature/protocols-2`. The Flow task acceptance text expects it to become committed/tracked, so the verifier is still mid-task rather than historical production code.
- Origin: `.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md` specifies the verifier source verbatim, including `const _knownPreExistingDuplicates = <String>{ 'structured gratitude journaling for well-being' };`.
- Spec rationale: `.flow/specs/fn-82-add-3-community-validated-protocols-to.md` acknowledges an existing duplicate lower-case protocol name, `structured gratitude journaling for well-being`, and keeps deduping it out of scope because the task is append-only/prefix-preserving.
- Baseline duplicate check from explore agent: working tree `protocols.json` has 60 entries and HEAD `protocols.json` has 57 entries; both contain exactly one duplicate lower(name) group, `structured gratitude journaling for well-being`, count 2, at indices 31 and 56.
- Current alignment: `_knownPreExistingDuplicates` allows exactly that one duplicate pair. It would reject any third copy of that name or any other duplicate name.
- Open design question: whether the verifier should remain static/literal per spec or dynamically derive the allowlist from `git show HEAD:protocols.json`, accepting the added shell-out/runtime complexity to prevent static allowlist rot after a future dedupe epic.

## Investigator Findings
<!-- Pair investigator appends structured findings here with file:line refs, evidence, and conclusions. -->

### Phase 2 - Static allowlist vs dynamic HEAD-derived duplicates (2026-05-08)

**Question:** Should `tool/verify_protocols_json.dart` keep the static `_knownPreExistingDuplicates` allowlist, or derive allowed duplicates dynamically from `git show HEAD:protocols.json`?

**Verdict:** Keep the static allowlist for fn-82. The static set is not accidental; it is explicitly specified by the task's literal-verbatim verifier and matches the parent spec's append-only/prefix-identity contract. A dynamic `HEAD:protocols.json` baseline would solve stale-allowlist hygiene after a future dedupe commit, but it would also normalize any duplicate that has already reached `HEAD`, weakening the verifier from "only this known historical pair is tolerated" to "whatever duplicates are currently committed are tolerated." The better compromise is a static allowlist with an additional hygiene/self-check in a follow-up: each allowlisted lower(name) must still exist with exactly the expected count (currently 2), so future dedupe fails loudly until the constant is removed.

#### Evidence from Flow spec/task language

- The task description is append-only and content-preserving: append 3 entries while preserving the existing 57 content-identical, and commit `tool/verify_protocols_json.dart` as a manual dev-tool (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:7-20`).
- Step 0 explicitly creates a **baseline-duplicate snapshot** before editing to lock what `_knownPreExistingDuplicates` must match; expected output is exactly `['structured gratitude journaling for well-being']`, and extra baseline collisions require halting/updating the constant (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:32-43`).
- R1's gate is a parsed JSON deep-equal prefix check against `git show HEAD:protocols.json`; it exists to prove the first 57 entries were not semantically edited, not to infer an evolving duplicate policy (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:55-76`; `.flow/specs/fn-82-add-3-community-validated-protocols-to.md:112`).
- The verifier source is introduced as the **canonical implementation** to commit verbatim (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:93`), and the embedded code defines the static set with the comment "Pre-existing duplicate that is INTENTIONALLY preserved (R1 append-only)" and "allows exactly one collision pair" (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:129-132`).
- The parent spec acknowledges the same duplicate by lower(name), documents that DB upsert yields one fewer distinct row, and makes dedupe out of scope because it would require an inline edit that violates R1 append-only (`.flow/specs/fn-82-add-3-community-validated-protocols-to.md:78`).
- Acceptance re-states the static contract: the baseline snapshot must show exactly the gratitude duplicate and the verifier must tolerate only the known collision pair with no new collisions (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:568,584,590`).

#### Actual verifier behavior matrix

Code anchors: the static set is in `tool/verify_protocols_json.dart:34-38`; `nameCounts` is built by lowercasing every string `name` (`tool/verify_protocols_json.dart:76-82`); a duplicate is tolerated only when the key is in `_knownPreExistingDuplicates` **and** its count is exactly 2 (`tool/verify_protocols_json.dart:84-90`). The script reads only the working-tree `protocols.json`, with no git/HEAD lookup (`tool/verify_protocols_json.dart:63-65`).

| Scenario | Static verifier result | Evidence/reasoning |
|---|---:|---|
| Known gratitude duplicate, count 2 | Pass | `_knownPreExistingDuplicates.contains(e.key) && e.value == 2` is true (`tool/verify_protocols_json.dart:84-87`). A read-only count check found both current 60-entry working tree and `HEAD` 57-entry JSON contain exactly this duplicate at indices 31 and 56. |
| Third copy of the known gratitude name | Fail | The name is allowlisted, but `e.value == 2` is false, so the verifier emits `uniqueness: lower(name) ... appears 3 times` (`tool/verify_protocols_json.dart:84-90`). |
| Any unrelated duplicate | Fail | `contains(e.key)` is false, so even count 2 enters the error branch (`tool/verify_protocols_json.dart:84-90`). |
| Future dedupe removes one gratitude copy while static allowlist remains | Pass silently today | Count becomes 1, so `e.value > 1` is false and the stale allowlist entry is never consulted (`tool/verify_protocols_json.dart:84-90`). This is the real lifecycle weakness of the static set. |
| Dynamic allowlist from `git show HEAD:protocols.json`, before fn-82 commit | Mostly equivalent for current task | HEAD has the same single duplicate pair, so deriving allowed names/counts from HEAD would still pass the fn-82 working tree and reject unrelated new working-tree duplicates. |
| Dynamic allowlist from `git show HEAD:protocols.json`, after a duplicate has been committed | Weaker policy | Once any duplicate pair lands in HEAD, it becomes part of the derived baseline and future verifier runs tolerate it. That changes the policy from "only this known historical pair" to "all committed duplicate pairs," which is not what the Flow text says. |
| Dynamic allowlist after a future dedupe commit | Cleaner hygiene | Once HEAD no longer has the gratitude duplicate, the derived allowlist drops it automatically. This benefit can be obtained without dynamic HEAD by adding a static self-check that the allowlisted key still has count 2. |

#### Process.runSync / shell-out precedent

- There is one Dart `tool/` precedent: `tool/generate_seed_sql.dart` shells out with `Process.runSync` to `shasum -a 256` or `sha256sum` for the migration audit hash (`tool/generate_seed_sql.dart:200-222`). That shows dev-tools may shell out when the dependency is narrow and directly tied to output generation.
- There is no existing Dart `tool/` git shell-out precedent. `tool/verify_protocols_json.dart` is currently a pure working-tree JSON validator, and the CI workflow does not invoke it (`.github/workflows/test.yaml:31-37,56`). The only CI tool script present here uses `find`/`grep`, not git (`tool/ci/check_adaptive_white_tokens.sh:5-65`).
- Therefore shell-out precedent is not decisive. A git shell-out is feasible, but it adds environmental coupling (git availability, committed file/ref semantics, current worktree vs HEAD ambiguity) in a file whose spec calls for a committed manual static gate.

#### Eliminated hypotheses

- **"The static allowlist is arbitrary implementation drift."** Disproved. The task spells out a baseline-duplicate snapshot and provides a canonical verifier implementation containing the constant (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:32-43,93,129-132`).
- **"The static allowlist lets third copies of the known duplicate through."** Disproved. The verifier requires the allowlisted key's count to be exactly 2 (`tool/verify_protocols_json.dart:84-90`).
- **"Dynamic HEAD derivation is strictly stronger."** Disproved. It is stronger only for stale-allowlist cleanup after dedupe; it is weaker after any duplicate pair is committed because it converts committed duplicates into allowed baseline duplicates.
- **"Process.runSync is forbidden by repo convention."** Disproved. `tool/generate_seed_sql.dart` uses it for checksum fallback (`tool/generate_seed_sql.dart:200-222`). The relevant distinction is not shell-out vs no shell-out, but static policy vs git-state-derived policy.

#### Recommendation

For fn-82, do **not** change `tool/verify_protocols_json.dart` to derive duplicates from `HEAD`. Keep the literal static allowlist so the verifier enforces the spec's known historical exception and continues to reject newly introduced duplicate pairs even after they are committed. If the stale-allowlist concern should be fixed now or in a follow-up, add a small static hygiene check instead: compute `nameCounts` as today, then assert every entry in `_knownPreExistingDuplicates` has the expected allowed count (currently exactly 2). That would make future dedupe fail loudly until the constant is removed, without letting arbitrary committed duplicates become policy.


## Investigation Log

### Phase 1 - Initial Assessment
**Hypothesis:** The hard-coded duplicate set was intentionally specified by the Flow task/spec as a static preflight guard, but may have lifecycle risk once the acknowledged duplicate is removed.
**Findings:** Exact matches exist in `.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md` and `tool/verify_protocols_json.dart`. Broader context points to `.flow/specs/fn-82-add-3-community-validated-protocols-to.md` and repo-root `protocols.json`.
**Evidence:** Initial RepoPrompt searches for `_knownPreExistingDuplicates` and `protocols.json`.
**Conclusion:** Proceeding with git archaeology, context-builder selection, pair investigation, and oracle synthesis.

### Phase 4 - Oracle Synthesis
**Hypothesis:** Dynamic `HEAD` derivation might be preferable because it automatically drops the gratitude exception after a future dedupe commit.
**Findings:** Oracle synthesis confirmed dynamic `HEAD` derivation is only preferable for a different contract: a temporary pre-commit diff checker. For a committed persistent verifier, `HEAD` means current committed catalog state; any duplicate already committed to `HEAD` would become implicitly allowed.
**Evidence:** Selected context includes `tool/verify_protocols_json.dart:34-90`, `.flow/tasks/fn-82-add-3-community-validated-protocols-to.1.md:32-43,124-193,568-590`, `.flow/specs/fn-82-add-3-community-validated-protocols-to.md:78,112-118`, and `tool/generate_seed_sql.dart:196-222`.
**Conclusion:** Keep the static exception for fn-82. Recommend a follow-up static count-map/self-check if maintainers want to prevent stale exception rot without changing verifier policy to git-state-derived behavior.

## Root Cause
The concern comes from promoting a fn-82-specific static duplicate exception into a persistent manual verifier without a stale-exception hygiene check. The static exception itself is intentional: fn-82's append-only/prefix-identity contract preserves a known `lower(name)` collision, `structured gratitude journaling for well-being`, and the task's canonical verifier tolerates exactly that collision pair. The lifecycle weakness is that, after a future dedupe removes one gratitude entry, the current verifier would not notice the stale allowlist because the duplicate branch only runs for `count > 1`.

Dynamic `git show HEAD:protocols.json` derivation addresses that one stale-allowlist case, but changes the verifier's policy from "only reviewed historical exceptions are allowed" to "whatever duplicate pairs are currently committed are allowed." That is weaker for a persistent committed verifier and does not match the Flow task's static gate.

## Recommendations
1. For fn-82, keep `tool/verify_protocols_json.dart` static/literal as specified; do not derive duplicate exceptions from `HEAD`.
2. If hardening is desired, create a small follow-up task to replace the set with an expected-count map, e.g. `_knownPreExistingDuplicateCounts = {'structured gratitude journaling for well-being': 2}`, and enforce both directions: actual duplicates must match the map, and every map entry must still appear with the expected count.
3. In the future dedupe epic, make removal of the gratitude duplicate verifier exception an explicit done criterion alongside the catalog edit.
4. Keep `git show HEAD:protocols.json` scoped to fn-82's append-only/prefix-identity gate or other pre-commit diff checks, not persistent duplicate policy inference.

## Preventive Measures
- Document near the verifier's duplicate policy that exceptions are reviewed catalog policy, not inferred from git state.
- Add a Flow follow-up for static count-map/self-check hardening if the team wants stale-exception failures before the dedupe epic.
- Add dedupe-epic checklist language: "remove stale duplicate verifier exception and prove zero unexpected duplicates."
- If the verifier is later promoted to CI, keep duplicate policy static unless the CI job is explicitly designed as a PR diff gate against a stable base branch.
