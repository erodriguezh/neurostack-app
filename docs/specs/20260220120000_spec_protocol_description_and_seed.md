# Spec: Protocol Description Field & Seed Data

**Date:** 2026-02-20
**Status:** Draft
**Branch:** `feature/paywall-modal`

---

> **Update (2026-05-06 / fn-82):** The original spec below (2026-02-20) describes the seed catalog at the time of the initial 57-protocol migration. As of fn-82 the catalog is **60 entries in `protocols.json`** (59 distinct after `lower(name)` upsert in the DB) and **85 citation entries** (83 distinct citations in the DB after the duplicate `lower(name)` upsert overwrites the first occurrence's citations). The historical narrative below is preserved unchanged as a snapshot of the 2026-02-20 state. See `.flow/specs/fn-82-add-3-community-validated-protocols-to.md` for the delta.

## Problem

- The `protocols.json` seed file contains 57 science-backed protocols with a `description` field (mechanism + expected outcomes), but the Protocol aggregate, ProtocolDto, and DB `protocols` table lack this field.
- The existing `supabase/seed.sql` uses stale enum values (`coldTherapy`, `supplementation`, `mindfulness`, `proven`, `strong`, `moderate`, `preliminary`) that do not match the Dart domain enums.
- The DB comments on `protocols.category` and `protocols.evidence_level` are outdated.
- No seed migration exists for the 57 protocols in `protocols.json`.

## Scope

- Add `description` to the Protocol domain model, DTO, and DB schema.
- Create a `ProtocolDescription` value object with non-empty validation.
- Seed the DB with 57 protocols and 76 citations from `protocols.json` (idempotent upsert).
- Fix stale DB comments and seed.sql enum values.
- **Out of scope:** UI changes (detail sheet display deferred).

---

## Data Contract: `protocols.json`

- **57 protocols**, **76 citations** total
- JSON fields per protocol: `name`, `description`, `target`, `category`, `evidence_level`, `research_citations`, `source_models`
- JSON fields per citation: `authors`, `year`, `title`, `journal`, `doi` (optional, missing 2/76), `url`, `verification_status`, `verification_note`
- **Discarded fields (not stored):** `verification_status`, `verification_note` (editorial), `source_models` (provenance)

### New field: `description`

| Property | Value |
|----------|-------|
| Type | `String` (non-empty, after trim) |
| Present in JSON | 60/60 protocols |
| Domain representation | `ProtocolDescription` value object |
| DB column | `text NOT NULL` (CHECK: non-empty after trim) |
| Invariant | Non-empty (validated at domain and DB level) |

> **Design decision — DEFAULT '' then CHECK:**
> Migration `20260221193000` added the column as `NOT NULL DEFAULT ''` so that
> existing rows (inserted before the description field existed) would not violate
> the NOT NULL constraint. Migration `20260221200000` then populated all 57
> protocols with real descriptions via ON CONFLICT upsert. Finally, migration
> `20260223203929` tightened the constraint by adding
> `CHECK (length(trim(description)) > 0)` and dropping `DEFAULT ''`. This
> two-phase approach kept every intermediate migration state valid while
> ultimately enforcing the same invariant at the DB level that
> `ProtocolDescription.create()` enforces at the domain level.

### Categories in JSON (7 values)

`coldExposure` (7), `exercise` (10), `heatTherapy` (7), `mind` (9), `nutrition` (8), `sleep` (9), `supplements` (10)

### Evidence levels in JSON (4 values)

`multipleRcts` (25), `singleRct` (25), `observational` (7), `expertConsensus` (3)

### Optionality observations

| Field | JSON | Domain | DB |
|-------|------|--------|----|
| `target.durationSeconds` | always present (60/60) | `Duration?` (optional) | jsonb (untyped) |
| `target.intensity` | always present (60/60) | `String?` (optional) | jsonb (untyped) |
| citation `url` | present 85/85 | `String?` (optional) | `text` (nullable) |
| citation `doi` | missing 2/85 | `String?` (optional) | `text` (nullable) |

> **Footnote on counts:** the `JSON` column counts literal entries in `protocols.json`. After `lower(name)` upsert in the DB, the duplicate `Structured Gratitude Journaling for Well-Being` collapses to one row, so DB-distinct counts are **59 protocols / 83 citations** (the later occurrence's 1 citation wins over the earlier occurrence's 2). The fn-82 addendum at the top of this file is the canonical two-track summary.

**Decision:** Keep `Target.duration` and `Target.intensity` optional in domain model — seed data happens to always have them, but the model should allow protocols without them.

---

## Key Files (current state)

### Domain layer

- `lib/features/protocol/domain/entities/protocol.dart` — Protocol aggregate root, `create()`, `reconstitute()`, `softDelete()`
- `lib/features/protocol/domain/value_objects/protocol_name.dart` — Pattern reference for `ProtocolDescription` VO (freezed sealed class, `_internal` factory, static `create()` returning `Either`)
- `lib/features/protocol/domain/value_objects/target.dart` — Target VO (freezed, `Frequency` required, `Duration?`, `String?` intensity)
- `lib/features/protocol/domain/value_objects/research_citation.dart` — Citation VO (authors, year, title, journal, doi?, url?)
- `lib/features/protocol/domain/failures/protocol_failures.dart` — `DomainFailure` constants (`noCitations`, `nameEmpty`, `nameTooLong`, etc.)
- `lib/features/protocol/domain/enums/category.dart` — 7 values: exercise, heatTherapy, coldExposure, nutrition, supplements, mind, sleep
- `lib/features/protocol/domain/enums/evidence_level.dart` — 4 values: multipleRcts(4), singleRct(3), observational(2), expertConsensus(1)

### Data layer

- `lib/features/protocol/data/dtos/protocol_dto.dart` — Freezed DTO, `toDomain()` with Either chain, `fromDomain()`, JSON keys use snake_case for multi-word fields
- `lib/features/protocol/data/dtos/target_dto.dart` — Freezed DTO, `durationSeconds` (camelCase in JSON)

### Database

- `supabase/migrations/20251204192228_initial_schema.sql` — `protocols` table (id, name, target, category, evidence_level, created_at, deleted_at), `research_citations` table (id, protocol_id FK, authors, year, title, journal, doi, url)
- `supabase/seed.sql` — 13 test protocols + 20 citations, uses stale enum values

### Test infrastructure

- `test/constants/test_constants.dart` — `_Protocol` class: `id`, `validName`, `emptyName`, `tooLongName`, researcher name variants, `createdAt`
- `test/factories/protocol_factory.dart` — `create()`, `reconstitute()`, `valid()` with optional params and sub-factory defaults
- `test/factories/dtos/protocol_dto_factory.dart` — `create()`, `createWithInvalid*()` state variations, `createValidJson()`, `createJsonMissingField()`, `createJsonWithWrongType()`
- `test/factories/factories.dart` — Barrel export for all factories
- `test/domain/protocol/protocol_test.dart` — Protocol entity tests (create, reconstitute, softDelete, events, immutability)
- `test/features/protocol/data/dtos/protocol_dto_test.dart` — DTO tests (toDomain, fromJson, fromDomain, roundtrip)

---

## Business Rules

- **INV-P1:** Every Protocol MUST have at least one Research Citation — **unchanged**
- **INV-P2:** Protocol Target specifications MUST be measurable — **unchanged**
- **INV-P3:** Protocol names MUST NOT include researcher names — **unchanged**
- **INV-P4:** Deleted Protocols MUST preserve historical Session data (soft delete) — **unchanged**
- **NEW:** Protocol description MUST NOT be empty (after trim)
