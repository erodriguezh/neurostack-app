import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// A reusable primary call-to-action button with consistent styling.
///
/// Used by auth and onboarding screens for primary actions.
class AppPrimaryCta extends StatelessWidget {
  const AppPrimaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.showGlow = true,
  });

  /// The text label displayed on the button.
  final String label;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Whether the button is enabled (default: true).
  final bool enabled;

  /// Whether to show a loading spinner instead of the label.
  final bool loading;

  /// Whether to show the sky glow effect when enabled (default: true).
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final isEnabled = enabled && !loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: context.borderRadius.full,
        boxShadow: isEnabled && showGlow ? context.shadows.skyGlowStrong : [],
      ),
      child: FilledButton(
        onPressed: isEnabled ? _handlePressed : null,
        style: _buildStyle(context),
        child: AnimatedSwitcher(
          duration: context.durations.duration150,
          child: loading
              ? SizedBox(
                  key: const ValueKey('cta-loading'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: enabled
                        ? kitColors.background
                        : semanticColors.inkSubtle,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  key: const ValueKey('cta-label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label),
                    SizedBox(width: context.spacing.xs),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
        ),
      ),
    );
  }

  void _handlePressed() {
    HapticFeedback.lightImpact();
    onPressed();
  }

  ButtonStyle _buildStyle(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;

    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: context.borderRadius.full),
      textStyle: context.theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return semanticColors.surface;
        }
        return kitColors.brandSky;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return semanticColors.inkSubtle;
        }
        return kitColors.background;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: semanticColors.borderSubtle);
        }
        return BorderSide(color: kitColors.brandSky);
      }),
    );
  }
}
