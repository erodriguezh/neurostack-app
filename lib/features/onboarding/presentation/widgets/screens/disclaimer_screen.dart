import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/onboarding_checkbox.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/onboarding_scaffold.dart';

/// Screen 4: Disclaimer - "One more thing"
///
/// Builds trust before commitment with health disclaimer.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({
    super.key,
    required this.disclaimerAccepted,
    required this.onDisclaimerChanged,
    required this.onComplete,
  });

  final bool disclaimerAccepted;
  final ValueChanged<bool> onDisclaimerChanged;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return OnboardingScaffold(
      currentStep: 3,
      bottomCta: AppPrimaryCta(
        label: "Let's go",
        onPressed: onComplete,
        enabled: disclaimerAccepted,
        showGlow: disclaimerAccepted,
      ),
      scrollableContent: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.lg),
        child: Column(
          children: [
            SizedBox(height: spacing.xxl),
            // Header
            Text(
              "One more thing.",
              style: GoogleFonts.newsreader(
                fontSize: 28,
                fontStyle: FontStyle.italic,
                color: kitColors.white90,
                letterSpacing: -0.025 * 28,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.sm),
            Text(
              "We take your health seriously. So should you.",
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w300,
                color: kitColors.white50,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.xl),
            // Disclaimer card
            _DisclaimerCard(),
            SizedBox(height: spacing.lg),
            // Checkbox
            OnboardingCheckbox(
              value: disclaimerAccepted,
              onChanged: onDisclaimerChanged,
              label: "I understand",
            ),
            SizedBox(height: spacing.xl),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: kitColors.white02,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kitColors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 100,
            decoration: BoxDecoration(
              color: kitColors.warning.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: spacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: kitColors.warning.withValues(alpha: 0.7),
                ),
                SizedBox(height: spacing.md),
                Text.rich(
                  TextSpan(
                    text:
                        "NeuroStack helps you track protocols based on published research—but ",
                    children: [
                      TextSpan(
                        text: "we're not doctors",
                        style: TextStyle(color: kitColors.white70),
                      ),
                      const TextSpan(text: ", and "),
                      TextSpan(
                        text: "this isn't medical advice",
                        style: TextStyle(color: kitColors.white70),
                      ),
                      const TextSpan(
                        text:
                            ". Before starting any new protocol, check with your healthcare provider.",
                      ),
                    ],
                  ),
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: kitColors.white60,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
