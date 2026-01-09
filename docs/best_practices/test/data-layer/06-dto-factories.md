# DTO Test Factories

> Extends: `01-test-factories.md`
> Used by: `data-layer-supabase-testing.md`

---

## Problem

Domain factories create entities. Data layer needs factories for:

- DTOs with parsing edge cases
- JSON maps with missing/malformed fields
- State variations for toDomain failures

---

## Template

```dart
// test/factories/dtos/{entity}_dto_factory.dart
abstract final class SessionDtoFactory {
  /// Valid DTO. Override only what matters.
  static SessionDto create({
    String? id,
    String? roomId,
    String startsAt = '2025-01-15T10:00:00Z',
    int maxParticipants = 10,
    List<ReservationDto>? reservations,
  }) {
    return SessionDto(
      id: id ?? 'session-${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId ?? TestConstants.dto.defaultRoomId,
      trainerId: TestConstants.dto.defaultTrainerId,
      startsAt: startsAt,
      maxParticipants: maxParticipants,
      reservations: reservations ?? [],
    );
  }

  // --- State Variations ---

  /// Fails toDomain() - invalid datetime.
  static SessionDto createWithInvalidDateTime() =>
      create(startsAt: TestConstants.dto.invalidDateTime);

  /// At capacity (boundary tests).
  static SessionDto createAtCapacity({int maxParticipants = 1}) {
    return create(
      maxParticipants: maxParticipants,
      reservations: List.generate(
        maxParticipants,
        (i) => ReservationDtoFactory.create(id: 'res-$i'),
      ),
    );
  }

  // --- JSON Variations ---

  /// Valid JSON map.
  static Map<String, dynamic> createValidJson({String? id}) => {
    'id': id ?? 'session-json-001',
    'room_id': TestConstants.dto.defaultRoomId,
    'trainer_id': TestConstants.dto.defaultTrainerId,
    'starts_at': TestConstants.dto.validIsoDateTime,
    'max_participants': 10,
    'reservations': <Map<String, dynamic>>[],
  };

  /// JSON missing required field.
  static Map<String, dynamic> createJsonMissingField(String field) {
    final json = createValidJson();
    json.remove(field);
    return json;
  }

  /// JSON with wrong type.
  static Map<String, dynamic> createJsonWithWrongType(String field, Object value) {
    final json = createValidJson();
    json[field] = value;
    return json;
  }
}
```

---

## State Variations by Error Type

| Method | Triggers | Use Case |
|--------|----------|----------|
| `createWithInvalidDateTime()` | `toDomain()` parsing failure | DateTime format validation |
| `createWithInvalidEmail()` | `toDomain()` parsing failure | Email format validation |
| `createAtCapacity()` | Boundary condition | Capacity limits |
| `createJsonMissingField(field)` | `fromJson()` null error | Required field validation |
| `createJsonWithWrongType(field, value)` | `fromJson()` type error | Type coercion tests |

---

## Usage

```dart
// DTO parsing failure
test('toDomain_whenInvalidDateTime_fails', () {
  final dto = SessionDtoFactory.createWithInvalidDateTime();
  expect(dto.toDomain(), isLeftWithCode<Session>('Session.InvalidDateTime'));
});

// JSON missing field (parameterized)
final requiredFields = ['id', 'room_id', 'starts_at'];

for (final field in requiredFields) {
  test('fromJson_whenMissing$field_throws', () {
    final json = SessionDtoFactory.createJsonMissingField(field);
    expect(() => SessionDto.fromJson(json), throwsA(isA<TypeError>()));
  });
}

// Boundary test
test('bookSession_whenAtCapacity_fails', () {
  final dto = SessionDtoFactory.createAtCapacity(maxParticipants: 10);
  // ... test booking 11th participant
});
```

---

## Barrel Export

```dart
// test/factories/dtos/dtos.dart
export 'session_dto_factory.dart';
export 'protocol_dto_factory.dart';
export 'reservation_dto_factory.dart';
```

---

## Checklist

- [ ] `create()` with all optional params + defaults
- [ ] `createWithInvalid{Field}()` for each parseable field
- [ ] `createAtCapacity()` for boundary tests
- [ ] `createValidJson()` returns snake_case keys
- [ ] `createJsonMissingField()` for required field tests
- [ ] Barrel export in `dtos.dart`
