# Add 3 community-validated protocols to catalog

## Overview

Expand the protocol catalog from **57 → 60** by appending three community-validated entries that the v2 research (`protocols2.md`) surfaced and that the existing seed lacks: **Daily Maintenance Calisthenics**, **Delayed Morning Caffeine**, and **Vitamin D3 + K2 (MK-7)**. This is a **pure data delta** — append entries to `protocols.json`, regenerate the idempotent seed migration via the existing `tool/generate_seed_sql.dart` pipeline, and update doc count references. **No domain, DTO, or schema changes.**

The intent ("expand the offer for premium users") maps to catalog expansion: the app gates protocol activation by *count*, not per-protocol. Free users remain capped at 2 active protocols (`SubscriptionStatus.protocolLimit = 2`); premium users (`protocolLimit = null`) are the ones who benefit from a larger menu.

## Quick commands

```bash
# 1. Verification dev-tool (committed, NOT a test target): parse protocols.json
#    and run every entry through domain value-object constructors + enum lookups
#    + citation/shape checks + uniqueness preflight + (for the 3 new entries)
#    DOI/URL/shape-parity gates. The script is a manual diagnostic, not a CI test.
dart run tool/verify_protocols_json.dart   # exits non-zero on any invariant break

# 2. Existing factory/DTO test suite (does not load protocols.json — keeps regressions on factories green)
flutter test test/domain/protocol/ test/features/protocol/data/dtos/

# 3. Regenerate seed migration (current convention; emits dollar-quoted upserts)
dart run tool/generate_seed_sql.dart > supabase/migrations/$(date -u +%Y%m%d%H%M%S)_seed_protocols_add3.sql

# 4. Static SQL gates (env-independent; required) — see R4 below for full list
MIG=$(ls -t supabase/migrations/*_seed_protocols_add3.sql | head -1)
[[ $(grep -c '^INSERT INTO public.protocols ' "$MIG") -eq 60 ]]
[[ $(grep -c '^INSERT INTO public.research_citations ' "$MIG") -eq 85 ]]

# 5. (Optional, env-dependent) Local idempotency smoke test — only run if the
#    Supabase CLI + Docker are available locally. CI is NOT expected to run this.
supabase db reset && supabase db push && supabase db push  # second apply: no errors, identical end state
```

## Boundaries / non-goals

- **No schema changes.** `protocols` and `research_citations` columns/constraints stay as-is.
- **No new domain/DTO fields.** No `evidence_rationale`, no `target_audience`, no `is_premium` flag — the catalog stays count-gated.
- **No high-risk pharmaceutical entries** (Rapamycin, Metformin, off-label GLP-1, peptides, Tongkat/Fadogia from `protocols2.md` are explicitly excluded — categories enum has no `pharmaceutical` value and adding one would be a separate epic).
- **No NSDR / Yoga Nidra entry** — already covered by existing "Guided Body Scan Deep Relaxation" (decision: merge as same protocol).
- **No committed regression test** that loads `protocols.json` and runs `Protocol.create` on every entry **as part of the test suite** (no `flutter test` invocation that imports the catalog at runtime). Adding such a test is good hygiene but is deferred to a follow-up epic. *In scope here:* a **committed dev-tool script** at `tool/verify_protocols_json.dart` (no underscore prefix; this IS committed, not ephemeral) — it is a manual diagnostic CLI, not part of any CI test target, and is documented as such. Committing it eliminates an entire class of "works only locally" risks (temp script fragility, procedural-non-commit gate brittleness, copy-paste drift) that earlier draft revisions tried to manage with a procedural gate. The boundary preserved is "no `flutter test` regression target loading `protocols.json`"; a committed `tool/` dev-script that the operator runs deliberately is consistent with the spirit of that boundary and matches the existing precedent of `tool/generate_seed_sql.dart`.
- **No UI changes.** Library/detail-sheet rendering of new entries follows the existing flow with no special affordances.
- **No evidence-grade UI badge.** Practice-scout proposed a GRADE-style two-axis label for low-evidence entries; we intentionally do not introduce that here. The three new entries use existing `evidence_level` values honestly per the convention below.
- **No live DOI fetching as a CI gate.** DOI verification is via offline format check (`^10\.[0-9]{4,9}/.+`) plus the pre-verified list in this spec; live `curl https://doi.org/<doi>` is a best-effort local check, not a blocking gate (the sandbox/CI may have no network).

## Catalog grouping rule (canonical)

Categories reflect the **primary user-facing intent / outcome**, not the underlying mechanism. This is the rule that resolves edge cases like "a circadian protocol with daytime cognitive outcomes":

| Category | Primary user intent / outcome | Example existing entries |
|---|---|---|
| `exercise` | Improve fitness / strength / cardiovascular capacity | Zone 2, strength training, push-ups |
| `heatTherapy` | Sauna/heat-stress adaptations | Sauna 4×/week |
| `coldExposure` | Cold-stress adaptations | Cold immersion, cold shower |
| `nutrition` | Dietary patterns / macros | Mediterranean diet, time-restricted eating, post-workout protein |
| `supplements` | Pill/compound regimens (single substance, daily) | Creatine, omega-3, magnesium |
| `mind` | Cognitive / arousal / mental-state regulation (contemplative practices **and** alertness/arousal-regulating behaviors) | Meditation, breathwork, gratitude journaling |
| `sleep` | Sleep-quality interventions (timing, environment, restriction) — outcome is **nighttime sleep** | Morning bright-light, evening dim-light, cool bedroom, sleep restriction therapy |

**UX disambiguation (concrete):** A user filtering Library by `sleep` is shopping for *better nighttime sleep*. A user filtering by `mind` is shopping for *better daytime cognitive / mental state*. Catch-all by primary outcome, not mechanism.

## Decision context

**Why these three (and only these three):** A delta of `protocols2.md` v2 research vs. the existing 57-entry seed shows 10 of the 14 ranked protocols are already covered (morning sunlight, sleep regularity, zone 2, strength training, sauna, creatine, omega-3, magnesium, cold exposure, time-restricted eating). Of the 4 net-new candidates, NSDR/Yoga Nidra was discarded as a duplicate of the existing Body Scan entry. That leaves Calisthenics, Caffeine Delay, and D3+K2.

**Why pure data delta and not a richer feature:** The user request is "expand the offer". Adding fields like `target_audience` (productivity / longevity / general — surfaced in `protocols2.md`) or a separate `evidence_rationale` text would require schema, DTO, factory, and test changes — out of scope for "add 3 protocols". If product later wants those filters, that's a separate epic.

**Why `mind` (not `sleep`) for Delayed Morning Caffeine:** Per the **Catalog grouping rule** above, category is keyed on *primary user-facing outcome*. The protocol's measurable outcome is **sustained daytime alertness and afternoon-crash mitigation** — a daytime cognitive/arousal outcome. The mechanism (cortisol awakening response) is circadian-adjacent, but the user is not buying improved nighttime sleep; they're buying daytime alertness. `sleep` was considered and rejected with this concrete UX example: a user filtering Library by `sleep` who wants better nighttime sleep would be confused to find a "delay your morning coffee" protocol; the same user filtering by `mind` for "improve daytime cognitive performance" would find it directly relevant.

**Accepted trade-off (icon mismatch):** The `mind` enum at `lib/features/protocol/domain/enums/category.dart:11` carries the icon `🧘` (lotus/meditation), which fits the existing contemplative-practice entries but is a mild UX mismatch for "delay your morning coffee". This is **accepted as an intentional product taxonomy decision**: the broader bucket meaning (cognitive/arousal regulation per Catalog grouping rule) takes precedence over a per-icon fit. Re-keying icons to the broader bucket meaning is a separate UX epic if/when product wants it. No icon change is in scope for fn-82.

Applied to the three new entries (full justification below in *The three new entries*):
- **Calisthenics → `expertConsensus`**: Claimed outcome = "functional preservation". Yang 2019 measures push-up *capacity at baseline* against future CVD events — this supports "push-up capacity is a functional marker correlated with hard clinical outcomes" but it does NOT directly study the daily-calisthenics protocol against "functional preservation" as the outcome (no intervention; capacity-as-marker is mechanism context). Schoenfeld 2017/2019 are mechanism meta-analyses on resistance-training frequency → hypertrophy/strength — they support the mechanism but do not address "functional preservation" as the exact outcome either. Per the exact-outcome rule, all 3 cited papers fall under step 6 (mechanism/context) → `expertConsensus`. (`observational` was considered and rejected: Yang 2019's outcome is CVD events, not "functional preservation"; using it as an `observational` anchor would conflate marker association with protocol-level evidence.)
- **Caffeine Delay → `expertConsensus`**: Claimed outcome = "sustained daytime alertness". No RCT exists on the delay-90-to-120-min protocol with alertness as the endpoint. Lovallo 2005/2006 are RCTs on caffeine + cortisol mechanism (not alertness as the outcome). Urry & Landolt 2014 is a mechanism review. All cited papers fall under step 6 → `expertConsensus`.
- **D3 + K2 → `singleRct`**: Claimed outcome = "bone density maintenance" (BMD). Scope is bone-only (cardiovascular framing rejected — see below). Knapen 2013 is a 3-year RCT on MK-7 in postmenopausal women with **BMD as a primary outcome** — direct RCT on the K2 component for the *exact* claimed outcome → step 4 → `singleRct`. Bischoff-Ferrari 2012 NEJM is a pooled analysis of D3 RCTs for **fracture prevention** (a clinical endpoint that BMD predicts but is not identical to BMD) — included as supporting context but does NOT promote the rating to `multipleRcts` per the exact-outcome rule. Geleijnse 2004 is a Rotterdam cohort on K2 + cardiovascular — included as breadth context only (off-scope for bone outcome). **Cardiovascular outcomes were considered and rejected from the protocol's scope:** VITAL trial (Manson 2019 NEJM, doi:10.1056/NEJMoa1809944) showed D3 alone did NOT significantly reduce major CVD events; citing it as a cardio anchor would overclaim. Martineau 2017 BMJ on D3 + ARI was also rejected — ARI is not a claimed outcome of this protocol.

**Why follow `ON CONFLICT (lower(name))` over UUIDv5 for stable IDs:** Practice-scout suggested UUIDv5 for stable cross-env seed IDs, but the existing pipeline (epics fn-67, fn-72) already chose `lower(name)` as the natural key with a unique index — switching now would invalidate every existing seed migration. Stick with the established convention.

**Pre-existing duplicate (acknowledged, out of scope):** `protocols.json` currently contains **two** entries with the same `lower(name)` value: `"structured gratitude journaling for well-being"` (verified by `python3 -c 'import json; from collections import Counter; d=json.load(open("protocols.json")); c=Counter(p["name"].lower() for p in d); print({n:k for n,k in c.items() if k>1})'`). Because the natural key is `lower(name)`, the seed migration's upsert produces **56 distinct rows** in `public.protocols`, not 57 — the second entry overwrites the first. After this epic's append-only delta of 3 new uniquely-named entries, the JSON array contains **60 entries** but the DB will contain **59 distinct protocols**. Fixing the duplicate is **out of scope here** (it requires an inline edit to one of the two existing entries, which violates R1 append-only) and is the subject of a separate follow-up epic. Acceptance below uses **array entry count** (60) for static SQL gates because `tool/generate_seed_sql.dart` emits one `INSERT` per array entry; the DB-distinct count (59) is the reality after upsert and is documented in R5 doc updates.

**Evidence-level convention (canonical, Option B with exact-outcome precedence):**
The `evidence_level` enum value is selected by the **strongest evidence directly addressing the protocol's exact claimed outcome** (as stated in the protocol name/description), with the following precedence ranking (top wins):

1. Multiple RCTs on the *exact protocol* → `multipleRcts`
2. Single RCT on the *exact protocol* → `singleRct`
3. Multiple RCTs on a *protocol component* directly addressing the protocol's *exact* claimed outcome → `multipleRcts`
4. Single RCT on a *protocol component* directly addressing the protocol's *exact* claimed outcome → `singleRct`
5. Observational evidence (cohort/cross-sectional) on the protocol's *exact* claimed outcome → `observational`
6. Mechanism-only RCTs (component but **not** on the exact outcome) / expert opinion → `expertConsensus`

"**Exact claimed outcome**" means the literal outcome stated in the protocol name/description, not a related/proxy endpoint. Example: "Bone Density Maintenance" matches RCTs on bone mineral density (BMD) but not on fracture prevention (a related but distinct clinical endpoint). Citations addressing related but non-exact outcomes may still be included in `research_citations[]` as supporting context, but they do NOT determine the rating.

## The three new entries

| Field | A. Daily Maintenance Calisthenics | B. Delayed Morning Caffeine | C. Vitamin D3 + K2 (MK-7) |
|---|---|---|---|
| Working name | "Daily Sub-Maximal Calisthenics for Functional Preservation" *(may refine — must satisfy INV-P3: no researcher names; ≤100 chars)* | "Delayed Morning Caffeine for Sustained Daytime Alertness" | "Vitamin D3 with K2 (MK-7) for Bone Density Maintenance" *(scope narrowed to bone-only — cardiovascular framing rejected because VITAL was null primary endpoint)* |
| Category enum | `exercise` | `mind` *(see Catalog grouping rule + Decision context)* | `supplements` |
| Evidence level enum | `expertConsensus` *(no RCT or observational study tests the daily-calisthenics protocol against "functional preservation" as outcome; Yang 2019 measures push-up *capacity* → CVD events, which is mechanism/marker context — does not anchor `observational` per exact-outcome rule; Schoenfeld papers are mechanism support on resistance-training frequency for hypertrophy/strength)* | `expertConsensus` *(no protocol-level RCT exists; cited papers are mechanism support)* | `singleRct` *(Knapen 2013 = direct RCT on K2 component for BMD)* |
| Frequency | min 7 / max 7 per week | min 7 / max 7 per week | min 7 / max 7 per week |
| Duration | ~600s (10 min, scaled to user fitness) | 5400s (90 min delay window) | 60s (compliance interval — matches existing supplement convention; 30s would render as "0 min" in `Target.displayText`) |
| Intensity | "80–90% of max output, sub-failure, scale volume to capacity" | "first caffeine 90–120 min after waking; water + electrolytes during delay" | "5,000 IU D3 + 100–200 mcg K2 (MK-7) once daily (community-typical range; Knapen 2013 RCT used 180 mcg MK-7/day, within this range)" |
| Citations (≥1 protocol-level + supporting mechanism papers) | 3: Yang 2019 JAMA Net Open *(push-up capacity ↔ CVD events cohort — mechanism/marker context, not protocol-level evidence)*; Schoenfeld 2019 J Sports Sci *(mechanism — resistance training frequency)*; Schoenfeld 2016 Sports Med *(mechanism — frequency on hypertrophy)* | 3: Lovallo 2005 Psychosom Med *(mechanism — caffeine + cortisol)*; Lovallo 2006 Pharmacol Biochem Behav *(mechanism — cortisol response)*; Urry & Landolt 2015 Curr Top Behav Neurosci *(mechanism review — adenosine)* | 3: Knapen 2013 Osteoporos Int *(K2 RCT — bone density anchor)*; Bischoff-Ferrari 2012 NEJM *(D3 pooled analysis — fracture prevention)*; Geleijnse 2004 J Nutr *(K2 cohort — breadth context only, NOT a claimed protocol outcome)* |

**Citation total after delta (computed expectation):** 76 → **85** (76 existing + 9 new). Final count is **re-derived from `protocols.json`** at task .2 start — if a citation was dropped/added during review, .2 patches docs to the actual count.

**Description shape:** mechanism + measurable expected outcomes, ≤2000 chars, non-empty after trim. Matches existing description style at `lib/features/protocol/domain/value_objects/protocol_description.dart:28-40`. **Researcher-name discipline:** `protocols2.md` source draft contains attributions like "Dr. Andy Galpin" — these MUST be stripped from the new descriptions; cite the underlying study instead.

**Dollar-quote collision (defense-in-depth):** the generator at `tool/generate_seed_sql.dart:228-236` auto-falls back to `$tag1$`, `$tag2$`… when the value contains the chosen tag, so collisions are not a hard hazard. As a defense-in-depth check before regeneration, run `python3 -c 'import re,json; d=json.load(open("protocols.json")); bad=[p["name"] for p in d if any(re.search(r"\$\w+\$", str(v)) for v in (p.get("name",""), p.get("description",""), (p.get("target") or {}).get("intensity","")))]; print("\n".join(bad) if bad else "OK")'` — output must be `OK`. Note `intensity` lives at `target.intensity` (the snippet correctly reads `(p.get("target") or {}).get("intensity","")`). Covers all generator tags (`n`, `desc`, `tgt`, `cat`, `ev`, `a`, `t`, `j`, `d`, `u`) plus any future tag the generator might add.

## Acceptance

- **R1 (content-identical, append-only, deterministic — JSON deep-equal prefix check):** `protocols.json` contains exactly 60 array entries (57 prior + 3 new); the prior 57 entries are **content-identical** to the pre-delta state when compared as parsed JSON (no semantic changes to any of the 57 existing objects' keys or values). **Note:** the 57 includes one pre-existing `lower(name)` duplicate (see *Pre-existing duplicate* in Decision context); after upsert the DB has **59 distinct rows** (56 pre-existing distinct + 3 new). **Enforcement:** edits are append-only at the end of the JSON array. The R1 gate is a **JSON deep-equal prefix check** (parse both `HEAD:protocols.json` and the working copy, assert the first 57 parsed entries are deep-equal, assert exactly 3 new entries appended at the end). This is whitespace-agnostic and key-order-agnostic by construction — purely semantic. (Earlier draft revisions used hunk-counting heuristics, which were brittle to editor formatting. The deep-equal check is the authoritative R1 gate.) See task .1 step 1 for the canonical Python implementation.
- **R2:** The 3 new entries are present in `protocols.json` with all required fields (`name`, `description`, `target.frequency.min_per_week`, `target.frequency.max_per_week`, `category`, `evidence_level`, `research_citations[]`); each carries ≥1 peer-reviewed citation, and **every citation on the 3 new entries has non-null `doi` and `url`** (the existing 57 may have nulls for legacy reasons; the new 3 must not).
- **R3 (verified by committed dev-tool script):** All 3 new entries pass the per-VO invariants — INV-P1 (≥1 citation), INV-P3 (no researcher-name pattern in `name`), `ProtocolName` ≤100 chars, `ProtocolDescription` non-empty after trim and ≤2000 chars, `Frequency.create(min, max)` returns `Right` (min≥1, max≥min), `Target.create(frequency, duration, intensity)` returns `Right`, `ResearchCitation.create(authors, year, title, journal, doi, url)` returns `Right` for every citation. `category` and `evidence_level` are valid enum identifiers. **Plus a uniqueness preflight on the 3 new names** — none of the 3 new `lower(name)` values collide with any other entry; the script tolerates the **single pre-existing duplicate** ("structured gratitude journaling for well-being") via a baseline-locked allowed-duplicate set and fails on any *new* duplicates. **Plus shape-parity checks** on the 3 new entries: `source_models` is a non-empty list of strings, and every citation has non-empty `verification_status` + `verification_note` strings. **Plus BMD scope-lock check** for the D3+K2 entry: its description must contain `bone mineral density` or `BMD` to keep the protocol's exact-outcome aligned with the Knapen RCT anchor. **Verification:** task .1 adds a **committed** `tool/verify_protocols_json.dart` (no underscore — this IS committed; manual dev-tool, not a CI test) that loads `protocols.json` and validates all 60 entries by directly calling **all five VO constructors** (`ProtocolName.create`, `ProtocolDescription.create`, `Frequency.create`, `Target.create`, `ResearchCitation.create`) plus enum lookups + uniqueness + shape parity + BMD scope lock. Every `Either` result MUST be `fold()`-ed; `Left` reports `failure.code` + `failure.message`. The script uses **type-guarded extraction** (no unchecked `as` casts) so it accumulates *all* errors in one run. Calling `Protocol.create()` end-to-end (entity-level + repository/DTO wiring) is out of scope — INV-P1 is checked structurally (`citations.length >= 1`). The factory/DTO test suite covers entity-level invariants on synthetic data; this dev-tool covers the catalog-data invariants by hitting the same VOs the runtime uses. **Invocation model: manual-only.** Script must exit 0 when run manually via `dart run tool/verify_protocols_json.dart` during the task, and is required as part of the task acceptance checklist. **CI does NOT invoke this script** — it is not registered as a test target and is not a build gate. (If product later wants CI enforcement, that is a separate epic — register it as a `flutter test` target or add a CI workflow step.)
- **R4 (static SQL gates + prefix-identity + optional dynamic):** A new Supabase migration file `supabase/migrations/<UTC-timestamp>_seed_protocols_add3.sql` is generated by `tool/generate_seed_sql.dart`. **Important framing:** the new migration is a **full reseed** of the entire catalog (the generator emits one INSERT-upsert per array entry, so the new file contains 60 INSERT blocks for protocols + DELETE+INSERT for all citations), NOT a "delta migration" containing only the 3 new entries. This matches the established convention from epic fn-67 (the existing `20260221200000_seed_protocols.sql` is also a full reseed). On `supabase db reset`, the prior migration runs first (re-creating the original 57 rows), then the new migration runs and re-upserts all 60 — idempotent and safe. The "delta" label refers to the source-of-truth `protocols.json` change (3 new entries appended), not to the migration file shape. **Required static checks** (env-independent, all must pass):
  1. File contains exactly 60 `INSERT INTO public.protocols ` blocks.
  2. File contains exactly 60 `DELETE FROM public.research_citations` blocks (one per protocol; the generator deletes citations even for zero-citation protocols).
  3. File contains exactly 85 `INSERT INTO public.research_citations ` blocks (76 existing + 9 new).
  4. File contains the unique-index DDL (`CREATE UNIQUE INDEX IF NOT EXISTS protocols_name_unique ON public.protocols (lower(name))`).
  5. **SHA-256 audit comment matches `protocols.json`** — cross-platform compute (matches the generator's fallback at `tool/generate_seed_sql.dart:200-222`):
     ```bash
     # Cross-platform SHA-256: prefer python3 (universally available); fall back to shasum/sha256sum
     if command -v python3 >/dev/null 2>&1; then
       EXPECTED=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open("protocols.json","rb").read()).hexdigest())')
     elif command -v shasum >/dev/null 2>&1; then
       EXPECTED=$(shasum -a 256 protocols.json | awk '{print $1}')
     elif command -v sha256sum >/dev/null 2>&1; then
       EXPECTED=$(sha256sum protocols.json | awk '{print $1}')
     else
       echo "FAIL R4.5: no SHA-256 tool available (need python3 / shasum / sha256sum)"; exit 1
     fi
     ACTUAL=$(grep -E '^-- SHA-256\(protocols.json\):' "$MIG" | awk '{print $3}')
     [[ "$EXPECTED" == "$ACTUAL" ]] || { echo "FAIL R4.5: SHA mismatch (expected $EXPECTED, got $ACTUAL)"; exit 1; }
     ```
  6. **All string-typed values inside `VALUES (` blocks use dollar-quoting** (`$tag$...$tag$`) — never single-quoted SQL string literals. The generator uses `_dollarQuote()` (`tool/generate_seed_sql.dart:228-236`) for every string column; the only literal that may appear in a string-typed column position is `null` (for nullable `doi`/`url` on legacy citations). **Verification:** lightweight static grep is a **best-effort regression tripwire** (SQL is not reliably regex-parseable; this catches the most common regression mode) **plus** authoritative manual audit of the first new protocol's INSERT block — manual audit is the source of truth if the grep is inconclusive. See task .1 step 5 for the bash command.

  7. **Prefix-identity check (catches generator regressions on existing rows):** The first 57 protocol upsert blocks emitted by the new migration must produce **content-identical SQL** (modulo the file's header / SHA / timestamp comment lines) to the corresponding 57 blocks in the prior canonical migration `supabase/migrations/20260221200000_seed_protocols.sql`. **Verification approach:** parse `protocols.json`, take the first 57 entries, emit the per-protocol upsert via the generator's `_writeProtocolUpserts` codepath into a string, and `diff` against the corresponding section of the prior migration (extracted by line range). If the generator's emit logic regressed since fn-67, this check catches it; if `protocols.json`'s first 57 entries were modified (R1 violation), this catches it too. Implementation: a `tool/verify_seed_prefix_identity.dart` helper or an inline `awk + diff` script. (See task .1 for the canonical implementation.)

  **Optional dynamic check** (only when Supabase CLI + Docker are available locally; CI is **not** required to run this): apply the migration twice (`supabase db reset` → `supabase db push` → `supabase db push`) and confirm no constraint violations on the second apply. **Do NOT assert total table counts** — `supabase db reset` runs `supabase/seed.sql` which inserts additional test protocols/citations beyond the production seed migrations (per `plan_update_protocol_domain_and_db.md` ~+13 test protocols + 20 test citations). Instead, assert by name set:
  ```sql
  -- All 3 new protocols are present after both applies (no upsert errors):
  SELECT name FROM public.protocols WHERE lower(name) IN (
    lower('Daily Sub-Maximal Calisthenics for Functional Preservation'),
    lower('Delayed Morning Caffeine for Sustained Daytime Alertness'),
    lower('Vitamin D3 with K2 (MK-7) for Bone Density Maintenance')
  );  -- expect 3 rows
  -- The 9 new citations are present (count by joining to the 3 new protocol names):
  SELECT COUNT(*) FROM public.research_citations c
    JOIN public.protocols p ON p.id = c.protocol_id
    WHERE lower(p.name) IN (lower('Daily Sub-Maximal...'), lower('Delayed Morning...'), lower('Vitamin D3 with K2...'));
  -- expect 9
  ```
- **R5 (count semantics, two-track):** All count references in docs are updated using counts derived from `protocols.json`. **Each updated number must specify which count it refers to** — "array entries / INSERT blocks emitted" vs "distinct DB rows after `lower(name)` upsert". Both counts are computed and used as appropriate per doc context:
  - `array_entries = len(json.load(open("protocols.json")))` → expected 60
  - `array_citations = sum(len(p.get("research_citations",[])) for p in data)` → expected 85
  - `distinct_protocols = len({p["name"].lower() for p in data})` → expected 59 (60 − 1 known duplicate)
  - `distinct_citations = sum(len(p.get("research_citations",[])) for p in data if p["name"].lower() not in seen_names_after_first_occurrence_only)` — citations on second occurrence of the duplicate name overwrite the first per the generator's DELETE+INSERT pattern. Compute by reverse-iterating and keeping last citation list per `lower(name)`. Expected: subtract the **first occurrence's citation count** for the duplicated name from `array_citations`.

  When updating present-tense doc lines: if the doc is talking about "the seed catalog" (what's in `protocols.json`), use `array_entries` / `array_citations`; if talking about "what ends up in the database after migration" or "active protocols available to users", use `distinct_protocols` / `distinct_citations`. Most existing doc lines are ambiguous — interpret them as **DB-after-upsert counts** (since that's what the user actually experiences) and use distinct counts. Historical migration prose remains preserved unchanged. Files: `docs/specs/20260220120000_spec_protocol_description_and_seed.md`, `docs/README.md:68,83`, `plan_update_protocol_domain_and_db.md:78-81,91`.
- **R6:** Existing test suite (`flutter test`) passes unchanged — no test count assertions for protocols exist (verified: only mocked length-of-3 in `protocol_repository_impl_test.dart`).
- **R7 (DOI offline format-plausibility gate, scoped):** Every citation on the **3 new entries** has `doi` matching the regex `^10\.[0-9]{4,9}/.+` (a **format-plausibility** check, **not** a real validity verification — the regex accepts plausibly-shaped strings without confirming the DOI resolves to a real article) and `url` is a non-null absolute http/https URL (preferably `https://doi.org/<doi>`). For the existing 57 entries the script enforces format **only when `doi` is non-null** (preserves existing missing-DOI entries). Live `curl -ILs https://doi.org/<doi>` is a best-effort local check (not a CI gate); resolvability is the human-review responsibility before merge.

## Early proof point

Task `fn-82-add-3-community-validated-protocols-to.1` is the proof point — it appends the 3 entries to `protocols.json`, regenerates the migration, and runs the one-off verification script. If the generator emits a malformed migration (e.g., enum mismatch), the static SQL count gates fail, the SHA audit mismatches, or the verification script flags any invariant violation, re-evaluate before continuing. Specifically: if Lovallo 2005 or Knapen 2013 DOIs fail offline format check, swap for the alternates listed in citations above; do not ship placeholder DOIs.

## Requirement coverage

| Req | Description | Task(s) | Gap justification |
|-----|-------------|---------|-------------------|
| R1  | 60 total entries; existing 57 content-identical; deterministic single-hunk gate | fn-82-add-3-community-validated-protocols-to.1 | — |
| R2  | New entries fully shaped; new citations all have non-null DOI+URL | fn-82-add-3-community-validated-protocols-to.1 | — |
| R3  | Domain invariants verified by one-off script (with proper Either fold) | fn-82-add-3-community-validated-protocols-to.1 | — |
| R4  | New migration generated + static SQL count/sha/dollar-quote gates | fn-82-add-3-community-validated-protocols-to.1 | — |
| R5  | Doc count references updated from final JSON; historical prose preserved | fn-82-add-3-community-validated-protocols-to.2 | — |
| R6  | Existing tests pass | fn-82-add-3-community-validated-protocols-to.1 | — |
| R7  | DOI offline format gate (strict for new 3, conditional for legacy 57) | fn-82-add-3-community-validated-protocols-to.1 | — |

## References

**Source material**
- `protocols2.md` (repo root) — v2 community research, 14 ranked + 5 high-risk protocols
- `docs/specs/20260220120000_spec_protocol_description_and_seed.md` — original 57-protocol seed spec

**Existing seed pipeline**
- `tool/generate_seed_sql.dart:5-7,18-38,67-106,108-165,200-222,228-236` — generator entrypoint, protocol upsert, citation DELETE+INSERT, sha256 audit, dollar-quote collision auto-fallback
- `protocols.json:1-1884` — repo-root data source, 57 entries
- `supabase/migrations/20260221200000_seed_protocols.sql:9` — `CREATE UNIQUE INDEX IF NOT EXISTS protocols_name_unique ON public.protocols (lower(name))` (natural key)
- `supabase/migrations/20260221200000_seed_protocols.sql:15-27,819-832` — exemplar protocol upsert + citation pattern

**Domain constraints to honor**
- `lib/features/protocol/domain/value_objects/protocol_name.dart:31-67` — INV-P3 regex set, ≤100 chars, returns `Either<DomainFailure, ProtocolName>` (must be `fold`-ed)
- `lib/features/protocol/domain/value_objects/protocol_description.dart:28-40` — non-empty trim, ≤2000 chars, returns `Either<DomainFailure, ProtocolDescription>`
- `lib/features/protocol/domain/entities/protocol.dart:59-72` — INV-P1 (≥1 citation) enforced in `Protocol.create`
- `lib/features/protocol/domain/enums/category.dart:5-13` — 7 valid enum values
- `lib/features/protocol/domain/enums/evidence_level.dart:4-8` — 4 valid enum values

**Premium gating (count-based, not per-protocol)**
- `lib/features/user/domain/enums/subscription_status.dart:4-22` — `free.protocolLimit = 2`, premium = `null` (unlimited)
- `lib/features/user/domain/entities/user.dart:109` — INV-M5/B2 paywall trigger on 3rd activation

**Related (no blockers)**
- fn-67-phase-32-seed-migration-upsert-57 — established the upsert pattern (done)
- fn-72-refactor-protocol-description-seed — tightened description CHECK (done)

**Citations (DOI offline format-verified; URLs resolvable when network is available)**
- Yang J et al., 2019, "Push-up Exercise Capacity and Future Cardiovascular Events", *JAMA Network Open*, doi:10.1001/jamanetworkopen.2018.8341 *(protocol-outcome cohort)*
- Schoenfeld BJ, Grgic J, Krieger J, 2019, "Resistance training frequency meta-analysis", *J Sports Sciences*, doi:10.1080/02640414.2018.1555906 *(mechanism support)*
- Schoenfeld BJ, Ogborn D, Krieger J, 2016, "Effects of Resistance Training Frequency on Measures of Muscle Hypertrophy: A Systematic Review and Meta-Analysis", *Sports Medicine* (Vol 46, Issue 11), doi:10.1007/s40279-016-0543-8 *(mechanism support; published Nov 2016 — corrected from "2017" in earlier draft)*
- Lovallo WR et al., 2005, "Caffeine Stimulation of Cortisol Secretion Across the Waking Hours", *Psychosomatic Medicine*, doi:10.1097/01.psy.0000181270.20036.06 *(mechanism RCT)*
- Lovallo WR et al., 2006, "Cortisol responses to mental stress, exercise, and meals following caffeine", *Pharmacol Biochem Behav*, doi:10.1016/j.pbb.2006.03.005 *(mechanism RCT)*
- Urry E, Landolt HP, 2015, "Adenosine, Caffeine, and Performance", *Curr Topics Behav Neurosci*, doi:10.1007/7854_2014_274 *(mechanism review; print-year 2015, DOI prefix `2014_` reflects online-first/series volume number — use 2015 as the canonical citation year per common indexing)*
- Geleijnse JM et al., 2004, "Menaquinone Intake and Coronary Heart Disease: Rotterdam Study", *J Nutrition*, doi:10.1093/jn/134.11.3100 *(K2 cohort, supporting)*
- Knapen MHJ et al., 2013, "Three-year low-dose menaquinone-7 supplementation in postmenopausal women", *Osteoporosis Int*, doi:10.1007/s00198-013-2325-6 *(K2 RCT — bone density anchor)*
- Bischoff-Ferrari HA et al., 2012, "A pooled analysis of vitamin D dose requirements for fracture prevention", *New England Journal of Medicine*, doi:10.1056/NEJMoa1109617 *(D3 RCT pooled analysis — fracture prevention)*
