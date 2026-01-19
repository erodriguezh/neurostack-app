import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/utils/date_time_extensions.dart';

void main() {
  group('DateTimeWeekExtension', () {
    test('weekStart_whenWednesday_returnsMonday', () {
      // Arrange
      final date = DateTime(2025, 1, 15); // Wednesday

      // Act
      final result = date.weekStart;

      // Assert
      expect(result, DateTime(2025, 1, 13));
    });

    test('weekEnd_whenWednesday_returnsSundayEndOfDay', () {
      // Arrange
      final date = DateTime(2025, 1, 15); // Wednesday

      // Act
      final result = date.weekEnd;

      // Assert
      // weekEnd now uses endOfDay (1 microsecond before next day)
      final expectedNextDay = DateTime(2025, 1, 20);
      expect(
        result,
        expectedNextDay.subtract(const Duration(microseconds: 1)),
      );
    });

    test('weekStart_whenCrossingYear_returnsPreviousYearMonday', () {
      // Arrange
      final date = DateTime(2025, 1, 1); // Wednesday

      // Act
      final result = date.weekStart;

      // Assert
      expect(result, DateTime(2024, 12, 30));
    });

    test('weekEnd_whenCrossingYear_returnsNextYearSunday', () {
      // Arrange
      final date = DateTime(2024, 12, 31); // Tuesday

      // Act
      final result = date.weekEnd;

      // Assert
      // weekEnd now uses endOfDay (1 microsecond before next day)
      final expectedNextDay = DateTime(2025, 1, 6);
      expect(
        result,
        expectedNextDay.subtract(const Duration(microseconds: 1)),
      );
    });

    test('isSameDay_whenSameCalendarDay_returnsTrue', () {
      // Arrange
      final first = DateTime(2025, 3, 10, 9, 30);
      final second = DateTime(2025, 3, 10, 18, 45);

      // Act
      final result = first.isSameDay(second);

      // Assert
      expect(result, isTrue);
    });

    test('isSameDay_whenDifferentDay_returnsFalse', () {
      // Arrange
      final first = DateTime(2025, 3, 10, 23, 59);
      final second = DateTime(2025, 3, 11, 0, 1);

      // Act
      final result = first.isSameDay(second);

      // Assert
      expect(result, isFalse);
    });

    test('startOfDay_returnsDateAtMidnight', () {
      // Arrange
      final date = DateTime(2025, 3, 15, 14, 30, 45, 123);

      // Act
      final result = date.startOfDay;

      // Assert
      expect(result, DateTime(2025, 3, 15));
      expect(result.isUtc, isFalse);
    });

    test('startOfDay_whenUtc_preservesUtc', () {
      // Arrange
      final date = DateTime.utc(2025, 3, 15, 14, 30);

      // Act
      final result = date.startOfDay;

      // Assert
      expect(result, DateTime.utc(2025, 3, 15));
      expect(result.isUtc, isTrue);
    });

    test('endOfDay_returnsOneMicrosecondBeforeNextDay', () {
      // Arrange
      final date = DateTime(2025, 3, 15, 8, 0);

      // Act
      final result = date.endOfDay;

      // Assert
      // endOfDay is 1 microsecond before start of next day
      final expectedNextDay = DateTime(2025, 3, 16);
      expect(
        result,
        expectedNextDay.subtract(const Duration(microseconds: 1)),
      );
      expect(result.isUtc, isFalse);
    });

    test('endOfDay_whenUtc_preservesUtc', () {
      // Arrange
      final date = DateTime.utc(2025, 3, 15, 8, 0);

      // Act
      final result = date.endOfDay;

      // Assert
      final expectedNextDay = DateTime.utc(2025, 3, 16);
      expect(
        result,
        expectedNextDay.subtract(const Duration(microseconds: 1)),
      );
      expect(result.isUtc, isTrue);
    });
  });
}
