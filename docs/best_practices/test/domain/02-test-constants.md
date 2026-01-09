# Flutter Unit Testing: Test Constants Pattern

> Used by: `01-TEST-FACTORIES.md`
> Pattern: Dart-idiomatic centralized test data

---

## Problem

Without centralized constants:

1. **Magic values** scattered across test files
2. **Inconsistent test data** - same entity, different values
3. **Undocumented domain relationships** - subscription limits → gym limits
4. **Refactoring pain** - change a default in 20 places

---

## Solution: Typed Constant Classes

```sh
test/
└── constants/
    └── test_constants.dart
```

---

## Structure Template

```dart
// test/constants/test_constants.dart

/// Centralized test constants.
/// Cross-references document domain relationships.
abstract final class TestConstants {
  static const subscription = _Subscription();
  static const gym = _Gym();
  static const room = _Room();
  static const session = _Session();
  static const participant = _Participant();
}

final class _Subscription {
  const _Subscription();

  final String id = 'sub-free-tier-001';
  final int maxRoomsFreeTier = 3;
  final int maxDailySessionsFreeTier = 4;
  final int maxGymsFreeTier = 1;
}

final class _Gym {
  const _Gym();

  final String id = 'gym-001';
  final String name = 'Test Gym';

  // Cross-reference: gym limits derive from subscription
  int get maxRooms => TestConstants.subscription.maxRoomsFreeTier;
}

final class _Room {
  const _Room();

  final String id = 'room-001';
  final String name = 'Test Room';

  // Cross-reference: room limits derive from subscription
  int get maxDailySessions => TestConstants.subscription.maxDailySessionsFreeTier;
}

final class _Session {
  const _Session();

  final String id = 'session-001';
  final String name = 'Yoga Class';
  final int maxParticipants = 10;

  // Dynamic value - use getter for fresh instance each access
  DateTime get defaultDate => DateTime.now().add(const Duration(days: 1));

  TimeRange get defaultTimeRange => TimeRange(
    start: const TimeOfDay(hour: 9, minute: 0),
    end: const TimeOfDay(hour: 10, minute: 0),
  );
}

final class _Participant {
  const _Participant();

  final String id = 'participant-001';
  final String name = 'Test User';
  final String email = 'test@example.com';
}
```

---

## Design Rules

| Type | Use For | Example |
|------|---------|---------|
| `final` field | Static values (strings, ints) | `final String id = 'gym-001'` |
| Getter | Generated/dynamic values | `DateTime get defaultDate => ...` |
| Cross-reference getter | Domain relationships | `int get maxRooms => TestConstants.subscription.maxRoomsFreeTier` |

---

## Cross-References Document Domain Rules

```dart
final class _Gym {
  const _Gym();

  // This cross-reference IS documentation:
  // "A gym's room limit comes from its subscription tier"
  int get maxRooms => TestConstants.subscription.maxRoomsFreeTier;
}

final class _Room {
  const _Room();

  // This cross-reference IS documentation:
  // "A room's daily session limit comes from the subscription tier"
  int get maxDailySessions => TestConstants.subscription.maxDailySessionsFreeTier;
}
```

**Benefit:** When reading tests, cross-references explain *why* limits exist.

---

## Usage in Factories

```dart
// test/factories/gym_factory.dart
import '../constants/test_constants.dart';

abstract final class GymFactory {
  static Gym create({
    String? id,
    String name = TestConstants.gym.name,          // Use constant
    int maxRooms = TestConstants.gym.maxRooms,     // Uses cross-reference
    String subscriptionId = TestConstants.subscription.id,
  }) {
    return Gym(
      id: id ?? TestConstants.gym.id,              // Nullable pattern
      name: name,
      maxRooms: maxRooms,
      subscriptionId: subscriptionId,
    );
  }
}
```

---

## Usage in Tests

```dart
test('gym_respects_subscription_room_limit', () {
  // Arrange - intent clear: testing subscription constraint
  final gym = GymFactory.create(
    maxRooms: TestConstants.subscription.maxRoomsFreeTier,
  );

  // Fill to capacity
  for (var i = 0; i < TestConstants.subscription.maxRoomsFreeTier; i++) {
    gym.addRoom(RoomFactory.create(id: 'room-$i'));
  }

  // Act
  final result = gym.addRoom(RoomFactory.create(id: 'extra'));

  // Assert
  expect(result.isFailure, true);
  expect(result.error, GymErrors.roomLimitReached);
});
```

---

## Before/After Comparison

### ❌ Before: Magic Values

```dart
test('gym cannot exceed room limit', () {
  final gym = Gym(
    id: 'gym-123',           // What is this?
    name: 'My Gym',          // Arbitrary
    maxRooms: 3,             // Why 3? What does it represent?
    subscriptionId: 'sub-1', // Random
  );

  for (var i = 0; i < 3; i++) {  // Why 3 again?
    gym.addRoom(Room(id: 'r-$i', name: 'Room', maxSessions: 5));
  }

  final result = gym.addRoom(Room(id: 'r-extra', name: 'Extra', maxSessions: 5));
  expect(result.isFailure, true);
});
```

**Problems:**

- `3` appears twice with no explanation
- No indication this tests a subscription constraint
- Magic strings obscure intent

### ✅ After: Named Constants

```dart
test('gym_respects_subscription_room_limit', () {
  // Arrange
  final gym = GymFactory.create(
    maxRooms: TestConstants.subscription.maxRoomsFreeTier,  // Self-documenting
  );

  for (var i = 0; i < TestConstants.subscription.maxRoomsFreeTier; i++) {
    gym.addRoom(RoomFactory.create(id: 'room-$i'));
  }

  // Act
  final result = gym.addRoom(RoomFactory.create());

  // Assert
  expect(result.isFailure, true);
  expect(result.error, GymErrors.roomLimitReached);
});
```

**Benefits:**

- `maxRoomsFreeTier` explains the constraint
- Cross-reference documents domain relationship
- Refactoring changes one place

---

## Dynamic Values Pattern

For values that must be unique per access:

```dart
final class _Session {
  const _Session();

  // ❌ BAD - same ID reused (causes conflicts in collection tests)
  final String id = Uuid().v4();  // Generated once at class load

  // ✅ GOOD - getter creates fresh value each access
  String get uniqueId => const Uuid().v4();

  // For dates that must be "in the future"
  DateTime get defaultDate => DateTime.now().add(const Duration(days: 1));

  // For stable test data, use fixed values
  final String id = 'session-001';  // Use with factory's nullable pattern
}
```

**Usage in factory:**

```dart
static Session create({
  String? id,  // Null = use constant, non-null = caller's value
  ...
}) {
  return Session(
    id: id ?? TestConstants.session.id,  // Default or unique
    ...
  );
}
```

---

## Domain Error Constants

Include error types for assertion clarity:

```dart
// In your domain layer (not test constants)
// lib/domain/gym/gym_errors.dart
abstract final class GymErrors {
  static const roomLimitReached = 'GYM_ROOM_LIMIT_REACHED';
  static const roomNotFound = 'GYM_ROOM_NOT_FOUND';
  static const duplicateRoomId = 'GYM_DUPLICATE_ROOM_ID';
}

// Usage in tests - specific, not generic
expect(result.error, GymErrors.roomLimitReached);
```

---

## Anti-Patterns

### ❌ Scattered Constants

```dart
// test/gym/gym_test.dart
const testGymId = 'gym-1';
const testGymName = 'Test';

// test/room/room_test.dart
const gymId = 'gym-test';      // Different!
const gymName = 'Test Gym';    // Different!
```

### ❌ Untyped Maps

```dart
// Hard to discover, no autocomplete, no type safety
const testData = {
  'gym': {'id': 'gym-1', 'name': 'Test'},
  'room': {'id': 'room-1', 'maxSessions': 5},
};
```

### ❌ Generated Values as Fields

```dart
final class _Session {
  const _Session();

  // BAD - executes once at load, same value forever
  final String id = const Uuid().v4();
  final DateTime date = DateTime.now();
}
```

---

## Checklist

- [ ] Single `test_constants.dart` file
- [ ] Typed classes with `final class` (Dart 3)
- [ ] Cross-references document domain relationships
- [ ] Getters for dynamic values (dates, UUIDs)
- [ ] Fixed values for stable test data
- [ ] Used by factories, not duplicated in tests
