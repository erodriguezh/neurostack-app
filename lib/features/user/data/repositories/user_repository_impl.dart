import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/data/supabase_error_mapper.dart';
import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/repositories/user_repository.dart';
import '../data_sources/user_remote_data_source.dart';
import '../dtos/user_dto.dart';

/// Repository implementation for User aggregate using Supabase.
///
/// Handles error mapping from infrastructure failures to domain failures.
/// All business logic lives in the domain layer, not here.
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  Future<Either<DomainFailure, User>> getById(String id) async {
    try {
      final dto = await _dataSource.getUser(id);
      return dto.toDomain();
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('User', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'User.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'User.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, List<User>>> list({
    SubscriptionStatus? subscriptionStatus,
    bool? onboardingCompleted,
  }) async {
    try {
      final dtos = await _dataSource.getUsers(
        subscriptionStatus: subscriptionStatus,
        onboardingCompleted: onboardingCompleted,
      );

      final users = <User>[];
      for (final dto in dtos) {
        final result = dto.toDomain();
        if (result.isLeft()) {
          return left(
            result.getLeft().getOrElse(() => throw StateError('Unreachable')),
          );
        }
        users.add(
          result.getOrElse((l) => throw StateError('Unreachable')),
        );
      }

      return right(users);
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('User', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'User.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'User.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, Unit>> save(User user) async {
    try {
      final dto = UserDto.fromDomain(user);
      await _dataSource.saveUser(dto);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return left(mapPostgrestError('User', e));
    } on AuthException catch (e) {
      return left(
        DomainFailure(
          code: 'User.AuthenticationFailed',
          message: e.message,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'User.UnexpectedError',
          message: e.toString(),
        ),
      );
    }
  }
}
