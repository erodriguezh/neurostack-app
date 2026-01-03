import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/curves.dart';

/// A ghost/secondary button for onboarding screens.
///
/// Used for "Skip trial" and similar secondary actions.
/// Styling: Full width, h-14, rounded-full, bg-white/5, border white/10.
class OnboardingGhostButton extends StatefulWidget {
  const OnboardingGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<OnboardingGhostButton> createState() => _OnboardingGhostButtonState();
}

class _OnboardingGhostButtonState extends State<OnboardingGhostButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final durations = context.durations;

    return SizedBox(
      width: double.infinity,
      height: 56, // h-14
      child: Material(
        color: kitColors.white05,
        shape: RoundedRectangleBorder(
          borderRadius: context.borderRadius.full,
          side: BorderSide(color: kitColors.white10),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
          onHover: (value) => setState(() => _isHovered = value),
          borderRadius: context.borderRadius.full,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: context.theme.textTheme.labelLarge?.copyWith(
                    color: kitColors.white80,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: context.spacing.xs),
                AnimatedSlide(
                  duration: durations.duration150,
                  curve: CustomCurves.easeOut,
                  offset: Offset(_isHovered ? 0.2 : 0, 0),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: kitColors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
