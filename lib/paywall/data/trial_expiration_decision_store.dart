import 'package:shared_preferences/shared_preferences.dart';

/// Persists trial expiration decision state to prevent repeated modal display.
///
/// Key format: `trial_expired_resolved:<userId>:<trialStartDate.toUtc().toIso8601String()>`
abstract interface class TrialExpirationDecisionStore {
  /// Returns true if the user has already resolved the trial expiration decision
  /// for this specific trial instance.
  Future<bool> isResolved({
    required String userId,
    required DateTime trialStartDate,
  });

  /// Marks the trial expiration decision as resolved for this trial instance.
  Future<void> markResolved({
    required String userId,
    required DateTime trialStartDate,
  });
}

class SharedPrefsTrialExpirationDecisionStore
    implements TrialExpirationDecisionStore {
  SharedPrefsTrialExpirationDecisionStore(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'trial_expired_resolved';

  String _key(String userId, DateTime trialStartDate) =>
      '$_keyPrefix:$userId:${trialStartDate.toUtc().toIso8601String()}';

  @override
  Future<bool> isResolved({
    required String userId,
    required DateTime trialStartDate,
  }) async {
    return _prefs.getBool(_key(userId, trialStartDate)) ?? false;
  }

  @override
  Future<void> markResolved({
    required String userId,
    required DateTime trialStartDate,
  }) async {
    await _prefs.setBool(_key(userId, trialStartDate), true);
  }
}
