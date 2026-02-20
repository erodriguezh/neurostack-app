import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/features/auth/data/user_bootstrap_service.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';

/// Fake [ConnectivityService] that always reports online.
///
/// Used in integration tests where connectivity status is irrelevant.
class FakeConnectivityService implements ConnectivityService {
  @override
  final ValueNotifier<NetworkStatus> status =
      ValueNotifier<NetworkStatus>(NetworkStatus.online);

  @override
  Future<void> init() async {}

  @override
  void dispose() {
    status.dispose();
  }
}

/// Fake [UserBootstrapService] that returns a fixed [User] on rehydration.
///
/// Used in integration tests to bypass the real Supabase remote data source
/// while still exercising the auth → rehydration flow.
class FakeUserBootstrapService implements UserBootstrapService {
  FakeUserBootstrapService(this._user);

  final User _user;
  bool _hasRemoteUserRecord = true;

  @override
  bool get hasRemoteUserRecord => _hasRemoteUserRecord;

  @override
  void invalidatePresenceCache() {
    _hasRemoteUserRecord = false;
  }

  @override
  Future<Either<DomainFailure, UserBootstrapResult>> rehydrateFromRemote({
    required String userId,
    DateTime? authCreatedAt,
  }) async {
    return right(UserBootstrapResult(user: _user, didRecoverUpsert: false));
  }
}
