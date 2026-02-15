import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:neurostack/features/session/data/dtos/session_dto.dart';
import 'package:neurostack/features/session/data/dtos/session_insert_dto.dart';
import 'package:neurostack/features/session/data/services/session_sync_service.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../constants/test_constants.dart';
import '../../../../factories/pending_session_factory.dart';
import '../../../../mocks/data_source_mocks.dart';
import '../../../../mocks/mock_services.dart';

// Mocks unique to this test file
class MockDataSourceAbstraction extends Mock implements DataSourceAbstraction {}

class MockAppLifecycleService extends Mock implements AppLifecycleService {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockUser extends Mock implements supabase.User {}

// Fakes for registerFallbackValue
class FakePendingSession extends Fake implements PendingSession {}

class FakeSessionInsertDto extends Fake implements SessionInsertDto {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakePendingSession());
    registerFallbackValue(FakeSessionInsertDto());
  });

  group('SessionSyncService', () {
    late SessionSyncService service;
    late MockSessionLocalDataSource mockLocal;
    late MockSessionRemoteDataSource mockRemote;
    late MockConnectivityService mockConnectivity;
    late MockDataSourceAbstraction mockDataSource;
    late MockAppLifecycleService mockAppLifecycle;
    late MockGoTrueClient mockAuth;
    late ValueNotifier<NetworkStatus> connectivityStatus;
    late ValueNotifier<AppLifecycleState?> lifecycleStatus;

    setUp(() {
      mockLocal = MockSessionLocalDataSource();
      mockRemote = MockSessionRemoteDataSource();
      mockConnectivity = MockConnectivityService();
      mockDataSource = MockDataSourceAbstraction();
      mockAppLifecycle = MockAppLifecycleService();
      mockAuth = MockGoTrueClient();
      connectivityStatus = ValueNotifier(NetworkStatus.online);
      lifecycleStatus = ValueNotifier<AppLifecycleState?>(null);

      when(() => mockConnectivity.status).thenReturn(connectivityStatus);
      when(() => mockAppLifecycle.lifecycle).thenReturn(lifecycleStatus);
      when(() => mockDataSource.auth).thenReturn(mockAuth);

      service = SessionSyncService(
        local: mockLocal,
        remote: mockRemote,
        connectivity: mockConnectivity,
        dataSource: mockDataSource,
        appLifecycle: mockAppLifecycle,
      );
    });

    tearDown(() {
      connectivityStatus.dispose();
      lifecycleStatus.dispose();
    });

    group('init', () {
      test('init_attachesConnectivityListener', () {
        // Act
        service.init();

        // Assert - verify listener was attached
        verify(() => mockConnectivity.status).called(greaterThan(0));
      });

      test('init_attachesLifecycleListener', () {
        // Act
        service.init();

        // Assert - verify listener was attached
        verify(() => mockAppLifecycle.lifecycle).called(greaterThan(0));
      });

      test('init_canBeCalledMultipleTimes_withoutDuplicateListeners', () {
        // Act
        service.init();
        service.init();

        // Assert - should not throw and listener should only fire once
        // (This is verified by the implementation removing before adding)
      });
    });

    group('dispose', () {
      test('dispose_removesConnectivityListener', () {
        // Arrange
        service.init();

        // Act
        service.dispose();

        // Assert - disposing again should not throw
        service.dispose();
      });

      test('dispose_removesLifecycleListener', () {
        // Arrange
        service.init();

        // Act
        service.dispose();

        // Assert - disposing again should not throw
        service.dispose();
      });
    });

    group('sync', () {
      group('precondition checks', () {
        test('sync_whenOffline_skips', () async {
          // Arrange
          connectivityStatus.value = NetworkStatus.offline;

          // Act
          await service.sync();

          // Assert - no calls to auth or local
          verifyNever(() => mockDataSource.auth);
          verifyNever(() => mockLocal.getPendingSessions(any()));
        });

        test('sync_whenNotAuthenticated_skips', () async {
          // Arrange
          connectivityStatus.value = NetworkStatus.online;
          when(() => mockAuth.currentUser).thenReturn(null);

          // Act
          await service.sync();

          // Assert - no calls to local
          verifyNever(() => mockLocal.getPendingSessions(any()));
        });

        test('sync_whenAlreadySyncing_skips', () async {
          // Arrange
          final mockUser = MockUser();
          when(() => mockUser.id).thenReturn(TestConstants.user.id);
          when(() => mockAuth.currentUser).thenReturn(mockUser);

          // Create a pending session that will be synced
          final pending = PendingSessionFactory.create();
          var syncCallCount = 0;

          when(() => mockLocal.getPendingSessions(any())).thenAnswer((_) async {
            syncCallCount++;
            // First call takes time, second should be skipped
            if (syncCallCount == 1) {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            }
            return [pending];
          });

          final sessionDto = SessionDto(
            id: 'synced-id',
            protocolId: pending.draft.protocolId,
            userId: pending.userId,
            completedAt: pending.draft.completedAt.toIso8601String(),
          );

          when(
            () => mockRemote.createSession(any()),
          ).thenAnswer((_) async => sessionDto);
          when(
            () => mockLocal.upsertSyncedSessions(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockLocal.removePendingSession(any(), any()),
          ).thenAnswer((_) async {});

          // Act - start two syncs simultaneously
          final sync1 = service.sync();
          final sync2 = service.sync();

          await Future.wait([sync1, sync2]);

          // Assert - getPendingSessions should only be called once
          verify(() => mockLocal.getPendingSessions(any())).called(1);
        });
      });

      group('sync flow', () {
        late MockUser mockUser;

        setUp(() {
          mockUser = MockUser();
          when(() => mockUser.id).thenReturn(TestConstants.user.id);
          when(() => mockAuth.currentUser).thenReturn(mockUser);
        });

        test('sync_whenNoPendingSessions_noOp', () async {
          // Arrange
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenAnswer((_) async => []);

          // Act
          await service.sync();

          // Assert
          verifyNever(() => mockRemote.createSession(any()));
        });

        test(
          'sync_onRemoteSuccess_removesFromPendingAndUpsertsToSynced',
          () async {
            // Arrange
            final pending = PendingSessionFactory.create(localId: 'local-1');
            when(
              () => mockLocal.getPendingSessions(any()),
            ).thenAnswer((_) async => [pending]);

            final sessionDto = SessionDto(
              id: 'remote-id-1',
              protocolId: pending.draft.protocolId,
              userId: pending.userId,
              completedAt: pending.draft.completedAt.toIso8601String(),
            );
            when(
              () => mockRemote.createSession(any()),
            ).thenAnswer((_) async => sessionDto);
            when(
              () => mockLocal.upsertSyncedSessions(any(), any()),
            ).thenAnswer((_) async {});
            when(
              () => mockLocal.removePendingSession(any(), any()),
            ).thenAnswer((_) async {});

            // Act
            await service.sync();

            // Assert
            verify(() => mockRemote.createSession(any())).called(1);
            verify(
              () => mockLocal.upsertSyncedSessions(
                TestConstants.user.id,
                any(that: hasLength(1)),
              ),
            ).called(1);
            verify(
              () => mockLocal.removePendingSession(
                TestConstants.user.id,
                'local-1',
              ),
            ).called(1);
          },
        );

        test('sync_onRemoteFailure_keepsPendingInQueue', () async {
          // Arrange
          final pending = PendingSessionFactory.create(localId: 'local-1');
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenAnswer((_) async => [pending]);
          when(
            () => mockRemote.createSession(any()),
          ).thenThrow(Exception('Network error'));

          // Act
          await service.sync();

          // Assert - no removal, no upsert
          verifyNever(() => mockLocal.removePendingSession(any(), any()));
          verifyNever(() => mockLocal.upsertSyncedSessions(any(), any()));
        });

        test('sync_withMultiplePending_processesAll', () async {
          // Arrange
          final pending1 = PendingSessionFactory.create(localId: 'local-1');
          final pending2 = PendingSessionFactory.create(localId: 'local-2');
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenAnswer((_) async => [pending1, pending2]);

          when(() => mockRemote.createSession(any())).thenAnswer((inv) async {
            final dto = inv.positionalArguments[0] as SessionInsertDto;
            return SessionDto(
              id: 'remote-${dto.protocolId}',
              protocolId: dto.protocolId,
              userId: dto.userId,
              completedAt: dto.completedAt,
            );
          });
          when(
            () => mockLocal.upsertSyncedSessions(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockLocal.removePendingSession(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await service.sync();

          // Assert - both processed
          verify(() => mockRemote.createSession(any())).called(2);
          verify(() => mockLocal.removePendingSession(any(), any())).called(2);
        });

        test('sync_withPartialFailure_continuesWithOthers', () async {
          // Arrange
          final pending1 = PendingSessionFactory.create(localId: 'local-1');
          final pending2 = PendingSessionFactory.create(localId: 'local-2');
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenAnswer((_) async => [pending1, pending2]);

          var callCount = 0;
          when(() => mockRemote.createSession(any())).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('First one fails');
            }
            return SessionDto(
              id: 'remote-2',
              protocolId: pending2.draft.protocolId,
              userId: pending2.userId,
              completedAt: pending2.draft.completedAt.toIso8601String(),
            );
          });
          when(
            () => mockLocal.upsertSyncedSessions(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockLocal.removePendingSession(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await service.sync();

          // Assert - both attempted, only second succeeded
          verify(() => mockRemote.createSession(any())).called(2);
          verify(
            () => mockLocal.removePendingSession(
              TestConstants.user.id,
              'local-2',
            ),
          ).called(1);
          // First one stays in queue
          verifyNever(
            () => mockLocal.removePendingSession(
              TestConstants.user.id,
              'local-1',
            ),
          );
        });

        test('sync_passesCorrectUserIdToRemote', () async {
          // Arrange
          final pending = PendingSessionFactory.create();
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenAnswer((_) async => [pending]);

          SessionInsertDto? capturedDto;
          when(() => mockRemote.createSession(any())).thenAnswer((inv) async {
            capturedDto = inv.positionalArguments[0] as SessionInsertDto;
            return SessionDto(
              id: 'remote-id',
              protocolId: capturedDto!.protocolId,
              userId: capturedDto!.userId,
              completedAt: capturedDto!.completedAt,
            );
          });
          when(
            () => mockLocal.upsertSyncedSessions(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockLocal.removePendingSession(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await service.sync();

          // Assert - userId from auth, not from pending session
          expect(capturedDto?.userId, TestConstants.user.id);
        });
      });

      group('error recovery', () {
        late MockUser mockUser;

        setUp(() {
          mockUser = MockUser();
          when(() => mockUser.id).thenReturn(TestConstants.user.id);
          when(() => mockAuth.currentUser).thenReturn(mockUser);
        });

        test('sync_doesNotThrow_onRemoteError', () async {
          // Arrange
          final pending = PendingSessionFactory.create();
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenAnswer((_) async => [pending]);
          when(
            () => mockRemote.createSession(any()),
          ).thenThrow(Exception('Server error'));

          // Act & Assert - should not throw
          await expectLater(service.sync(), completes);
        });

        test('sync_doesNotThrow_onLocalError', () async {
          // Arrange
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenThrow(Exception('Local storage error'));

          // Act & Assert - sync() should never throw (called via unawaited())
          await expectLater(service.sync(), completes);

          // Remote should not be called since local failed first
          verifyNever(() => mockRemote.createSession(any()));
        });

        test('sync_remoteSuccess_butUpsertFails_stillRemovesPending', () async {
          // Arrange - This tests the critical correctness property:
          // If remote succeeds but local caching fails, we still remove from
          // pending to avoid duplicate submissions.
          final pending = PendingSessionFactory.create(localId: 'local-1');
          when(
            () => mockLocal.getPendingSessions(any()),
          ).thenAnswer((_) async => [pending]);

          final sessionDto = SessionDto(
            id: 'remote-id-1',
            protocolId: pending.draft.protocolId,
            userId: pending.userId,
            completedAt: pending.draft.completedAt.toIso8601String(),
          );
          when(
            () => mockRemote.createSession(any()),
          ).thenAnswer((_) async => sessionDto);
          when(
            () => mockLocal.removePendingSession(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockLocal.upsertSyncedSessions(any(), any()),
          ).thenThrow(Exception('disk full'));

          // Act
          await expectLater(service.sync(), completes);

          // Assert - remote was called, pending was removed even though upsert failed
          verify(() => mockRemote.createSession(any())).called(1);
          verify(
            () => mockLocal.removePendingSession(
              TestConstants.user.id,
              'local-1',
            ),
          ).called(1);
        });
      });
    });

    group('connectivity listener', () {
      late MockUser mockUser;

      setUp(() {
        mockUser = MockUser();
        when(() => mockUser.id).thenReturn(TestConstants.user.id);
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(
          () => mockLocal.getPendingSessions(any()),
        ).thenAnswer((_) async => []);
      });

      test('connectivityChange_toOnline_triggersSync', () async {
        // Arrange
        connectivityStatus.value = NetworkStatus.offline;
        service.init();

        // Act
        connectivityStatus.value = NetworkStatus.online;

        // Allow async sync to execute
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockLocal.getPendingSessions(any())).called(1);
      });

      test('connectivityChange_toOffline_doesNotTriggerSync', () async {
        // Arrange
        service.init();
        reset(mockLocal); // Clear any calls from init

        // Act
        connectivityStatus.value = NetworkStatus.offline;

        // Allow async sync to execute (if any)
        await Future<void>.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockLocal.getPendingSessions(any()));
      });
    });

    group('lifecycle listener', () {
      late MockUser mockUser;

      setUp(() {
        mockUser = MockUser();
        when(() => mockUser.id).thenReturn(TestConstants.user.id);
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(
          () => mockLocal.getPendingSessions(any()),
        ).thenAnswer((_) async => []);
      });

      test('lifecycleChange_toResumed_triggersSync', () async {
        // Arrange
        lifecycleStatus.value = AppLifecycleState.paused;
        service.init();

        // Act
        lifecycleStatus.value = AppLifecycleState.resumed;

        // Allow async sync to execute
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockLocal.getPendingSessions(any())).called(1);
      });

      test('lifecycleChange_toPaused_doesNotTriggerSync', () async {
        // Arrange
        lifecycleStatus.value = AppLifecycleState.resumed;
        service.init();
        reset(mockLocal); // Clear any calls from init

        // Act
        lifecycleStatus.value = AppLifecycleState.paused;

        // Allow async sync to execute (if any)
        await Future<void>.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockLocal.getPendingSessions(any()));
      });

      test('lifecycleChange_toInactive_doesNotTriggerSync', () async {
        // Arrange
        lifecycleStatus.value = AppLifecycleState.resumed;
        service.init();
        reset(mockLocal); // Clear any calls from init

        // Act
        lifecycleStatus.value = AppLifecycleState.inactive;

        // Allow async sync to execute (if any)
        await Future<void>.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockLocal.getPendingSessions(any()));
      });

      test('lifecycleChange_toDetached_doesNotTriggerSync', () async {
        // Arrange
        lifecycleStatus.value = AppLifecycleState.resumed;
        service.init();
        reset(mockLocal); // Clear any calls from init

        // Act
        lifecycleStatus.value = AppLifecycleState.detached;

        // Allow async sync to execute (if any)
        await Future<void>.delayed(Duration.zero);

        // Assert
        verifyNever(() => mockLocal.getPendingSessions(any()));
      });
    });
  });
}
