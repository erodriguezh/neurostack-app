import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/domain/value_objects/trial_period.dart';
import '../../../constants/test_constants.dart';
import '../../../factories/factories.dart';

void main() {
  group('TrialPeriod', () {
    // INV-M2: Exactly 7 days
    test('trialDurationDays_isExactly7', () {
      // Act & Assert
      expect(TrialPeriod.trialDurationDays, 7);
    });

    group('startNow', () {
      test('startNow_createsTrialWithCurrentTime', () {
        // Act
        final trial = TrialPeriod.startNow();

        // Assert - trial should start within last second
        final now = DateTime.now();
        final difference = now.difference(trial.startDate).inSeconds;
        expect(difference, lessThanOrEqualTo(1));
      });
    });

    group('endDate', () {
      test('endDate_isExactly7DaysAfterStart', () {
        // Arrange
        final trial = TrialPeriodFactory.create();

        // Act - use trial.startDate to avoid coupling to factory defaults
        final expectedEnd = trial.startDate.add(const Duration(days: 7));

        // Assert
        expect(trial.endDate, expectedEnd);
      });
    });

    group('fromDates', () {
      test('fromDates_preservesProvidedDates', () {
        // Arrange - use explicit dates that may not follow 7-day rule
        // This simulates DB hydration where we trust the stored values
        final startDate = DateTime(2025, 1, 1, 12, 0, 0);
        final endDate = DateTime(2025, 1, 8, 12, 0, 0);

        // Act
        final trial = TrialPeriod.fromDates(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert - both dates should be preserved exactly
        expect(trial.startDate, startDate);
        expect(trial.endDate, endDate);
      });

      test('fromDates_doesNotRecomputeEndDate', () {
        // Arrange - intentionally use a non-standard end date
        // to verify fromDates doesn't recompute
        final startDate = DateTime(2025, 6, 15);
        final customEndDate = DateTime(2025, 6, 22, 23, 59, 59);

        // Act
        final trial = TrialPeriod.fromDates(
          startDate: startDate,
          endDate: customEndDate,
        );

        // Assert - endDate should NOT be startDate + 7 days
        final computedEndDate = startDate.add(const Duration(days: 7));
        expect(trial.endDate, isNot(equals(computedEndDate)));
        expect(trial.endDate, customEndDate);
      });
    });

    group('isExpired', () {
      test('isExpired_beforeEndDate_returnsFalse', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime = TestConstants.trial.activeCheckTime;

        // Act & Assert
        expect(trial.isExpired(checkTime), false);
      });

      test('isExpired_afterEndDate_returnsTrue', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime = TestConstants.trial.expiredCheckTime;

        // Act & Assert
        expect(trial.isExpired(checkTime), true);
      });

      test('isExpired_exactlyAtEndDate_returnsTrue', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime = TestConstants.trial.endDate;

        // Act & Assert - boundary: exactly at end IS expired (inclusive)
        // This ensures consistency with daysRemaining(0) and displayText("Trial expired")
        expect(trial.isExpired(checkTime), true);
      });
    });

    group('daysRemaining', () {
      final remainingCases = [
        (daysElapsed: 0, expected: 7, desc: 'day1'),
        (daysElapsed: 3, expected: 4, desc: 'midTrial'),
        (daysElapsed: 6, expected: 1, desc: 'lastDay'),
        (daysElapsed: 7, expected: 0, desc: 'expired'),
        (daysElapsed: 10, expected: 0, desc: 'longExpired'),
      ];

      for (final c in remainingCases) {
        test('daysRemaining_after${c.daysElapsed}Days_returns${c.expected}', () {
          // Arrange
          final trial = TrialPeriodFactory.create();
          final checkTime =
              TestConstants.trial.startDate.add(Duration(days: c.daysElapsed));

          // Act & Assert
          expect(trial.daysRemaining(checkTime), c.expected);
        });
      }
    });

    group('status', () {
      test('status_whenActive_returnsActive', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime = TestConstants.trial.activeCheckTime;

        // Act
        final status = trial.status(checkTime);

        // Assert
        expect(status, TrialStatus.active);
      });

      test('status_whenExpired_returnsExpired', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime = TestConstants.trial.expiredCheckTime;

        // Act
        final status = trial.status(checkTime);

        // Assert
        expect(status, TrialStatus.expired);
      });
    });

    group('displayText', () {
      test('displayText_whenActive_showsDaysRemaining', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime = TestConstants.trial.activeCheckTime; // 3 days elapsed

        // Act
        final text = trial.displayText(checkTime);

        // Assert
        expect(text, '4 days left in trial');
      });

      test('displayText_whenExpired_showsExpired', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime = TestConstants.trial.expiredCheckTime;

        // Act
        final text = trial.displayText(checkTime);

        // Assert
        expect(text, 'Trial expired');
      });

      test('displayText_whenOneDay_showsSingularDay', () {
        // Arrange
        final trial = TrialPeriodFactory.create();
        final checkTime =
            TestConstants.trial.startDate.add(const Duration(days: 6));

        // Act
        final text = trial.displayText(checkTime);

        // Assert
        expect(text, '1 day left in trial');
      });
    });
  });
}
