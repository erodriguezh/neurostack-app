import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../../../../core/utils/app_lifecycle_service.dart';
import '../../../../core/utils/connectivity/connectivity_service.dart';
import '../../../../core/utils/data_source/data_source_abstraction.dart';
import '../data_sources/session_local_data_source.dart';
import '../data_sources/session_remote_data_source.dart';
import '../dtos/session_insert_dto.dart';

/// Background sync service for pending sessions.
///
/// Syncs locally queued sessions to the remote server when online
/// and authenticated. Attaches to connectivity changes to trigger
/// sync on network recovery.
///
/// Pattern: Follows [AuthService] for connectivity listening.
class SessionSyncService {
  SessionSyncService({
    required SessionLocalDataSource local,
    required SessionRemoteDataSource remote,
    required ConnectivityService connectivity,
    required DataSourceAbstraction dataSource,
    required AppLifecycleService appLifecycle,
  })  : _local = local,
        _remote = remote,
        _connectivity = connectivity,
        _dataSource = dataSource,
        _appLifecycle = appLifecycle;

  final SessionLocalDataSource _local;
  final SessionRemoteDataSource _remote;
  final ConnectivityService _connectivity;
  final DataSourceAbstraction _dataSource;
  final AppLifecycleService _appLifecycle;
  final Logger _logger = Logger('SessionSyncService');

  VoidCallback? _connectivityListener;
  VoidCallback? _lifecycleListener;
  bool _isSyncing = false;

  /// Initializes the service and attaches connectivity and lifecycle listeners.
  ///
  /// Call once after service construction. The listeners trigger
  /// [sync] when:
  /// - Network status changes to online (connectivity)
  /// - App state changes to resumed (lifecycle)
  void init() {
    // Connectivity listener
    _connectivityListener ??= _handleConnectivityChange;
    _connectivity.status.removeListener(_connectivityListener!);
    _connectivity.status.addListener(_connectivityListener!);

    // Lifecycle listener
    _lifecycleListener ??= _handleLifecycleChange;
    _appLifecycle.lifecycle.removeListener(_lifecycleListener!);
    _appLifecycle.lifecycle.addListener(_lifecycleListener!);

    _logger.info('SessionSyncService initialized');
  }

  /// Disposes the service and detaches listeners.
  ///
  /// Call on app shutdown or when the service is no longer needed.
  void dispose() {
    if (_connectivityListener != null) {
      _connectivity.status.removeListener(_connectivityListener!);
      _connectivityListener = null;
    }
    if (_lifecycleListener != null) {
      _appLifecycle.lifecycle.removeListener(_lifecycleListener!);
      _lifecycleListener = null;
    }
    _logger.info('SessionSyncService disposed');
  }

  /// Syncs all pending sessions for the current authenticated user.
  ///
  /// Algorithm:
  /// 1. Check online + authenticated
  /// 2. Load pending sessions for current user
  /// 3. For each: push to remote via [SessionRemoteDataSource.createSession]
  /// 4. On success: remove from pending queue, upsert synced session
  /// 5. On failure: keep in queue for retry (silent, no throw)
  ///
  /// Safe to call from multiple places - guards against concurrent syncs.
  Future<void> sync() async {
    // Guard against concurrent syncs
    if (_isSyncing) {
      _logger.fine('Sync already in progress, skipping');
      return;
    }

    // Check online status
    if (_connectivity.status.value != NetworkStatus.online) {
      _logger.fine('Offline, skipping sync');
      return;
    }

    // Check authentication
    final userId = _dataSource.auth.currentUser?.id;
    if (userId == null) {
      _logger.fine('No authenticated user, skipping sync');
      return;
    }

    _isSyncing = true;
    try {
      await _syncForUser(userId);
    } catch (e, st) {
      // Never throw from sync() - it's called via unawaited() from connectivity listener
      _logger.warning('Session sync failed unexpectedly: $e', e, st);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncForUser(String userId) async {
    final pending = await _local.getPendingSessions(userId);
    if (pending.isEmpty) {
      _logger.fine('No pending sessions to sync');
      return;
    }

    _logger.info('Syncing ${pending.length} pending session(s) for user $userId');

    for (final session in pending) {
      // Bail early if we go offline mid-loop
      if (_connectivity.status.value != NetworkStatus.online) {
        _logger.fine('Went offline mid-sync, stopping');
        return;
      }

      try {
        // Create insert DTO from draft
        final insertDto = SessionInsertDto.fromDraft(session.draft, userId);

        // Push to remote
        final sessionDto = await _remote.createSession(insertDto);

        // CRITICAL: Once remote insert succeeds, remove from pending immediately
        // to avoid duplicate submissions even if subsequent local ops fail.
        try {
          await _local.removePendingSession(userId, session.localId);
        } catch (e, st) {
          _logger.warning(
            'Remote created session but failed to remove pending ${session.localId}: $e',
            e,
            st,
          );
          // If removal fails, we may duplicate later; at least don't crash.
        }

        // Convert DTO to domain and upsert to synced cache (best effort)
        final domainResult = sessionDto.toDomain();
        await domainResult.fold(
          (failure) async {
            _logger.warning(
              'Session created but DTO conversion failed: ${failure.message}',
            );
            // Remote has it, pending already removed - nothing else to do.
          },
          (syncedSession) async {
            try {
              await _local.upsertSyncedSessions(userId, [syncedSession]);
            } catch (e, st) {
              _logger.warning(
                'Failed to upsert synced session ${syncedSession.id}: $e',
                e,
                st,
              );
            }
            _logger.fine('Synced session ${session.localId} -> ${syncedSession.id}');
          },
        );
      } catch (e, st) {
        // Remote push failed - keep in pending queue for retry
        _logger.warning(
          'Failed to sync session ${session.localId}: $e',
          e,
          st,
        );
      }
    }
  }

  void _handleConnectivityChange() {
    final status = _connectivity.status.value;
    if (status == NetworkStatus.online) {
      _logger.fine('Network online, triggering sync');
      unawaited(sync());
    }
  }

  void _handleLifecycleChange() {
    final state = _appLifecycle.lifecycle.value;
    if (state == AppLifecycleState.resumed) {
      _logger.fine('App resumed, triggering sync');
      unawaited(sync());
    }
  }
}
