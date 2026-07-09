# Coding Standards

These standards reflect the patterns actually used in this Flutter app (`neurostack`).
The stack is **MVVM + lightweight DDD** with `fpdart` (Either/Unit), `freezed` + `json_serializable`
for DTOs/value objects, `supabase_flutter` for the backend, a custom service locator for DI, and
`mocktail` + `fake_async` for tests.

## Style

### Naming
- `PascalCase` for classes, types, enums, and mixins (e.g. `LogSessionViewModel`, `SessionDto`, `EntityMixin`).
- `camelCase` for variables, methods, parameters, and named constructor args.
- Private members are prefixed with a leading underscore (`_dataSource`, `_selectedDate`, `_clampDate`).
- `snake_case` for all Dart file names.
- Domain events use **past-tense** names (e.g. `SessionLoggedEvent`).
- Centralized failure codes follow `{Aggregate}.{Invariant}` (e.g. `Session.InvalidDateTime`, `Session.CapacityExceeded`).

### File naming & suffixes
- Suffix files by role: `_view.dart`, `_view_model.dart`, `_state.dart`, `_repository.dart` (interface),
  `_repository_impl.dart` (implementation), `_data_source.dart`, `_dto.dart`, `_use_case.dart`,
  `_failures.dart`, `_events.dart`, `_service.dart`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are committed alongside their source and are
  excluded from analysis (see `analysis_options.yaml`). Never hand-edit them; regenerate with `build_runner`.

### Formatting & lints
- Lint baseline is `package:flutter_lints/flutter.yaml` plus these enabled rules
  (`analysis_options.yaml`): `prefer_const_constructors`, `prefer_const_declarations`,
  `sized_box_for_whitespace`, `use_key_in_widget_constructors`, `avoid_unnecessary_containers`.
- Use `const` constructors/declarations wherever possible (enforced by lint).
- Trailing commas are preserved by the formatter (`formatter.trailing_commas: preserve`); keep them
  on multi-line argument/parameter lists so `dart format` lays them out one-per-line.
- Always pass `super.key` / use `Key` in widget constructors.
- Suppress lints narrowly with `// ignore:` / `// ignore_for_file:` rather than disabling project-wide.

### Comments
- Prefer self-documenting code through descriptive naming; use comments sparingly and only when they add value.
- Use `///` doc comments for the rationale behind non-obvious domain rules and public API intent.

## Testing

### Core principle
Tests verify **behavior through public interfaces**, not implementation details. The implementation
can change entirely; a test should only break when observable behavior changes. In this codebase the
"public interface" is a domain object's factory/methods (e.g. `SessionDraft.create(...)`), a
repository/use-case API, or a widget's rendered output and interactions — never private helpers or
internal call wiring.

### Good tests
Exercise real code paths through the public API and assert on the observable result. Prefer real
domain objects built from factories over mocks; describe _what_ the system does, not _how_.

```dart
// GOOD: behavior through the public factory; asserts the specific outcome via Either matchers.
// (test/domain/session/session_draft_test.dart)
test('create_withTooOldTimestamp_returnsDateTooOld', () {
  // Arrange
  final tooOldTime = TestConstants.session.currentTime.subtract(
    const Duration(days: 8),
  );

  // Act
  final result = SessionDraftFactory.create(completedAt: tooOldTime);

  // Assert
  expect(result, isLeftWith(SessionFailures.dateTooOld));
});
```

- Test behavior callers/users care about, through the public API only.
- Use real entities, value objects, use cases, DTOs, and mappers (via factories) — they are pure, so don't mock them.
- One logical assertion per test; survive internal refactors.

### Bad tests
```dart
// BAD: restates a one-liner — the function IS the spec. Adds no confidence, breaks on any refactor.
test('toIso_returnsIsoString', () {
  expect(dto.startsAt, '2025-01-15T10:00:00Z');
});

// BAD: asserting internal call wiring as the point of the test (HOW, not WHAT).
test('submit_callsRepositorySave', () async {
  await viewModel.submit();
  verify(() => mockSessionRepository.create(any())).called(1); // sole assertion
});

// BAD: bypasses the interface to verify through the backend instead of observable behavior.
test('create persists to supabase', () async {
  await repository.create(draft);
  final rows = await supabase.from('sessions').select();
  expect(rows, isNotEmpty);
});
```

Red flags:
- Mocking your own domain objects (entities, value objects, use cases, mappers) or testing private methods.
- Asserting on call counts/order of internal collaborators as the goal of the test.
- A test that mirrors a trivial function (one-liner, simple mapping, string concatenation).
- Thin delegation tests — when a ViewModel/handler just forwards to a use case or repository, test the
  real behavior in that use case/repository instead of mocking it and re-asserting the forwarding.
- Verifying through external means (querying Supabase/`SharedPreferences` directly) instead of the public API.
- The test name describes HOW (`callsX`, `usesY`) rather than WHAT (the observable result).

### Mocking — at boundaries only
Mock at the system's seams, not its internals. In this project the seams are the abstractions that
wrap external systems: data sources and external-SDK/platform wrappers (Supabase via
`DataSourceAbstraction`, RevenueCat, `SharedPreferences`, connectivity, `Uuid`, time/randomness).

- Use `mocktail`. `Mock` subclasses live in `test/mocks/` (`mock_services.dart`, `data_source_mocks.dart`);
  reusable fakes for `any()` fallbacks live in `test/mocks/fake_params.dart`; prefer hand-written fakes
  for richer boundaries (e.g. `test/mocks/fake_revenuecat_client.dart`).
- When testing a ViewModel, stub its injected ports (repository/use-case/service) to drive scenarios,
  but assert on the resulting **state** the View observes — not on how often a collaborator was called.
- `verify(...).called(n)` is legitimate only to confirm an interaction crossed a real boundary
  (e.g. the remote data source was hit), never as a stand-in for a behavioral assertion.
- Never mock entities, value objects, use-case _logic_, DTOs, or pure helpers. If something is hard to
  test without mocking internals, fix the interface.

### Lifecycle
- Create fresh mocks and state in `setUp()`; reserve `setUpAll()` for one-time work like
  `registerFallbackValue(...)`. Never stub inside a mock's constructor.
- Control time with `fake_async` — never use real `Future.delayed`/timers in tests.
- In widget tests, `pump()`/`pumpAndSettle()` after every interaction (`tap`, `enterText`).

### Organization
- Test files **must** end with `_test.dart`.
- Mirror the `lib/` structure under `test/`: domain/aggregate tests live in `test/domain/{aggregate}/`,
  and feature data/presentation tests live in `test/features/{feature}/{layer}/`.
- Shared test infrastructure is **not** mirrored and lives in dedicated top-level folders:
  `test/factories/`, `test/constants/`, `test/matchers/`, `test/mocks/`, `test/helpers/`.
- Widget tests sit next to the feature they cover (e.g. `test/library/widgets/`, `test/progress/widgets/`).
- Integration tests live in `integration_test/`, organized into `flows/`, `mocks/`, and `utils/`.

### Naming & structure
- Name tests `{method}_{scenario}_{expectedResult}`
  (e.g. `create_withValidData_succeeds`, `create_withTooOldTimestamp_returnsDateTooOld`).
- Use `group()` per method/aggregate under test.
- Follow Arrange-Act-Assert with blank-line separation between the three sections.
- Boundary tests must hit the exact limit and verify **success before failure** (not arbitrary values).

### Test data & assertions
- Build entities/DTOs with factories: `abstract final class {Name}Factory` exposing a `create()` with
  sensible defaults and `createWith...`/`createAtCapacity` variations. Factories live in
  `test/factories/` (domain), `test/factories/value_objects/`, and `test/factories/dtos/`, re-exported
  via barrels (`factories.dart`, `dtos.dart`).
- Keep shared literals in `test/constants/test_constants.dart`.
- For `Either`/Result code, assert the **specific** `DomainFailure` — not a generic exception — using the
  matchers in `test/matchers/either_matchers.dart` (`isRight`/`isLeft`, `isRightWith`/`isLeftWith`,
  `isLeftWithCode`).
- Use parameterized loops for validation/edge-case coverage rather than copy-pasted tests.

### TDD Workflow: Vertical Slices

Do NOT write all tests first, then all implementation. That produces tests that verify _imagined_ behavior and are insensitive to real changes.

Correct approach — one test, one implementation, repeat:

```
RED→GREEN: test1→impl1
RED→GREEN: test2→impl2
RED→GREEN: test3→impl3
```

Each test responds to what you learned from the previous cycle. Never refactor while RED — get to GREEN first.

## Architecture

### Layering (MVVM + DDD)
- Organize each complex feature as a vertical slice under `lib/features/{feature}/`:
  - `domain/` — `entities/`, `value_objects/`, `repositories/` (interfaces), `data_sources/`
    (interfaces), `failures/`, `events/`, `use_cases/` (optional), `enums/`.
  - `data/` — `dtos/`, `repositories/` (implementations), `data_sources/` (implementations),
    `mappers/`, `services/`.
  - `presentation/` — `views/`, `view_models/`, `widgets/`.
- Keep simple features flat (≈≤5 files) directly in their folder (e.g. `home/`, `settings/`,
  `startup/`, `not_found/`).
- Shared infrastructure lives in `lib/core/` (`abstractions/`, `ui/` + `ui/constants/` design tokens,
  `utils/` including `http/`, `navigation/`, `l10n/`, `internal_notification/`, and `locator.dart`) and
  app wiring in `lib/config/` (`route_config.dart`, `locator_config.dart`).

### State management
- State management is **`ValueNotifier`-based MVVM** (no Bloc/Riverpod/Provider).
- For a single value, expose `ValueNotifier<T>` directly; for multiple related values, use a single
  sealed state class wrapped in one `ValueNotifier<State>` to keep updates atomic and avoid race conditions.
- ViewModels own their `ValueNotifier`s, expose them via getters, and Views render through
  `ValueListenableBuilder` (commonly with a `switch` expression over the sealed state).

### Dependency injection
- DI is a **custom service locator** (`lib/core/utils/locator.dart`), configured in
  `lib/config/locator_config.dart` via `Module<T>` entries with `lazy: true|false`.
- Always inject dependencies through constructors. Views resolve services with `locator<T>()` only to
  construct their ViewModel.

### ViewModel / View rules
- Views never use services directly — they go through their ViewModel.
- Views contain only UI and `BuildContext`-bound logic (localization, navigation triggers, pickers);
  defer all other logic to the ViewModel.
- ViewModels never reference `BuildContext`.
- ViewModels never depend on other ViewModels — extract shared state/logic into a service.
- ViewModels dispose their own resources (`ValueNotifier`s, listeners) in `dispose()`; the View's
  `State.dispose()` calls the ViewModel's `dispose()`.

### Domain modeling
- Entities use `EntityMixin`/`AggregateRootMixin` (mixins, not abstract classes, to preserve single
  inheritance). Construct them via a private constructor plus a static `create(...)` returning
  `Either<DomainFailure, T>` for validation, and a `reconstitute(...)` factory for rebuilding trusted
  persisted state.
- Value objects (`freezed`) self-validate via a static `create(...)` returning `Either<DomainFailure, T>`.
- Use enhanced Dart enums for behavior-rich types — do **not** model simple enums with `freezed`.
- Expose collections as read-only (`UnmodifiableListView`); aggregates reference other aggregates by ID only.
- One repository per aggregate root; child entities/value objects are reached through their parent.

### Data layer
- DTOs are separate from domain models, defined with `freezed` + `json_serializable`, mapping DB
  columns with `@JsonKey(name: 'snake_case')`. They expose `fromJson`, `toDomain()` (returning
  `Either<DomainFailure, T>`, chained with `flatMap`), and `fromDomain(...)`.
- Repository implementations are persistence gateways only — no business rules. Catch backend/IO
  exceptions at the data layer and map them to `Left(DomainFailure(...))`.

### Error handling
- Never throw exceptions for business-rule failures; return `Either<DomainFailure, T>` (`fpdart`).
- Define failures centrally per feature in `{feature}_failures.dart` as named constants with
  `{Aggregate}.{Invariant}` codes; chain `Either` operations with `flatMap`/`fold`.

### Use cases
- Add a `UseCase` only for genuinely complex operations (2+ repositories or multi-step workflows).
  For simple pass-through calls, invoke the repository directly from the ViewModel.
