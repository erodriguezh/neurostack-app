# Phase 1.3: Add description field to Protocol entity

**Plan reference:** `plan_update_protocol_domain_and_db.md` Phase 1.3 + 1.4

## Scope

Add `ProtocolDescription description` field to the `Protocol` entity, following the same pattern as `name: ProtocolName`. Update test factories so all existing tests keep passing.

## Approach

1. **Edit** `lib/features/protocol/domain/entities/protocol.dart`:
   - Add import for `protocol_description.dart`
   - Add `required this.description` to `Protocol._()` private constructor
   - Add `final ProtocolDescription description` field (after `name`)
   - Add `required ProtocolDescription description` to `Protocol.create()`
   - Add `required ProtocolDescription description` to `Protocol.reconstitute()`
   - Pass `description: description` in `softDelete()` copy

2. **Run codegen**: `dart run build_runner build --delete-conflicting-outputs`

3. **Update test infrastructure** (to fix compile errors from new required param):
   - `test/constants/test_constants.dart` — add `validDescription`, `emptyDescription`
   - Create `test/factories/value_objects/protocol_description_factory.dart`
   - `test/factories/factories.dart` — add barrel export
   - `test/factories/protocol_factory.dart` — add description param

4. **Verify**: `flutter analyze` then `flutter test`

## Quick commands
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] Protocol entity has `description` field of type `ProtocolDescription`
- [ ] All existing tests pass with factory defaults
- [ ] `flutter analyze` clean

## References
- `plan_update_protocol_domain_and_db.md` Phase 1.3, 1.4, 4.1-4.4
- Pattern: `lib/features/protocol/domain/value_objects/protocol_name.dart`
