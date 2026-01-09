import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/progress/progress_state.dart';
import 'package:neurostack/progress/progress_view_model.dart';

void main() {
  group('ProgressViewModel', () {
    group('computeCellState', () {
      test('computeCellState_pastDayWithSession_returnsCompleted', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 8);
        final completedDays = {DateTime(2025, 1, 8)};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.completed);
      });

      test('computeCellState_pastDayWithoutSession_returnsNotDone', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 8);
        final completedDays = <DateTime>{};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.notDone);
      });

      test('computeCellState_todayWithoutSession_returnsFuture', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 10);
        final completedDays = <DateTime>{};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.future);
      });

      test('computeCellState_todayWithSession_returnsCompleted', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 10);
        final completedDays = {DateTime(2025, 1, 10)};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.completed);
      });

      test('computeCellState_futureDay_returnsFuture', () {
        // Arrange
        final now = DateTime(2025, 1, 10);
        final day = DateTime(2025, 1, 12);
        final completedDays = <DateTime>{};

        // Act
        final result = ProgressViewModel.computeCellState(
          day: day,
          completedDays: completedDays,
          now: now,
        );

        // Assert
        expect(result, CellState.future);
      });
    });
  });
}
