import 'package:shared_preferences/shared_preferences.dart';

/// Manages onboarding completion state with migration for existing users.
///
/// Uses init/sync pattern: `init()` runs async migration, `isCompleted` is sync getter.
class OnboardingStore {
  OnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  static const _hasCompletedKey = 'has_completed_onboarding';
  static const _hasEverLaunchedKey = 'has_ever_launched';
  static const _migrationVersionKey = 'onboarding_migration_version';
  static const _currentMigrationVersion = 1;

  bool _isInitialized = false;
  bool _isCompletedCached = false;

  /// Returns true once init() has completed - used by router guard.
  bool get isInitialized => _isInitialized;

  /// Call once at startup before any routing.
  Future<void> init() async {
    // Check persisted flag first
    if (_prefs.getBool(_hasCompletedKey) ?? false) {
      _isCompletedCached = true;
      _isInitialized = true;
      return;
    }

    // Durable marker: has_ever_launched survives logout and cache clears
    // This was seeded by pre-onboarding versions on first launch
    final hasEverLaunched = _prefs.getBool(_hasEverLaunchedKey) ?? false;

    // Version-based migration: runs once per migration version
    final storedVersion = _prefs.getInt(_migrationVersionKey) ?? 0;
    if (storedVersion < _currentMigrationVersion) {
      // Check for existing user signals (durable marker OR legacy data)
      // NOTE: intended_route is NOT included - guard now writes it on deep links
      final hasLegacyAppData = _prefs.getKeys().any(
        (key) => key == 'cached_user' || key == 'auth_email',
      );

      if (hasEverLaunched || hasLegacyAppData) {
        // Existing user from pre-onboarding version - skip onboarding
        await markCompleted();
        // CRITICAL: Set migration version AFTER markCompleted() succeeds
        // This ensures migration retries if app crashes mid-migration
        await _prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
        _isCompletedCached = true;
        _isInitialized = true;
        return;
      }

      // New install - set migration version to prevent future migration attempts
      await _prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
    }

    // NOTE: Do NOT set has_ever_launched here - it's only seeded by pre-onboarding releases
    // This ensures future migration bumps don't auto-complete for users who never finished

    // New install OR returning user who didn't have legacy data
    // Show onboarding - user must complete to set has_completed_onboarding
    _isCompletedCached = false;
    _isInitialized = true;
  }

  /// Sync access for routing guards - MUST call init() first.
  bool get isCompleted => _isCompletedCached;

  /// Marks onboarding as completed.
  Future<void> markCompleted() async {
    await _prefs.setBool(_hasCompletedKey, true);
    _isCompletedCached = true;
  }
}
