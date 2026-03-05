import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// A centered error message with a "Pull to refresh to retry." subtitle.
///
/// Used by Home, Library, and Progress views when data loading fails.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: semanticColors.inkSubtle,
                height: 1.5,
              ),
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              'Pull to refresh to retry.',
              textAlign: TextAlign.center,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: semanticColors.inkSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
