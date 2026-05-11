# Citation URL/DOI normalization (cross-cutting follow-up)

Loose notes from fn-82 implementation. Surfaced as a refactor candidate; left out of scope so the protocol-add work stays a pure data delta.

## What the redundancy looks like

Every entry in `protocols.json` carries both `research_citations[].doi` and `research_citations[].url`, where `url` is almost always `https://doi.org/<doi>`. This redundancy is mirrored in:

- `protocols.json` — 85 citations after fn-82 (76 prior + 9 new), all carry both fields.
- `tool/generate_seed_sql.dart:138-160` — generator emits both columns separately into the seed migration.
- `supabase/migrations/<seed>_seed_protocols.sql` — DELETE+INSERT pairs include both `doi` and `url` columns.
- `public.research_citations` table schema — separate `doi` and `url` columns (initial schema migration).
- `lib/features/protocol/domain/value_objects/research_citation.dart:34-72` — VO models both fields.
- `lib/features/protocol/data/dtos/research_citation_dto.dart` — DTO models both fields.

`url` is computable from `doi` for ~all citations. Storing it as a separate field invites drift (one updated, the other forgotten) and bloats every payload.

## What an epic might do

Pick one direction:

**A. Drop `url` from JSON / DB / DTO / VO.** Compute the URL on-demand from DOI in the presentation layer.
- Pros: single source of truth; no drift risk; smaller payload.
- Cons: loses the (rare) case where `url` ≠ `https://doi.org/<doi>` (e.g., publisher landing page that's not the canonical DOI URL). For fn-82 entries every URL is the canonical DOI URL, but legacy entries should be audited first.

**B. Keep both, add a CI/preflight gate** asserting `url == "https://doi.org/" + doi` whenever `doi` is non-null.
- Pros: cheap; preserves URL-only legacy citations (if any).
- Cons: still two fields to maintain; gate adds drift surface.

**C. Drop `doi`, keep `url`.** Less attractive — DOI is the canonical academic key, dropping it is lossy for citation discovery and verification.

**Recommendation:** A, with a one-time audit to confirm no production citation has a non-DOI url.

## Pre-existing duplicate also worth bundling into the same epic

Independent of url/doi: `protocols.json` has two entries with `lower(name) == "structured gratitude journaling for well-being"`. Because the seed migration upserts on `ON CONFLICT (lower(name))`, the second entry overwrites the first → the DB has 56 distinct rows from the original 57 JSON entries, and after fn-82, 59 distinct rows from 60 JSON entries.

Fixing this is one inline edit (rename one of the two), but that violates the append-only R1 contract for any subsequent "add N more protocols" epic until the dedupe lands first. Worth bundling here so the JSON stops lying about its content.

## Files implicated

- `protocols.json` — JSON shape change (+ dedupe).
- `supabase/migrations/<timestamp>_normalize_citations.sql` — drop `url` column (or keep with CHECK).
- `tool/generate_seed_sql.dart` — stop emitting `url` column.
- `lib/features/protocol/domain/value_objects/research_citation.dart` — drop `url` field, derive from `doi`.
- `lib/features/protocol/data/dtos/research_citation_dto.dart` — drop `url` field.
- `tool/verify_protocols_json.dart` — drop new-entry URL gate, keep DOI gate.
- `test/factories/protocol/` — drop `url` parameter from factories.
- Any UI that links from a citation (e.g., library detail sheet) — read DOI, build URL inline.

## Acceptance criteria sketch

- DB migration drops `url` column without data loss (audit query first: any row where `url IS NOT NULL AND url <> 'https://doi.org/' || doi`).
- All citations round-trip JSON ↔ DTO ↔ VO without the `url` field.
- Presentation layer builds `https://doi.org/<doi>` on the fly when needed.
- The single duplicate gratitude entry is collapsed; verifier's `_knownPreExistingDuplicates` set drops to empty.
- `flutter analyze` clean; existing tests pass; library/detail-sheet citation link still works.

## Out of scope for this note

- Live DOI resolution (network-bound CI gate) — separate concern.
- Citation deduplication across protocols (e.g., Schoenfeld papers cited in multiple protocols) — separate.
- Verification metadata cleanup (`verification_status`, `verification_note`, `source_models`) — separate.
