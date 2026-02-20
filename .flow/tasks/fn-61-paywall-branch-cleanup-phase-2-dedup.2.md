# fn-61-paywall-branch-cleanup-phase-2-dedup.2 Test infrastructure: mock consolidation and factory adoption

## Description
Consolidate remaining test mock/fake duplication and improve adoption of `EntitlementSnapshotFactory` across paywall-related tests.

**Size:** M
**Files:**
- `test/mocks/mock_services.dart` (add MockTrialReminderService, MockSubscriptionStatusResolver, and any other duplicated mocks found by scan)
- `test/home/home_view_model_test.dart` (remove local mock definitions, import from mock_services)
- `test/mocks/fake_params.dart` (new — extract FakeCheckEligibilityParams, FakePendingSession, and any other duplicated fakes found by scan)
- `test/features/session/presentation/views/log_session_view_test.dart` (use shared fakes)
- `test/features/session/presentation/view_models/log_session_view_model_test.dart` (use shared fakes)
- `test/features/session/data/services/session_sync_service_test.dart` (use shared fakes)
- `test/library/library_view_model_test.dart` (use EntitlementSnapshotFactory where applicable)
- `test/paywall/data/revenuecat_service_test.dart` (use EntitlementSnapshotFactory where applicable)

## Approach

### Phase 0: Repo-wide mock/fake discovery

0. **Scan the entire test tree for duplication** before starting consolidation:
   ```bash
   rg "extends Mock implements" test/
   rg "extends Fake implements" test/
   ```
   Review all hits. For each duplicated mock/fake class:
   - If it appears in 2+ test files with identical behavior → centralize it
   - If it has custom stateful behavior specific to one test → leave it local (document the exception)
   - If it's in `progress_view_model_test.dart` → out of scope (per epic)
   - If it's in `integration_test/` → out of scope (cross-runner sharing not possible)

### Phase A: Mock consolidation

1. **Move `MockTrialReminderService` and `MockSubscriptionStatusResolver`** from `test/home/home_view_model_test.dart:19-22` to `test/mocks/mock_services.dart`. Update the import in home_view_model_test.dart.

2. **Move any additional duplicated mocks** discovered in Phase 0 to `test/mocks/mock_services.dart`.

3. **Extract shared fake classes** to a new `test/mocks/fake_params.dart`:
   - `FakeCheckEligibilityParams extends Fake implements CheckEligibilityParams` (from 2 files)
   - `FakePendingSession extends Fake implements PendingSession` (from 3 files)
   - Any additional duplicated fakes discovered in Phase 0
   Add to `test/mocks/` barrel if one exists, or add imports directly.

4. **Update test files** to import from shared locations instead of defining locally.

### Phase B: EntitlementSnapshotFactory adoption

5. **Review inline `EntitlementSnapshot(...)` constructions** in:
   - `test/library/library_view_model_test.dart` (~2 inline)
   - `test/paywall/data/revenuecat_service_test.dart` (~7 inline)

6. **Replace with factory methods** ONLY when:
   - The scenario matches one of the factory's documented cases (activeTrial, activePaidMonthly, activePaidYearly, gracePeriod, expiredTrial, expiredPaid, expiredIntro), AND
   - The test does not assert on fields that the factory currently hardcodes (e.g., specific `originalTransactionId` values, custom `expirationDate` values, `latestPurchaseDate`)
   
   **Before replacing each inline constructor, check:**
   - Does the test assert on `expirationDate` (absolute or relative to `now`)?
   - Does the test assert on `latestPurchaseDate`?
   - Does the test assert on `originalTransactionId`?
   
   If yes to any: either use the factory with explicit parameter overrides to preserve the exact asserted values, OR keep the inline constructor as-is.
   
   Example of safe factory usage with parameter overrides:
   ```dart
   final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
     userId: user.id,
     expirationDate: customExpiration,
     originalTransactionId: 'original-txn',
   );
   ```
   
   Factory replacement must NOT change any expectations or asserted field values.

7. **Do NOT convert** inline constructions in `test/paywall/domain/entitlement_snapshot_test.dart` — those tests deliberately construct edge-case scenarios that require full control over every field.

8. **Run `flutter test`** after each phase to catch regressions.

## Key context

- The `EntitlementSnapshotFactory` is at `test/factories/entitlement_snapshot_factory.dart` and exported via `test/factories/factories.dart`
- Centralized mocks live in `test/mocks/mock_services.dart` (12 mock classes already there)
- The `FakeRevenueCatClient` in `test/mocks/fake_revenuecat_client.dart` is intentionally separate from `integration_test/mocks/fake_revenuecat_client.dart` — do NOT merge cross-runner fakes
- `progress_view_model_test.dart` fakes are intentionally OUT OF SCOPE — they have complex stateful behavior

## Acceptance
- [ ] `MockTrialReminderService` and `MockSubscriptionStatusResolver` live in `test/mocks/mock_services.dart`
- [ ] No mock class definitions remain in `test/home/home_view_model_test.dart`
- [ ] `FakeCheckEligibilityParams` defined once in `test/mocks/` (removed from 2 test files)
- [ ] `FakePendingSession` defined once in `test/mocks/` (removed from 3 test files)
- [ ] All `extends Mock implements` in `test/` reviewed — shared service/repository mocks live in `test/mocks/mock_services.dart` unless documented as intentionally local (e.g., custom stateful behavior)
- [ ] All `extends Fake implements` used in 2+ test files centralized into `test/mocks/` (except explicitly out-of-scope cases like `progress_view_model_test.dart` and `integration_test/`)
- [ ] `library_view_model_test.dart` uses `EntitlementSnapshotFactory` where factory covers the scenario
- [ ] `revenuecat_service_test.dart` uses `EntitlementSnapshotFactory` where factory covers the scenario
- [ ] All factory replacements preserve any existing expectations on `expirationDate`, `latestPurchaseDate`, and `originalTransactionId` (via explicit parameters if necessary)
- [ ] `entitlement_snapshot_test.dart` retains inline constructors (intentional)
- [ ] No test changed its semantic assertions (only construction method changed)
- [ ] `flutter test` all pass
## Done summary
Consolidated duplicate mock/fake classes into shared test/mocks/ files (mock_services.dart, fake_params.dart) and replaced 3 inline EntitlementSnapshot constructions with EntitlementSnapshotFactory usage in library_view_model_test.dart and revenuecat_service_test.dart.
## Evidence
- Commits: ec37f331cde6cd59b0b06542391b9d8e8c045980
- Tests: flutter analyze, flutter test
- PRs: