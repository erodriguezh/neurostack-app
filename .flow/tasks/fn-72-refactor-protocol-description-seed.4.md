## Description
Refactor the `toDomain()` method in `ProtocolDto` from the repeated `isLeft()`/`getOrElse(unreachable)` pattern (~70 lines) to fpdart `Either.Do` notation (~30 lines). This is the **first** `Either.Do` usage in the codebase.

**Size:** M
**Files:**
- `lib/features/protocol/data/dtos/protocol_dto.dart` (L58-167 — main refactor)
- Possibly a private helper function within the same file for enum parsing and DateTime parsing

## Approach

- Use `Either.Do(($) { ... })` — the `$` extractor short-circuits to `Left` automatically
- **Value object fields** (name, description): `$(ProtocolName.create(name))` — direct bind
- **Nested DTO** (target): `$(target.toDomain())` — direct bind
- **Enum parsing** (category, evidenceLevel): Extract a private `_parseEnum<T>()` helper that returns `Either<DomainFailure, T>`, wrapping `T.values.byName()` in try/catch. Must preserve existing failure codes (`Dto.InvalidCategory`, `Dto.InvalidEvidenceLevel`)
- **DateTime parsing**: Extract into a dedicated `_parseDateTime(String raw) → Either<DomainFailure, DateTime>` helper with its own try/catch returning `Dto.ParseError`. **Do NOT wrap the Either.Do block in a broad try/catch** — this would swallow `$` short-circuit exceptions (which are internal throws used by Either.Do) and break failure codes
- **Citation list**: Use a simple `for` loop inside the Do block: `for (final c in citations) { domainCitations.add($(c.toDomain())); }`. Avoid `Either.traverseList` or `$` inside `.map()` — the for-loop approach is deterministic and avoids fpdart API edge cases
- **Add a brief code comment** explaining this is Either.Do notation (first usage), pointing to fpdart docs

## Key context

- fpdart 1.2.0 `Either.Do` uses exception-based short-circuiting internally. The `$` function throws `_EitherThrow(leftValue)` which is caught by the `Either.Do` factory. A broad outer try/catch would intercept this throw before Either.Do can catch it, causing all Left results to be reported as `Dto.ParseError` instead of their correct failure codes.
- Reference patterns in codebase:
  - `target_dto.dart:32-43` — clean flatMap chain (4 lines)
  - `log_session_use_case.dart:72-82` — multi-step flatMap pipeline
  - These use `flatMap`, not `Either.Do`. The new approach is the recommended modern fpdart pattern.
- Existing tests in `protocol_dto_test.dart` cover all failure paths — they should pass unchanged after refactoring (behavior-preserving)
- The architecture guide at `docs/best_practices/architecture/mvvm_and_ddd_guide.md:631-634` already recommends flatMap chaining in toDomain(); Either.Do is the evolution of that guidance

## Acceptance
- [ ] `ProtocolDto.toDomain()` uses `Either.Do` notation
- [ ] No `isLeft()` calls in `protocol_dto.dart`
- [ ] No `getOrElse((l) => throw StateError('Unreachable'))` in `protocol_dto.dart`
- [ ] No broad try/catch wrapping the Either.Do block — DateTime/enum parsing use dedicated Either-returning helpers
- [ ] Method body is ~30 lines (down from ~70)
- [ ] Enum parse failure codes preserved: `Dto.InvalidCategory`, `Dto.InvalidEvidenceLevel`
- [ ] DateTime parse failures still produce `Dto.ParseError` via dedicated `_parseDateTime` helper
- [ ] Citation list built via simple for-loop with `$` bind (not traverseList or $ inside .map)
- [ ] All existing tests in `protocol_dto_test.dart` pass unchanged
- [ ] `flutter test` passes (full suite)
- [ ] `flutter analyze` clean

## Done summary
Refactored ProtocolDto.toDomain() from the repeated isLeft/getOrElse(unreachable) pattern (~70 lines) to fpdart Either.Do notation (~30 lines), extracting dedicated _parseEnum and _parseDateTime helpers to preserve failure codes without broad try/catch.
## Evidence
- Commits: e1becd5582c7764616544b2994aac6c2e2c41fa6
- Tests: flutter test test/features/protocol/data/dtos/protocol_dto_test.dart, flutter test, flutter analyze
- PRs: