import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/data/dtos/pending_session_dto.dart';
import 'package:neurostack/features/session/data/dtos/session_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/test_constants.dart';
import '../../../../factories/pending_session_factory.dart';
import '../../../../factories/session_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionLocalDataSource', () {
    late SessionLocalDataSource dataSource;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dataSource = SessionLocalDataSource(prefs);
    });

    group('Pending Sessions', () {
      group('savePendingSession', () {
        test('savePendingSession_whenEmpty_savesSession', () async {
          // Arrange
          final pending = PendingSessionFactory.create();

          // Act
          await dataSource.savePendingSession(pending);

          // Assert
          final loaded = await dataSource.getPendingSessions(pending.userId);
          expect(loaded, hasLength(1));
          expect(loaded.first.localId, pending.localId);
        });

        test('savePendingSession_appendsToExisting', () async {
          // Arrange
          final pending1 = PendingSessionFactory.create(localId: 'local-1');
          final pending2 = PendingSessionFactory.create(localId: 'local-2');

          // Act
          await dataSource.savePendingSession(pending1);
          await dataSource.savePendingSession(pending2);

          // Assert
          final loaded = await dataSource.getPendingSessions(
            TestConstants.user.id,
          );
          expect(loaded, hasLength(2));
          expect(
            loaded.map((p) => p.localId),
            containsAll(['local-1', 'local-2']),
          );
        });

        test('savePendingSession_upsertsExistingByLocalId', () async {
          // Arrange
          final original = PendingSessionFactory.create(localId: 'local-1');
          await dataSource.savePendingSession(original);

          // Create updated version with same localId but different retry count
          final updated = PendingSessionFactory.withRetryCount(
            localId: 'local-1',
            retryCount: 5,
          );

          // Act
          await dataSource.savePendingSession(updated);

          // Assert
          final loaded = await dataSource.getPendingSessions(
            TestConstants.user.id,
          );
          expect(loaded, hasLength(1));
          expect(loaded.first.retryCount, 5);
        });
      });

      group('getPendingSessions', () {
        test('getPendingSessions_whenEmpty_returnsEmptyList', () async {
          // Act
          final result = await dataSource.getPendingSessions(
            TestConstants.user.id,
          );

          // Assert
          expect(result, isEmpty);
        });

        test('getPendingSessions_onlyReturnsSessionsForUser', () async {
          // Arrange
          final userA = PendingSessionFactory.create(
            localId: 'local-a',
            userId: 'user-a',
          );
          final userB = PendingSessionFactory.create(
            localId: 'local-b',
            userId: 'user-b',
          );

          await dataSource.savePendingSession(userA);
          await dataSource.savePendingSession(userB);

          // Act
          final resultA = await dataSource.getPendingSessions('user-a');
          final resultB = await dataSource.getPendingSessions('user-b');

          // Assert
          expect(resultA, hasLength(1));
          expect(resultA.first.localId, 'local-a');
          expect(resultB, hasLength(1));
          expect(resultB.first.localId, 'local-b');
        });
      });

      group('removePendingSession', () {
        test('removePendingSession_removesFromQueue', () async {
          // Arrange
          final pending1 = PendingSessionFactory.create(localId: 'local-1');
          final pending2 = PendingSessionFactory.create(localId: 'local-2');
          await dataSource.savePendingSession(pending1);
          await dataSource.savePendingSession(pending2);

          // Act
          await dataSource.removePendingSession(
            TestConstants.user.id,
            'local-1',
          );

          // Assert
          final loaded = await dataSource.getPendingSessions(
            TestConstants.user.id,
          );
          expect(loaded, hasLength(1));
          expect(loaded.first.localId, 'local-2');
        });

        test('removePendingSession_whenLastSession_clearsKey', () async {
          // Arrange
          final pending = PendingSessionFactory.create();
          await dataSource.savePendingSession(pending);

          // Act
          await dataSource.removePendingSession(
            pending.userId,
            pending.localId,
          );

          // Assert
          final loaded = await dataSource.getPendingSessions(pending.userId);
          expect(loaded, isEmpty);
          // Key should be removed
          expect(
            prefs.containsKey('pending_sessions_${pending.userId}'),
            isFalse,
          );
        });

        test('removePendingSession_whenNotExists_noOp', () async {
          // Arrange
          final pending = PendingSessionFactory.create();
          await dataSource.savePendingSession(pending);

          // Act - remove non-existent
          await dataSource.removePendingSession(
            pending.userId,
            'non-existent-id',
          );

          // Assert - original still there
          final loaded = await dataSource.getPendingSessions(pending.userId);
          expect(loaded, hasLength(1));
        });
      });

      group('clearPendingSessions', () {
        test('clearPendingSessions_removesAllForUser', () async {
          // Arrange
          await dataSource.savePendingSession(
            PendingSessionFactory.create(localId: 'local-1'),
          );
          await dataSource.savePendingSession(
            PendingSessionFactory.create(localId: 'local-2'),
          );

          // Act
          await dataSource.clearPendingSessions(TestConstants.user.id);

          // Assert
          final loaded = await dataSource.getPendingSessions(
            TestConstants.user.id,
          );
          expect(loaded, isEmpty);
        });
      });

      group('corrupt data handling', () {
        test(
          'getPendingSessions_whenCorruptJson_clearsAndReturnsEmpty',
          () async {
            // Arrange - write corrupt data directly
            await prefs.setString(
              'pending_sessions_${TestConstants.user.id}',
              'not valid json',
            );

            // Act
            final result = await dataSource.getPendingSessions(
              TestConstants.user.id,
            );

            // Assert
            expect(result, isEmpty);
            expect(
              prefs.containsKey('pending_sessions_${TestConstants.user.id}'),
              isFalse,
            );
          },
        );

        test('getPendingSessions_whenNotList_clearsAndReturnsEmpty', () async {
          // Arrange - write JSON object instead of list
          await prefs.setString(
            'pending_sessions_${TestConstants.user.id}',
            jsonEncode({'foo': 'bar'}),
          );

          // Act
          final result = await dataSource.getPendingSessions(
            TestConstants.user.id,
          );

          // Assert
          expect(result, isEmpty);
          expect(
            prefs.containsKey('pending_sessions_${TestConstants.user.id}'),
            isFalse,
          );
        });

        test('getPendingSessions_whenSingleCorruptEntry_skipsIt', () async {
          // Arrange - one valid, one corrupt entry
          final validDto = PendingSessionDto.fromDomain(
            PendingSessionFactory.create(localId: 'valid'),
          );
          await prefs.setString(
            'pending_sessions_${TestConstants.user.id}',
            jsonEncode([
              validDto.toJson(),
              {'invalid': 'entry'}, // Missing required fields
            ]),
          );

          // Act
          final result = await dataSource.getPendingSessions(
            TestConstants.user.id,
          );

          // Assert - only valid entry returned
          expect(result, hasLength(1));
          expect(result.first.localId, 'valid');
        });

        test(
          'getPendingSessions_selfHeals_removesCorruptEntriesFromStorage',
          () async {
            // Arrange - one valid, one corrupt entry
            final validDto = PendingSessionDto.fromDomain(
              PendingSessionFactory.create(localId: 'valid'),
            );
            await prefs.setString(
              'pending_sessions_${TestConstants.user.id}',
              jsonEncode([
                validDto.toJson(),
                {'invalid': 'entry'}, // Missing required fields
              ]),
            );

            // Act - first read triggers self-healing
            await dataSource.getPendingSessions(TestConstants.user.id);

            // Assert - storage now only contains valid entry
            final raw = prefs.getString(
              'pending_sessions_${TestConstants.user.id}',
            );
            expect(raw, isNotNull);
            final decoded = jsonDecode(raw!) as List;
            expect(decoded, hasLength(1)); // corrupt entry was removed
          },
        );
      });
    });

    group('Synced Sessions', () {
      group('upsertSyncedSessions', () {
        test('upsertSyncedSessions_savesNewSessions', () async {
          // Arrange
          final sessions = [
            SessionFactory.reconstitute(id: 'session-1'),
            SessionFactory.reconstitute(id: 'session-2'),
          ];

          // Act
          await dataSource.upsertSyncedSessions(
            TestConstants.user.id,
            sessions,
          );

          // Assert
          final loaded = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );
          expect(loaded, hasLength(2));
          expect(
            loaded.map((s) => s.id),
            containsAll(['session-1', 'session-2']),
          );
        });

        test('upsertSyncedSessions_updatesExistingById', () async {
          // Arrange - save initial session
          final original = SessionFactory.reconstitute(
            id: 'session-1',
            notes: 'Original notes',
          );
          await dataSource.upsertSyncedSessions(
            TestConstants.user.id,
            [original],
          );

          // Create updated version with same ID
          final updated = SessionFactory.reconstitute(
            id: 'session-1',
            notes: 'Updated notes',
          );

          // Act
          await dataSource.upsertSyncedSessions(
            TestConstants.user.id,
            [updated],
          );

          // Assert
          final loaded = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );
          expect(loaded, hasLength(1));
          expect(loaded.first.notes, 'Updated notes');
        });

        test('upsertSyncedSessions_mergesWithExisting', () async {
          // Arrange - save initial session
          await dataSource.upsertSyncedSessions(
            TestConstants.user.id,
            [SessionFactory.reconstitute(id: 'session-1')],
          );

          // Act - upsert new session
          await dataSource.upsertSyncedSessions(
            TestConstants.user.id,
            [SessionFactory.reconstitute(id: 'session-2')],
          );

          // Assert - both sessions present
          final loaded = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );
          expect(loaded, hasLength(2));
        });
      });

      group('getSyncedSessions', () {
        test('getSyncedSessions_whenEmpty_returnsEmptyList', () async {
          // Act
          final result = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );

          // Assert
          expect(result, isEmpty);
        });

        test('getSyncedSessions_onlyReturnsSessionsForUser', () async {
          // Arrange
          await dataSource.upsertSyncedSessions(
            'user-a',
            [SessionFactory.reconstitute(id: 'session-a')],
          );
          await dataSource.upsertSyncedSessions(
            'user-b',
            [SessionFactory.reconstitute(id: 'session-b')],
          );

          // Act
          final resultA = await dataSource.getSyncedSessions('user-a');
          final resultB = await dataSource.getSyncedSessions('user-b');

          // Assert
          expect(resultA, hasLength(1));
          expect(resultA.first.id, 'session-a');
          expect(resultB, hasLength(1));
          expect(resultB.first.id, 'session-b');
        });
      });

      group('clearSyncedSessions', () {
        test('clearSyncedSessions_removesAllForUser', () async {
          // Arrange
          await dataSource.upsertSyncedSessions(
            TestConstants.user.id,
            [
              SessionFactory.reconstitute(id: 'session-1'),
              SessionFactory.reconstitute(id: 'session-2'),
            ],
          );

          // Act
          await dataSource.clearSyncedSessions(TestConstants.user.id);

          // Assert
          final loaded = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );
          expect(loaded, isEmpty);
        });
      });

      group('corrupt data handling', () {
        test(
          'getSyncedSessions_whenCorruptJson_clearsAndReturnsEmpty',
          () async {
            // Arrange
            await prefs.setString(
              'synced_sessions_${TestConstants.user.id}',
              'not valid json',
            );

            // Act
            final result = await dataSource.getSyncedSessions(
              TestConstants.user.id,
            );

            // Assert
            expect(result, isEmpty);
            expect(
              prefs.containsKey('synced_sessions_${TestConstants.user.id}'),
              isFalse,
            );
          },
        );

        test('getSyncedSessions_whenSingleCorruptEntry_skipsIt', () async {
          // Arrange
          final validDto = SessionDto.fromDomain(
            SessionFactory.reconstitute(id: 'valid'),
            TestConstants.user.id,
          );
          await prefs.setString(
            'synced_sessions_${TestConstants.user.id}',
            jsonEncode([
              validDto.toJson(),
              {'invalid': 'entry'},
            ]),
          );

          // Act
          final result = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );

          // Assert
          expect(result, hasLength(1));
          expect(result.first.id, 'valid');
        });

        test(
          'getSyncedSessions_selfHeals_removesCorruptEntriesFromStorage',
          () async {
            // Arrange - one valid, one corrupt entry (missing id)
            final validDto = SessionDto.fromDomain(
              SessionFactory.reconstitute(id: 'valid'),
              TestConstants.user.id,
            );
            await prefs.setString(
              'synced_sessions_${TestConstants.user.id}',
              jsonEncode([
                validDto.toJson(),
                {'invalid': 'entry'},
              ]),
            );

            // Act - first read triggers self-healing
            await dataSource.getSyncedSessions(TestConstants.user.id);

            // Assert - storage now only contains valid entry
            final raw = prefs.getString(
              'synced_sessions_${TestConstants.user.id}',
            );
            expect(raw, isNotNull);
            final decoded = jsonDecode(raw!) as List;
            expect(decoded, hasLength(1)); // corrupt entry was removed
          },
        );

        test('getSyncedSessions_rejectsEntryWithEmptyId', () async {
          // Arrange - entry with empty id
          final validDto = SessionDto.fromDomain(
            SessionFactory.reconstitute(id: 'valid'),
            TestConstants.user.id,
          );
          // Create an entry with empty id by manipulating JSON
          final emptyIdEntry = {
            'id': '',
            'protocol_id': 'some-protocol',
            'user_id': TestConstants.user.id,
            'completed_at': DateTime.now().toIso8601String(),
          };
          await prefs.setString(
            'synced_sessions_${TestConstants.user.id}',
            jsonEncode([
              validDto.toJson(),
              emptyIdEntry,
            ]),
          );

          // Act
          final result = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );

          // Assert - entry with empty id is rejected
          expect(result, hasLength(1));
          expect(result.first.id, 'valid');
        });

        test('getSyncedSessions_rejectsEntryWithEmptyProtocolId', () async {
          // Arrange - entry with empty protocol_id
          final validDto = SessionDto.fromDomain(
            SessionFactory.reconstitute(id: 'valid'),
            TestConstants.user.id,
          );
          final emptyProtocolEntry = {
            'id': 'bad',
            'protocol_id': '',
            'user_id': TestConstants.user.id,
            'completed_at': DateTime.now().toIso8601String(),
          };
          await prefs.setString(
            'synced_sessions_${TestConstants.user.id}',
            jsonEncode([
              validDto.toJson(),
              emptyProtocolEntry,
            ]),
          );

          // Act
          final result = await dataSource.getSyncedSessions(
            TestConstants.user.id,
          );

          // Assert - entry with empty protocol_id is rejected
          expect(result, hasLength(1));
          expect(result.first.id, 'valid');
        });
      });
    });

    group('listSessions (combined)', () {
      test('listSessions_combinesSyncedAndPending', () async {
        // Arrange
        await dataSource.upsertSyncedSessions(
          TestConstants.user.id,
          [SessionFactory.reconstitute(id: 'synced-1')],
        );
        await dataSource.savePendingSession(
          PendingSessionFactory.create(localId: 'pending-1'),
        );

        // Act
        final result = await dataSource.listSessions(TestConstants.user.id);

        // Assert
        expect(result, hasLength(2));
        // Pending sessions are prefixed with 'pending:' to avoid ID collisions
        expect(
          result.map((s) => s.id),
          containsAll(['synced-1', 'pending:pending-1']),
        );
      });

      test('listSessions_sortsByCompletedAtDescending', () async {
        // Arrange
        final older = SessionFactory.reconstitute(
          id: 'older',
          completedAt: DateTime(2025, 1, 10),
        );
        final newer = SessionFactory.reconstitute(
          id: 'newer',
          completedAt: DateTime(2025, 1, 15),
        );
        await dataSource.upsertSyncedSessions(
          TestConstants.user.id,
          [older, newer],
        );

        // Act
        final result = await dataSource.listSessions(TestConstants.user.id);

        // Assert
        expect(result.first.id, 'newer');
        expect(result.last.id, 'older');
      });

      test('listSessions_filtersFromDate', () async {
        // Arrange
        final before = SessionFactory.reconstitute(
          id: 'before',
          completedAt: DateTime(2025, 1, 5),
        );
        final after = SessionFactory.reconstitute(
          id: 'after',
          completedAt: DateTime(2025, 1, 15),
        );
        await dataSource.upsertSyncedSessions(
          TestConstants.user.id,
          [before, after],
        );

        // Act
        final result = await dataSource.listSessions(
          TestConstants.user.id,
          from: DateTime(2025, 1, 10),
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, 'after');
      });

      test('listSessions_filtersToDate', () async {
        // Arrange
        final before = SessionFactory.reconstitute(
          id: 'before',
          completedAt: DateTime(2025, 1, 5),
        );
        final after = SessionFactory.reconstitute(
          id: 'after',
          completedAt: DateTime(2025, 1, 15),
        );
        await dataSource.upsertSyncedSessions(
          TestConstants.user.id,
          [before, after],
        );

        // Act
        final result = await dataSource.listSessions(
          TestConstants.user.id,
          to: DateTime(2025, 1, 10),
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, 'before');
      });

      test('listSessions_filtersDateRange', () async {
        // Arrange
        final sessions = [
          SessionFactory.reconstitute(
            id: 'early',
            completedAt: DateTime(2025, 1, 1),
          ),
          SessionFactory.reconstitute(
            id: 'mid',
            completedAt: DateTime(2025, 1, 10),
          ),
          SessionFactory.reconstitute(
            id: 'late',
            completedAt: DateTime(2025, 1, 20),
          ),
        ];
        await dataSource.upsertSyncedSessions(TestConstants.user.id, sessions);

        // Act
        final result = await dataSource.listSessions(
          TestConstants.user.id,
          from: DateTime(2025, 1, 5),
          to: DateTime(2025, 1, 15),
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, 'mid');
      });

      test('listSessions_pendingSessionsUsePrefixedLocalId', () async {
        // Arrange
        final pending = PendingSessionFactory.create(localId: 'pending-local');
        await dataSource.savePendingSession(pending);

        // Act
        final result = await dataSource.listSessions(TestConstants.user.id);

        // Assert - pending IDs are prefixed to avoid collision with server UUIDs
        expect(result.first.id, 'pending:pending-local');
        expect(result.first.protocolId, pending.draft.protocolId);
      });
    });

    group('Round-trip tests', () {
      test('pendingSession_roundtrip_preservesAllFields', () async {
        // Arrange
        final original = PendingSessionFactory.withRetryCount(
          localId: 'local-123',
          retryCount: 3,
        );

        // Act
        await dataSource.savePendingSession(original);
        final loaded = await dataSource.getPendingSessions(
          TestConstants.user.id,
        );

        // Assert
        expect(loaded, hasLength(1));
        final restored = loaded.first;
        expect(restored.localId, original.localId);
        expect(restored.userId, original.userId);
        expect(restored.draft.protocolId, original.draft.protocolId);
        expect(restored.draft.completedAt, original.draft.completedAt);
        expect(restored.retryCount, original.retryCount);
        expect(restored.createdAt, original.createdAt);
      });

      test('syncedSession_roundtrip_preservesAllFields', () async {
        // Arrange
        final original = SessionFactory.reconstitute(
          id: 'session-123',
          notes: 'Test notes',
        );

        // Act
        await dataSource.upsertSyncedSessions(
          TestConstants.user.id,
          [original],
        );
        final loaded = await dataSource.getSyncedSessions(
          TestConstants.user.id,
        );

        // Assert
        expect(loaded, hasLength(1));
        final restored = loaded.first;
        expect(restored.id, original.id);
        expect(restored.protocolId, original.protocolId);
        expect(restored.completedAt, original.completedAt);
        expect(restored.notes, original.notes);
      });
    });
  });
}
