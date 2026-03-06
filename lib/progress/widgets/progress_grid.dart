import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/progress/progress_state.dart';
import 'package:neurostack/progress/widgets/progress_day_cell.dart';

class ProgressGrid extends StatelessWidget {
  const ProgressGrid({
    super.key,
    required this.rows,
    required this.weekRange,
    required this.todayIndex,
    required this.isOffline,
    required this.onTapMissedCell,
  });

  final List<ProtocolRow> rows;
  final DateTimeRange weekRange;
  final int todayIndex;
  final bool isOffline;
  final void Function(String protocolId, String protocolName, DateTime day)
  onTapMissedCell;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    assert(!weekRange.start.isAfter(weekRange.end));
    final spacing = context.spacing;
    final semanticColors = context.semanticColors;

    return Container(
      decoration: BoxDecoration(
        color: semanticColors.surfaceElevated,
        borderRadius: context.borderRadius.r24,
        border: Border.all(color: semanticColors.borderSubtle),
      ),
      padding: EdgeInsets.all(spacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          const preferredGap = 8.0;
          const minGap = 2.0;
          const minCellSize = 36.0;
          const maxCellSize = 52.0;
          const minNameWidth = 64.0;

          const minGridWidth =
              minNameWidth + (minCellSize * 7) + (preferredGap * 6);
          final layoutWidth = math.max(maxWidth, minGridWidth);

          final desiredNameWidth = layoutWidth * 0.32;
          final maxNameWidthForMinCells = math.max(
            0.0,
            layoutWidth - (minCellSize * 7 + preferredGap * 6),
          );

          double nameWidth;
          if (maxNameWidthForMinCells < minNameWidth) {
            nameWidth = math.max(0.0, maxNameWidthForMinCells);
          } else {
            nameWidth = desiredNameWidth
                .clamp(minNameWidth, maxNameWidthForMinCells)
                .toDouble();
          }
          nameWidth = math.min(nameWidth, layoutWidth);

          final gapMax = math.max(0.0, (layoutWidth - nameWidth) / 6);
          final cellGap = gapMax >= minGap
              ? gapMax.clamp(minGap, preferredGap).toDouble()
              : gapMax;

          final availableWidth = math.max(
            0.0,
            layoutWidth - nameWidth - (cellGap * 6),
          );
          final cellSize = math.min(maxCellSize, availableWidth / 7);

          if (rows.isEmpty) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: layoutWidth,
                height: math.max(140, cellSize * 4),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.layers,
                        size: 32,
                        color: semanticColors.borderSubtle,
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        'Add protocols to track',
                        style: context.theme.textTheme.bodyMedium?.copyWith(
                          color: semanticColors.inkSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: layoutWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(context, nameWidth, cellSize, cellGap),
                  SizedBox(height: spacing.md),
                  for (final row in rows) ...[
                    _buildProtocolRow(
                      context,
                      row,
                      nameWidth,
                      cellSize,
                      cellGap,
                    ),
                    SizedBox(height: spacing.lg - spacing.xs),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    double nameWidth,
    double cellSize,
    double cellGap,
  ) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: nameWidth),
        for (var i = 0; i < _dayLabels.length; i++) ...[
          if (i > 0) SizedBox(width: cellGap),
          SizedBox(
            width: cellSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dayLabels[i],
                  textAlign: TextAlign.center,
                  style: context.theme.textTheme.labelSmall?.copyWith(
                    color: i == todayIndex
                        ? kitColors.brandSky
                        : semanticColors.inkSubtle,
                  ),
                ),
                SizedBox(height: context.spacing.xs),
                if (i == todayIndex)
                  Container(
                    height: 2,
                    width: cellSize * 0.6,
                    decoration: BoxDecoration(
                      color: kitColors.brandSky,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProtocolRow(
    BuildContext context,
    ProtocolRow row,
    double nameWidth,
    double cellSize,
    double cellGap,
  ) {
    final semanticColors = context.semanticColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: nameWidth,
          child: Tooltip(
            message: row.protocolName,
            child: Text(
              row.protocolName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: semanticColors.ink,
              ),
            ),
          ),
        ),
        for (var i = 0; i < row.cells.length; i++) ...[
          if (i > 0) SizedBox(width: cellGap),
          ProgressDayCell(
            state: row.cells[i].state,
            size: cellSize,
            isOffline: isOffline,
            onTap: row.cells[i].state == CellState.notDone && !isOffline
                ? () => onTapMissedCell(
                    row.protocolId,
                    row.protocolName,
                    row.cells[i].date,
                  )
                : null,
          ),
        ],
      ],
    );
  }
}
