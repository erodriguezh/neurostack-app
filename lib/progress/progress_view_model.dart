import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/utils/auth_helpers.dart' as auth;
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/date_time_extensions.dart';
import 'package:neurostack/core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/progress/data/cached_week_progress_store.dart';
import 'package:neurostack/progress/progress_state.dart';

class ProgressViewModel {
  final Logger _logger = Logger('Progress');

  ProgressViewModel({
    required NotifyService notifyService,
    required RouterService routerService,
    required AuthService authService,
    required UserRepository userRepository,
    required ProtocolRepository protocolRepository,
    required SessionRepository sessionRepository,
    required SessionLocalDataSource sessionLocalDataSource,
    required ConnectivityService connectivityService,
    CachedUserStore? cachedUserStore,
    CachedWeekProgressStore? cachedWeekProgressStore,
    HomeBottomTabCoordinator? tabCoordinator,
  })  : _notifyService = notifyService,
        _authService = authService,
        _userRepository = userRepository,
        _protocolRepository = protocolRepository,
        _sessionRepository = sessionRepository,
        _sessionLocalDataSource = sessionLocalDataSource,
        _connectivityService = connectivityService,
        _cachedUserStore = cachedUserStore,
        _cachedWeekProgressStore = cachedWeekProgressStore,
        _tabCoordinator = tabCoordinator ??
            HomeBottomTabCoordinator(
              routerService: routerService,
            );

  final NotifyService _notifyService;
  final AuthService _authService;
  final UserRepository _userRepository;
  final ProtocolRepository _protocolRepository;
  final SessionRepository _sessionRepository;
  final SessionLocalDataSource _sessionLocalDataSource;
  final ConnectivityService _connectivityService;
  final CachedUserStore? _cachedUserStore;
  final CachedWeekProgressStore? _cachedWeekProgressStore;
  final HomeBottomTabCoordinator _tabCoordinator;
  final ValueNotifier<ProgressState> state = ValueNotifier(
    const ProgressInitial(),
  );

  bool _isLoading = false;
  bool _isDisposed = false;
  VoidCallback? _connectivityListener;
  User? _cachedUser;
  ProgressLoaded? _lastLoaded;

  Future<void> init() async {
    _connectivityListener ??= _handleConnectivityChange;
    _connectivityService.status.removeListener(_connectivityListener!);
    _connectivityService.status.addListener(_connectivityListener!);

    await _loadWeek(showLoading: true);
  }

  Future<void> refresh() async {
    await _loadWeek(showLoading: false);
  }

  Future<void> onAppResumed() async {
    await _loadWeek(showLoading: false);
  }

  void onSelectBottomTab(HomeBottomTab tab) {
    _tabCoordinator.onSelect(
      tab,
      currentTab: HomeBottomTab.progress,
    );
  }

  /// Updates the grid cell state when a session is logged via the modal.
  ///
  /// This is more efficient than [refresh] as it only updates the affected cell
  /// without reloading all data from the server.
  Future<void> onSessionLogged(Session session) async {
    final current = state.value;
    if (current is! ProgressLoaded) {
      return;
    }

    final dayStart = _startOfDay(session.completedAt);

    // Only update if the session date is within the displayed week
    if (dayStart.isBefore(current.weekRange.start) ||
        dayStart.isAfter(current.weekRange.end)) {
      return;
    }

    final updated = _updateCellState(
      current,
      session.protocolId,
      dayStart,
      CellState.completed,
    );

    state.value = updated;
    _lastLoaded = updated;

    _notifyService.setHapticFeedbackEvent(HapticFeedbackEvent.success);

    final userId = auth.resolveUserId(_authService);
    if (userId != null) {
      await _persistCache(userId, updated);
    }
  }

  void dispose() {
    _isDisposed = true;
    if (_connectivityListener != null) {
      _connectivityService.status.removeListener(_connectivityListener!);
    }
    state.dispose();
  }

  Future<void> _loadWeek({
    required bool showLoading,
    bool preferCacheWhenOffline = true,
  }) async {
    if (_isLoading || _isDisposed) {
      return;
    }

    _isLoading = true;
    final now = DateTime.now();
    final weekStart = now.weekStart;
    final weekEnd = now.weekEnd;
    final weekRange = DateTimeRange(start: weekStart, end: weekEnd);
    final todayIndex = _todayIndex(now, weekStart, weekEnd);
    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;

    if (showLoading) {
      state.value = const ProgressLoading();
    }

    if (isOffline && preferCacheWhenOffline) {
      final cachedUser = await auth.resolveCachedUser(
        authService: _authService,
        cachedUser: _cachedUser,
        cachedUserStore: _cachedUserStore,
      );

      // First, try reading from SessionLocalDataSource for combined sessions
      // Build rows even if sessions is empty (to show active protocols)
      if (cachedUser != null) {
        _cachedUser = cachedUser;
        final sessions = await _sessionLocalDataSource.listSessions(
          cachedUser.id,
          from: weekStart,
          to: weekEnd,
        );

        final protocolIds = <String>{...cachedUser.activeProtocolIds};
        for (final session in sessions) {
          protocolIds.add(session.protocolId);
        }

        // Only proceed with local DS if we have protocols to show
        if (protocolIds.isNotEmpty) {
          final protocolNamesById = await _resolveProtocolNames(protocolIds);
          final completedDaysByProtocolId = _groupCompletedSessions(sessions);
          final rows = _buildRows(
            protocolNamesById: protocolNamesById,
            completedDaysByProtocolId: completedDaysByProtocolId,
            weekStart: weekStart,
            now: now,
          );

          final loaded = ProgressLoaded(
            rows: rows,
            weekRange: weekRange,
            todayIndex: todayIndex,
            isOffline: true,
          );

          await _persistCache(cachedUser.id, loaded);
          _setLoaded(loaded);
          return;
        }
      }

      // Fallback: try WeekProgressCache (for cases without cached user)
      WeekProgressCache? cache;
      if (cachedUser != null && _cachedWeekProgressStore != null) {
        cache = await _cachedWeekProgressStore.loadWeek(
          cachedUser.id,
          weekStart,
        );
      }

      if (cache == null &&
          _lastLoaded != null &&
          _startOfDay(_lastLoaded!.weekRange.start).isSameDay(weekStart)) {
        cache = _buildCache(_lastLoaded!);
      }

      if (cache != null) {
        final rows = _buildRows(
          protocolNamesById: cache.protocolNamesById,
          completedDaysByProtocolId: cache.completedDaysByProtocolId,
          weekStart: weekStart,
          now: now,
        );
        _setLoaded(
          ProgressLoaded(
            rows: rows,
            weekRange: weekRange,
            todayIndex: todayIndex,
            isOffline: true,
          ),
        );
        return;
      }

      _setLoaded(
        ProgressLoaded(
          rows: const [],
          weekRange: weekRange,
          todayIndex: todayIndex,
          isOffline: true,
        ),
      );
      return;
    }

    final userId = auth.resolveUserId(_authService);
    if (userId == null) {
      _setFailure(
        const DomainFailure(
          code: 'Progress.UserUnavailable',
          message: 'Unable to load user.',
        ),
        preserveContent: !showLoading,
      );
      return;
    }

    final userResult = await _userRepository.getById(userId);
    if (userResult.isLeft()) {
      _setFailure(
        _failureMessage(userResult, 'Unable to load user.'),
        preserveContent: !showLoading,
      );
      return;
    }

    final user = userResult.getOrElse((_) => throw StateError('Unreachable'));
    final isOnline =
        _connectivityService.status.value == NetworkStatus.online;

    // If online, fetch from remote and upsert to local cache (best-effort)
    // Remote sync failure is non-fatal: we fall back to cached + pending sessions
    if (isOnline) {
      final sessionsResult = await _sessionRepository.list(
        from: weekStart,
        to: weekEnd,
      );

      await sessionsResult.fold(
        (failure) async {
          // Non-fatal: continue with cached + pending sessions
          _logger.fine('Remote session fetch failed: ${failure.code}');
        },
        (remoteSessions) async {
          try {
            await _sessionLocalDataSource.upsertSyncedSessions(
              userId,
              remoteSessions,
            );
          } catch (e) {
            // Cache write failure is also non-fatal
            _logger.fine('Session cache upsert failed: $e');
          }
        },
      );
    }

    // Read combined sessions (synced + pending) from local data source
    final sessions = await _sessionLocalDataSource.listSessions(
      userId,
      from: weekStart,
      to: weekEnd,
    );

    final protocolIds = <String>{...user.activeProtocolIds};
    for (final session in sessions) {
      protocolIds.add(session.protocolId);
    }

    final protocolNamesById = await _resolveProtocolNames(protocolIds);
    final completedDaysByProtocolId = _groupCompletedSessions(sessions);
    final rows = _buildRows(
      protocolNamesById: protocolNamesById,
      completedDaysByProtocolId: completedDaysByProtocolId,
      weekStart: weekStart,
      now: now,
    );

    final loaded = ProgressLoaded(
      rows: rows,
      weekRange: weekRange,
      todayIndex: todayIndex,
      isOffline: !isOnline,
    );

    _cachedUser = user;
    await _cachedUserStore?.saveUser(user);
    await _persistCache(user.id, loaded);
    _setLoaded(loaded);
  }

  ProgressLoaded _updateCellState(
    ProgressLoaded current,
    String protocolId,
    DateTime day,
    CellState nextState,
  ) {
    final updatedRows = current.rows.map((row) {
      if (row.protocolId != protocolId) {
        return row;
      }
      final updatedCells = row.cells.map((cell) {
        if (cell.date.isSameDay(day)) {
          return DayCell(date: cell.date, state: nextState);
        }
        return cell;
      }).toList();

      return ProtocolRow(
        protocolId: row.protocolId,
        protocolName: row.protocolName,
        cells: updatedCells,
      );
    }).toList();

    return current.copyWith(rows: updatedRows);
  }

  Future<void> _persistCache(String userId, ProgressLoaded loaded) async {
    if (_cachedWeekProgressStore == null) {
      return;
    }
    final cache = _buildCache(loaded);
    await _cachedWeekProgressStore.saveWeek(
      userId,
      loaded.weekRange.start,
      cache,
    );
  }

  WeekProgressCache _buildCache(ProgressLoaded loaded) {
    final protocolNamesById = <String, String>{};
    final completedDaysByProtocolId = <String, Set<DateTime>>{};

    for (final row in loaded.rows) {
      protocolNamesById[row.protocolId] = row.protocolName;
      final completed = <DateTime>{};
      for (final cell in row.cells) {
        if (cell.state == CellState.completed) {
          completed.add(cell.date);
        }
      }
      completedDaysByProtocolId[row.protocolId] = completed;
    }

    return WeekProgressCache(
      weekRange: loaded.weekRange,
      protocolNamesById: protocolNamesById,
      completedDaysByProtocolId: completedDaysByProtocolId,
    );
  }

  List<ProtocolRow> _buildRows({
    required Map<String, String> protocolNamesById,
    required Map<String, Set<DateTime>> completedDaysByProtocolId,
    required DateTime weekStart,
    required DateTime now,
  }) {
    final orderedIds = protocolNamesById.keys.toList()
      ..sort((a, b) {
        final nameA = protocolNamesById[a] ?? '';
        final nameB = protocolNamesById[b] ?? '';
        return nameA.compareTo(nameB);
      });

    final rows = <ProtocolRow>[];
    for (final protocolId in orderedIds) {
      final protocolName = protocolNamesById[protocolId] ?? 'Protocol unavailable';
      final completedDays = completedDaysByProtocolId[protocolId] ?? <DateTime>{};
      final cells = List<DayCell>.generate(7, (index) {
        final day = _startOfDay(weekStart.add(Duration(days: index)));
        final state = computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );
        return DayCell(date: day, state: state);
      });

      rows.add(
        ProtocolRow(
          protocolId: protocolId,
          protocolName: protocolName,
          cells: cells,
        ),
      );
    }
    return rows;
  }

  Map<String, Set<DateTime>> _groupCompletedSessions(List<Session> sessions) {
    final grouped = <String, Set<DateTime>>{};
    for (final session in sessions) {
      final day = _startOfDay(session.completedAt);
      grouped.putIfAbsent(session.protocolId, () => <DateTime>{}).add(day);
    }
    return grouped;
  }

  Future<Map<String, String>> _resolveProtocolNames(
    Set<String> protocolIds,
  ) async {
    final protocolNamesById = <String, String>{};
    for (final protocolId in protocolIds) {
      final result = await _protocolRepository.getById(protocolId);
      protocolNamesById[protocolId] = result.fold(
        (_) => 'Protocol unavailable',
        (protocol) => protocol.name.value,
      );
    }
    return protocolNamesById;
  }

  int _todayIndex(DateTime now, DateTime weekStart, DateTime weekEnd) {
    if (now.isBefore(weekStart) || now.isAfter(weekEnd)) {
      return -1;
    }
    return now.weekday - 1;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _setLoaded(ProgressLoaded loaded) {
    if (_isDisposed) {
      return;
    }
    state.value = loaded;
    _lastLoaded = loaded;
    _isLoading = false;
  }

  void _setFailure(DomainFailure failure, {required bool preserveContent}) {
    if (_isDisposed) {
      return;
    }

    _notifyService.setToastEvent(ToastEventError(message: failure.message));

    if (preserveContent && _lastLoaded != null) {
      final isOffline =
          _connectivityService.status.value == NetworkStatus.offline;
      state.value = _lastLoaded!.copyWith(isOffline: isOffline);
      _lastLoaded = state.value as ProgressLoaded;
      _isLoading = false;
      return;
    }

    state.value = ProgressError(failure);
    _isLoading = false;
  }

  DomainFailure _failureMessage<T>(
    Either<DomainFailure, T> result,
    String fallbackMessage,
  ) {
    return result.getLeft().getOrElse(
          () => DomainFailure(
            code: 'Progress.UnexpectedError',
            message: fallbackMessage,
          ),
        );
  }

  void _handleConnectivityChange() {
    if (_isDisposed) {
      return;
    }

    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;
    final current = state.value;

    if (current is ProgressLoaded) {
      if (current.isOffline == isOffline) {
        return;
      }
      if (isOffline) {
        _setLoaded(current.copyWith(isOffline: true));
        return;
      }
    }

    _loadWeek(showLoading: false, preferCacheWhenOffline: isOffline);
  }

  @visibleForTesting
  static CellState computeCellState({
    required DateTime day,
    required Set<DateTime> completedDays,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final dayStart = DateTime(day.year, day.month, day.day);

    if (dayStart.isAfter(today)) {
      return CellState.future;
    }

    final hasSession = completedDays.any((entry) => entry.isSameDay(dayStart));
    if (dayStart.isSameDay(today)) {
      return hasSession ? CellState.completed : CellState.future;
    }

    return hasSession ? CellState.completed : CellState.notDone;
  }
}
