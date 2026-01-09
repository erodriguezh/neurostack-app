# Either Matchers (fpdart)

> Extends: `04-result-assertions.md`
> Used by: `data-layer-supabase-testing.md`

---

## Problem

Basic Either checks lack context on failure:

```dart
// ❌ Failure message: "Expected: true, Actual: false"
expect(result.isRight(), true);

// ❌ Verbose, loses context
result.fold(
  (f) => expect(f.code, 'Session.NotFound'),
  (_) => fail('Expected Left'),
);
```

---

## Solution

```dart
// test/matchers/either_matchers.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

Matcher isRight<L, R>() => _IsRight<L, R>();
Matcher isLeft<L, R>() => _IsLeft<L, R>();
Matcher isLeftWithCode<R>(String code) => _IsLeftWithCode<R>(code);
Matcher isRightWith<L, R>(R expected) => _IsRightWith<L, R>(expected);

class _IsRight<L, R> extends Matcher {
  @override
  bool matches(Object? item, Map matchState) =>
      item is Either<L, R> && item.isRight();

  @override
  Description describe(Description d) => d.add('is Right');

  @override
  Description describeMismatch(Object? item, Description d, Map m, bool v) {
    if (item is Either<DomainFailure, R>) {
      return item.fold(
        (f) => d.add('is Left: [${f.code}] ${f.message}'),
        (_) => d.add('is Right'),
      );
    }
    return d.add('is not an Either');
  }
}

class _IsLeft<L, R> extends Matcher {
  @override
  bool matches(Object? item, Map matchState) =>
      item is Either<L, R> && item.isLeft();

  @override
  Description describe(Description d) => d.add('is Left');
}

class _IsLeftWithCode<R> extends Matcher {
  const _IsLeftWithCode(this.expectedCode);
  final String expectedCode;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is Either<DomainFailure, R>) {
      return item.fold((f) => f.code == expectedCode, (_) => false);
    }
    return false;
  }

  @override
  Description describe(Description d) =>
      d.add('is Left with code "$expectedCode"');

  @override
  Description describeMismatch(Object? item, Description d, Map m, bool v) {
    if (item is Either<DomainFailure, R>) {
      return item.fold(
        (f) => d.add('is Left: [${f.code}] ${f.message}'),
        (r) => d.add('is Right: $r'),
      );
    }
    return d.add('is not an Either');
  }
}

class _IsRightWith<L, R> extends Matcher {
  const _IsRightWith(this.expected);
  final R expected;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is Either<L, R>) {
      return item.fold((_) => false, (r) => r == expected);
    }
    return false;
  }

  @override
  Description describe(Description d) => d.add('is Right with $expected');
}
```

---

## Usage

```dart
import '../matchers/either_matchers.dart';

// Basic checks
expect(result, isRight<DomainFailure, Session>());
expect(result, isLeft<DomainFailure, Session>());

// Specific failure code
expect(result, isLeftWithCode<Session>('Session.NotFound'));
// Failure: Expected: is Left with code "Session.NotFound"
//          Actual: is Left: [Session.PermissionDenied] RLS policy blocked

// Specific success value
expect(result, isRightWith<DomainFailure, Session>(expectedSession));
```

---

## Matcher Selection

| Matcher | Use When |
|---------|----------|
| `isRight()` | Only care that it succeeded |
| `isRightWith(value)` | Need exact return value |
| `isLeft()` | Only care that it failed |
| `isLeftWithCode(code)` | Need specific error type |

---

## Integration with DomainFailure

Matchers assume `DomainFailure` has `code` and `message`:

```dart
// lib/core/errors/domain_failure.dart
class DomainFailure {
  const DomainFailure({required this.code, required this.message});
  final String code;
  final String message;
}
```

Adjust matcher types if using different failure class.
