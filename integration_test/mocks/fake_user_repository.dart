import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';

/// Fake [UserRepository] that returns a fixed [User] for integration tests.
///
/// Used to bypass the real Supabase remote data source while still exercising
/// the full HomeViewModel._loadHome() flow. Without this, the
/// [MockDataSourceAbstraction] would throw on `.from('users')` since only
/// `.auth` is stubbed.
class FakeUserRepository implements UserRepository {
  FakeUserRepository(this._user);

  User _user;

  /// Update the user returned by [getById] (e.g., after subscription changes).
  void setUser(User user) {
    _user = user;
  }

  @override
  Future<Either<DomainFailure, User>> getById(String id) async {
    if (id == _user.id) {
      return right(_user);
    }
    return left(
      const DomainFailure(code: 'User.NotFound', message: 'User not found'),
    );
  }

  @override
  Future<Either<DomainFailure, List<User>>> list({
    SubscriptionStatus? subscriptionStatus,
    bool? onboardingCompleted,
  }) async {
    return right([_user]);
  }

  @override
  Future<Either<DomainFailure, Unit>> save(User user) async {
    _user = user;
    return right(unit);
  }
}
