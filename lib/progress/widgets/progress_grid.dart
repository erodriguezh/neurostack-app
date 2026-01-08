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
    final kitColors = context.kitColors;

    return Container(
      decoration: BoxDecoration(
        color: kitColors.white02,
        borderRadius: context.borderRadius.r24,
        border: Border.all(color: kitColors.white10),
      ),
      padding: EdgeInsets.all(spacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final nameWidth = (maxWidth * 0.32).clamp(88.0, 144.0);
          const cellGap = 8.0;
          final availableWidth = maxWidth - nameWidth - (cellGap * 6);
          final cellSize = (availableWidth / 7).clamp(28.0, 52.0);

          if (rows.isEmpty) {
            return SizedBox(
              height: math.max(140, cellSize * 4),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.layers,
                      size: 32,
                      color: kitColors.white20,
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      'Add protocols to track',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: kitColors.white40,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
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
                        : kitColors.white40,
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
    final kitColors = context.kitColors;

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
                color: kitColors.white70,
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
