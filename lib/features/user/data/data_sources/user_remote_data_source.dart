import '../../../../core/utils/data_source/data_source_abstraction.dart';
import '../../domain/enums/subscription_status.dart';
import '../dtos/user_dto.dart';

/// Remote data source for User aggregate.
///
/// Handles all Supabase table operations for users.
/// Returns [UserDto] objects, not raw JSON.
class UserRemoteDataSource {
  final DataSourceAbstraction _dataSource;

  UserRemoteDataSource(this._dataSource);

  static const _table = 'users';

  /// Retrieves a single user by ID.
  ///
  /// Throws [Exception] if user not found or connection fails.
  Future<UserDto> getUser(String id) async {
    final json = await _dataSource
        .from(_table)
        .select()
        .eq('id', id)
        .single();
    return UserDto.fromJson(json);
  }

  /// Queries users with optional filters.
  ///
  /// All filters combine with AND logic. Returns empty list if no matches.
  /// Primarily used for admin/analytics queries in mobile context.
  Future<List<UserDto>> getUsers({
    SubscriptionStatus? subscriptionStatus,
    bool? onboardingCompleted,
  }) async {
    var query = _dataSource.from(_table).select();

    if (subscriptionStatus != null) {
      query = query.eq('subscription_status', subscriptionStatus.name);
    }

    if (onboardingCompleted != null) {
      query = query.eq('onboarding_completed', onboardingCompleted);
    }

    final jsonList = await query;
    return jsonList.map<UserDto>((json) => UserDto.fromJson(json)).toList();
  }

  /// Persists a user (insert or update).
  ///
  /// Trial expiration is handled by User.getEffectiveStatus() in domain logic,
  /// not at the database level.
  Future<void> saveUser(UserDto dto) async {
    await _dataSource.from(_table).upsert(dto.toJson());
  }

  /// Inserts a user with explicit conflict handling for recovery flows.
  Future<void> upsertUser(
    UserDto dto, {
    String? onConflict,
    bool ignoreDuplicates = false,
  }) async {
    await _dataSource.from(_table).upsert(
      dto.toJson(),
      onConflict: onConflict,
      ignoreDuplicates: ignoreDuplicates,
    );
  }
}
