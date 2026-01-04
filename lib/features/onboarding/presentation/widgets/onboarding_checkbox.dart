import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// A custom checkbox for the onboarding disclaimer screen.
///
/// 24px size, rounded-lg, brand colors, scale animation on check.
class OnboardingCheckbox extends StatelessWidget {
  const OnboardingCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final durations = context.durations;
    final spacing = context.spacing;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          AnimatedContainer(
            duration: durations.duration150,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: context.borderRadius.lg,
              color: value ? kitColors.brandSky : kitColors.white05,
              border: Border.all(
                color: value ? kitColors.brandSky : kitColors.white20,
                width: 1.5,
              ),
            ),
            child: AnimatedScale(
              duration: durations.duration150,
              scale: value ? 1.0 : 0.0,
              child: Icon(
                Icons.check,
                size: 16,
                color: kitColors.background,
              ),
            ),
          ),
          SizedBox(width: spacing.md),
          // Label
          Expanded(
            child: Text(
              label,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: kitColors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
