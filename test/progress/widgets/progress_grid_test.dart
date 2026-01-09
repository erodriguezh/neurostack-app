import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/progress/progress_state.dart';
import 'package:neurostack/progress/widgets/progress_day_cell.dart';
import 'package:neurostack/progress/widgets/progress_grid.dart';

void main() {
  testWidgets('progressGrid_narrowWidth_doesNotOverflow', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    final weekStart = DateTime(2025, 1, 6);
    final rows = _buildRows(weekStart);

    await tester.pumpWidget(
      _wrap(
        Center(
          child: SizedBox(
            width: 200,
            child: ProgressGrid(
              rows: rows,
              weekRange: DateTimeRange(
                start: weekStart,
                end: weekStart.add(const Duration(days: 6)),
              ),
              todayIndex: 2,
              isOffline: false,
              onTapMissedCell: (_, __, ___) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(find.byType(ProgressDayCell), findsNWidgets(7 * rows.length));
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.buildTheme(Brightness.dark),
    home: Scaffold(body: child),
  );
}

List<ProtocolRow> _buildRows(DateTime weekStart) {
  return [
    ProtocolRow(
      protocolId: 'protocol-1',
      protocolName: 'A very long protocol name that should ellipsize safely',
      cells: _buildCells(weekStart, completedIndices: {0, 2}),
    ),
    ProtocolRow(
      protocolId: 'protocol-2',
      protocolName: 'Sauna',
      cells: _buildCells(weekStart),
    ),
  ];
}

List<DayCell> _buildCells(
  DateTime weekStart, {
  Set<int> completedIndices = const {},
}) {
  return List.generate(7, (index) {
    final date = weekStart.add(Duration(days: index));
    final state = completedIndices.contains(index)
        ? CellState.completed
        : CellState.notDone;
    return DayCell(date: date, state: state);
  });
}
