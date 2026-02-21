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
Added createWithEmptyDescription() factory method to ProtocolDtoFactory and updated protocol_dto_test.dart with description validation test case in invalidCases, 'description' in requiredFields for fromJson tests, and description assertion in fromDomain roundtrip test.
## Evidence
- Commits: 24b91e02076d25b60d884078aae89d463201b460
- Tests: flutter analyze, flutter test
- PRs: