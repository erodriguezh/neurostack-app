# Flutter Unit Testing: Test Factory Pattern

> Depends on: `02-TEST-CONSTANTS.md`
> Used by: All domain/service tests

---

## Problem

Inline object construction in tests creates:

1. **Magic values** - What does `Room('r-1', 'Test', 5, 'Main', 2)` mean?
2. **Maintenance burden** - Changing `Room` constructor signature breaks 50 tests
3. **Obscured intent** - Which parameters does this test actually care about?

---

## Solution: One Factory Per Domain Entity

```sh
test/
└── factories/
    ├── factories.dart          # Barrel export
    ├── gym_factory.dart
    ├── room_factory.dart
    ├── session_factory.dart
    └── participant_factory.dart
```

---

## Factory Template

```dart
// test/factories/gym_factory.dart
import 'package:my_app/domain/gym/gym.dart';
import '../constants/test_constants.dart';

abstract final class GymFactory {
  /// Creates a Gym with sensible defaults.
  /// Override only parameters relevant to your test.
  static Gym create({
    String? id,
    String name = TestConstants.gym.name,
    int maxRooms = TestConstants.subscription.maxRoomsFreeTier,
    String subscriptionId = TestConstants.subscription.id,
  }) {
    return Gym(
      id: id ?? TestConstants.gym.id,
      name: name,
      maxRooms: maxRooms,
      subscriptionId: subscriptionId,
    );
  }

  /// Creates a Gym already at room capacity.
  /// Use for boundary tests.
  static Gym createAtCapacity({int maxRooms = 1}) {
    final gym = create(maxRooms: maxRooms);
    for (var i = 0; i < maxRooms; i++) {
      gym.addRoom(RoomFactory.create(id: 'room-$i'));
    }
    return gym;
  }

  /// Creates a Gym with specific rooms pre-added.
  static Gym createWithRooms(List<Room> rooms, {int? maxRooms}) {
    final gym = create(maxRooms: maxRooms ?? rooms.length + 1);
    for (final room in rooms) {
      gym.addRoom(room);
    }
    return gym;
  }
}
```

---

## Factory Design Rules

| Rule | Rationale |
|------|-----------|
| All parameters optional | Tests override only what matters |
| Use `TestConstants` for defaults | Consistency; documents domain |
| Nullable ID pattern `String? id` | Allows unique IDs for collections |
| Return **real** domain objects | Never mocks for domain entities |
| `abstract final class` | Prevents instantiation; groups static methods |
| Helper factories for common states | `createAtCapacity`, `createWithRooms` |

---

## Before/After Comparison

### ❌ Before: Inline Construction

```dart
test('addRoom_whenAtMaxCapacity_returnsError', () {
  // What's important here? What are these values?
  final gym = Gym(
    id: 'gym-123',
    name: 'Test Gym',
    maxRooms: 1,
    subscriptionId: 'sub-456',
  );
  final room = Room(
    id: 'room-789',
    name: 'Conference Room',
    maxSessions: 5,
  );

  gym.addRoom(room);
  final result = gym.addRoom(Room(
    id: 'room-xyz',
    name: 'Another Room',
    maxSessions: 3,
  ));

  expect(result.isFailure, true);
});
```

**Problems:**

- 15+ lines of boilerplate
- Intent buried in noise
- Magic strings everywhere
- Brittle to constructor changes

### ✅ After: Factory Pattern

```dart
test('addRoom_whenAtMaxCapacity_returnsError', () {
  // Arrange
  final gym = GymFactory.createAtCapacity(maxRooms: 1);
  final extraRoom = RoomFactory.create();

  // Act
  final result = gym.addRoom(extraRoom);

  // Assert
  expect(result.isFailure, true);
  expect(result.error, GymErrors.roomLimitReached);
});
```

**Benefits:**

- 6 lines, intent crystal clear
- Only boundary-relevant parameter shown (`maxRooms: 1`)
- Constructor changes require one factory update

---

## Complete Factory Examples

### Room Factory

```dart
// test/factories/room_factory.dart
abstract final class RoomFactory {
  static Room create({
    String? id,
    String name = TestConstants.room.name,
    int maxDailySessions = TestConstants.room.maxDailySessions,
  }) {
    return Room(
      id: id ?? TestConstants.room.id,
      name: name,
      maxDailySessions: maxDailySessions,
    );
  }

  static Room createAtSessionCapacity({int maxDailySessions = 1}) {
    final room = create(maxDailySessions: maxDailySessions);
    for (var i = 0; i < maxDailySessions; i++) {
      room.scheduleSession(SessionFactory.create(id: 'session-$i'));
    }
    return room;
  }
}
```

### Session Factory

```dart
// test/factories/session_factory.dart
abstract final class SessionFactory {
  static Session create({
    String? id,
    String name = TestConstants.session.name,
    DateTime? date,
    TimeRange? timeRange,
    int maxParticipants = TestConstants.session.maxParticipants,
  }) {
    return Session(
      id: id ?? TestConstants.session.id,
      name: name,
      date: date ?? TestConstants.session.defaultDate,
      timeRange: timeRange ?? TestConstants.session.defaultTimeRange,
      maxParticipants: maxParticipants,
    );
  }

  static Session createAtParticipantCapacity({int maxParticipants = 1}) {
    final session = create(maxParticipants: maxParticipants);
    for (var i = 0; i < maxParticipants; i++) {
      session.addParticipant(ParticipantFactory.create(id: 'participant-$i'));
    }
    return session;
  }

  /// Creates a session at a specific time range (for overlap tests).
  static Session createAtTime(int startHour, int endHour, {String? id}) {
    return create(
      id: id,
      timeRange: TimeRangeFactory.fromHours(startHour, endHour),
    );
  }
}
```

### Participant Factory

```dart
// test/factories/participant_factory.dart
abstract final class ParticipantFactory {
  static Participant create({
    String? id,
    String name = TestConstants.participant.name,
    String email = TestConstants.participant.email,
  }) {
    return Participant(
      id: id ?? TestConstants.participant.id,
      name: name,
      email: email,
    );
  }
}
```

---

## Value Object Factories

For complex value objects, create utility factories:

```dart
// test/factories/time_range_factory.dart
abstract final class TimeRangeFactory {
  static TimeRange fromHours(int startHour, int endHour) {
    assert(startHour >= 0 && startHour <= 23);
    assert(endHour > startHour && endHour <= 24);

    return TimeRange(
      start: TimeOfDay(hour: startHour, minute: 0),
      end: TimeOfDay(hour: endHour, minute: 0),
    );
  }

  static TimeRange get morning => fromHours(8, 12);
  static TimeRange get afternoon => fromHours(13, 17);
  static TimeRange get evening => fromHours(18, 21);
}
```

---

## Barrel Export

```dart
// test/factories/factories.dart
export 'gym_factory.dart';
export 'room_factory.dart';
export 'session_factory.dart';
export 'participant_factory.dart';
export 'time_range_factory.dart';
```

**Usage in tests:**

```dart
import '../factories/factories.dart';
```

---

## When to Create a Factory

| Create Factory When | Skip Factory When |
|---------------------|-------------------|
| Entity appears in 3+ tests | One-off test helper |
| Constructor has 4+ parameters | Simple 1-2 param constructor |
| Entity has boundary states | No state variations tested |
| Multiple tests need same "prepared" state | Test is self-contained |

---

## Anti-Patterns

### ❌ Mocking Domain Entities

```dart
// NEVER do this
class MockGym extends Mock implements Gym {}

test('bad test', () {
  final gym = MockGym();
  when(() => gym.hasCapacity).thenReturn(false);
  // Testing mock behavior, not domain logic
});
```

**Why:** You're testing mock behavior, not your actual domain logic.

### ❌ Factories That Return Mocks

```dart
// NEVER do this
abstract final class GymFactory {
  static Gym create() {
    final mock = MockGym();
    when(() => mock.id).thenReturn('gym-1');
    return mock;
  }
}
```

**Why:** Defeats the purpose; domain logic untested.

### ❌ Factories With Required Parameters

```dart
// Avoid - defeats the purpose
static Gym create({
  required String id,       // Should have default
  required String name,     // Should have default
  int maxRooms = 3,
}) { ... }
```

**Why:** Tests should override only what matters.

---

## Checklist

- [ ] One factory per domain entity
- [ ] All parameters optional with defaults from `TestConstants`
- [ ] Nullable ID pattern for collection uniqueness
- [ ] Helper methods for common states (`createAtCapacity`)
- [ ] Returns real domain objects, never mocks
- [ ] Barrel export for clean imports
