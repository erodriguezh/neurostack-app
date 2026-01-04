import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// Progress indicator dots for onboarding flow.
///
/// Non-tappable, visual only. Shows current position in the flow.
class OnboardingProgressDots extends StatelessWidget {
  const OnboardingProgressDots({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  /// Current step index (0-based).
  final int currentStep;

  /// Total number of steps.
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.sm / 2),
          child: AnimatedContainer(
            duration: context.durations.duration150,
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : kitColors.white20,
            ),
          ),
        );
      }),
    );
  }
}
