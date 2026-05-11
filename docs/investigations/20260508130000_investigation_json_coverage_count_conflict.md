# Investigation: JSON Coverage Count Conflict

## Summary
Confirmed: fn-82.2 introduced a documentation-instruction conflict by directing DB-distinct counts into cells labelled as JSON/source coverage. The generator/count math is correct; the affected JSON-labelled cells should use array counts (`60/60`, `85/85`, `2/85`) unless the table is explicitly redesigned/relabelled as DB-distinct.

## Symptoms
- Cells labelled `Present in JSON` and always-present `X/X` currently use DB-distinct denominators/counts such as `59/59`, `83/83`, and `2/83`.
- The column/row labels imply JSON-array coverage, where counts may be `60/60`, `85/85`, and `2/85`.
- The task spec appears to explicitly direct `distinct_protocols/distinct_protocols` for at least some of these present-tense cells.

## Background / Prior Research
- Git archaeology indicates the original protocol seed spec was created in commit `588988a` (2026-02-20) with `57/57`, `76/76`, and `2/76` cells, while the current `59/59`, `83/83`, and `2/83` values are uncommitted working-directory edits.
- Commit `dcac9ad` (fn-82.1, 2026-05-08) reportedly created `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md` with explicit instructions to update optionality table lines 66–69 using `distinct_protocols` / `distinct_citations`, even though those cells sit under a `JSON` column.
- The same archaeology found the line-38 `Present in JSON | 59/59 protocols` edit was not explicitly targeted by the task instructions, which focused on optionality table lines 66–69.
- Working hypothesis from git history: the task correctly defined both `array_*` and `distinct_*` meanings, but then applied `distinct_*` to JSON-labelled documentation cells, creating the semantic conflict.

## Investigator Findings
<!-- The pair investigator appends structured analysis here: file:line refs, evidence, conclusions. -->

### 2026-05-08 - fn-82.2 count semantics vs JSON-labelled coverage cells

**Hypothesis:** Confirmed. Task fn-82.2 correctly defines two count domains, but then directs DB-distinct values into cells whose labels read as JSON/source coverage.

**Evidence - task wording:**
- `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:28-30` defines `array_entries` / `array_citations` as the `protocols.json` array and emitted INSERT-block counts.
- `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:32-39` defines `distinct_protocols` / `distinct_citations` as DB state after `lower(name)` upsert, with last duplicate occurrence winning.
- `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:74-76` explicitly permits in-place edits to coverage rows and directs `57/57` protocol cells to `${distinct_protocols}/${distinct_protocols}` and `76/76` citation cells to `${distinct_citations}/${distinct_citations}` / `2/${distinct_citations}`.
- `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:119-121` restates the semantic split: `array_*` means entries/INSERTs; `distinct_*` means DB rows after upsert; ambiguous lines default to distinct.

**Evidence - affected spec cells:**
- `docs/specs/20260220120000_spec_protocol_description_and_seed.md:40` currently says `Present in JSON | 59/59 protocols`. That row is explicitly JSON-labelled and therefore should describe literal `protocols.json` coverage if edited for current state.
- `docs/specs/20260220120000_spec_protocol_description_and_seed.md:64-71` contains the optionality table. Its second column is labelled `JSON`, but rows now show `always present (59/59)`, `present 83/83`, and `missing 2/83`.
- The current uncommitted diff shows `docs/specs/20260220120000_spec_protocol_description_and_seed.md:40` changed from `57/57` to `59/59` even though fn-82.2 only singled out the optionality table rows for in-place edits; the task's separate caution at `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:78-84` says to leave the line-38-style `57/57` row if it is historical narrative. This makes the `Present in JSON` edit outside the clearest task scope.

**Evidence - actual counts and upsert behavior:**
- Recomputed from `protocols.json`: `array_entries=60`, `array_citations=85`, `distinct_protocols=59`, `distinct_citations=83`.
- `protocols.json:1101-1144` is the first `Structured Gratitude Journaling for Well-Being` entry with 2 citations; `protocols.json:1856-1882` is the later entry with the same `lower(name)` and 1 citation.
- `tool/generate_seed_sql.dart:79-87` emits one protocol upsert per JSON array entry using `ON CONFLICT ((lower(name))) DO UPDATE`; `tool/generate_seed_sql.dart:108-124` deletes citations per protocol name before re-inserting; `tool/generate_seed_sql.dart:126-151` inserts the citations for the current array entry.
- The generated migration confirms the same order/shape: `supabase/migrations/20260508124758_seed_protocols_add3.sql:1-9` says the migration upserts 60 protocols and creates the `lower(name)` unique index; duplicate protocol upserts occur at `supabase/migrations/20260508124758_seed_protocols_add3.sql:449-457` and `:799-807`; the duplicate citation delete/reinsert blocks occur at `:1524-1548` and `:1910-1918`. Because the later delete runs after the earlier two inserts, the DB retains only the later duplicate's one citation, so citations are `85 - 2 = 83`.
- The two missing DOI citations are not on the overwritten duplicate: `protocols.json:923-943` and `protocols.json:1677-1697` are the two citation objects without `doi`. Therefore the DB-distinct DOI-missing count remains 2, while the literal JSON denominator is 85 and the DB-distinct denominator is 83.

**Ruled-out alternatives:**
- Not a runtime seed/generator bug: the generator behavior is intentional and documented in fn-82's epic (`.flow/specs/fn-82-add-3-community-validated-protocols-to.md:76-78`, `:153-160`).
- Not an arithmetic error in the fn-82.2 script: the DB-distinct numbers `59` and `83` are correct for last-wins upsert semantics.
- Not evidence that `protocols.json` contains only 59 protocols or 83 citation entries: the literal source file contains 60 protocol objects and 85 citation objects.

**Conclusion:** The conflict is instruction-level/documentation-level: fn-82.2 asks maintainers to put DB-distinct counts into cells labelled as JSON coverage. This makes the resulting spec internally inconsistent with its own fn-82 addendum, which already distinguishes `60 entries in protocols.json` from `59 distinct after lower(name) upsert` and `85 citation entries` from `83 distinct citations`.

**Recommended resolution:**
1. In `docs/specs/20260220120000_spec_protocol_description_and_seed.md`, use literal JSON counts wherever the label says `Present in JSON` or the table column is `JSON`: `60/60 protocols`, `present 85/85`, and `missing 2/85`.
2. Preserve DB-distinct counts only where the label says DB, app-visible, product-facing, or distinct-after-upsert. If useful, add a footnote below the optionality table: `DB-distinct counts are 59 protocols / 83 citations after the duplicate lower(name) upsert; the JSON column counts literal source entries.`
3. Treat the `Present in JSON | 59/59 protocols` edit as outside the narrow fn-82.2 optionality-row scope unless the task is amended; if retained as a current-state cell, change it to `60/60 protocols`.
4. Amend fn-82.2/R5 wording in a follow-up task or review note so future documentation updates do not default JSON-labelled cells to `distinct_*` counts without relabelling the cells.

## Investigation Log

### Phase 1 - Initial Assessment
**Hypothesis:** The task spec conflicts with target document labels: task instructions used DB-distinct counts for cells labelled as JSON-level coverage.
**Findings:** Confirmed by git archaeology, context_builder, pair investigation, and oracle synthesis.
**Evidence:** `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:28-39` defines array vs distinct semantics, while `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:74-76` directs distinct values into present-tense coverage cells. `docs/specs/20260220120000_spec_protocol_description_and_seed.md:40` and `:64-71` contain the affected JSON-labelled cells.
**Conclusion:** Confirmed; final root cause and recommendations below.

## Root Cause
The root cause is a task-spec instruction conflict in `.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md`. The task correctly defines two count domains: `array_*` for literal `protocols.json` entries / emitted INSERT blocks (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:28-30`) and `distinct_*` for final DB state after `lower(name)` upsert (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:32-39`). It then directs maintainers to apply `distinct_*` values to present-tense coverage cells (`.flow/tasks/fn-82-add-3-community-validated-protocols-to.2.md:74-76`) that sit in JSON-labelled locations.

The affected target cells are JSON/source-data labels, not DB-state labels: `docs/specs/20260220120000_spec_protocol_description_and_seed.md:40` says `Present in JSON | 59/59 protocols`, and `docs/specs/20260220120000_spec_protocol_description_and_seed.md:64-71` has an optionality table whose second column is `JSON` but contains `59/59`, `83/83`, and `2/83`.

The underlying counts are not wrong: `protocols.json` contains 60 protocol entries and 85 citation entries, while DB-distinct state is 59 protocols / 83 citations because the duplicate `Structured Gratitude Journaling for Well-Being` entry is upserted by `lower(name)` and the later citation delete/reinsert wins (`protocols.json:1101-1135`, `protocols.json:1855-1882`, `tool/generate_seed_sql.dart:76-155`, `supabase/migrations/20260508124758_seed_protocols_add3.sql:1-9`, `:449-457`, `:799-807`, `:1524-1548`, `:1910-1918`). The defect is therefore documentation semantics, not runtime seed generation or arithmetic.

## Recommendations
1. In `docs/specs/20260220120000_spec_protocol_description_and_seed.md`, change JSON-labelled cells to literal JSON-array counts:
   - `Present in JSON | 59/59 protocols` → `Present in JSON | 60/60 protocols`
   - `always present (59/59)` → `always present (60/60)` for both `target.durationSeconds` and `target.intensity`
   - `citation url | present 83/83` → `citation url | present 85/85`
   - `citation doi | missing 2/83` → `citation doi | missing 2/85`
2. Preserve DB-distinct counts only where wording explicitly says DB rows, post-upsert state, app-visible catalog count, user-facing availability, or `distinct after lower(name) upsert`.
3. Keep the existing fn-82 addendum as the canonical two-track summary because it already states both semantics: 60/85 JSON entries and 59/83 DB-distinct rows.
4. Optional improvement: add a short footnote under the optionality table: `The JSON column counts literal protocols.json entries; DB-distinct counts after lower(name) upsert are 59 protocols / 83 citations.`
5. If a future author prefers DB-distinct values in the table, redesign it with an explicit separate column such as `DB after upsert`; do not silently relabel the existing JSON column.

## Preventive Measures
- Add a count-semantics guardrail to fn-82.2/R5 or the follow-up review note: **label wins over default**. If a cell says `JSON` / `protocols.json` / source entries / citation entries / emitted INSERT blocks, use `array_*`; use `distinct_*` only for DB/app/user-visible wording.
- Add a doc-review checklist item before protocol/citation count updates: classify each count as JSON/source-array, emitted migration block, DB-distinct post-upsert, or app/user-visible before changing the value.
- Do not allow the “default ambiguous lines to distinct” rule to override explicit source-data labels such as `Present in JSON` or a `JSON` table column.
- Preserve historical 57/76 dated-spec narrative; only current-state addenda or clearly present-tense data cells should be updated.
