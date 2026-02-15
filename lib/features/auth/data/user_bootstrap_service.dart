import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';

import '../../../core/utils/app_environment.dart';
import '../../../core/failures/domain_failure.dart';
import '../../../core/utils/data_source/data_source_abstraction.dart';
import '../../user/data/data_sources/user_remote_data_source.dart';
import '../../user/data/dtos/user_dto.dart';
import '../../user/domain/entities/user.dart';
import '../../user/domain/repositories/user_repository.dart';

class UserBootstrapResult {
  UserBootstrapResult({required this.user, required this.didRecoverUpsert});

  final User user;
  final bool didRecoverUpsert;
}

class UserBootstrapService {
  UserBootstrapService(
    this._userRepository,
    this._userRemoteDataSource,
    this._dataSource,
  );

  final UserRepository _userRepository;
  final UserRemoteDataSource _userRemoteDataSource;
  final DataSourceAbstraction _dataSource;
  final Logger _logger = Logger('UserBootstrap');

  bool _hasRemoteUserRecord = false;

  bool get hasRemoteUserRecord => _hasRemoteUserRecord;

  void invalidatePresenceCache() {
    _hasRemoteUserRecord = false;
  }

  Future<Either<DomainFailure, UserBootstrapResult>> rehydrateFromRemote({
    required String userId,
    DateTime? authCreatedAt,
  }) async {
    final fetchResult = await _userRepository.getById(userId);
    if (fetchResult.isRight()) {
      _hasRemoteUserRecord = true;
      final user = fetchResult.getOrElse(
        (_) => throw StateError('Unreachable'),
      );
      return right(UserBootstrapResult(user: user, didRecoverUpsert: false));
    }

    final failure = fetchResult.getLeft().getOrElse(
      () => const DomainFailure(
        code: 'User.UnexpectedError',
        message: 'Unknown error',
      ),
    );
    if (failure.code == 'User.NotFound') {
      _logger.info(
        'User record missing (env=${AppEnvironment.tag}, userId=$userId). Attempting recovery upsert.',
      );
      final createdAt = _resolveAuthCreatedAt(authCreatedAt);
      final newUser = User.create(
        id: userId,
        createdAt: createdAt,
      );
      final dto = UserDto.fromDomain(newUser);

      try {
        await _userRemoteDataSource.upsertUser(
          dto,
          onConflict: 'id',
          ignoreDuplicates: true,
        );
      } catch (e) {
        _logger.warning(
          'User recovery upsert failed (env=${AppEnvironment.tag}, userId=$userId): $e',
        );
        return left(
          DomainFailure(
            code: 'User.RecoveryUpsertFailed',
            message: e.toString(),
          ),
        );
      }

      final retryResult = await _userRepository.getById(userId);
      if (retryResult.isRight()) {
        _hasRemoteUserRecord = true;
        final user = retryResult.getOrElse(
          (_) => throw StateError('Unreachable'),
        );
        return right(UserBootstrapResult(user: user, didRecoverUpsert: true));
      }
      final retryFailure = retryResult.getLeft().getOrElse(
        () => const DomainFailure(
          code: 'User.UnexpectedError',
          message: 'User fetch failed after recovery upsert',
        ),
      );
      _logger.warning(
        'User fetch failed after recovery upsert (env=${AppEnvironment.tag}, userId=$userId, code=${retryFailure.code}, message=${retryFailure.message})',
      );
      return left(
        retryFailure,
      );
    }

    _logger.warning(
      'User fetch failed (env=${AppEnvironment.tag}, userId=$userId, code=${failure.code}, message=${failure.message})',
    );
    return left(failure);
  }

  DateTime _resolveAuthCreatedAt(DateTime? authCreatedAt) {
    if (authCreatedAt != null) {
      return authCreatedAt;
    }

    final authUser = _dataSource.auth.currentUser;
    if (authUser != null) {
      try {
        return DateTime.parse(authUser.createdAt);
      } catch (_) {
        // Fall through to now.
      }
    }

    return DateTime.now();
  }
}
