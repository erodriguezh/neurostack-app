# Phase 2.1: Add description to ProtocolDto

**Plan reference:** `plan_update_protocol_domain_and_db.md` Phase 2.1 + 2.2

## Scope

Add `description` field to `ProtocolDto` freezed class, wire `toDomain()` and `fromDomain()`, update test factories, run codegen, and verify.

## Approach

1. **Edit** `lib/features/protocol/data/dtos/protocol_dto.dart`:
   - Add import for `protocol_description.dart`
   - Add `required String description` to freezed factory (after `name`, before `target`)
   - In `toDomain()`: add description validation block after name parsing, same pattern as `nameResult`
   - Pass `description: domainDescription` to `Protocol.reconstitute()`
   - In `fromDomain()`: add `description: protocol.description.value`

2. **Run codegen**: `dart run build_runner build --delete-conflicting-outputs`

3. **Update test infrastructure** (Phase 4.5 from plan):
   - `test/factories/dtos/protocol_dto_factory.dart` — add `description` param to `create()`, add `createWithEmptyDescription()`, add `'description'` to `createValidJson()`

4. **Verify**: `flutter analyze` then `flutter test`

## Quick commands
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] ProtocolDto has `description` field
- [ ] `toDomain()` validates description and maps to `ProtocolDescription`
- [ ] `fromDomain()` extracts `description.value`
- [ ] Test factory updated with description support
- [ ] All existing tests pass
- [ ] `flutter analyze` clean

## References
- `plan_update_protocol_domain_and_db.md` Phase 2.1, 2.2, 4.5
- Pattern: `nameResult` validation in `protocol_dto.dart`
