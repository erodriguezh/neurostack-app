import 'package:freezed_annotation/freezed_annotation.dart';

part 'trial_period.freezed.dart';

/// Trial period status.
enum TrialStatus {
  /// Days 1-7 of trial.
  active,

  /// Day 8+ after trial start.
  expired,

  /// User converted to paid subscription.
  converted,
}

/// 7-day trial period management.
///
/// Enforces **INV-M2**: Premium Trial MUST last exactly 7 days.
@freezed
sealed class TrialPeriod with _$TrialPeriod {
  const TrialPeriod._();

  @internal
  const factory TrialPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) = _TrialPeriod;

  /// Trial duration in days. Enforces **INV-M2**.
  static const trialDurationDays = 7;

  /// Creates a trial period starting now.
  factory TrialPeriod.startNow() {
    final start = DateTime.now();
    return TrialPeriod(
      startDate: start,
      endDate: start.add(const Duration(days: trialDurationDays)),
    );
  }

  /// Creates a trial period with a specific start date.
  /// Computes end date as start + 7 days.
  /// Used for backwards compatibility when only start date is available.
  factory TrialPeriod.fromStartDate(DateTime startDate) => TrialPeriod(
        startDate: startDate,
        endDate: startDate.add(const Duration(days: trialDurationDays)),
      );

  /// Creates a trial period with explicit dates from database.
  /// This is the ONLY safe constructor for DB hydration.
  /// Use [startNow] or [fromStartDate] for creating new trials.
  factory TrialPeriod.fromDates({
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      TrialPeriod(startDate: startDate, endDate: endDate);

  /// Check if the trial has expired as of [currentTime].
  ///
  /// Trial expires at [endDate] (inclusive). This ensures consistent behavior:
  /// - `isExpired(endDate)` returns true
  /// - `daysRemaining(endDate)` returns 0
  /// - `displayText(endDate)` returns "Trial expired"
  bool isExpired(DateTime currentTime) => !currentTime.isBefore(endDate);

  /// Days remaining in the trial (0 if expired).
  int daysRemaining(DateTime currentTime) {
    if (isExpired(currentTime)) return 0;
    return endDate.difference(currentTime).inDays;
  }

  /// Get the trial status as of [currentTime].
  TrialStatus status(DateTime currentTime) {
    if (isExpired(currentTime)) return TrialStatus.expired;
    return TrialStatus.active;
  }

  /// Display text for UI showing days remaining.
  /// Example: "3 days left in trial"
  String displayText(DateTime currentTime) {
    final remaining = daysRemaining(currentTime);
    if (remaining == 0) return 'Trial expired';
    if (remaining == 1) return '1 day left in trial';
    return '$remaining days left in trial';
  }
}
