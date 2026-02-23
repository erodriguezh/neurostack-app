## Description
Extract the duplicated `.getOrElse((l) => throw Exception('Factory produced invalid X: $l'))` pattern from 8 factory files (10 instances) into a shared top-level `unwrapOrThrow<T>()` function.

**Size:** M
**Files:**
- `test/factories/factory_helpers.dart` (NEW)
- `test/factories/factories.dart` (update barrel to export `factory_helpers.dart`)
- `test/factories/value_objects/frequency_factory.dart` (L8-10)
- `test/factories/value_objects/protocol_name_factory.dart` (L9-11)
- `test/factories/value_objects/protocol_description_factory.dart` (L12-14)
- `test/factories/value_objects/research_citation_factory.dart` (L15-17)
- `test/factories/value_objects/target_factory.dart` (L14 + L35 — 2 instances)
- `test/factories/value_objects/session_duration_factory.dart` (L8-10)
- `test/factories/protocol_factory.dart` (L68-69)
- `test/factories/session_factory.dart` (L48-49)
- `docs/best_practices/test/domain/01-test-factories.md` (mention shared utility in barrel section)

## Approach

- Use a **top-level function** (not an extension on `Either`) — prevents accidental auto-import into `lib/` production code
- Signature: `T unwrapOrThrow<L, T>(Either<L, T> result, [String? context])` — generic on both `L` and `T`
- **Context strings must match current factory messages exactly** — e.g. `'Frequency'`, `'Protocol'`, `'ProtocolName'`, `'ProtocolDescription'`, `'ResearchCitation'`, `'Target'`, `'SessionDuration'`, `'Session'`. These are entity names, NOT method-qualified names like `'FrequencyFactory.valid'`.
- Default context: `'value'` (when caller omits context arg)
- Error message format: `'Factory produced invalid $context: $l'` — matches existing convention
- Add to existing barrel `test/factories/factories.dart`

## Key context

- The 10 instances are identical in structure but differ in the entity name in the error message
- `test/factories/factories.dart` barrel already re-exports: `protocol_factory.dart`, `session_factory.dart`, `session_draft_factory.dart`, `user_factory.dart`, etc.
- Some factories (UserFactory, EntitlementSnapshotFactory, PendingSessionFactory, StackFactory) do NOT use this pattern (their constructors don't return Either) — leave those untouched

## Acceptance
- [ ] `test/factories/factory_helpers.dart` exists with `unwrapOrThrow<L, T>()` function
- [ ] `test/factories/factories.dart` barrel exports `factory_helpers.dart`
- [ ] All 10 instances of `.getOrElse((l) => throw Exception('Factory produced invalid...'))` replaced with `unwrapOrThrow()` calls
- [ ] Error messages use entity-name context matching current strings (e.g. `'Frequency'`, `'Protocol'`), NOT method-qualified names
- [ ] No `throw Exception('Factory produced invalid` string literal in any factory file (grep returns 0 hits)
- [ ] `flutter test` passes
- [ ] `flutter analyze` clean (no unused imports, no lint warnings)
- [ ] `docs/best_practices/test/domain/01-test-factories.md` mentions `factory_helpers.dart` utility
