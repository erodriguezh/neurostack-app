# Flutter Unit Testing: Core Rules

> Composable with: `01-TEST-FACTORIES.md`, `02-TEST-CONSTANTS.md`, `03-PARAMETERIZED-TESTS.md`, `04-RESULT-ASSERTIONS.md`

---

## Project Structure

```sh
my_app/
├── lib/
│   ├── domain/
│   │   └── {aggregate}/
│   │       ├── {aggregate}.dart
│   │       └── {aggregate}_errors.dart
│   └── services/
└── test/
    ├── domain/
    │   └── {aggregate}/
    │       └── {aggregate}_test.dart
    ├── factories/                    # One factory per domain entity
    │   ├── {entity}_factory.dart
    │   └── factories.dart            # Barrel export
    ├── constants/
    │   └── test_constants.dart
    └── matchers/                     # Custom test matchers
        └── result_matchers.dart
```

**Rules:**

- Test files **must** end with `_test.dart`
- Mirror `lib/` structure in `test/` for domain/service tests
- Factories and constants are **shared** infrastructure—not mirrored

---

## Test Naming

**Pattern:** `{method}_{scenario}_{expectedResult}`

```dart
// ✅ GOOD - describes exact behavior
test('addRoom_whenAtMaxCapacity_returnsRoomLimitError', () {});
test('cancelReservation_whenTooCloseToSession_returnsCancellationError', () {});
test('fetchUser_whenApiReturns200_returnsUser', () {});

// ❌ BAD - vague or missing context
test('test1', () {});
test('addRoom works', () {});
test('should fail', () {});
```

---

## Arrange-Act-Assert (Strict)

Maintain **visual separation** with blank lines. No exceptions.

```dart
test('addRoom_whenAtMaxCapacity_returnsRoomLimitError', () {
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

**Violations:**

```dart
// ❌ BAD - no separation, mixed concerns
test('addRoom fails at capacity', () {
  final gym = GymFactory.createAtCapacity(maxRooms: 1);
  final result = gym.addRoom(RoomFactory.create());
  expect(result.isFailure, true);
  expect(result.error, GymErrors.roomLimitReached);
});
```

---

## Boundary Testing (Mandatory)

**Rule:** Always test at the exact limit, not arbitrary values.

```dart
// ✅ GOOD - tests exact boundary (maxRooms: 1, add 2)
test('addRoom_whenAtMaxCapacity_returnsError', () {
  // Arrange - boundary is 1
  final gym = GymFactory.create(maxRooms: 1);
  final room1 = RoomFactory.create(id: 'room-1');
  final room2 = RoomFactory.create(id: 'room-2');

  // Act
  final result1 = gym.addRoom(room1);
  final result2 = gym.addRoom(room2);

  // Assert - verify SUCCESS then FAILURE
  expect(result1.isSuccess, true, reason: 'First room should succeed');
  expect(result2.isFailure, true, reason: 'Second room should hit boundary');
  expect(result2.error, GymErrors.roomLimitReached);
});

// ❌ BAD - arbitrary values don't test boundaries
test('addRoom fails eventually', () {
  final gym = GymFactory.create(maxRooms: 5);
  for (var i = 0; i < 10; i++) {
    gym.addRoom(RoomFactory.create(id: 'room-$i'));
  }
  // What are we actually testing? The limit? Some limit?
});
```

**Always verify success before failure** - proves the boundary is exact.

---

## Test Lifecycle

```dart
void main() {
  late MockHttpClient client;
  late UserService service;

  setUpAll(() {
    // One-time setup: mocktail fallbacks, expensive resources
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    // Per-test setup: fresh mocks, fresh state
    client = MockHttpClient();
    service = UserService(client: client);
  });

  tearDown(() {
    // Per-test cleanup (if needed)
  });

  // Tests here...
}
```

**Rules:**

- `setUp()` runs before **each** test—use for mocks and state
- `setUpAll()` runs **once**—use for expensive setup, fallback values
- Never stub in mock constructors; always stub in `setUp()` or test body

---

## Grouping Tests

Group by **method under test**, then by **scenario category**:

```dart
group('Gym', () {
  group('addRoom', () {
    test('addRoom_whenUnderCapacity_succeeds', () {});
    test('addRoom_whenAtCapacity_returnsError', () {});
    test('addRoom_whenDuplicateId_returnsError', () {});
  });

  group('removeRoom', () {
    test('removeRoom_whenRoomExists_succeeds', () {});
    test('removeRoom_whenRoomNotFound_returnsError', () {});
  });
});
```

---

## Async Testing

```dart
// Futures - use async/await
test('fetchUser_whenApiSucceeds_returnsUser', () async {
  when(() => client.get(any())).thenAnswer(
    (_) async => Response('{"name":"Test"}', 200),
  );

  final user = await service.fetchUser(1);

  expect(user.name, 'Test');
});

// Errors - use throwsA with type matcher
test('fetchUser_whenApiReturns404_throwsNotFoundException', () {
  when(() => client.get(any())).thenAnswer(
    (_) async => Response('', 404),
  );

  expect(
    () => service.fetchUser(1),
    throwsA(isA<NotFoundException>()),
  );
});

// Streams - use emitsInOrder
test('counterStream_emitsSequence', () {
  expect(
    counterStream,
    emitsInOrder([1, 2, 3, emitsDone]),
  );
});

// Time control - use fakeAsync (NEVER real delays)
test('search_debounces500ms', () {
  fakeAsync((async) {
    controller.query = 'test';

    async.elapse(Duration(milliseconds: 499));
    expect(searchCount, 0, reason: 'Should not search before debounce');

    async.elapse(Duration(milliseconds: 1));
    expect(searchCount, 1, reason: 'Should search after debounce');
  });
});
```

---

## Common Assertions

```dart
// Values
expect(value, equals(42));
expect(value, isNull);
expect(value, isNotNull);

// Collections
expect(list, isEmpty);
expect(list, hasLength(3));
expect(list, contains('item'));

// Types with property checks
expect(
  user,
  isA<User>()
    .having((u) => u.name, 'name', 'Alice')
    .having((u) => u.age, 'age', greaterThan(18)),
);

// Combined matchers
expect(value, allOf([isNotNull, greaterThan(0), lessThan(100)]));
```

---

## Mocking with Mocktail

```dart
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient client;
  late UserService service;

  setUp(() {
    client = MockHttpClient();
    service = UserService(client: client);
  });

  test('fetchUser_callsCorrectEndpoint', () async {
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response('{"name":"Test"}', 200),
    );

    await service.fetchUser(42);

    verify(() => client.get(Uri.parse('/users/42'))).called(1);
  });
}
```

**Rule:** Stub in `setUp()` or test body—never in mock class constructor.

---

## Pitfalls (Hard Rules)

| ❌ Never | ✅ Always |
|----------|-----------|
| `await Future.delayed(...)` in tests | Use `fakeAsync` |
| Shared mutable state between tests | Reset in `setUp()` |
| Missing `pump()` after interaction | `pump()` after every `tap()`, `enterText()` |
| Stubbing in mock constructor | Stub in `setUp()` or test body |
| Arbitrary test values | Boundary values |
| Generic exception checks | Specific error type/code checks |

---

## Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
  mocktail: ^1.0.0
  fake_async: ^1.3.0
```

---

## Checklist

- [ ] Name follows `{method}_{scenario}_{expectedResult}`
- [ ] AAA sections visually separated
- [ ] Tests at exact boundaries, not arbitrary values
- [ ] Success verified before failure (boundary tests)
- [ ] No real delays—uses `fakeAsync`
- [ ] Specific error types asserted
- [ ] No shared mutable state
- [ ] `pump()` after interactions (widget tests)
