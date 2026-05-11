---
satisfies: [R5]
---

## Description

Update protocol-count and citation-count references across the docs surface using **counts derived from `protocols.json` after task .1 lands**, with explicit semantics: each updated number distinguishes "array entries" (count of objects in `protocols.json` / `INSERT` blocks emitted) from "distinct DB rows after `lower(name)` upsert" (what the user actually experiences in the app). The pre-existing duplicate of "structured gratitude journaling for well-being" makes these two counts diverge by 1 (60 vs 59 for protocols; citations diverge by however many citations the duplicate's first-occurrence has). Pure find-and-replace; no logic changes; **historical migration prose preserved unchanged**.

**Size:** S
**Files:**
- `docs/specs/20260220120000_spec_protocol_description_and_seed.md` (top-of-file addendum + a few present-tense data cells; line numbers below are *indicative* — search by anchor text)
- `docs/README.md` (locate by anchor text "57 protocols, idempotent upsert" and "seed 57 protocols")
- `plan_update_protocol_domain_and_db.md` (locate by anchor text "57 protocols + 76 citations" and "57 protocols")

**Anchor-text-based search-and-replace** (preferred over line numbers — line numbers drift; anchor text is stable):

## Approach

**Step 0: Re-derive both counts from `protocols.json`** before patching any docs. Hard rule: do not assume 60/85 or 59/whatever — compute and capture both:

```bash
python3 <<'PY' > /tmp/fn-82-counts.txt
import json
from collections import OrderedDict

data = json.load(open("protocols.json"))

# Array-level counts (what protocols.json contains, what the migration emits as INSERT blocks)
array_entries = len(data)
array_citations = sum(len(p.get("research_citations", [])) for p in data)

# Distinct-after-upsert counts (what ends up in the DB after lower(name) ON CONFLICT upsert)
# The generator deletes ALL citations per protocol then re-inserts in the array-iteration order,
# so for any duplicated lower(name), only the LAST occurrence's citations survive.
seen = OrderedDict()  # lower(name) -> last-seen citation count
for p in data:
    seen[p["name"].lower()] = len(p.get("research_citations", []))
distinct_protocols = len(seen)
distinct_citations = sum(seen.values())

print(f"array_entries={array_entries}")
print(f"array_citations={array_citations}")
print(f"distinct_protocols={distinct_protocols}")
print(f"distinct_citations={distinct_citations}")
PY
cat /tmp/fn-82-counts.txt
# shellcheck source=/dev/null
source /tmp/fn-82-counts.txt
echo "Array: ${array_entries} protocols / ${array_citations} citations"
echo "Distinct (DB after upsert): ${distinct_protocols} protocols / ${distinct_citations} citations"
```

Expected pair: `array_entries=60, array_citations=85, distinct_protocols=59, distinct_citations=<computed>` (depends on how many citations the duplicate's first occurrence has — both copies of "Structured Gratitude Journaling for Well-Being" carry citations; the second copy's citations win after upsert).

**Step 1: Decide which count to use per doc line based on context.**

Rule of thumb:
- **"the seed catalog has X protocols"** / **"protocols.json contains X"** / **"the migration emits X upserts"** → use `array_*` counts.
- **"the app shows X protocols"** / **"the database has X distinct protocols"** / **"users can choose from X protocols"** / unqualified "X protocols" in product-facing docs → use `distinct_*` counts.

Most existing doc lines are ambiguous. Default rule for ambiguous lines: **interpret as DB-after-upsert (what users experience)** and use `distinct_*` counts. When the line is genuinely about "the seed source file", use `array_*`.

**Step 2: Mechanical find-and-replace, scoped to present-tense references about the seed catalog count** (not unrelated `57`/`76` numerics elsewhere in the repo, and not historical migration narrative).

**Hard rule — preserve historical narrative in dated specs.** `docs/specs/20260220120000_spec_protocol_description_and_seed.md` is a **dated spec** that describes the state of the catalog as of 2026-02-20 (57 protocols, 76 citations). **Rewriting any "57"/"76" inside the original Problem/Scope narrative or the Design-decision callout would falsify the historical record** of what was true on that date. The reviewer-preferred pattern: **add a top-of-file addendum** stating the post-fn-82 counts, and limit in-place edits to clearly present-tense data cells (coverage tables, totals at the bottom of the spec) — NOT prose paragraphs.

**`docs/specs/20260220120000_spec_protocol_description_and_seed.md`:**

**(a) Addendum at top of file (preferred — minimal in-place rewriting):** Insert immediately after the YAML frontmatter / first heading, before the Problem section:
```markdown
> **Update (2026-05-06 / fn-82):** The original spec below (2026-02-20) describes the seed catalog at the time of the initial 57-protocol migration. As of fn-82 the catalog is **${array_entries} entries in `protocols.json`** (${distinct_protocols} distinct after `lower(name)` upsert in the DB) and **${array_citations} citation entries** (${distinct_citations} distinct citations in the DB after the duplicate `lower(name)` upsert overwrites the first occurrence's citations). The historical narrative below is preserved unchanged as a snapshot of the 2026-02-20 state. See `.flow/specs/fn-82-add-3-community-validated-protocols-to.md` for the delta.
```

**(b) Present-tense data cells (in-place edits permitted):** Only the coverage tables / totals at the bottom of the spec (typically lines 66–69, "X/Y protocols" and "X/Y citations") may be edited in place because they are *current state* not *historical narrative*:
- Lines 66–67 (coverage cells `57/57 protocols`): `${distinct_protocols}/${distinct_protocols} protocols`
- Lines 68–69 (`76/76` citation cells): `${distinct_citations}/${distinct_citations}`; verify the `missing 2/76` DOI-missing denominator separately — should become `2/${distinct_citations}` (no new missing DOIs from the 9 fn-82 additions).

**(c) Do NOT in-place edit the following lines** (they are part of the historical narrative on 2026-02-20):
- Line 11 (`57 science-backed protocols` in the Problem statement) — leave; addendum at top covers the update
- Line 14 (`57 protocols` in Scope) — leave
- Line 20 (`57 protocols and 76 citations` in the migration narrative) — leave
- Line 28 (`**57 protocols**, **76 citations** total` in the original totals callout) — leave; addendum covers the update
- Line 38 (`57/57 protocols` if it appears in the historical migration narrative — verify context; leave if narrative)
- Lines 46–52 (Design-decision callout) — leave

**`docs/README.md`** (search by anchor text, not line number):
- Anchor `57 protocols, idempotent upsert` → `${distinct_protocols} protocols, idempotent upsert` *(product-facing — DB count)*
- Anchor `seed 57 protocols` → `seed ${array_entries} protocols (${distinct_protocols} distinct after lower(name) upsert)` *(this line is talking about the seed source — both numbers help)*

**`plan_update_protocol_domain_and_db.md`** (search by anchor text):
- Anchor `57 protocols + 76 citations` → `${array_entries} protocols + ${array_citations} citations (in protocols.json; ${distinct_protocols}/${distinct_citations} distinct after upsert)` *(plan doc is talking about the seed source — array count primary)*
- Anchor `57 protocols` (in the collision-avoidance rationale section, distinct from the line above) → `${distinct_protocols} protocols (in DB)` — verify by surrounding context to avoid hitting other "57" references

**Do NOT touch:**
- `docs/ubiquitous-language.md` — no count references
- `CLAUDE.md` / `AGENTS.md` — no count references
- Test files — `research_citation_test.dart:184,198` use `57` for string-truncation length (unrelated)
- `trial_expired_modal_test.dart:80,94` — UI tests, unrelated
- `docs/legal/research-findings.md` — `57` is a line-number reference, unrelated
- Historical migration prose anywhere

**Step 3: Final diff sanity check.** Before committing:

```bash
git diff -- 'docs/' '*.md' | grep -E '^[+-]' | grep -E '\b(57|76)\b' | head -20
# Expected: only the lines you intended to change, nothing else
```

## Investigation targets

**Required** (read before editing):
- `docs/specs/20260220120000_spec_protocol_description_and_seed.md` — full file; confirm every count reference is caught and historical prose is identified
- `docs/README.md:60-95` — verify the spec links section shows the right counts
- `plan_update_protocol_domain_and_db.md` — full file
- `protocols.json` — to compute counts (Step 0)

## Key context

- **Counts are derived, not assumed.** Step 0 reads from `protocols.json` to get the actual values. Two distinct counts are computed: `array_*` (entries / INSERTs emitted) and `distinct_*` (DB rows after `lower(name)` upsert). The pre-existing duplicate of "structured gratitude journaling for well-being" makes these diverge by 1 protocol; citations diverge by the duplicate's first-occurrence citation count.
- **Historical narrative is sacrosanct.** The spec contains a "Design decision" callout describing what the original 57-protocol migration did. Rewriting it to "60" or "59" misrepresents what happened. Update only present-tense summaries.
- **Default ambiguous lines to `distinct_*` counts.** What users experience in the app is the DB-after-upsert state. The few lines genuinely about "the seed source file" use `array_*`.

## Acceptance

- [ ] Step 0 captured both `array_*` and `distinct_*` counts from `protocols.json` (not hard-coded) before any edits
- [ ] `docs/specs/20260220120000_spec_protocol_description_and_seed.md` has a **top-of-file addendum** (Update note) stating `${array_entries}` / `${array_citations}` / `${distinct_protocols}` / `${distinct_citations}`; **historical narrative lines (Problem, Scope, original totals) are unchanged**; only coverage cells at the bottom (`X/X protocols`, `X/X citations`) are edited in-place to use `distinct_*`
- [ ] `docs/README.md`: the line containing anchor `57 protocols, idempotent upsert` shows `${distinct_protocols} protocols, idempotent upsert`; the line containing anchor `seed 57 protocols` shows both counts (the line is about the seed source)
- [ ] `plan_update_protocol_domain_and_db.md`: the line containing anchor `57 protocols + 76 citations` shows `${array_entries} protocols + ${array_citations} citations` plus distinct-count parenthetical; the line in the collision-avoidance section shows `${distinct_protocols} protocols (in DB)`
- [ ] **Historical migration prose** in `docs/specs/20260220120000_spec_protocol_description_and_seed.md` (Design decision callout around lines 46–52) is unchanged from pre-task state (verify with `git diff` showing no edits inside that range)
- [ ] No false-positive replacements: `57` and `76` references in unrelated files remain untouched (run `git grep -n -E '\b(57|76)\b' -- '*.md'` before/after to diff)
- [ ] `flutter analyze` and `flutter test` pass unchanged

## Done summary
# fn-82.2 — Update protocol count references in docs

## Result

Documentation count references updated to reflect the post-fn-82 catalog. Two-track count semantics (array-level in `protocols.json` vs DB-distinct after `lower(name)` upsert) are now explicit throughout the docs surface.

## Counts (computed from protocols.json at task start)

- `array_entries` = 60 (literal entries in protocols.json / INSERT blocks emitted)
- `array_citations` = 85
- `distinct_protocols` = 59 (60 minus the pre-existing duplicate)
- `distinct_citations` = 83 (85 minus the duplicate's first-occurrence 2 citations; the second occurrence's 1 citation wins after upsert)

## Edits

**`docs/specs/20260220120000_spec_protocol_description_and_seed.md`**
- Top-of-file addendum stating the post-fn-82 catalog state with both array and distinct counts.
- Data-contract / optionality table cells flipped to literal JSON counts (60/60, 85/85, 2/85) since they sit under "Present in JSON" / "JSON" labels.
- "Categories in JSON" distribution updated: `exercise (10)`, `mind (9)`, `supplements (10)` (+1 each for the fn-82 additions).
- "Evidence levels in JSON" distribution updated: `singleRct (25)` (+D3+K2), `expertConsensus (3)` (+calisthenics, +caffeine).
- Footnote under the optionality table making the JSON-vs-DB-distinct two-track semantics explicit.
- Historical narrative (Problem, Scope, original totals, Design-decision callout, "all 57 protocols" migration prose) preserved unchanged as a snapshot of the 2026-02-20 state.

**`docs/README.md`**
- "57 protocols, idempotent upsert" anchor → "59 protocols, idempotent upsert" (product-facing → DB count).
- "seed 57 protocols" anchor → "seed 60 protocols (59 distinct after lower(name) upsert)" (seed-source line → both counts).

**`plan_update_protocol_domain_and_db.md`**
- Top-of-file addendum mirroring the spec's, explaining why historical implementation prose still says "57".
- Section 3.2 heading updated: "upsert 60 protocols + 85 citations (in protocols.json; 59/83 distinct after upsert)".
- Collision-avoidance line: "(which insert 59 distinct protocols)" (DB context).
- Phase 3.2 body line "For each of 57 protocols" preserved as historical implementation prose.

## Quality gates

- `flutter analyze` — clean.
- `flutter test` — 959 tests pass.
- `git diff -- 'docs/' '*.md'` sanity check: only intended replacements; no false positives.
- Historical narrative grep confirms preservation of `57 science-backed`, `57 protocols and 76 citations`, `**57 protocols**, **76 citations** total`, "all 57 protocols", and "For each of 57 protocols" in their narrative contexts.
- RepoPrompt impl-review: SHIP after two iterations:
  - Iteration 1: NEEDS_WORK (Major) — JSON-labelled cells contained DB-distinct counts; flipped to array counts + added footnote.
  - Iteration 2: NEEDS_WORK (Major) — Categories/Evidence-level distribution lines still summed to 57; updated to current 60-entry distributions.
  - Iteration 3: SHIP, no surviving findings, R5 satisfied.

## FYI / decisions surfaced during review

- Task spec instruction was internally inconsistent: it directed `distinct_protocols/distinct_protocols` for cells whose labels read as JSON-level coverage. The fix-loop established the convention "label wins over default": cells labelled "JSON" / "Present in JSON" carry literal source counts; DB-distinct counts go in addenda/footnotes/explicit DB-state wording.
- The `docs/specs/20260506150000_spec_add_3_community_protocols.md` epic spec contains pre-delta phrasing like `57 → 60`; out of scope for fn-82.2 (planning artifact, not a current-state count reference).
- A separate investigation file `docs/investigations/20260508130000_investigation_json_coverage_count_conflict.md` documented the cell-label semantic conflict and informed the fix.

## Requirements coverage

- R5 (Doc count references updated, two-track semantics explicit, historical prose preserved) — satisfied.
## Evidence
- Commits:
- Tests:
- PRs: