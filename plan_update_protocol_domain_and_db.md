# Plan: Update Protocol Domain Model & Database

**Spec:** [`docs/specs/20260220120000_spec_protocol_description_and_seed.md`](docs/specs/20260220120000_spec_protocol_description_and_seed.md)
**Seed source:** [`protocols.json`](protocols.json)

---

## Phase 1 — Domain Layer

### 1.1 Add failure constant ✅
- **Edit** `lib/features/protocol/domain/failures/protocol_failures.dart`
  - Add `static const descriptionEmpty = DomainFailure(code: 'Protocol.DescriptionEmpty', message: '...')`
  - Cite: follows existing pattern of `nameEmpty`, `nameTooLong` etc. in same file
  - **Done:** commit `588988a`

### 1.2 Create `ProtocolDescription` value object ✅
- **New** `lib/features/protocol/domain/value_objects/protocol_description.dart`
  - Freezed sealed class, `_internal` factory, static `create(String)` returning `Either<DomainFailure, ProtocolDescription>`
  - Validation: non-empty after trim → returns `ProtocolFailures.descriptionEmpty` on failure
  - Validation: max length 2000 chars after trim → returns `ProtocolFailures.descriptionTooLong` on failure
  - `@override toString() => value`
  - Cite: follow exact pattern from `lib/features/protocol/domain/value_objects/protocol_name.dart`

### 1.3 Add `description` field to Protocol entity
- **Edit** `lib/features/protocol/domain/entities/protocol.dart`
  - Add import for `protocol_description.dart`
  - Add `required this.description` to `Protocol._()` private constructor (line ~24)
  - Add `final ProtocolDescription description` field declaration (after `name`)
  - Add `required ProtocolDescription description` param to `Protocol.create()` (line ~56)
  - Add `required ProtocolDescription description` param to `Protocol.reconstitute()` (line ~88)
  - Pass `description: description` in `softDelete()` copy constructor (line ~120)
  - Cite: same pattern used by `name: ProtocolName` in same file
  - **Call-site check:** Confirmed no `Protocol.create(` calls in `lib/` outside the entity itself — only test factories need updating (Phase 4). Rely on `flutter analyze` as gate.

### 1.4 Run codegen ✅
- `dart run build_runner build --delete-conflicting-outputs`
  - Generates `protocol_description.freezed.dart`
  - **Done:** included in commit `18fb120` (Phase 1.3)

---

## Phase 2 — Data Layer (DTO)

### 2.1 Add `description` to ProtocolDto ✅
- **Edit** `lib/features/protocol/data/dtos/protocol_dto.dart`
  - Add import for `protocol_description.dart`
  - Add `required String description` to freezed factory (after `name` at line ~31, before `target`)
  - No `@JsonKey` needed — single word, same convention as `name` (line ~31)
  - In `toDomain()` (line ~56): add description validation block after name parsing (lines 59-67):
    ```
    final descriptionResult = ProtocolDescription.create(description);
    // isLeft check + extract, same pattern as nameResult
    ```
  - Pass `description: domainDescription` to `Protocol.reconstitute()` (line ~132)
  - In `fromDomain()` (line ~154): add `description: protocol.description.value`
  - Cite: follows `nameResult` pattern at lines 59-67 of same file
  - **Done:** commit `24b91e0`

### 2.2 Run codegen ✅
- `dart run build_runner build --delete-conflicting-outputs`
  - Regenerates `protocol_dto.freezed.dart` and `protocol_dto.g.dart`
  - **Done:** included in commit `24b91e0` (Phase 2.1)

---

## Phase 3 — Database Migrations

### 3.1 Schema migration — add column + fix comments ✅
- **New** `supabase/migrations/20260221193000_add_protocol_description.sql`
  - `ALTER TABLE public.protocols ADD COLUMN IF NOT EXISTS description text NOT NULL DEFAULT ''`
  - Fix stale `COMMENT ON COLUMN public.protocols.category` → list actual enum values (exercise, heatTherapy, coldExposure, nutrition, supplements, mind, sleep)
  - Fix stale `COMMENT ON COLUMN public.protocols.evidence_level` → list actual enum values (multipleRcts, singleRct, observational, expertConsensus)
  - Fix stale `COMMENT ON COLUMN public.protocols.target` → note mixed key casing: top-level camelCase (`durationSeconds`, `intensity`), nested frequency snake_case (`min_per_week`, `max_per_week`) per `@JsonKey` overrides
  - Add `COMMENT ON COLUMN public.protocols.description`
  - Cite: existing comments at `supabase/migrations/20251204192228_initial_schema.sql` lines 33-37
  - **Done:** commit `ba54cea`

### 3.2 Seed migration — upsert 57 protocols + 76 citations ✅
- **New** `supabase/migrations/YYYYMMDDHHMMSS_seed_protocols.sql`
  - Add case-insensitive unique index: `CREATE UNIQUE INDEX IF NOT EXISTS protocols_name_unique ON public.protocols (lower(name))`
  - For each of 57 protocols: `INSERT INTO public.protocols (name, description, target, category, evidence_level) VALUES (...) ON CONFLICT ((lower(name))) DO UPDATE SET description=EXCLUDED.description, target=EXCLUDED.target, category=EXCLUDED.category, evidence_level=EXCLUDED.evidence_level`
  - For citations: `DELETE FROM public.research_citations WHERE protocol_id = (SELECT id FROM public.protocols WHERE name = ...)` then re-insert
  - Use `durationSeconds` (camelCase) in target JSONB — matches `lib/features/protocol/data/dtos/target_dto.dart` field name (line ~21)
  - Strip `verification_status`, `verification_note`, `source_models` from JSON data
  - Use explicit `null` for missing DOI values; use dollar-quoted strings (`$desc$...$desc$`) for safe SQL literals
  - **Generate SQL programmatically:** commit a Dart helper script `tool/generate_seed_sql.dart` that reads `protocols.json` and outputs the migration SQL. Include a SHA-256 checksum of `protocols.json` as a comment in the generated SQL for audit trail. Script is run manually; output is committed.
  - Cite: existing seed pattern at `supabase/seed.sql`; target JSONB format at `lib/features/protocol/data/dtos/target_dto.dart`

### 3.3 Fix `supabase/seed.sql` (test data) ✅
- **Edit** `supabase/seed.sql`
  - **Remove explicit IDs** from protocol INSERTs — stop using `OVERRIDING SYSTEM VALUE` with fixed IDs 1..13. Instead let the DB assign identity values, matching the approach used by the seed migration in 3.2. This avoids PK collisions when `supabase db reset` runs migrations (which insert 57 protocols) before seed.sql (which inserts 13 test protocols).
  - **Resolve citation FKs by name:** replace `protocol_id = <literal int>` with `protocol_id = (SELECT id FROM public.protocols WHERE name = '...')` in research_citations INSERTs.
  - Add `description` column to INSERT statement — use placeholder descriptions for 13 test protocols
  - Fix stale category values (`coldTherapy` → `coldExposure`, `supplementation` → `supplements`, `mindfulness` → `mind`)
  - Fix stale evidence levels (`strong` → `singleRct`, `moderate` → `observational`, `proven` → `multipleRcts`, `preliminary` → `expertConsensus`)
  - Fix JSONB key: `duration_seconds` → `durationSeconds` in all target objects
  - Cite: Dart enums at `lib/features/protocol/domain/enums/category.dart` and `evidence_level.dart`; TargetDto key at `lib/features/protocol/data/dtos/target_dto.dart` line 21

---

## Phase 4 — Test Infrastructure

### 4.1 Add test constants ✅
- **Edit** `test/constants/test_constants.dart`
  - Add to `_Protocol` class (after line ~44):
    ```dart
    final String validDescription = 'High-intensity interval training combining 4-minute intervals at 90-95% max HR.';
    final String emptyDescription = '';
    ```
  - Cite: follows existing `validName`/`emptyName` pattern at lines 35-36

### 4.2 Create `ProtocolDescriptionFactory` ✅
- **New** `test/factories/value_objects/protocol_description_factory.dart`
  - `abstract final class ProtocolDescriptionFactory`
  - `valid()` → returns `ProtocolDescription` using `TestConstants.protocol.validDescription`
  - `create(String)` → returns `Either<DomainFailure, ProtocolDescription>`
  - Cite: follow pattern from `test/factories/value_objects/protocol_name_factory.dart`

### 4.3 Update barrel export ✅
- **Edit** `test/factories/factories.dart`
  - Add `export 'value_objects/protocol_description_factory.dart';` (after line ~11, with other VO factories)
  - Cite: existing exports at lines 10-16

### 4.4 Update `ProtocolFactory` ✅
- **Edit** `test/factories/protocol_factory.dart`
  - Add imports for `ProtocolDescription` and `ProtocolDescriptionFactory`
  - Add `ProtocolDescription? description` param to `create()` (line ~17)
  - Pass `description: description ?? ProtocolDescriptionFactory.valid()` to `Protocol.create()` (line ~25)
  - Add same param to `reconstitute()` (line ~37)
  - Pass `description: description ?? ProtocolDescriptionFactory.valid()` to `Protocol.reconstitute()` (line ~47)
  - Cite: follows existing `name ?? ProtocolNameFactory.valid()` pattern at lines 27, 49

### 4.5 Update `ProtocolDtoFactory` ✅
- **Edit** `test/factories/dtos/protocol_dto_factory.dart`
  - Add `String? description` param to `create()` (line ~18)
  - Pass `description: description ?? TestConstants.protocol.validDescription` to `ProtocolDto()` (line ~28)
  - Add `createWithEmptyDescription()` state variation (after line ~88):
    ```dart
    static ProtocolDto createWithEmptyDescription() {
      return create(description: TestConstants.protocol.emptyDescription);
    }
    ```
  - Add `'description': TestConstants.protocol.validDescription` to `createValidJson()` (after line ~98, after `'name'` key)
  - Cite: follows `createWithInvalidName()` pattern at lines 44-46; follows `createValidJson()` structure at lines 95-105

### 4.6 Fix `TargetDtoFactory` JSON key mismatch ✅
- **Edit** `test/factories/dtos/target_dto_factory.dart`
  - Change `'duration_seconds'` → `'durationSeconds'` in `createValidJson()` (line ~52)
  - Added `createWithNullDuration()` state variation to bypass factory default for nullable path testing
  - Fixed stale doc comment `"snake_case keys"` → `"matching generated fromJson/toJson keys"` (also fixed in `ProtocolDtoFactory` and `ResearchCitationDtoFactory`)
  - This aligns the test fixture with the actual `TargetDto` serialization key (camelCase)
  - Cite: `lib/features/protocol/data/dtos/target_dto.dart` line ~21

---

## Phase 5 — Tests

### 5.1 New: `ProtocolDescription` unit tests ✅
- **New** `test/domain/protocol/value_objects/protocol_description_test.dart`
  - `create` succeeds: valid string, single char, trims whitespace
  - `create` fails: empty → `ProtocolFailures.descriptionEmpty`, whitespace-only → `ProtocolFailures.descriptionEmpty`
  - `toString` returns underlying value
  - Cite: follow structure from `test/domain/protocol/value_objects/protocol_name_test.dart`

### 5.2 Update `protocol_test.dart` ✅
- **Edit** `test/domain/protocol/protocol_test.dart`
  - Add one explicit test: `create_withDescription_preservesDescription`
  - All existing tests continue to work via factory defaults (no breakage)
  - Cite: existing entity tests in same file

### 5.3 Update `protocol_dto_test.dart` ✅
- **Edit** `test/features/protocol/data/dtos/protocol_dto_test.dart`
  - Add `(factory: ProtocolDtoFactory.createWithEmptyDescription, code: 'Protocol.DescriptionEmpty')` to parameterized `invalidCases` list
  - Add `'description'` to `requiredFields` list for fromJson missing-field tests
  - Add description assertion to roundtrip preservation test
  - Cite: existing parameterized patterns in same file

### 5.4 Add `TargetDto` duration roundtrip assertion ✅
- **New** `test/features/protocol/data/dtos/target_dto_test.dart`
  - toDomain valid, invalid frequency, max < min, null duration
  - fromJson valid, missing frequency
  - fromDomain roundtrip preserves durationSeconds
  - fromJson/toJson roundtrip guards camelCase `durationSeconds` key
  - Cite: existing DTO roundtrip patterns
- **New** `test/features/protocol/data/dtos/frequency_dto_test.dart`
  - toDomain valid, invalid min, max < min
  - fromJson valid, missing fields
  - fromDomain roundtrip preserves values
  - fromJson/toJson roundtrip guards snake_case @JsonKey mapping
- **New** `test/features/protocol/data/dtos/research_citation_dto_test.dart`
  - toDomain valid, parameterized invalid cases (empty authors/title/journal, invalid year)
  - fromJson valid, missing fields, null doi, null url
  - fromDomain roundtrip preserves all fields

---

## Phase 6 — Verify ✅

- `dart format lib test` — 0 changes needed
- `flutter analyze` — no issues found
- `flutter test` — 571 tests passed

---

## Files Summary

| Action | File | Phase |
|--------|------|-------|
| New | `lib/features/protocol/domain/value_objects/protocol_description.dart` | 1.2 |
| New | `test/factories/value_objects/protocol_description_factory.dart` | 4.2 |
| New | `test/domain/protocol/value_objects/protocol_description_test.dart` | 5.1 |
| New | `supabase/migrations/..._add_protocol_description.sql` | 3.1 |
| New | `supabase/migrations/..._seed_protocols.sql` | 3.2 |
| New | `tool/generate_seed_sql.dart` | 3.2 |
| Edit | `lib/features/protocol/domain/failures/protocol_failures.dart` | 1.1 |
| Edit | `lib/features/protocol/domain/entities/protocol.dart` | 1.3 |
| Edit | `lib/features/protocol/data/dtos/protocol_dto.dart` | 2.1 |
| Edit | `test/constants/test_constants.dart` | 4.1 |
| Edit | `test/factories/factories.dart` | 4.3 |
| Edit | `test/factories/protocol_factory.dart` | 4.4 |
| Edit | `test/factories/dtos/protocol_dto_factory.dart` | 4.5 |
| Edit | `test/factories/dtos/target_dto_factory.dart` | 4.6 |
| Edit | `test/domain/protocol/protocol_test.dart` | 5.2 |
| Edit | `test/features/protocol/data/dtos/protocol_dto_test.dart` | 5.3 |
| New | `test/features/protocol/data/dtos/target_dto_test.dart` | 5.4 |
| New | `test/features/protocol/data/dtos/frequency_dto_test.dart` | 5.4 |
| New | `test/features/protocol/data/dtos/research_citation_dto_test.dart` | 5.4 |
| Edit | `test/factories/dtos/research_citation_dto_factory.dart` | 4.6 |
| Edit | `supabase/seed.sql` | 3.3 |

## Not Changed (UI deferred)

- `lib/library/widgets/protocol_detail_sheet.dart` — description display deferred
- All other UI files, view models, repository implementations
