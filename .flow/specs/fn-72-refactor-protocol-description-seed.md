# Refactor Protocol Description & Seed Migration Code

## Overview

Post-implementation cleanup of the 18 commits (fn-62 → fn-71) that added `ProtocolDescription` VO, Protocol/DTO description field, seed migrations, DTO tests & factories. This epic addresses code duplication, a DB/domain invariant mismatch, and seed SQL fragility.

**Stakeholders:** Developers only (no user-facing changes). One DB migration (CHECK constraint) affects operations.

## Scope

Five refactoring items plus one critical data-integrity fix:

1. **Extract `_pascalCase` test helper** — duplicated in 4 test files → shared `test/helpers/string_helpers.dart`
2. **Extract `unwrapOrThrow` factory helper** — duplicated in 8 factory files (10 instances) → shared `test/factories/factory_helpers.dart`
3. **Fix generator comment + resilient seed.sql citations** — misleading comment at `tool/generate_seed_sql.dart:84-85` + convert 22 scalar-subquery citation INSERTs in `supabase/seed.sql` to `INSERT...SELECT...WHERE`. Only `supabase/seed.sql` is changed; the generated migration is explicitly out of scope.
4. **Refactor `ProtocolDto.toDomain()` to `Either.Do`** — replace 5× repeated `isLeft`/`getOrElse(unreachable)` blocks with fpdart Do notation
5. **Tighten DB description constraint** — add `CHECK (length(trim(description)) > 0)` + drop `DEFAULT ''`

### Out of scope
- Refactoring `TargetDto.toDomain()` or use cases to Either.Do (future consistency pass)
- Updating `tool/generate_seed_sql.dart` output to use INSERT...SELECT (generator always runs before citations exist)
- Duplicate protocol names in seed migration (handled by existing `ON CONFLICT` upsert)

## Approach

### Either.Do notation (first usage in codebase)
- fpdart 1.2.0 supports `Either.Do(($) { ... })` — the `$` extractor short-circuits to `Left` automatically
- Reference for multi-value accumulation: `target_dto.dart:32-43` (flatMap), `log_session_use_case.dart:72-82` (pipeline)
- Enum parsing (`Category.values.byName`, `EvidenceLevel.values.byName`) must be wrapped in helpers returning `Either` to participate in Do notation
- **DateTime parsing**: Extract into a dedicated `_parseDateTime(String raw) → Either<DomainFailure, DateTime>` helper with its own try/catch returning `Dto.ParseError`. Do NOT wrap the entire `Either.Do` block in a broad try/catch — this would swallow `$` short-circuit exceptions and break failure codes
- **Citation list**: Use a simple `for` loop with `$(c.toDomain())` inside the Do block. Avoid `Either.traverseList` or `$` inside `.map()` — the for-loop approach is deterministic and avoids fpdart API edge cases
- **This is the first Either.Do usage** — document the pattern choice in a code comment for future contributors

### Test helper extraction
- New `test/helpers/` directory with barrel `test/helpers/helpers.dart`
- `pascalCase()` (drop `_` prefix) as public top-level function
- `unwrapOrThrow<T>()` as top-level function in `test/factories/factory_helpers.dart` (not an extension — prevents accidental production imports)
- Follow existing `test/matchers/either_matchers.dart` precedent for shared test utilities
- Context strings must match **current** factory error messages (entity name like `'Frequency'`, `'Protocol'`, NOT method-qualified like `'FrequencyFactory.valid'`)

### Seed SQL resilience
- `INSERT INTO ... SELECT ... FROM protocols WHERE ...` pattern: if protocol missing, zero rows inserted (no FK violation, no NULL)
- This is a **different failure mode** than current: silent skip vs. explicit error. Acceptable for seed data.
- Scope is strictly `supabase/seed.sql` — generated migrations are out of scope

### DB constraint
- Migration must run AFTER `20260221200000_seed_protocols.sql` (all 57 protocols already have descriptions)
- Pre-check: `SELECT count(*) FROM protocols WHERE description = ''` should return 0
- Add `CHECK (length(trim(description)) > 0)` — matches domain VO validation exactly
- Drop `DEFAULT ''` — forces all INSERT paths to provide explicit description
- Guard constraint creation with `IF NOT EXISTS` via PL/pgSQL block (Postgres has no `ADD CONSTRAINT IF NOT EXISTS`) for idempotent re-apply during `supabase db reset`

## Quick commands
```bash
flutter test
flutter analyze
dart format lib test
```

## Risks / Dependencies

| Risk | Mitigation |
|------|-----------|
| Either.Do `$` short-circuit caught by broad try/catch | Do NOT wrap Either.Do in try/catch; extract DateTime parsing into separate Either-returning helper |
| Either.Do is first usage — two competing patterns | Document pattern choice; plan future consistency pass |
| CHECK constraint fails if empty descriptions exist | Pre-check query in migration; abort if non-zero |
| ADD CONSTRAINT fails on re-apply (no IF NOT EXISTS) | Guard with PL/pgSQL `IF NOT EXISTS (SELECT 1 FROM pg_constraint ...)` block |
| seed.sql INSERT...SELECT silently skips missing protocols | Acceptable for test seed data; production uses ON CONFLICT upsert |
| fpdart 1.2.0 Either.Do API might differ from docs | Verify exact syntax before implementing; fallback to flatMap if needed |

**Epic dependencies:** None (fn-62 → fn-71 all done). No blocking open epics.

## Acceptance

- [ ] All 4 `_pascalCase` duplicates removed; single shared helper in `test/helpers/`
- [ ] All 10 `getOrElse((l) => throw Exception(...))` instances use shared `unwrapOrThrow` with entity-name context matching current messages
- [ ] `generate_seed_sql.dart:84-85` comment accurately describes passthrough from `protocols.json`
- [ ] `supabase/seed.sql` citation inserts use `INSERT...SELECT...WHERE` (no scalar subqueries in seed.sql; generated migration is out of scope)
- [ ] `ProtocolDto.toDomain()` uses Either.Do notation with ~30 lines (down from ~70); no broad try/catch wrapping the Do block
- [ ] DateTime parsing in dedicated helper returning `Either`, not caught by Do block's short-circuit mechanism
- [ ] DB CHECK constraint `length(trim(description)) > 0` prevents empty descriptions; DEFAULT '' removed; migration is idempotent (re-apply safe)
- [ ] `flutter test` passes
- [ ] `flutter analyze` clean
- [ ] Doc structure diagrams updated (AGENTS.md, index.md, data-layer-supabase-testing.md); `result_matchers.dart` → `either_matchers.dart` fixed in index.md

## References

- fpdart `Either.Do`: https://pub.dev/packages/fpdart
- Existing flatMap reference: `lib/features/protocol/data/dtos/target_dto.dart:32-43`
- Existing pipeline reference: `lib/features/session/domain/use_cases/log_session_use_case.dart:72-82`
- Shared test matchers precedent: `test/matchers/either_matchers.dart`
- Factory unwrap pattern: `test/factories/protocol_factory.dart:68-69`
- DB migration with DEFAULT: `supabase/migrations/20260221193000_add_protocol_description.sql:13-14`
- Domain VO invariant: `lib/features/protocol/domain/value_objects/protocol_description.dart:28-40`
- Architecture guide (flatMap recommendation): `docs/best_practices/architecture/mvvm_and_ddd_guide.md:631-634`
