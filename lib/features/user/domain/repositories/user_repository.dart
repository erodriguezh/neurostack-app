import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/domain_failure.dart';
import '../entities/user.dart';
import '../enums/subscription_status.dart';

/// Repository interface for User aggregate persistence.
///
/// Defines the contract for user storage and retrieval operations.
/// All methods return `Either<DomainFailure, T>` to handle errors at domain level.
abstract interface class UserRepository {
  /// Retrieves a single user by their unique identifier.
  ///
  /// Returns [DomainFailure] if the user is not found or if an
  /// infrastructure error occurs.
  Future<Either<DomainFailure, User>> getById(String id);

  /// Queries users with optional filters.
  ///
  /// Parameters:
  /// - [subscriptionStatus]: Filter by subscription state (for analytics, cohort queries)
  /// - [onboardingCompleted]: Filter by onboarding completion status
  ///
  /// Multiple filters combine with AND logic.
  /// Returns an empty list if no users match the criteria.
  /// Primarily used for admin/analytics queries in mobile context.
  Future<Either<DomainFailure, List<User>>> list({
    SubscriptionStatus? subscriptionStatus,
    bool? onboardingCompleted,
  });

  /// Persists a user (insert or update).
  ///
  /// Returns [Unit] on success, [DomainFailure] on infrastructure errors.
  /// Trial/subscription gating is handled by `SubscriptionStatusResolver`.
  Future<Either<DomainFailure, Unit>> save(User user);
}
