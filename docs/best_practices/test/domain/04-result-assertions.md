
# Flutter Unit Testing: Result Type Assertions

> Applies to: Projects using Result/Either types (fpdart)
> Skip if: Using exceptions for error handling

---

## Problem

Generic exception checks don't verify *which* business rule failed:

```dart
// ❌ BAD - proves nothing about domain logic
test('addRoom fails at capacity', () {
  expect(
    () => gym.addRoom(room),
    throwsA(isA<Exception>()),  // Any exception passes!
  );
});
```

**Why this fails:** Test passes for `ArgumentError`, `StateError`, wrong domain error—anything.

---

## Solution: Assert Specific Domain Errors

```dart
// ✅ GOOD - verifies exact business rule
test('addRoom_whenAtCapacity_returnsRoomLimitError', () {
  // Arrange
  final gym = GymFactory.createAtCapacity(maxRooms: 1);

  // Act
  final result = gym.addRoom(RoomFactory.create());

  // Assert
  expect(result.isFailure, true);
  expect(result.error, GymErrors.roomLimitReached);  // Specific!
});
```

---

## Result Type Setup

### Define Domain Errors

```dart
// lib/domain/gym/gym_errors.dart
enum GymError {
  roomLimitReached,
  roomNotFound,
  duplicateRoomId,
}

// Or as sealed class for richer errors
sealed class GymError {
  const GymError();
}

final class RoomLimitReached extends GymError {
  const RoomLimitReached(this.limit);
  final int limit;
}

final class RoomNotFound extends GymError {
  const RoomNotFound(this.roomId);
  final String roomId;
}
```

### Define Result Type

```dart
// lib/core/result.dart
sealed class Result<T, E> {
  const Result();
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;
}

final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;
}

// Extension for ergonomic access
extension ResultX<T, E> on Result<T, E> {
  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T get value => (this as Success<T, E>).value;
  E get error => (this as Failure<T, E>).error;

  R fold<R>(R Function(E) onFailure, R Function(T) onSuccess) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }
}
```

---

## Assertion Patterns

### Pattern 1: Direct Property Access

```dart
test('addRoom_whenAtCapacity_returnsRoomLimitError', () {
  // Arrange
  final gym = GymFactory.createAtCapacity(maxRooms: 1);

  // Act
  final result = gym.addRoom(RoomFactory.create());

  // Assert
  expect(result.isFailure, true);
  expect(result.error, GymError.roomLimitReached);
});
```

### Pattern 2: Pattern Matching (Dart 3)

```dart
test('addRoom_whenAtCapacity_returnsRoomLimitError', () {
  // Arrange
  final gym = GymFactory.createAtCapacity(maxRooms: 1);

  // Act
  final result = gym.addRoom(RoomFactory.create());

  // Assert
  expect(
    result,
    isA<Failure<Room, GymError>>()
      .having((f) => f.error, 'error', GymError.roomLimitReached),
  );
});
```

### Pattern 3: Fold with Fail

```dart
test('addRoom_whenAtCapacity_returnsRoomLimitError', () {
  // Arrange
  final gym = GymFactory.createAtCapacity(maxRooms: 1);

  // Act
  final result = gym.addRoom(RoomFactory.create());

  // Assert
  final error = result.fold(
    (e) => e,
    (_) => fail('Expected failure, got success'),
  );
  expect(error, GymError.roomLimitReached);
});
```

---

## Custom Matchers (Recommended)

Create reusable matchers for cleaner assertions:

```dart
// test/matchers/result_matchers.dart
import 'package:test/test.dart';
import 'package:my_app/core/result.dart';

/// Matches a successful Result containing [expected].
Matcher isSuccessWith<T>(T expected) => _IsSuccess<T>(expected);

/// Matches a failed Result containing [expected] error.
Matcher isFailureWith<E>(E expected) => _IsFailure<E>(expected);

/// Matches any successful Result.
Matcher isSuccess<T>() => isA<Success<T, Object?>>();

/// Matches any failed Result.
Matcher isFailure<E>() => isA<Failure<Object?, E>>();

class _IsSuccess<T> extends Matcher {
  const _IsSuccess(this.expected);
  final T expected;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is Success<T, Object?>) {
      return item.value == expected;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('is Success with value $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Failure) {
      return mismatchDescription.add('is Failure with error ${item.error}');
    }
    if (item is Success) {
      return mismatchDescription.add('is Success with value ${item.value}');
    }
    return mismatchDescription.add('is not a Result');
  }
}

class _IsFailure<E> extends Matcher {
  const _IsFailure(this.expected);
  final E expected;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is Failure<Object?, E>) {
      return item.error == expected;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('is Failure with error $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Success) {
      return mismatchDescription.add('is Success with value ${item.value}');
    }
    if (item is Failure) {
      return mismatchDescription.add('is Failure with error ${item.error}');
    }
    return mismatchDescription.add('is not a Result');
  }
}
```

### Usage

```dart
import '../matchers/result_matchers.dart';

test('addRoom_whenAtCapacity_returnsRoomLimitError', () {
  final gym = GymFactory.createAtCapacity(maxRooms: 1);

  final result = gym.addRoom(RoomFactory.create());

  expect(result, isFailureWith(GymError.roomLimitReached));
});

test('addRoom_whenUnderCapacity_succeeds', () {
  final gym = GymFactory.create(maxRooms: 5);
  final room = RoomFactory.create();

  final result = gym.addRoom(room);

  expect(result, isSuccessWith(room));
});
```

---

## Testing Rich Error Types

For sealed class errors with data:

```dart
sealed class BookingError {
  const BookingError();
}

final class SessionFull extends BookingError {
  const SessionFull({required this.maxParticipants});
  final int maxParticipants;
}

final class SessionCancelled extends BookingError {
  const SessionCancelled({required this.cancelledAt});
  final DateTime cancelledAt;
}

// Test with property matching
test('book_whenSessionFull_returnsSessionFullError', () {
  final session = SessionFactory.createAtCapacity(maxParticipants: 10);

  final result = session.book(ParticipantFactory.create());

  expect(result.isFailure, true);
  expect(
    result.error,
    isA<SessionFull>().having((e) => e.maxParticipants, 'maxParticipants', 10),
  );
});
```

---

## Boundary Tests with Results

Verify success THEN failure:

```dart
test('addRoom_whenAtCapacity_returnsError', () {
  // Arrange
  final gym = GymFactory.create(maxRooms: 1);
  final room1 = RoomFactory.create(id: 'room-1');
  final room2 = RoomFactory.create(id: 'room-2');

  // Act
  final result1 = gym.addRoom(room1);
  final result2 = gym.addRoom(room2);

  // Assert - success first
  expect(result1, isSuccessWith(room1));

  // Assert - then failure with specific error
  expect(result2, isFailureWith(GymError.roomLimitReached));
});
```

---

## Using with fpdart

If using `dartz`:

```dart
import 'package:fpdart/fpdart.dart';

test('addRoom_whenAtCapacity_returnsLeft', () {
  final gym = GymFactory.createAtCapacity(maxRooms: 1);

  final result = gym.addRoom(RoomFactory.create());

  expect(result.isLeft(), true);
  expect(
    result.getLeft().toNullable(),
    GymError.roomLimitReached,
  );
});
```

Custom matcher for dartz:

```dart
Matcher isLeft<L>(L expected) => predicate<Either<L, Object?>>(
  (either) => either.match((l) => l == expected, (_) => false),
  'is Left($expected)',
);

Matcher isRight<R>(R expected) => predicate<Either<Object?, R>>(
  (either) => either.match((_) => false, (r) => r == expected),
  'is Right($expected)',
);

// Usage
expect(result, isLeft(GymError.roomLimitReached));
```

---

## When to Use

| Use Result Assertions | Use Exception Assertions |
|----------------------|-------------------------|
| Domain layer with business rules | Infrastructure/IO errors |
| Multiple error types possible | Single failure mode |
| Error codes matter for logic | Caller just needs to catch |
| Using Result/Either pattern | Using throw/catch pattern |

---

## Checklist

- [ ] Domain errors defined as enum or sealed class
- [ ] Result type with `isSuccess`/`isFailure` accessors
- [ ] Custom matchers for clean assertions
- [ ] Specific error type/code verified
- [ ] Success verified before failure (boundary tests)
- [ ] Rich errors tested with `.having()` for properties
