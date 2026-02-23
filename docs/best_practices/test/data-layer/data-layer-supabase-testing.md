# Supabase Data Layer Testing

> Composable with: `00-flutter-testing-core.md`, `01-test-factories.md`, `02-test-constants.md`, `03-parameterized-tests.md`, `04-result-assertions.md`
> Extensions: `06-dto-factories.md`, `07-either-matchers.md`

---

## Scope

```sh
Unit Tests (this guide)
├── Repositories (mock Feature Data Sources)
├── DTOs (toDomain, fromJson)
└── Error Mapping (PostgrestException → DomainFailure)
```

**Rule:** Mock at the data source boundary, not the Supabase client.

---

## Project Structure

```sh
test/
├── constants/
│   └── test_constants.dart
├── factories/
│   └── dtos/
│       └── session_dto_factory.dart
├── helpers/
│   └── string_helpers.dart
├── matchers/
│   └── either_matchers.dart
├── mocks/
│   └── data_source_mocks.dart
└── features/
    └── {feature}/
        └── data/
            ├── dtos/{feature}_dto_test.dart
            └── repositories/{feature}_repository_impl_test.dart
```

---

## Test Constants

Extend `02-test-constants.md` with data layer specifics.

```dart
// test/constants/test_constants.dart
abstract final class TestConstants {
  static const dto = _Dto();
  static const postgrest = _Postgrest();
}

final class _Dto {
  const _Dto();
  final String defaultRoomId = 'room-test-001';
  final String defaultUserId = 'user-test-001';
  final String validIsoDateTime = '2025-01-15T10:00:00Z';
  final String invalidDateTime = 'not-a-date';
}

final class _Postgrest {
  const _Postgrest();
  final String notFound = 'PGRST116';
  final String uniqueViolation = '23505';
  final String foreignKeyViolation = '23503';
  final String rlsViolation = '42501';
  final String connectionFailed = 'PGRST301';
}
```

---

## Error Mapping Tests (Parameterized)

```dart
group('mapPostgrestError', () {
  final errorCases = [
    (code: TestConstants.postgrest.notFound, expected: 'NotFound'),
    (code: TestConstants.postgrest.uniqueViolation, expected: 'DuplicateRecord'),
    (code: TestConstants.postgrest.foreignKeyViolation, expected: 'InvalidReference'),
    (code: TestConstants.postgrest.rlsViolation, expected: 'PermissionDenied'),
    (code: TestConstants.postgrest.connectionFailed, expected: 'ConnectionFailed'),
  ];

  for (final c in errorCases) {
    test('mapPostgrestError_when${c.expected}_returnsCorrectCode', () {
      // Arrange
      final error = PostgrestException(code: c.code, message: 'test');

      // Act
      final failure = mapPostgrestError('Session', error);

      // Assert
      expect(failure.code, 'Session.${c.expected}');
    });
  }
});
```

---

## Repository Tests

```dart
void main() {
  late MockSessionRemoteDataSource mockDataSource;
  late SessionRepositoryImpl sut;

  setUp(() {
    mockDataSource = MockSessionRemoteDataSource();
    sut = SessionRepositoryImpl(mockDataSource);
  });

  group('getById', () {
    test('getById_whenDataSourceSucceeds_returnsSession', () async {
      // Arrange
      final dto = SessionDtoFactory.create(id: 'session-123');
      when(() => mockDataSource.getSession('session-123'))
          .thenAnswer((_) async => dto);

      // Act
      final result = await sut.getById('session-123');

      // Assert
      expect(result, isRight<DomainFailure, Session>());
    });

    test('getById_whenRowNotFound_returnsNotFoundFailure', () async {
      // Arrange
      when(() => mockDataSource.getSession(any())).thenThrow(
        PostgrestException(code: TestConstants.postgrest.notFound, message: ''),
      );

      // Act
      final result = await sut.getById('missing');

      // Assert
      expect(result, isLeftWithCode<Session>('Session.NotFound'));
    });
  });
}
```

---

## DTO Tests

```dart
group('SessionDto.toDomain', () {
  test('toDomain_whenValid_returnsSession', () {
    final dto = SessionDtoFactory.create();
    expect(dto.toDomain(), isRight<DomainFailure, Session>());
  });

  test('toDomain_whenInvalidDateTime_returnsParsingFailure', () {
    final dto = SessionDtoFactory.createWithInvalidDateTime();
    expect(dto.toDomain(), isLeftWithCode<Session>('Session.InvalidDateTime'));
  });
});

group('SessionDto.fromJson', () {
  final requiredFields = ['id', 'room_id', 'starts_at'];

  for (final field in requiredFields) {
    test('fromJson_whenMissing$field_throws', () {
      final json = SessionDtoFactory.createJsonMissingField(field);
      expect(() => SessionDto.fromJson(json), throwsA(isA<TypeError>()));
    });
  }
});
```

---

## Boundary Tests

```dart
group('pagination boundaries', () {
  test('list_whenAtPageLimit_succeeds', () async {
    // Arrange
    final dtos = List.generate(100, (i) => SessionDtoFactory.create(id: 'session-$i'));
    when(() => mockDataSource.getSessions(limit: 100)).thenAnswer((_) async => dtos);

    // Act
    final result = await sut.list(limit: 100);

    // Assert - success at boundary
    expect(result.isRight(), true, reason: 'Should succeed at limit');
  });

  test('list_whenOverPageLimit_returnsLimitExceeded', () async {
    // Arrange
    when(() => mockDataSource.getSessions(limit: 101)).thenThrow(
      PostgrestException(code: 'PGRST103', message: 'Limit exceeded'),
    );

    // Act
    final result = await sut.list(limit: 101);

    // Assert - failure over boundary
    expect(result, isLeftWithCode<List<Session>>('Session.LimitExceeded'));
  });
});
```

---

## Checklist

- [ ] DTO factories: `createInvalid`, `createAtCapacity`, `createJsonMissingField` (see `06-dto-factories.md`)
- [ ] Error tests use parameterized pattern
- [ ] `TestConstants` includes `dto` and `postgrest` sections
- [ ] Either matchers show failure details (see `07-either-matchers.md`)
- [ ] Tests follow `{method}_{scenario}_{result}` naming
- [ ] AAA sections separated by blank lines
- [ ] Boundary tests verify success before failure
- [ ] Mock at data source level, not query builder
