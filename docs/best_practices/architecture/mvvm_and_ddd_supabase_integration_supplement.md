> **Prerequisite:** This guide extends the DDD + MVVM Flutter Best Practices guide. Read that first for domain primitives (EntityMixin, AggregateRootMixin), Value Objects, repository interfaces, and ViewModel patterns. This supplement covers Supabase-specific data layer implementation.

---

## Architecture Position

Supabase components live exclusively in the **Data layer**:

```
Domain Layer (from DDD guide)
├── Repository Interfaces
├── Entities / Aggregates
└── Failures

Data Layer (this supplement)
├── DataSourceAbstraction (client wrapper)
├── Feature Data Sources (return DTOs)
├── DTOs (Freezed + @JsonKey)
└── Repository Implementations
```

---

## 1. Core Data Source Wrapper

Wrap `SupabaseClient` for testability and centralized access.

```dart
// lib/core/utils/data_source/data_source_abstraction.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper enabling dependency injection and mocking.
/// Reference: GitHub issue #864 - no official mocking guide exists.
class DataSourceAbstraction {
  final SupabaseClient _client;

  DataSourceAbstraction(this._client);

  factory DataSourceAbstraction.instance() =>
      DataSourceAbstraction(Supabase.instance.client);

  SupabaseClient get client => _client;
  SupabaseQueryBuilder from(String table) => _client.from(table);
  GoTrueClient get auth => _client.auth;
  SupabaseStorageClient get storage => _client.storage;
  RealtimeClient get realtime => _client.realtime;
}
```

---

## 2. Feature Data Source

Per-feature data source handles table operations and **returns DTOs** (not raw JSON).

```dart
// lib/features/session/data/data_sources/session_remote_data_source.dart
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';

class SessionRemoteDataSource {
  final DataSourceAbstraction _dataSource;

  SessionRemoteDataSource(this._dataSource);

  static const _table = 'sessions';

  /// Returns DTO, not raw JSON. Parsing happens here.
  Future<SessionDto> getSession(String id) async {
    final json = await _dataSource
        .from(_table)
        .select('*, reservations(*)')
        .eq('id', id)
        .single();
    return SessionDto.fromJson(json);
  }

  Future<List<SessionDto>> getSessions({
    String? roomId,
    String? trainerId,
    DateTime? startAfter,
    DateTime? startBefore,
  }) async {
    var query = _dataSource.from(_table).select('*, reservations(*)');

    if (roomId != null) query = query.eq('room_id', roomId);
    if (trainerId != null) query = query.eq('trainer_id', trainerId);
    if (startAfter != null) {
      query = query.gte('starts_at', startAfter.toIso8601String());
    }
    if (startBefore != null) {
      query = query.lte('starts_at', startBefore.toIso8601String());
    }

    final jsonList = await query;
    return jsonList.map((json) => SessionDto.fromJson(json)).toList();
  }

  Future<void> saveSession(SessionDto dto) async {
    await _dataSource.from(_table).upsert(dto.toJson());
  }

  Future<void> deleteSession(String id) async {
    await _dataSource.from(_table).delete().eq('id', id);
  }
}
```

**Key points:**

- Data source returns `SessionDto`, not `Map<String, dynamic>`
- JSON parsing is encapsulated here, not leaked to repository
- Repository only deals with DTOs and domain objects

---

## 3. DTO with @JsonKey Annotations

Supabase uses snake_case columns. Use `@JsonKey` for mapping.

```dart
// lib/features/session/data/dtos/session_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'session_dto.freezed.dart';
part 'session_dto.g.dart';

@freezed
class SessionDto with _$SessionDto {
  const SessionDto._();

  const factory SessionDto({
    required String id,
    @JsonKey(name: 'room_id') required String roomId,
    @JsonKey(name: 'trainer_id') required String trainerId,
    @JsonKey(name: 'starts_at') required String startsAt,
    @JsonKey(name: 'max_participants') required int maxParticipants,
    @Default([]) List<ReservationDto> reservations,
  }) = _SessionDto;

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  /// Use flatMap for chained Either operations
  Either<DomainFailure, Session> toDomain() {
    return _parseDateTime(startsAt).flatMap((parsedStartsAt) {
      return _parseReservations(reservations).flatMap((domainReservations) {
        return Right(Session(
          id: id,
          roomId: roomId,
          trainerId: trainerId,
          startsAt: parsedStartsAt,
          maxParticipants: maxParticipants,
          reservations: domainReservations,
        ));
      });
    });
  }

  Either<DomainFailure, DateTime> _parseDateTime(String value) {
    try {
      return Right(DateTime.parse(value));
    } catch (e) {
      return Left(DomainFailure(
        code: 'Session.InvalidDateTime',
        message: 'Failed to parse datetime: $value',
      ));
    }
  }

  Either<DomainFailure, List<Reservation>> _parseReservations(
    List<ReservationDto> dtos,
  ) {
    final reservations = <Reservation>[];
    for (final dto in dtos) {
      final result = dto.toDomain();
      if (result.isLeft()) return Left(result.getLeft().toNullable()!);
      reservations.add(result.getRight().toNullable()!);
    }
    return Right(reservations);
  }

  static SessionDto fromDomain(Session session) => SessionDto(
        id: session.id,
        roomId: session.roomId,
        trainerId: session.trainerId,
        startsAt: session.startsAt.toIso8601String(),
        maxParticipants: session.maxParticipants,
        reservations: session.reservations
            .map((r) => ReservationDto.fromDomain(r))
            .toList(),
      );
}
```

---

## 4. Repository Implementation

Catches Supabase exceptions and maps to domain failures following **{Aggregate}.{Invariant}** naming.

```dart
// lib/features/session/data/repositories/session_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _dataSource;

  SessionRepositoryImpl(this._dataSource);

  @override
  Future<Either<DomainFailure, Session>> getById(String id) async {
    try {
      final dto = await _dataSource.getSession(id);
      return dto.toDomain();
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestError('Session', e));
    } on AuthException catch (e) {
      return Left(DomainFailure(
        code: 'Session.AuthenticationFailed',
        message: e.message,
      ));
    } catch (e) {
      return Left(DomainFailure(
        code: 'Session.UnexpectedError',
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<DomainFailure, List<Session>>> list({
    String? roomId,
    String? trainerId,
    DateTime? startAfter,
    DateTime? startBefore,
  }) async {
    try {
      final dtos = await _dataSource.getSessions(
        roomId: roomId,
        trainerId: trainerId,
        startAfter: startAfter,
        startBefore: startBefore,
      );

      final sessions = <Session>[];
      for (final dto in dtos) {
        final result = dto.toDomain();
        if (result.isLeft()) return Left(result.getLeft().toNullable()!);
        sessions.add(result.getRight().toNullable()!);
      }
      return Right(sessions);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestError('Session', e));
    } catch (e) {
      return Left(DomainFailure(
        code: 'Session.UnexpectedError',
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<DomainFailure, Unit>> save(Session session) async {
    try {
      final dto = SessionDto.fromDomain(session);
      await _dataSource.saveSession(dto);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestError('Session', e));
    } catch (e) {
      return Left(DomainFailure(
        code: 'Session.UnexpectedError',
        message: e.toString(),
      ));
    }
  }
}
```

---

## 5. Error Mapping (Aggregate-Prefixed)

Map Supabase errors to domain failures using `{Aggregate}.{ErrorType}` convention.

```dart
// lib/core/data/supabase_error_mapper.dart

/// Maps PostgrestException to DomainFailure with aggregate prefix.
/// Common codes from Supabase/PostgreSQL documentation.
DomainFailure _mapPostgrestError(String aggregate, PostgrestException e) {
  return switch (e.code) {
    '23505' => DomainFailure(
        code: '$aggregate.DuplicateRecord',
        message: 'Record already exists',
      ),
    '23503' => DomainFailure(
        code: '$aggregate.InvalidReference',
        message: 'Referenced record does not exist',
      ),
    '42501' => DomainFailure(
        code: '$aggregate.PermissionDenied',
        message: 'Access denied by security policy',
      ),
    'PGRST116' => DomainFailure(
        code: '$aggregate.NotFound',
        message: 'Record not found',
      ),
    'PGRST301' => DomainFailure(
        code: '$aggregate.ConnectionFailed',
        message: 'Database connection failed',
      ),
    _ => DomainFailure(
        code: '$aggregate.DatabaseError',
        message: '${e.code}: ${e.message}',
      ),
  };
}
```

**Note:** The aggregate prefix ensures error codes follow the same `{Aggregate}.{Invariant}` pattern as business rule failures defined in the domain layer.

---

## 6. Manual Dependency Injection

Register Supabase services using the existing `ModuleLocator` pattern.

### 6.1 Add Modules to Configuration

```dart
// lib/config/locator_config.dart
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
// ... other imports

final modules = [
  // Core services
  Module<RouterService>(
    builder: () => RouterService(supportedRoutes: routes),
    lazy: false,
  ),
  Module<NotifyService>(builder: () => NotifyService(), lazy: false),

  // Supabase data source (lazy - created on first use)
  Module<DataSourceAbstraction>(
    builder: () => DataSourceAbstraction.instance(),
    lazy: true,
  ),

  // Feature data sources (lazy - depend on DataSourceAbstraction)
  Module<SessionRemoteDataSource>(
    builder: () => SessionRemoteDataSource(locator<DataSourceAbstraction>()),
    lazy: true,
  ),

  // Repositories (lazy - depend on data sources)
  Module<SessionRepository>(
    builder: () => SessionRepositoryImpl(locator<SessionRemoteDataSource>()),
    lazy: true,
  ),
];
```

**Module registration order doesn't matter**—lazy modules resolve dependencies when first accessed, not at registration time.

### 6.2 Initialize Supabase Before Locator

```dart
// lib/startup/startup_view_model.dart
Future<void> initializeApp() async {
  appStateNotifier.value = const InitializingApp();
  try {
    // Supabase must initialize before locator registration
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );

    locator.registerMany(modules);
    loggingSubscription = _loggingAbstraction.initializeLogging();
    appStateNotifier.value = const AppInitialized();
  } catch (e, st) {
    appStateNotifier.value = AppInitializationError(e, st);
  }
}
```


```

---

## 7. Consolidated ViewModel State

Use a single state object instead of multiple ValueNotifiers to prevent race conditions.

```dart
// lib/features/session/presentation/view_models/session_state.dart
sealed class SessionDetailState {
  const SessionDetailState();
}

class SessionDetailInitial extends SessionDetailState {
  const SessionDetailInitial();
}

class SessionDetailLoading extends SessionDetailState {
  const SessionDetailLoading();
}

class SessionDetailLoaded extends SessionDetailState {
  final Session session;
  const SessionDetailLoaded(this.session);
}

class SessionDetailError extends SessionDetailState {
  final DomainFailure failure;
  const SessionDetailError(this.failure);
}

// lib/features/session/presentation/view_models/session_detail_view_model.dart
class SessionDetailViewModel {
  final SessionRepository _sessionRepository;
  final String _sessionId;

  SessionDetailViewModel({
    required SessionRepository sessionRepository,
    required String sessionId,
  })  : _sessionRepository = sessionRepository,
        _sessionId = sessionId;

  final ValueNotifier<SessionDetailState> state =
      ValueNotifier(const SessionDetailInitial());

  Future<void> load() async {
    state.value = const SessionDetailLoading();

    final result = await _sessionRepository.getById(_sessionId);

    state.value = result.fold(
      (failure) => SessionDetailError(failure),
      (session) => SessionDetailLoaded(session),
    );
  }

  Future<void> cancelReservation(String participantId) async {
    final currentState = state.value;
    if (currentState is! SessionDetailLoaded) return;

    final session = currentState.session;
    final result = session.cancelReservation(participantId, DateTime.now());

    await result.fold(
      (failure) async => state.value = SessionDetailError(failure),
      (_) async {
        final saveResult = await _sessionRepository.save(session);
        state.value = saveResult.fold(
          (failure) => SessionDetailError(failure),
          (_) => SessionDetailLoaded(session),
        );
      },
    );
  }

  void dispose() {
    state.dispose();
  }
}
```

**Widget usage:**

```dart
@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<SessionDetailState>(
    valueListenable: _viewModel.state,
    builder: (context, state, _) {
      return switch (state) {
        SessionDetailInitial() => const SizedBox.shrink(),
        SessionDetailLoading() => const CircularProgressIndicator(),
        SessionDetailLoaded(:final session) => SessionContent(session: session),
        SessionDetailError(:final failure) => ErrorDisplay(failure: failure),
      };
    },
  );
}
```

---

## 8. Supabase Gotchas

|Issue|Source|Mitigation|
|---|---|---|
|Returns `List` even for `.single()`|otakoyi.software|Use `.single()` modifier—SDK handles extraction|
|No transaction support|otakoyi.software|Use Edge Functions for multi-table atomic operations|
|Deep links break on Android|GitHub #688|Verify redirect URL exactly matches Supabase dashboard|
|Realtime + RLS token refresh|GitHub #1012|Shorter token expiry helps identify issues faster|
|No official mocking guide|GitHub #864|Wrap in data source, inject mock for tests|

---

## File Structure

Extends DDD guide structure with Supabase-specific additions:

```
lib/
├── config/
│   └── locator_config.dart                    # Add Supabase modules here
├── core/
│   ├── data/
│   │   └── supabase_error_mapper.dart         # ← New
│   ├── utils/
│   │   └── data_source/
│   │       └── data_source_abstraction.dart   # Existing wrapper
│   ├── domain/
│   │   └── (from DDD guide)
│   └── failures/
│       └── domain_failure.dart
└── features/
    └── session/
        ├── data/
        │   ├── data_sources/
        │   │   └── session_remote_data_source.dart  # ← New
        │   ├── dtos/
        │   │   └── session_dto.dart                 # ← @JsonKey added
        │   └── repositories/
        │       └── session_repository_impl.dart
        ├── domain/
        │   └── (from DDD guide)
        └── presentation/
            └── view_models/
                ├── session_state.dart               # ← Sealed states
                └── session_detail_view_model.dart
```

---

## Checklist

Before implementing Supabase integration, verify:

- [ ] `DataSourceAbstraction` wraps `SupabaseClient` for testability
- [ ] Feature data sources return DTOs, not raw JSON
- [ ] DTOs use `@JsonKey` for snake_case column mapping
- [ ] `toDomain()` uses `flatMap` for chained Either operations
- [ ] Repository catches `PostgrestException` and `AuthException`
- [ ] Error codes follow `{Aggregate}.{ErrorType}` pattern
- [ ] Supabase modules registered in `locator_config.dart`
- [ ] Supabase initialized before `locator.registerMany(modules)`
- [ ] ViewModel uses single sealed state class, not multiple ValueNotifiers
- [ ] State transitions handled exhaustively with switch expressions