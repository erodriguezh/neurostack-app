# fn-65-phase-21-add-description-to-protocoldto.1 Add description field to ProtocolDto, update toDomain/fromDomain, update test factories, verify

## Description

Add `description` field to `ProtocolDto` freezed class. Wire `toDomain()` to validate description via `ProtocolDescription.create()` (same pattern as `nameResult`). Wire `fromDomain()` to extract `description.value`. Update `ProtocolDtoFactory` with description support. Run codegen. Verify with analyze + tests.

## Acceptance
- [ ] ProtocolDto freezed factory has `required String description` field
- [ ] `toDomain()` validates description via `ProtocolDescription.create()`
- [ ] `fromDomain()` maps `protocol.description.value`
- [ ] ProtocolDtoFactory updated with description param and `createWithEmptyDescription()`
- [ ] `createValidJson()` includes `'description'` key
- [ ] Codegen run successfully
- [ ] `flutter analyze` clean
- [ ] `flutter test` green

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
