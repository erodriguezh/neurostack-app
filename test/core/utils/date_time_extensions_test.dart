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
      expect(result, DateTime(2025, 1, 19, 23, 59, 59));
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
      expect(result, DateTime(2025, 1, 5, 23, 59, 59));
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
  });
}
