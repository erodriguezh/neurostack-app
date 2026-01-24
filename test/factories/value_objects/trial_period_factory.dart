import 'package:neurostack/features/user/domain/value_objects/trial_period.dart';
import '../../constants/test_constants.dart';

abstract final class TrialPeriodFactory {
  /// Creates a trial period starting at test constant date.
  static TrialPeriod create({DateTime? startDate}) {
    return TrialPeriod.fromStartDate(
      startDate ?? TestConstants.trial.startDate,
    );
  }

  /// Creates an already-expired trial period.
  static TrialPeriod expired() {
    // Start 8 days ago from reference point
    return TrialPeriod.fromStartDate(
      TestConstants.trial.startDate.subtract(const Duration(days: 8)),
    );
  }

  /// Creates a trial with N days remaining.
  static TrialPeriod withDaysRemaining(int days, {required DateTime asOf}) {
    assert(days >= 0 && days <= 7, 'Days must be between 0 and 7');
    final startDate = asOf.subtract(Duration(days: 7 - days));
    return TrialPeriod.fromStartDate(startDate);
  }

  /// Creates a trial with explicit start and end dates.
  /// Use for DB hydration testing where endDate is stored, not computed.
  static TrialPeriod withDates({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return TrialPeriod.fromDates(startDate: startDate, endDate: endDate);
  }
}
