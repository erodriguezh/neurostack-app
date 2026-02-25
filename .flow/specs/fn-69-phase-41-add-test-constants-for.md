# Phase 4.1: Add test constants for ProtocolDescription

## Context
Phase 4 of the protocol domain update plan adds test infrastructure. Phase 4.1 adds test constants needed by subsequent factory and test phases.

## Requirements
- Edit `test/constants/test_constants.dart`
- Add to `_Protocol` class (after existing name constants ~line 44):
  ```dart
  final String validDescription = 'High-intensity interval training combining 4-minute intervals at 90-95% max HR.';
  final String emptyDescription = '';
  ```
- Follows existing `validName`/`emptyName` pattern at lines 35-36

## Acceptance Criteria
- `flutter analyze` passes
- `flutter test` passes
- Constants available for use in subsequent Phase 4.2+ tasks
