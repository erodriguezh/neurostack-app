import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/entities/session_draft.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/features/user/domain/value_objects/stack.dart'
    as user_stack;
import 'package:neurostack/progress/data/cached_week_progress_store.dart';
import 'package:neurostack/progress/progress_state.dart';
import 'package:neurostack/progress/progress_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../factories/factories.dart';

void main() {
  group('ProgressViewModel', () {
    group('computeCellState', () {
      test('computeCellState_pastDayWithSession_returnsCompleted', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 8);
        final completedDays = {DateTime(2025, 1, 8)};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.completed);
      });

      test('computeCellState_pastDayWithoutSession_returnsNotDone', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 8);
        final completedDays = <DateTime>{};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.notDone);
      });

      test('computeCellState_todayWithoutSession_returnsFuture', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 10);
        final completedDays = <DateTime>{};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.future);
      });

      test('computeCellState_todayWithSession_returnsCompleted', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 10);
        final completedDays = {DateTime(2025, 1, 10)};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.completed);
      });

      test('computeCellState_futureDay_returnsFuture', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 12);
        final completedDays = <DateTime>{};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.future);
      });
    });

    group('onSessionLogged', () {
      late ProgressViewModel viewModel;
      late FakeNotifyService notifyService;
      late FakeAuthService authService;
      late FakeCachedWeekProgressStore cachedWeekProgressStore;
      late FakeSessionLocalDataSource sessionLocalDataSource;

      setUp(() async {
        notifyService = FakeNotifyService();
        authService = FakeAuthService();
        cachedWeekProgressStore = FakeCachedWeekProgressStore();
        sessionLocalDataSource = FakeSessionLocalDataSource();

        viewModel = ProgressViewModel(
          notifyService: notifyService,
          routerService: FakeRouterService(),
          authService: authService,
          userRepository: FakeUserRepository(),
          protocolRepository: FakeProtocolRepository(),
          sessionRepository: FakeSessionRepository(),
          sessionLocalDataSource: sessionLocalDataSource,
          connectivityService: FakeConnectivityService(),
          cachedUserStore: FakeCachedUserStore(),
          cachedWeekProgressStore: cachedWeekProgressStore,
        );
      });

      tearDown(() {
        viewModel.dispose();
      });

      test(
        'updates cell state to completed for session within current week',
        () async {
          // Arrange: Set up a loaded state with a notDone cell
          final weekStart = DateTime(2025, 1, 13); // Monday
          final weekEnd = DateTime(2025, 1, 19, 23, 59, 59, 999); // Sunday end
          final sessionDay = DateTime(2025, 1, 15); // Wednesday
          const protocolId = 'protocol-001';

          final initialRow = ProtocolRow(
            protocolId: protocolId,
            protocolName: 'Test Protocol',
            cells: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));
              return DayCell(
                date: day,
                state: CellState.notDone,
              );
            }),
          );

          // Set the view model to a loaded state
          viewModel.state.value = ProgressLoaded(
            rows: [initialRow],
            weekRange: DateTimeRange(start: weekStart, end: weekEnd),
            todayIndex: 4, // Friday
            isOffline: false,
          );

          final session = SessionFactory.reconstitute(
            id: 'session-001',
            protocolId: protocolId,
            completedAt: sessionDay,
          );

          // Act
          await viewModel.onSessionLogged(session);

          // Assert
          final state = viewModel.state.value;
          expect(state, isA<ProgressLoaded>());

          final loaded = state as ProgressLoaded;
          final row = loaded.rows.firstWhere((r) => r.protocolId == protocolId);
          final cell = row.cells.firstWhere(
            (c) => c.date.day == sessionDay.day,
          );

          expect(cell.state, CellState.completed);
        },
      );

      test('triggers haptic feedback on session logged', () async {
        // Arrange
        final weekStart = DateTime(2025, 1, 13);
        final weekEnd = DateTime(2025, 1, 19, 23, 59, 59, 999);
        const protocolId = 'protocol-001';

        final initialRow = ProtocolRow(
          protocolId: protocolId,
          protocolName: 'Test Protocol',
          cells: List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            return DayCell(date: day, state: CellState.notDone);
          }),
        );

        viewModel.state.value = ProgressLoaded(
          rows: [initialRow],
          weekRange: DateTimeRange(start: weekStart, end: weekEnd),
          todayIndex: 4,
          isOffline: false,
        );

        final session = SessionFactory.reconstitute(
          id: 'session-001',
          protocolId: protocolId,
          completedAt: DateTime(2025, 1, 15),
        );

        // Act
        await viewModel.onSessionLogged(session);

        // Assert
        expect(
          notifyService.lastHapticEvent,
          HapticFeedbackEvent.success,
        );
      });

      test('does nothing when state is not ProgressLoaded', () async {
        // Arrange: Keep initial state (not loaded)
        expect(viewModel.state.value, isA<ProgressInitial>());

        final session = SessionFactory.reconstitute(
          id: 'session-001',
          protocolId: 'protocol-001',
          completedAt: DateTime(2025, 1, 15),
        );

        // Act
        await viewModel.onSessionLogged(session);

        // Assert: State should remain unchanged
        expect(viewModel.state.value, isA<ProgressInitial>());
        expect(notifyService.lastHapticEvent, isNull);
      });

      test('does nothing when session date is outside current week', () async {
        // Arrange
        final weekStart = DateTime(2025, 1, 13);
        final weekEnd = DateTime(2025, 1, 19, 23, 59, 59, 999);
        const protocolId = 'protocol-001';

        final initialRow = ProtocolRow(
          protocolId: protocolId,
          protocolName: 'Test Protocol',
          cells: List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            return DayCell(date: day, state: CellState.notDone);
          }),
        );

        final initialState = ProgressLoaded(
          rows: [initialRow],
          weekRange: DateTimeRange(start: weekStart, end: weekEnd),
          todayIndex: 4,
          isOffline: false,
        );
        viewModel.state.value = initialState;

        // Session from a different week
        final session = SessionFactory.reconstitute(
          id: 'session-001',
          protocolId: protocolId,
          completedAt: DateTime(2025, 1, 6), // Previous week
        );

        // Act
        await viewModel.onSessionLogged(session);

        // Assert: State should remain unchanged
        final state = viewModel.state.value as ProgressLoaded;
        final row = state.rows.firstWhere((r) => r.protocolId == protocolId);

        // All cells should still be notDone
        for (final cell in row.cells) {
          expect(cell.state, CellState.notDone);
        }
        expect(notifyService.lastHapticEvent, isNull);
      });

      test('persists cache when userId is available', () async {
        // Arrange
        final weekStart = DateTime(2025, 1, 13);
        final weekEnd = DateTime(2025, 1, 19, 23, 59, 59, 999);
        const protocolId = 'protocol-001';
        const userId = 'user-001';

        // Set authenticated state
        authService.setAuthenticatedOnline(userId);

        final initialRow = ProtocolRow(
          protocolId: protocolId,
          protocolName: 'Test Protocol',
          cells: List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            return DayCell(date: day, state: CellState.notDone);
          }),
        );

        viewModel.state.value = ProgressLoaded(
          rows: [initialRow],
          weekRange: DateTimeRange(start: weekStart, end: weekEnd),
          todayIndex: 4,
          isOffline: false,
        );

        final session = SessionFactory.reconstitute(
          id: 'session-001',
          protocolId: protocolId,
          completedAt: DateTime(2025, 1, 15),
        );

        // Act
        await viewModel.onSessionLogged(session);

        // Assert
        expect(cachedWeekProgressStore.saveWeekCalled, isTrue);
        expect(cachedWeekProgressStore.lastSavedUserId, userId);
      });
    });

    group('_loadWeek combined sessions', () {
      late ProgressViewModel viewModel;
      late FakeNotifyService notifyService;
      late FakeAuthService authService;
      late FakeConnectivityService connectivityService;
      late FakeSessionRepository sessionRepository;
      late FakeSessionLocalDataSource sessionLocalDataSource;
      late FakeUserRepository userRepository;
      late FakeCachedUserStore cachedUserStore;

      setUp(() async {
        notifyService = FakeNotifyService();
        authService = FakeAuthService();
        connectivityService = FakeConnectivityService();
        sessionRepository = FakeSessionRepository();
        sessionLocalDataSource = FakeSessionLocalDataSource();
        userRepository = FakeUserRepository();
        cachedUserStore = FakeCachedUserStore();
      });

      ProgressViewModel createViewModel() {
        return ProgressViewModel(
          notifyService: notifyService,
          routerService: FakeRouterService(),
          authService: authService,
          userRepository: userRepository,
          protocolRepository: FakeProtocolRepository(),
          sessionRepository: sessionRepository,
          sessionLocalDataSource: sessionLocalDataSource,
          connectivityService: connectivityService,
          cachedUserStore: cachedUserStore,
          cachedWeekProgressStore: FakeCachedWeekProgressStore(),
        );
      }

      tearDown(() {
        viewModel.dispose();
      });

      test('online_remoteListSucceeds_upsertsToLocalDataSource', () async {
        // Arrange
        const userId = 'user-001';
        authService.setAuthenticatedOnline(userId);
        connectivityService.status.value = NetworkStatus.online;

        final remoteSession = SessionFactory.reconstitute(
          id: 'remote-session-001',
          protocolId: 'protocol-001',
          completedAt: DateTime.now(),
        );
        sessionRepository.sessionsToReturn = [remoteSession];

        viewModel = createViewModel();

        // Act
        await viewModel.init();

        // Assert
        expect(sessionLocalDataSource.upsertSyncedSessionsCalled, isTrue);
        expect(sessionLocalDataSource.lastUpsertUserId, userId);
        expect(
          sessionLocalDataSource.lastUpsertedSessions,
          contains(remoteSession),
        );
      });

      test('online_remoteListFails_stillLoadsFromLocalDataSource', () async {
        // Arrange
        const userId = 'user-001';
        authService.setAuthenticatedOnline(userId);
        connectivityService.status.value = NetworkStatus.online;

        // Remote fails
        sessionRepository.shouldFail = true;

        // But we have local sessions
        final localSession = SessionFactory.reconstitute(
          id: 'local-session-001',
          protocolId: 'protocol-001',
          completedAt: DateTime.now(),
        );
        await sessionLocalDataSource.upsertSyncedSessions(userId, [
          localSession,
        ]);
        sessionLocalDataSource.upsertSyncedSessionsCalled = false; // Reset

        viewModel = createViewModel();

        // Act
        await viewModel.init();

        // Assert: Should load successfully (not error state)
        final state = viewModel.state.value;
        expect(state, isA<ProgressLoaded>());
      });

      test(
        'offline_cachedUserWithActiveProtocols_showsRowsEvenWithNoSessions',
        () async {
          // Arrange
          const userId = 'user-001';
          const protocolId = 'protocol-001';

          final user = UserFactory.create(
            id: userId,
            subscriptionStatus: SubscriptionStatus.free,
            onboardingCompleted: true,
            stack: user_stack.Stack.fromIds([protocolId]),
          );

          // Set offline auth state
          authService.authState.value = AuthenticatedOffline(user);
          connectivityService.status.value = NetworkStatus.offline;

          // Cache the user for offline lookup
          await cachedUserStore.saveUser(user);

          // No sessions in local data source
          viewModel = createViewModel();

          // Act
          await viewModel.init();

          // Assert: Should show rows for active protocols even with no sessions
          final state = viewModel.state.value;
          expect(state, isA<ProgressLoaded>());

          final loaded = state as ProgressLoaded;
          expect(loaded.rows.length, 1);
          expect(loaded.rows.first.protocolId, protocolId);
          expect(loaded.isOffline, isTrue);
        },
      );

      test('offline_pendingSessionInLocalDS_showsAsCompleted', () async {
        // Arrange
        const userId = 'user-001';
        const protocolId = 'protocol-001';
        final now = DateTime.now();
        final sessionDay = DateTime(now.year, now.month, now.day, 12);

        final user = UserFactory.create(
          id: userId,
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
          stack: user_stack.Stack.fromIds([protocolId]),
        );

        authService.authState.value = AuthenticatedOffline(user);
        connectivityService.status.value = NetworkStatus.offline;
        await cachedUserStore.saveUser(user);

        // Add a pending session using reconstitute for testing
        final draft = SessionDraft.reconstitute(
          protocolId: protocolId,
          completedAt: sessionDay,
        );
        final pendingSession = PendingSession.create(
          localId: 'pending-001',
          userId: userId,
          draft: draft,
          createdAt: now,
        );
        await sessionLocalDataSource.savePendingSession(pendingSession);

        viewModel = createViewModel();

        // Act
        await viewModel.init();

        // Assert
        final state = viewModel.state.value;
        expect(state, isA<ProgressLoaded>());

        final loaded = state as ProgressLoaded;
        final row = loaded.rows.firstWhere((r) => r.protocolId == protocolId);

        // Find the cell for today
        final todayCell = row.cells.firstWhere(
          (c) =>
              c.date.day == sessionDay.day && c.date.month == sessionDay.month,
        );
        expect(todayCell.state, CellState.completed);
      });
    });
  });
}

// Fake implementations for testing

class FakeNotifyService extends NotifyService {
  HapticFeedbackEvent? lastHapticEvent;

  @override
  void setHapticFeedbackEvent(HapticFeedbackEvent? event) {
    lastHapticEvent = event;
    super.setHapticFeedbackEvent(event);
  }
}

class FakeAuthService implements AuthService {
  @override
  final ValueNotifier<AuthState> authState = ValueNotifier<AuthState>(
    const Unauthenticated(),
  );

  @override
  bool get isAuthenticated =>
      authState.value is AuthenticatedOnline ||
      authState.value is AuthenticatedOffline;

  void setAuthenticatedOnline(String userId) {
    final user = UserFactory.create(
      id: userId,
      subscriptionStatus: SubscriptionStatus.free,
      onboardingCompleted: true,
    );
    authState.value = AuthenticatedOnline(user);
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> logout({bool forceOnboarding = true}) async {}

  @override
  Future<void> invalidateUserCache() async {}

  @override
  void dispose() {
    authState.dispose();
  }
}

class FakeRouterService extends RouterService {
  FakeRouterService()
    : super(
        supportedRoutes: [
          RouteEntry(
            path: '/',
            builder: (key, routeData) => const SizedBox.shrink(),
          ),
          RouteEntry(
            path: '/404',
            builder: (key, routeData) => const SizedBox.shrink(),
          ),
        ],
      );
}

class FakeUserRepository implements UserRepository {
  @override
  Future<Either<DomainFailure, User>> getById(String id) async {
    return right(
      UserFactory.create(
        id: id,
        subscriptionStatus: SubscriptionStatus.free,
        onboardingCompleted: true,
      ),
    );
  }

  @override
  Future<Either<DomainFailure, List<User>>> list({
    SubscriptionStatus? subscriptionStatus,
    bool? onboardingCompleted,
  }) async {
    return right([]);
  }

  @override
  Future<Either<DomainFailure, Unit>> save(User user) async {
    return right(unit);
  }
}

class FakeProtocolRepository implements ProtocolRepository {
  @override
  Future<Either<DomainFailure, Protocol>> getById(String id) async {
    return right(ProtocolFactory.reconstitute(id: id));
  }

  @override
  Future<Either<DomainFailure, List<Protocol>>> list({
    Category? category,
    EvidenceLevel? evidenceLevel,
    bool? activeOnly,
  }) async {
    return right([]);
  }

  @override
  Future<Either<DomainFailure, Unit>> save(Protocol protocol) async {
    return right(unit);
  }
}

class FakeSessionRepository implements SessionRepository {
  List<Session> sessionsToReturn = [];
  bool shouldFail = false;

  @override
  Future<Either<DomainFailure, Session>> getById(String id) async {
    return right(SessionFactory.reconstitute(id: id));
  }

  @override
  Future<Either<DomainFailure, List<Session>>> list({
    String? protocolId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (shouldFail) {
      return left(
        const DomainFailure(
          code: 'Session.NetworkError',
          message: 'Network error',
        ),
      );
    }
    return right(sessionsToReturn);
  }

  @override
  Future<Either<DomainFailure, Session>> create(SessionDraft session) async {
    return right(
      SessionFactory.reconstitute(
        id: 'created-session-id',
        protocolId: session.protocolId,
        completedAt: session.completedAt,
      ),
    );
  }
}

class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService() {
    status.value = NetworkStatus.online;
  }

  @override
  final ValueNotifier<NetworkStatus> status = ValueNotifier<NetworkStatus>(
    NetworkStatus.online,
  );

  @override
  Future<void> init() async {}

  @override
  void dispose() {
    status.dispose();
  }
}

class FakeCachedUserStore implements CachedUserStore {
  FakeCachedUserStore();

  User? _cachedUser;

  @override
  Future<User?> loadUser() async => _cachedUser;

  @override
  Future<void> saveUser(User user) async {
    _cachedUser = user;
  }

  @override
  Future<void> clearUser() async {
    _cachedUser = null;
  }
}

class FakeCachedWeekProgressStore extends CachedWeekProgressStore {
  FakeCachedWeekProgressStore() : super(_FakeSharedPreferences());

  bool saveWeekCalled = false;
  String? lastSavedUserId;
  DateTime? lastSavedWeekStart;
  WeekProgressCache? lastSavedCache;

  @override
  Future<void> saveWeek(
    String userId,
    DateTime weekStart,
    WeekProgressCache cache,
  ) async {
    saveWeekCalled = true;
    lastSavedUserId = userId;
    lastSavedWeekStart = weekStart;
    lastSavedCache = cache;
  }

  @override
  Future<WeekProgressCache?> loadWeek(
    String userId,
    DateTime weekStart,
  ) async {
    return null;
  }

  @override
  Future<void> clearWeek(String userId, DateTime weekStart) async {}
}

class _FakeSharedPreferences implements SharedPreferences {
  final Map<String, Object> _data = {};

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  // Stub out other methods we don't need
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSessionLocalDataSource implements SessionLocalDataSource {
  // Per-user storage to match production behavior
  final Map<String, List<Session>> _syncedSessionsByUser = {};
  final List<PendingSession> _pendingSessions = [];

  bool upsertSyncedSessionsCalled = false;
  String? lastUpsertUserId;
  List<Session>? lastUpsertedSessions;

  @override
  Future<void> savePendingSession(PendingSession pending) async {
    _pendingSessions.removeWhere((p) => p.localId == pending.localId);
    _pendingSessions.add(pending);
  }

  @override
  Future<List<PendingSession>> getPendingSessions(String userId) async {
    return _pendingSessions.where((p) => p.userId == userId).toList();
  }

  @override
  Future<void> removePendingSession(String userId, String localId) async {
    _pendingSessions.removeWhere(
      (p) => p.userId == userId && p.localId == localId,
    );
  }

  @override
  Future<void> clearPendingSessions(String userId) async {
    _pendingSessions.removeWhere((p) => p.userId == userId);
  }

  @override
  Future<void> upsertSyncedSessions(
    String userId,
    List<Session> sessions,
  ) async {
    upsertSyncedSessionsCalled = true;
    lastUpsertUserId = userId;
    lastUpsertedSessions = sessions;

    final userSessions = _syncedSessionsByUser.putIfAbsent(userId, () => []);
    for (final session in sessions) {
      userSessions.removeWhere((s) => s.id == session.id);
      userSessions.add(session);
    }
  }

  @override
  Future<List<Session>> getSyncedSessions(String userId) async {
    return List.from(_syncedSessionsByUser[userId] ?? []);
  }

  @override
  Future<void> clearSyncedSessions(String userId) async {
    _syncedSessionsByUser.remove(userId);
  }

  @override
  Future<List<Session>> listSessions(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final userSynced = _syncedSessionsByUser[userId] ?? [];
    final all = <Session>[...userSynced];

    // Convert pending to Session
    for (final pending in _pendingSessions.where((p) => p.userId == userId)) {
      all.add(
        Session.reconstitute(
          id: '${SessionLocalDataSource.pendingIdPrefix}${pending.localId}',
          protocolId: pending.draft.protocolId,
          completedAt: pending.draft.completedAt,
          duration: pending.draft.duration,
          notes: pending.draft.notes,
        ),
      );
    }

    final filtered = all.where((session) {
      if (from != null && session.completedAt.isBefore(from)) {
        return false;
      }
      if (to != null && session.completedAt.isAfter(to)) {
        return false;
      }
      return true;
    }).toList();

    // Sort by completedAt descending (matching production behavior)
    filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return filtered;
  }
}
