# Flutter Testing Rules Index

## Rule Files

| File | Purpose | When to Read |
|------|---------|--------------|
| [00-FLUTTER-TESTING-CORE.md](00-FLUTTER-TESTING-CORE.md) | Core patterns: naming, AAA, boundaries, lifecycle | **Always** - foundational |
| [01-TEST-FACTORIES.md](01-TEST-FACTORIES.md) | Factory pattern for domain entities | Writing domain/service tests |
| [02-TEST-CONSTANTS.md](02-TEST-CONSTANTS.md) | Centralized test data management | Setting up test infrastructure |
| [03-PARAMETERIZED-TESTS.md](03-PARAMETERIZED-TESTS.md) | DRY testing for edge cases | Testing validation, boundaries |
| [04-RESULT-ASSERTIONS.md](04-RESULT-ASSERTIONS.md) | Domain error assertions | Using Result/Either types |
| [05-WIDGET-TESTS.md](05-WIDGET-TESTS.md) | Widget testing patterns | UI testing |

## Quick Reference

### Test Naming

```sh
{method}_{scenario}_{expectedResult}
```

### File Structure

```sh
test/
├── domain/{aggregate}/{aggregate}_test.dart
├── factories/{entity}_factory.dart
├── constants/test_constants.dart
├── helpers/string_helpers.dart
└── matchers/either_matchers.dart
```

### Must-Have Patterns

**Boundary Testing:**

```dart
// Test at exact limit, verify success THEN failure
final result1 = entity.action(item1);
final result2 = entity.action(item2);
expect(result1.isSuccess, true);   // First: success
expect(result2.isFailure, true);   // Then: failure at boundary
```

**Factory Pattern:**

```dart
// Override only what matters
final gym = GymFactory.createAtCapacity(maxRooms: 1);
```

**Specific Error Assertions:**

```dart
expect(result.error, GymErrors.roomLimitReached);  // Not generic Exception
```

## Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
  mocktail: ^1.0.0
  fake_async: ^1.3.0
  bloc_test: ^9.0.0    # If using BLoC
```

## Hard Rules (Never Violate)

1. **Never** use `await Future.delayed()` in tests → use `fakeAsync`
2. **Never** share mutable state between tests → reset in `setUp()`
3. **Never** skip `pump()` after widget interactions
4. **Never** stub mocks in constructors → stub in `setUp()` or test body
5. **Never** use arbitrary values for boundary tests → test at exact limits
6. **Never** assert generic exceptions → assert specific error types/codes

## Adoption Guide

### Existing Project

1. Add `test/factories/` and `test/constants/` directories
2. Create factories for most-tested entities first
3. Refactor tests incrementally (don't big-bang rewrite)
4. Add parameterized tests for validation logic

### New Project

1. Set up directory structure from start
2. Create `TestConstants` before first test
3. Create factory for each domain entity as you add tests
4. Use parameterized tests from day one for edge cases

## Principles (From .NET DDD Analysis)

| Principle | Implementation |
|-----------|----------------|
| Test isolation | Factories with defaults, no shared state |
| Business focus | Test domain invariants, not implementation |
| Readability | AAA pattern, descriptive naming |
| Maintainability | Constants, factories, utility classes |
| Completeness | Boundary testing, parameterized edge cases |
