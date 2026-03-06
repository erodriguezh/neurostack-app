import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// Upgrade CTA banner shown to non-premium users in the Settings screen.
///
/// Displays a crown icon with a glow, headline text ("Unlock All Protocols"),
/// subtitle text, and a trailing chevron. Tapping navigates to the paywall.
///
/// Visibility is controlled by the parent widget via a
/// `ValueListenableBuilder` on the premium status.
class SettingsUpgradeBanner extends StatefulWidget {
  const SettingsUpgradeBanner({
    super.key,
    required this.onTap,
  });

  /// Called when the user taps the banner. Typically navigates to `/paywall`.
  final VoidCallback onTap;

  @override
  State<SettingsUpgradeBanner> createState() => _SettingsUpgradeBannerState();
}

class _SettingsUpgradeBannerState extends State<SettingsUpgradeBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.only(
        left: spacing.lg,
        right: spacing.lg,
        top: spacing.xl,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            if (!mounted) return;
            setState(() => _pressed = highlighted);
          },
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.03),
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedScale(
            scale: _pressed ? 0.99 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Ink(
                padding: EdgeInsets.all(spacing.lg),
                decoration: BoxDecoration(
                  color: semanticColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: kitColors.brandSky.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Crown icon with glow shadow
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: kitColors.brandSky.withValues(alpha: 0.25),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.crown,
                        size: 32,
                        color: kitColors.brandSky,
                      ),
                    ),
                    SizedBox(width: spacing.md),

                    // Headline + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Unlock All Protocols',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: semanticColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unlimited protocols, all future updates',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: semanticColors.inkSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.sm),

                    // Trailing chevron
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: semanticColors.inkSubtle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
