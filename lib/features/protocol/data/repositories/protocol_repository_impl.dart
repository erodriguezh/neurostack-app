import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/supabase_error_mapper.dart';
import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/protocol.dart';
import '../../domain/enums/category.dart';
import '../../domain/enums/evidence_level.dart';
import '../../domain/repositories/protocol_repository.dart';
import '../data_sources/protocol_remote_data_source.dart';
import '../dtos/protocol_dto.dart';

/// Repository implementation for Protocol aggregate using Supabase.
///
/// Handles error mapping from infrastructure failures to domain failures.
/// All business logic lives in the domain layer, not here.
class ProtocolRepositoryImpl implements ProtocolRepository {
  final ProtocolRemoteDataSource _dataSource;

  ProtocolRepositoryImpl(this._dataSource);

  @override
  Future<Either<DomainFailure, Protocol>> getById(String id) async {
    try {
      final dto = await _dataSource.getProtocol(id);
      return dto.toDomain();
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('Protocol', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'Protocol.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Protocol.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, List<Protocol>>> list({
    Category? category,
    EvidenceLevel? evidenceLevel,
    bool? activeOnly,
  }) async {
    try {
      final dtos = await _dataSource.getProtocols(
        category: category,
        evidenceLevel: evidenceLevel,
        activeOnly: activeOnly,
      );

      final protocols = <Protocol>[];
      for (final dto in dtos) {
        final result = dto.toDomain();
        if (result.isLeft()) {
          return left(
            result.getLeft().getOrElse(() => throw StateError('Unreachable')),
          );
        }
        protocols.add(
          result.getOrElse((l) => throw StateError('Unreachable')),
        );
      }

      return right(protocols);
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('Protocol', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'Protocol.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Protocol.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, Unit>> save(Protocol protocol) async {
    try {
      final dto = ProtocolDto.fromDomain(protocol);
      await _dataSource.saveProtocol(dto);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('Protocol', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'Protocol.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Protocol.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }
}
