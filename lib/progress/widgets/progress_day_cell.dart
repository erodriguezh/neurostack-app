import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/dashed_rounded_border.dart';
import 'package:neurostack/progress/progress_state.dart';

class ProgressDayCell extends StatelessWidget {
  const ProgressDayCell({
    super.key,
    required this.state,
    required this.size,
    required this.isOffline,
    required this.onTap,
  });

  final CellState state;
  final double size;
  final bool isOffline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = !isOffline && onTap != null;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: context.durations.duration150,
        transitionBuilder: (child, animation) {
          final scale = Tween<double>(begin: 0.96, end: 1).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: _buildCell(context),
      ),
    );
  }

  Widget _buildCell(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final borderRadius = context.borderRadius.xxl;

    switch (state) {
      case CellState.completed:
        return Container(
          key: const ValueKey('cell-completed'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: kitColors.brandSky.withValues(alpha: 0.2),
            borderRadius: borderRadius,
            border: Border.all(
              color: kitColors.brandSky.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: kitColors.brandSky.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.check,
            size: 16,
            color: kitColors.brandSky,
          ),
        );
      case CellState.notDone:
        return Container(
          key: const ValueKey('cell-not-done'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: semanticColors.surface,
            borderRadius: borderRadius,
            border: Border.all(color: semanticColors.borderSubtle),
          ),
        );
      case CellState.future:
        return DashedRoundedBorder(
          key: const ValueKey('cell-future'),
          borderRadius: borderRadius,
          color: semanticColors.borderSubtle,
          strokeWidth: 1,
          child: SizedBox(width: size, height: size),
        );
    }
  }
}
