import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../../../../core/data/supabase_error_mapper.dart';
import '../../../../core/failures/domain_failure.dart';
import '../../../../core/utils/data_source/data_source_abstraction.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../data_sources/session_remote_data_source.dart';
import '../dtos/session_dto.dart';

/// Repository implementation for Session aggregate using Supabase.
///
/// Handles error mapping from infrastructure failures to domain failures.
/// All business logic lives in the domain layer, not here.
class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _dataSource;
  final DataSourceAbstraction _auth;

  SessionRepositoryImpl(this._dataSource, this._auth);

  @override
  Future<Either<DomainFailure, Session>> getById(String id) async {
    try {
      final dto = await _dataSource.getSession(id);
      return dto.toDomain();
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('Session', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'Session.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Session.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, List<Session>>> list({
    String? protocolId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final dtos = await _dataSource.getSessions(
        protocolId: protocolId,
        from: from,
        to: to,
      );

      final sessions = <Session>[];
      for (final dto in dtos) {
        final result = dto.toDomain();
        if (result.isLeft()) {
          return left(
            result.getLeft().getOrElse(() => throw StateError('Unreachable')),
          );
        }
        sessions.add(
          result.getOrElse((l) => throw StateError('Unreachable')),
        );
      }

      return right(sessions);
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('Session', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'Session.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Session.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, Unit>> save(Session session) async {
    try {
      // Get current user ID from auth context
      final userId = _auth.auth.currentUser?.id;
      if (userId == null) {
        return left(
          const DomainFailure(
            code: 'Session.NotAuthenticated',
            message: 'User must be authenticated to save sessions',
          ),
        );
      }

      final dto = SessionDto.fromDomain(session, userId);
      await _dataSource.saveSession(dto);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('Session', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'Session.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Session.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }
}
