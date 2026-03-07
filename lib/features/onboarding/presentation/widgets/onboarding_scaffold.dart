import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/ui/widgets/dark_theme_scope.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/onboarding_progress_dots.dart';

/// Scaffold wrapper for all onboarding screens.
///
/// Provides consistent layout with grid background, scrollable content,
/// fixed bottom region with progress dots and CTA.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.scrollableContent,
    required this.bottomCta,
    required this.currentStep,
    this.totalSteps = 4,
  });

  /// The scrollable content area (screen-specific).
  final Widget scrollableContent;

  /// The bottom CTA widget (primary or ghost button).
  final Widget bottomCta;

  /// Current step index (0-based).
  final int currentStep;

  /// Total number of steps (default: 4).
  final int totalSteps;

  /// Show top glow only for Screen 3 (Offer screen, step index 2).
  bool get _showTopGlow => currentStep == 2;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return DarkThemeScope(
      child: AppGridBackground(
        showTopGlow: _showTopGlow,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: scrollableContent),
                      // Flexible spacer that fills remaining space
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        fillOverscroll: false,
                        child: SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                // Fixed bottom region (outside scroll)
                Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OnboardingProgressDots(
                        currentStep: currentStep,
                        totalSteps: totalSteps,
                      ),
                      SizedBox(height: spacing.md),
                      bottomCta,
                    ],
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
