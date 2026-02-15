import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/dismiss_button.dart';

/// A dismissible banner shown when the user's trial is about to expire.
///
/// Displays "Trial expires tomorrow" with an "Upgrade Now" action button
/// and a dismiss (X) button. Visually styled to match [HomeStatusBanner].
class TrialReminderAlert extends StatelessWidget {
  const TrialReminderAlert({
    super.key,
    required this.onUpgrade,
    required this.onDismiss,
  });

  /// Called when the user taps "Upgrade Now".
  final VoidCallback onUpgrade;

  /// Called when the user dismisses the alert.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;
    final accent = kitColors.yellow400;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.lg,
                  vertical: spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(color: kitColors.white10),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, size: 16, color: accent),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        'Your trial ends soon',
                        style: context.theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: accent,
                        ),
                      ),
                    ),
                    _UpgradeButton(onTap: onUpgrade),
                    SizedBox(width: spacing.xs),
                    DismissButton(onTap: onDismiss),
                  ],
                ),
              ),
            ),
            // Top accent line (matches HomeStatusBanner pattern)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accent.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: kitColors.brandSky,
        textStyle: context.theme.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text('Upgrade Now'),
    );
  }
}
