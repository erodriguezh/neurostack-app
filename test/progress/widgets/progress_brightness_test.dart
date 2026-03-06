import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/core/ui/widgets/dashed_rounded_border.dart';
import 'package:neurostack/progress/progress_state.dart';
import 'package:neurostack/progress/widgets/progress_day_cell.dart';
import 'package:neurostack/progress/widgets/progress_grid.dart';

import '../../helpers/contrast_ratio.dart';

void main() {
  Widget wrap({
    required Brightness brightness,
    required Widget child,
  }) {
    return MaterialApp(
      key: ValueKey(brightness),
      theme: AppTheme.buildTheme(brightness),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Progress widgets brightness migration', () {
    // --- ProgressDayCell ---
    group('ProgressDayCell', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders completed cell without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: const ProgressDayCell(
                    state: CellState.completed,
                    size: 44,
                    isOffline: false,
                    onTap: null,
                  ),
                ),
              );

              expect(
                find.byKey(const ValueKey('cell-completed')),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            'renders notDone cell with semantic surface/borderSubtle',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: ProgressDayCell(
                    state: CellState.notDone,
                    size: 44,
                    isOffline: false,
                    onTap: () {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final container = tester.widget<Container>(
                find.byKey(const ValueKey('cell-not-done')),
              );
              final decoration = container.decoration as BoxDecoration;
              expect(decoration.color, equals(semanticColors.surface));
              expect(
                (decoration.border as Border).top.color,
                equals(semanticColors.borderSubtle),
              );
            },
          );

          testWidgets(
            'renders future cell with semantic border',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: const ProgressDayCell(
                    state: CellState.future,
                    size: 44,
                    isOffline: false,
                    onTap: null,
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final dashed = tester.widget<DashedRoundedBorder>(
                find.byKey(const ValueKey('cell-future')),
              );
              expect(dashed.color, equals(semanticColors.border));
            },
          );

          testWidgets(
            'completed cell uses brandSky (not whiteXX)',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: const ProgressDayCell(
                    state: CellState.completed,
                    size: 44,
                    isOffline: false,
                    onTap: null,
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final kitColors = theme.extension<KitColorsExtension>()!;

              final icon = tester.widget<Icon>(
                find.descendant(
                  of: find.byKey(const ValueKey('cell-completed')),
                  matching: find.byType(Icon),
                ),
              );
              expect(icon.color, equals(kitColors.brandSky));
            },
          );
        });
      }
    });

    // --- ProgressGrid ---
    group('ProgressGrid', () {
      ProgressGrid makeGrid({List<ProtocolRow>? rows}) {
        final weekStart = DateTime(2025, 1, 6);
        return ProgressGrid(
          rows: rows ?? _buildRows(weekStart),
          weekRange: DateTimeRange(
            start: weekStart,
            end: weekStart.add(const Duration(days: 6)),
          ),
          todayIndex: 2,
          isOffline: false,
          onTapMissedCell: (_, __, ___) {},
        );
      }

      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders populated grid without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(brightness: brightness, child: makeGrid()),
              );

              expect(find.byType(ProgressDayCell), findsWidgets);
            },
          );

          testWidgets(
            'grid container uses semantic surfaceElevated and border',
            (tester) async {
              await tester.pumpWidget(
                wrap(brightness: brightness, child: makeGrid()),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              // Find the outer container of ProgressGrid
              final gridContainer = tester.widget<Container>(
                find
                    .descendant(
                      of: find.byType(ProgressGrid),
                      matching: find.byWidgetPredicate(
                        (w) =>
                            w is Container &&
                            w.decoration is BoxDecoration &&
                            (w.decoration as BoxDecoration).border != null &&
                            (w.decoration as BoxDecoration).borderRadius !=
                                null,
                      ),
                    )
                    .first,
              );
              final decoration = gridContainer.decoration as BoxDecoration;
              expect(
                decoration.color,
                equals(semanticColors.surfaceElevated),
              );
              expect(
                (decoration.border as Border).top.color,
                equals(semanticColors.border),
              );
            },
          );

          testWidgets(
            'protocol name uses semantic ink',
            (tester) async {
              await tester.pumpWidget(
                wrap(brightness: brightness, child: makeGrid()),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              // Find the protocol name text
              final protocolText = tester.widget<Text>(
                find.text(
                  'A very long protocol name that should ellipsize safely',
                ),
              );
              expect(
                (protocolText.style as TextStyle).color,
                equals(semanticColors.ink),
              );
            },
          );

          testWidgets(
            'protocol name contrast >= 4.5:1 against grid container',
            (tester) async {
              await tester.pumpWidget(
                wrap(brightness: brightness, child: makeGrid()),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final ratio = contrastRatio(
                semanticColors.ink,
                semanticColors.surfaceElevated,
              );
              expect(
                ratio,
                greaterThanOrEqualTo(wcagAANormalText),
                reason:
                    'Protocol name contrast in ${brightness.name} mode '
                    '(got $ratio)',
              );
            },
          );

          testWidgets(
            'empty state renders without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: makeGrid(rows: []),
                ),
              );

              expect(
                find.text('Add protocols to track'),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            'empty state text uses semantic inkSubtle',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: makeGrid(rows: []),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final emptyText = tester.widget<Text>(
                find.text('Add protocols to track'),
              );
              expect(
                (emptyText.style as TextStyle).color,
                equals(semanticColors.inkSubtle),
              );
            },
          );
        });
      }
    });

    // --- BackdateSessionSheet (via source audit) ---
    // The sheet is shown via showModalBottomSheet which requires
    // navigation context. We verify via source file audit.
    group('BackdateSessionSheet source audit', () {
      test(
        'backdate_session_sheet.dart contains no kitColors.whiteXX',
        () {
          final whiteXXPattern = RegExp(
            r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
          );
          final source = File(
            'lib/progress/widgets/backdate_session_sheet.dart',
          ).readAsStringSync();
          expect(
            whiteXXPattern.allMatches(source),
            isEmpty,
            reason:
                'backdate_session_sheet.dart should not reference any '
                'kitColors.whiteXX tokens',
          );
        },
      );

      test(
        'backdate_session_sheet.dart contains no kitColors.panel',
        () {
          final source = File(
            'lib/progress/widgets/backdate_session_sheet.dart',
          ).readAsStringSync();
          expect(
            RegExp(r'kitColors\.panel').allMatches(source),
            isEmpty,
            reason:
                'backdate_session_sheet.dart should not reference '
                'kitColors.panel for sheet background',
          );
        },
      );
    });

    // --- ProgressView subtitle (source audit) ---
    group('ProgressView source audit', () {
      test(
        'progress_view.dart contains no kitColors.whiteXX',
        () {
          final whiteXXPattern = RegExp(
            r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
          );
          final source = File(
            'lib/progress/progress_view.dart',
          ).readAsStringSync();
          expect(
            whiteXXPattern.allMatches(source),
            isEmpty,
            reason:
                'progress_view.dart should not reference any '
                'kitColors.whiteXX tokens',
          );
        },
      );

      testWidgets(
        'progress_view.dart subtitle contrast >= 3.0:1 in both modes',
        (_) async {
          for (final brightness in Brightness.values) {
            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;
            // Subtitle uses semanticColors.inkSubtle against the
            // grid background surface.
            final ratio = contrastRatio(
              semanticColors.inkSubtle,
              semanticColors.gridBackground,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAALargeText),
              reason:
                  'Progress subtitle contrast in ${brightness.name} '
                  'mode (got $ratio)',
            );
          }
        },
      );

      // Task 10 flips adaptive routes to AppGridBackgroundMode.adaptive.
      test(
        'progress_view.dart AppGridBackground mode is adaptive',
        () {
          final source = File(
            'lib/progress/progress_view.dart',
          ).readAsStringSync();
          expect(
            RegExp(r'mode:\s*AppGridBackgroundMode\.adaptive').hasMatch(source),
            isTrue,
            reason:
                'progress_view.dart should explicitly set '
                'AppGridBackgroundMode.adaptive',
          );
        },
      );
    });

    // --- Source file whiteXX audits ---
    group('source file whiteXX audits', () {
      final whiteXXPattern = RegExp(
        r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
      );

      final files = [
        'lib/progress/progress_view.dart',
        'lib/progress/widgets/progress_grid.dart',
        'lib/progress/widgets/progress_day_cell.dart',
        'lib/progress/widgets/backdate_session_sheet.dart',
      ];

      for (final path in files) {
        test('$path contains no kitColors.whiteXX references', () {
          final source = File(path).readAsStringSync();
          final matches = whiteXXPattern.allMatches(source);
          expect(
            matches,
            isEmpty,
            reason: '$path should not reference any kitColors.whiteXX tokens',
          );
        });
      }
    });
  });
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
