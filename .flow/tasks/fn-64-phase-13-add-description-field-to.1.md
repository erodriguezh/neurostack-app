# fn-64-phase-13-add-description-field-to.1 Add ProtocolDescription field to Protocol entity, run codegen, update tests, verify

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Added ProtocolDescription field to Protocol entity (private constructor, create, reconstitute, softDelete) and ProtocolDto (freezed factory, toDomain validation, fromDomain mapping). Updated ProtocolFactory, ProtocolDtoFactory, and codegen. All 538 tests pass, flutter analyze clean.
## Evidence
- Commits: 18fb120eda9323b32be53805cf244437026db392
- Tests: flutter analyze, flutter test
- PRs: