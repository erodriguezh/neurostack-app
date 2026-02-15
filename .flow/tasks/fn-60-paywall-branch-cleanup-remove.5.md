# fn-60-paywall-branch-cleanup-remove.5 Consolidate test mocks and fakes

## Description
Consolidate duplicate mock class declarations scattered across test files into a shared `test/mocks/` directory. Assess the two `FakeRevenueCatClient` implementations.

**Size:** M
**Files:**
- `test/mocks/mock_services.dart` (NEW — shared mock declarations)
- `test/home/home_view_model_test.dart` (remove inline mocks, import shared)
- `test/library/library_view_model_test.dart` (remove inline mocks, import shared)
- `test/features/session/presentation/views/log_session_view_test.dart` (remove inline mocks, import shared)
- `test/core/utils/app_lifecycle_service_test.dart` (remove inline mock, import shared)
- `test/paywall/data/revenuecat_service_test.dart` (extract inline FakeRevenueCatClient)
- `integration_test/mocks/fake_revenuecat_client.dart` (document or consolidate)

## Duplicate mocks to consolidate

These mock classes are re-declared in 2-3+ test files each:
- `MockNotifyService` (3 files)
- `MockRouterService` (2 files)
- `MockAuthService` (2 files)
- `MockUserRepository` (2 files)
- `MockProtocolRepository` (2 files)
- `MockSessionRepository` (2 files)
- `MockConnectivityService` (2 files)
- `MockRevenueCatService` (3 files)
- `MockSessionLocalDataSource` (2 files)

## `FakeRevenueCatClient` assessment

Two independent implementations exist:
1. **Unit test** (`test/paywall/data/revenuecat_service_test.dart:L9-107`): More features — `configureDelay`, `configureThrows`, error simulation
2. **Integration test** (`integration_test/mocks/fake_revenuecat_client.dart:L13-109`): Different features — `simulatePurchase`, `setSnapshot`, call counting

These serve different purposes. Extract the unit test fake to its own file (`test/mocks/fake_revenuecat_client.dart`). Document both fakes as intentionally separate due to different testing needs.

## Approach

- Create `test/mocks/mock_services.dart` with all shared mock class declarations using mocktail
- Existing `test/mocks/data_source_mocks.dart` already exists — add the new file alongside it
- Replace inline mock declarations in each test file with imports from the shared file
- Keep test-specific mocks that are truly unique to a single test file
- Do NOT consolidate the two FakeRevenueCatClient implementations — they serve different purposes

## Key context

- The codebase uses `mocktail` (not `mockito`) for mocking — `extends Mock implements X` pattern
- `test/mocks/data_source_mocks.dart` already exists as a shared mocks file — follow the same pattern
- Integration tests live in `integration_test/` which has its own `mocks/` directory — keep that separation
## Acceptance
- [ ] `test/mocks/mock_services.dart` created with shared mock declarations
- [ ] No duplicate mock class declarations across `test/home/`, `test/library/`, `test/features/session/`, `test/core/`
- [ ] Unit test `FakeRevenueCatClient` extracted from inline test to `test/mocks/` or `test/paywall/mocks/`
- [ ] Integration test `FakeRevenueCatClient` remains in `integration_test/mocks/` (intentionally separate)
- [ ] `flutter test` passes (all tests green)
- [ ] `flutter analyze` passes
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
