import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final spacing = context.spacing;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semanticColors.borderSubtle,
              border: Border.all(color: semanticColors.border),
            ),
            child: Icon(
              LucideIcons.layers,
              size: 32,
              color: semanticColors.inkSubtle,
            ),
          ),
          SizedBox(height: spacing.md),
          Text(
            'Add your first protocol',
            style: context.theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: semanticColors.inkSubtle,
            ),
          ),
          SizedBox(height: spacing.lg),
          GestureDetector(
            onTap: onBrowse,
            child: Text(
              'Browse Library',
              style: context.theme.textTheme.bodySmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kitColors.brandSky,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
