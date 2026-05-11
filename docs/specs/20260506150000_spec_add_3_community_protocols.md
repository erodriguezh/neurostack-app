# Spec: Add 3 Community-Validated Protocols (Catalog Delta 57 → 60)

- **Date:** 2026-05-06
- **Status:** Draft
- **Branch:** `fn-82-add-3-protocols`
- **Flow epic:** `fn-82-add-3-community-validated-protocols-to` — see `.flow/specs/fn-82-add-3-community-validated-protocols-to.md`
- **Predecessor spec:** `docs/specs/20260220120000_spec_protocol_description_and_seed.md` (original 57-protocol seed)
- **Source research:** `protocols2.md` (repo root) — v2 community-evidence research

---

## Problem

- Existing seed catalog ships **57 protocols + 76 citations** (`protocols.json`).
- v2 community research (`protocols2.md`) surfaced 14 ranked + 5 high-risk protocols; **10 of the 14 are already covered** in the existing seed.
- Three net-new community-validated entries are missing:
  - **Daily Maintenance Calisthenics** (high-frequency, low-volume bodyweight)
  - **Delayed Morning Caffeine** (90–120 min post-waking)
  - **Vitamin D3 + K2 (MK-7)** combined daily supplementation
- Premium users — who can activate unlimited protocols (`SubscriptionStatus.protocolLimit == null`, `lib/features/user/domain/enums/subscription_status.dart:4-22`) — currently see the same 57-entry catalog as free users; expanding the catalog increases premium value without changing free-tier mechanics.

---

## Scope

### In scope
- Append 3 entries to `protocols.json` matching the existing JSON shape (no key reorder, no field additions).
- Regenerate the seed migration via `tool/generate_seed_sql.dart` → new file `supabase/migrations/<UTC-timestamp>_seed_protocols_add3.sql`.
- Verify all domain invariants pass for the new entries via the existing test suite.
- Update doc count references (57 → 60, 76 → 85).

### Out of scope
- **No domain/DTO/schema changes.** `protocols` and `research_citations` columns/constraints stay as-is (`supabase/migrations/20251204192228_initial_schema.sql:14-22, 50-60`).
- **No new fields** on `Protocol` (no `target_audience`, no `evidence_rationale`, no `is_premium`).
- **No high-risk pharmaceutical entries** from `protocols2.md` (Rapamycin, Metformin, GLP-1, peptides, Tongkat/Fadogia) — `category` enum has no `pharmaceutical` value (`lib/features/protocol/domain/enums/category.dart:5-13`).
- **No NSDR / Yoga Nidra entry** — already covered by existing "Guided Body Scan Deep Relaxation" (decision: merge as same protocol).
- **No protocol-shape integration test** that loads `protocols.json` and runs `Protocol.create` per entry — gap noted, deferred to a follow-up epic.
- **No UI changes** in library/detail-sheet/paywall.
- **No GRADE-style two-axis evidence label** — keeps `evidence_level` enum as-is.

---

## Data Contract

### `protocols.json` shape (unchanged — see `protocols.json:1-50` for first entry)
- `name: string` (≤100 chars, non-empty, INV-P3 forbidden patterns — `lib/features/protocol/domain/value_objects/protocol_name.dart:31-67`)
- `description: string` (non-empty after trim, ≤2000 chars — `lib/features/protocol/domain/value_objects/protocol_description.dart:28-40`)
- `target.frequency.min_per_week: int`, `target.frequency.max_per_week: int`
- `target.durationSeconds: int?` (optional in domain; 57/57 existing entries populate it — keep populated for the 3 new entries)
- `target.intensity: string?` (optional in domain; 57/57 existing entries populate it)
- `category: string` ∈ `{exercise, heatTherapy, coldExposure, nutrition, supplements, mind, sleep}` (`lib/features/protocol/domain/enums/category.dart:5-13`)
- `evidence_level: string` ∈ `{multipleRcts, singleRct, observational, expertConsensus}` (`lib/features/protocol/domain/enums/evidence_level.dart:4-9`)
- `research_citations[]` (≥1 required by INV-P1 — `lib/features/protocol/domain/entities/protocol.dart:59-72`)
  - `authors, year, title, journal, doi (optional but preferred), url (optional but preferred), verification_status, verification_note, source_models[]`
  - The generator drops `verification_status`, `verification_note`, `source_models` at `tool/generate_seed_sql.dart:145` — they are kept in JSON for parity with existing entries.

### Generator pipeline (unchanged)
- `tool/generate_seed_sql.dart:18-38` — entrypoint; reads `protocols.json` from CWD
- `tool/generate_seed_sql.dart:67-106` — protocol upsert SQL emitter (idempotent `INSERT ... ON CONFLICT (lower(name)) DO UPDATE SET ...`)
- `tool/generate_seed_sql.dart:108-165` — citation strategy: DELETE-then-INSERT per protocol (idempotent rebuild)
- `tool/generate_seed_sql.dart:200-222` — SHA-256 audit checksum via `shasum`/`sha256sum`

### Idempotency key (unchanged convention)
- `supabase/migrations/20260221200000_seed_protocols.sql:9` — `CREATE UNIQUE INDEX IF NOT EXISTS protocols_name_unique ON public.protocols (lower(name))`
- Stick with this `lower(name)` natural key; do **not** introduce UUIDv5 stable IDs (would invalidate the established fn-67 / fn-72 pipeline).

---

## The 3 New Entries

### A. Daily Sub-Maximal Calisthenics for Functional Preservation
- **Category:** `exercise`
- **Evidence level:** `observational`
- **Frequency:** 7 / week (min 7, max 7)
- **Duration:** ~600 s (10 min, scale to capacity)
- **Intensity:** "80–90% of max output, sub-failure, scale volume to capacity"
- **Description theme:** Daily neuromuscular maintenance via high-frequency, low-volume bodyweight (e.g., 100 push-ups + 12 pull-ups scaled), staying below failure to act as a behavioral feedback signal for systemic state. Mechanism: preservation of lean mass, persistent systemic blood flow, neuromuscular pattern reinforcement.
- **Citations:**
  - Yang J et al., 2019, *JAMA Network Open*, doi:`10.1001/jamanetworkopen.2018.8341` — push-up capacity ↔ CVD events (cohort, n=1,104 men)
  - Schoenfeld BJ, Grgic J, Krieger J, 2019, *J Sports Sciences*, doi:`10.1080/02640414.2018.1555906` — RT frequency meta-analysis
  - Schoenfeld BJ, Ogborn D, Krieger J, 2017, *Sports Medicine*, doi:`10.1007/s40279-016-0543-8` — earlier RT frequency meta-analysis

### B. Delayed Morning Caffeine for Sustained Daytime Alertness
- **Category:** `mind` *(per user — afternoon-crash mitigation framing)*
- **Evidence level:** `expertConsensus` *(no direct RCT on the 90–120 min delay; mechanism is well-established)*
- **Frequency:** 7 / week (min 7, max 7)
- **Duration:** 5400 s (90 min delay window)
- **Intensity:** "first caffeine 90–120 min after waking; water + electrolytes during delay"
- **Description theme:** Delaying first caffeine intake to allow the cortisol awakening response to peak and adenosine to clear naturally. Mechanism: avoids stacking caffeine on top of endogenous cortisol, which produces a delayed afternoon energy crash; aligns with circadian alertness curve. Pairs with morning sunlight exposure (existing protocol).
- **Citations:**
  - Lovallo WR et al., 2005, *Psychosomatic Medicine*, doi:`10.1097/01.psy.0000181270.20036.06` — caffeine + cortisol secretion
  - Lovallo WR et al., 2006, *Pharmacol Biochem Behav*, doi:`10.1016/j.pbb.2006.03.005` — cortisol responses to mental stress + caffeine
  - Urry E, Landolt HP, 2014, *Curr Topics Behav Neurosci*, doi:`10.1007/7854_2014_274` — adenosine + caffeine kinetics review

### C. Vitamin D3 with K2 (MK-7) for Bone and Cardiovascular Health
- **Category:** `supplements`
- **Evidence level:** `singleRct` *(Knapen 2013 = direct 3-yr RCT for the K2 portion; D3 has multiple RCTs — overall most-conservative honest grade)*
- **Frequency:** 7 / week (min 7, max 7)
- **Duration:** 30 s (compliance interval — daily pill)
- **Intensity:** "5,000 IU D3 + ~50 mcg K2 (MK-7) once daily"
- **Description theme:** Combined daily supplementation; K2 (MK-7) directs calcium to bones rather than arteries, addressing the arterial-calcification concern raised when D3 is supplemented alone. Pairs immune/respiratory benefit (D3) with bone density and arterial stiffness benefit (K2 / MK-7).
- **Citations:**
  - Geleijnse JM et al., 2004, *J Nutrition*, doi:`10.1093/jn/134.11.3100` — Rotterdam Study, K2 intake ↔ reduced CHD/aortic calcification
  - Knapen MHJ et al., 2013, *Osteoporosis Int*, doi:`10.1007/s00198-013-2325-6` — 3-yr RCT, MK-7 180 mcg/d, postmenopausal women
  - Martineau AR et al., 2017, *BMJ*, doi:`10.1136/bmj.i6583` — D3 IPD meta-analysis (25 RCTs, n=10,933) for respiratory infections

---

## Business Rules (unchanged)

- **INV-P1:** Every Protocol MUST have at least one Research Citation — `lib/features/protocol/domain/entities/protocol.dart:59-72`
- **INV-P2:** Protocol Target specifications MUST be measurable
- **INV-P3:** Protocol names MUST NOT include researcher names — regex set at `lib/features/protocol/domain/value_objects/protocol_name.dart:31-67`
  - Possessive: `'s Protocol/Method/...`
  - Honorific: `Dr. <Name>`
  - "The <Name> Protocol/Method/Approach"
- **INV-P4:** Deleted Protocols MUST preserve historical Session data (soft delete)
- **Description constraint:** non-empty after trim, ≤2000 chars (added in predecessor spec at `docs/specs/20260220120000_spec_protocol_description_and_seed.md`)

---

## Premium Gating (unchanged — count-based, not per-protocol)

- No `is_premium` / `subscription_tier` column on `protocols` (`supabase/migrations/20251204192228_initial_schema.sql:14-22`).
- All catalog entries are equally available; gating happens per user via `protocolLimit`.
- `lib/features/user/domain/enums/subscription_status.dart:4-22` — `free.protocolLimit = 2`, `expired.protocolLimit = 2`, premium variants `protocolLimit = null` (unlimited).
- `lib/features/user/domain/entities/user.dart:109` — INV-M5/B2: paywall fires when free user attempts a 3rd activation.
- **Catalog expansion implicitly benefits premium** (more variety, no new gating logic).

---

## Migration Strategy (unchanged pattern)

- New file: `supabase/migrations/<UTC-timestamp>_seed_protocols_add3.sql` — generated, not hand-written.
- Generator emits dollar-quoted upsert blocks per protocol (e.g., `$n$<name>$n$`, `$desc$<description>$desc$`, `$tgt$<json>$tgt$::jsonb`).
- Citation rows: DELETE existing + INSERT fresh per protocol (idempotent rebuild on re-apply).
- Naming convention: `YYYYMMDDHHmmss_<short_description>.sql` UTC (`supabase/migrations/` historical files confirm).
- Reference exemplar: `supabase/migrations/20260221200000_seed_protocols.sql:15-27` (protocol upsert), `:819-832` (citation block).

---

## Risk + Mitigation

- **Citation DOI rot:** all 9 DOIs verified to resolve at plan time; if a DOI fails CI verification, swap for one of the alternates listed (do **not** ship placeholder DOIs — practice-scout guidance: "don't fabricate DOIs to satisfy a NOT NULL").
- **Dollar-quote collision in description prose:** generator uses `$n$, $desc$, $tgt$, $cat$, $ev$` — descriptions written in normal prose are safe; quick check `grep -E '\$(n|desc|tgt|cat|ev)\$' protocols.json` should return nothing inside string values.
- **Migration order at merge:** if another seed-touching migration lands first, rename our file with a later UTC timestamp and re-run `supabase db reset`; never reorder applied migrations.
- **Description length:** 2000-char ceiling; v2 research blurbs are typically shorter — keep the description focused on mechanism + measurable expected outcomes, mirror existing entries' brevity.
- **Honest evidence labeling:** two of three entries use `observational` / `expertConsensus`; existing seed already has 7 + 1 entries at those levels, so the mix shifts only slightly.

---

## Key Files

### Source data (modify)
- `protocols.json:1-1884` — repo-root seed source, append 3 entries inside the existing JSON array

### Generator + migration target (re-run, generate new file)
- `tool/generate_seed_sql.dart:18-38, 67-106, 108-165, 200-222` — generator pipeline
- `supabase/migrations/<UTC-timestamp>_seed_protocols_add3.sql` — new file (generated)

### Constraint references (read, do not modify)
- `lib/features/protocol/domain/value_objects/protocol_name.dart:31-67` — INV-P3 regexes + length cap
- `lib/features/protocol/domain/value_objects/protocol_description.dart:28-40` — non-empty + 2000 char cap
- `lib/features/protocol/domain/entities/protocol.dart:59-72` — INV-P1 enforcement
- `lib/features/protocol/domain/enums/category.dart:5-13` — 7 valid categories
- `lib/features/protocol/domain/enums/evidence_level.dart:4-9` — 4 valid evidence levels
- `supabase/migrations/20260221200000_seed_protocols.sql:9` — unique index on `lower(name)`
- `supabase/migrations/20260223203929_tighten_protocol_description.sql:22-46` — DB-level CHECK on description trim

### Test references (read, run, do not modify)
- `test/factories/protocol_factory.dart:17-39` — domain factory pattern
- `test/factories/dtos/protocol_dto_factory.dart:12-40` — DTO factory pattern
- `test/constants/test_constants.dart` — test constants

### Docs to update (count refs only — see plan)
- `docs/README.md:68, 83`
- `docs/specs/20260220120000_spec_protocol_description_and_seed.md:11, 14, 20, 28, 38, 46, 66-69`
- `plan_update_protocol_domain_and_db.md:78-81, 91`

---

## Acceptance

- [ ] `protocols.json` contains exactly 60 entries; existing 57 byte-identical to pre-delta state
- [ ] 3 new entries fully shaped (name, description, target, category, evidence_level, ≥1 citation each)
- [ ] All new entries pass INV-P1, INV-P3, name ≤100 chars, description ≤2000 chars, valid enums
- [ ] New idempotent migration generated; double-apply produces no diff
- [ ] All 9 new citation DOIs resolve via doi.org
- [ ] `flutter test test/domain/protocol/ test/features/protocol/data/dtos/` passes
- [ ] `flutter analyze` clean
- [ ] Doc count references updated to 60 / 85

---

## References

- **Predecessor:** `docs/specs/20260220120000_spec_protocol_description_and_seed.md`
- **Source research:** `protocols2.md` (repo root)
- **Flow epic:** `.flow/specs/fn-82-add-3-community-validated-protocols-to.md`
- **Implementation plan:** `plan_add_3_community_protocols.md`
- **Related epics (predecessors, all done):**
  - `fn-67-phase-32-seed-migration-upsert-57` — established upsert pipeline
  - `fn-72-refactor-protocol-description-seed` — tightened description CHECK
