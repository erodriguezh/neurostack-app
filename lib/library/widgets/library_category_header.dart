import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

class LibraryCategoryHeader extends StatelessWidget {
  const LibraryCategoryHeader({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    return Text(
      label,
      style: context.theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        letterSpacing: 1.2,
        color: kitColors.white50,
      ),
    );
  }
}
