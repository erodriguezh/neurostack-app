# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run                              # Select platform interactively
flutter run -d chrome                    # Run on web
flutter run --dart-define-from-file=env/env.json  # Run with env config

# Code generation (freezed, json_serializable)
flutter pub run build_runner build       # One-time build
flutter pub run build_runner watch       # Watch mode

# Testing
flutter test                             # Run all tests
flutter test test/domain/user/           # Run specific test directory
flutter test --coverage                  # Generate coverage

# Linting
flutter analyze                          # Static analysis
dart format lib/ test/                   # Format code

# Clean rebuild
flutter clean && flutter pub get
```

## Architecture Overview

**MVVM + Domain-Driven Design** using ValueNotifier state management (no external state management packages).

### Decision Framework

| Condition | Action |
|-----------|--------|
| Simple CRUD with <3 fields | Basic MVVM only |
| Fields need validation | Add Value Objects |
| Multiple repositories involved | Add Use Case |
| Complex business rules | Add Aggregate Root |

### Layer Structure

```
lib/
├── config/                    # locator_config.dart, route_config.dart
├── core/
│   ├── domain/                # EntityMixin, AggregateRootMixin, DomainEvent
│   ├── failures/              # DomainFailure (freezed)
│   ├── ui/constants/          # Design tokens (colors, spacing, text styles)
│   └── utils/
│       ├── data_source/       # DataSourceAbstraction (Supabase wrapper)
│       ├── http/              # HTTP client abstraction
│       ├── navigation/        # RouterService
│       └── locator.dart       # Service locator
├── features/{feature}/
│   ├── domain/                # Entities, value objects, failures, repository interfaces
│   ├── data/                  # DTOs, data sources, repository implementations
│   └── presentation/          # Views, ViewModels, state classes
└── {simple_feature}/          # Flat structure for ≤5 files
```

## Key Patterns

### State Management

- Single `ValueNotifier<T>` per ViewModel (use sealed state class for complex state)
- Expose as `ValueListenable<T>` getter
- Views use `ValueListenableBuilder` with switch expressions

```dart
// ViewModel
final ValueNotifier<SessionDetailState> state = ValueNotifier(const SessionDetailInitial());

// View
return switch (state) {
  SessionDetailInitial() => const SizedBox.shrink(),
  SessionDetailLoading() => const CircularProgressIndicator(),
  SessionDetailLoaded(:final session) => SessionContent(session: session),
  SessionDetailError(:final failure) => ErrorDisplay(failure: failure),
};
```

### Result Types

Uses `fpdart` Either with `flatMap` chaining - never throw exceptions in business logic:

```dart
Either<DomainFailure, Session> result = dto.toDomain();
return result.flatMap((session) => _validateSession(session));
```

### Aggregate Roots

- Use `EntityMixin<T>` and `AggregateRootMixin<T>` mixins (not abstract classes)
- Business logic lives in aggregates, not ViewModels or repositories
- Collections exposed via `UnmodifiableListView`
- Aggregates reference other aggregates by ID only
- One repository per aggregate root

### Error Handling

Naming convention: `{Aggregate}.{Invariant}`

```dart
abstract class SessionFailures {
  static const capacityExceeded = DomainFailure(
    code: 'Session.CapacityExceeded',
    message: 'Cannot have more reservations than capacity allows',
  );
}
```

### DTOs

- Separate from domain models
- Use `@JsonKey(name: 'snake_case')` for Supabase column mapping
- `toDomain()` returns `Either<DomainFailure, T>`, uses `flatMap` chaining
- `fromDomain(T)` static factory for serialization

### Data Sources

- `DataSourceAbstraction` wraps `SupabaseClient` for testability
- Feature data sources return DTOs, not raw JSON
- Repositories catch `PostgrestException` and map to domain failures

## Architecture Rules

1. Views never use services directly - only through ViewModels
2. ViewModels never use other ViewModels - shared logic goes to Services
3. ViewModels have no BuildContext access
4. All dependencies injected through constructors
5. Views call ViewModel's `dispose()` method for cleanup
6. ValueNotifiers disposed in ViewModel's dispose method

## Critical Don'ts

| Anti-Pattern | Solution |
|--------------|----------|
| Abstract class for Entity | Use mixin |
| Public collections | `UnmodifiableListView` |
| Object references between aggregates | Store IDs only |
| Exceptions for business rules | Use Either |
| Multiple ValueNotifiers for state | Single sealed state |
| `throw 'unreachable'` in Either code | Use `flatMap` chaining |
| Use Cases for simple calls | Call repository directly |
| Repository per entity | Only aggregate roots get repositories |
| Business logic in repository | Validate in domain layer |
| Freezed for simple enums | Enhanced Dart enums |

## Testing

Test files mirror `lib/` structure in `test/`.

**Custom matchers** in `test/matchers/`:
- `isRightWith<R>(expected)` - Success with value
- `isLeftWith(failure)` - Failure with error

**Test factories** in `test/factories/` for domain objects.

**Naming:** `{method}_{scenario}_{expectedResult}`

**Pattern:** Arrange-Act-Assert. Widget tests use real ViewModels (no mocking).

## Environment Setup

Copy `env/default.env.json` to `env/env.json` and fill with Supabase config values.

## Key Technologies

- Flutter 3.32.0, Dart ^3.8.0
- Supabase (backend)
- fpdart (Either/Result types)
- freezed (immutable classes, sealed unions - but use enhanced enums for simple cases)
- mocktail (testing)
