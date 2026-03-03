import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/settings/widgets/settings_tile.dart';

/// The "SUPPORT & RESOURCES" section of the Settings screen.
///
/// Contains an uppercase section header and a rounded tile container
/// holding the five settings tiles (Contact Us, Send Feedback, Rate the
/// App, Feature Request, Cancel Subscription). Tiles are separated by
/// 1 px dividers.
class SettingsSupportSection extends StatelessWidget {
  const SettingsSupportSection({
    super.key,
    required this.isPremium,
    required this.onContactTap,
    required this.onFeedbackTap,
    required this.onRateAppTap,
    required this.onFeatureRequestTap,
    required this.onCancelSubscriptionTap,
  });

  /// Whether the user has premium status. Drives Cancel Subscription
  /// tile visibility.
  final bool isPremium;

  /// Navigate to the Contact Us page.
  final VoidCallback onContactTap;

  /// Placeholder action for Send Feedback (TODO: Wiredash).
  final VoidCallback onFeedbackTap;

  /// Placeholder action for Rate the App (TODO: App Store).
  final VoidCallback onRateAppTap;

  /// Placeholder action for Feature Request (TODO: Wiredash).
  final VoidCallback onFeatureRequestTap;

  /// Opens platform subscription management.
  final VoidCallback onCancelSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    // Build the list of tiles, filtering out invisible ones for divider logic.
    final tiles = <_TileEntry>[
      _TileEntry(
        icon: LucideIcons.mail,
        label: 'Contact Us',
        trailing: LucideIcons.chevronRight,
        onTap: onContactTap,
        isVisible: true,
      ),
      _TileEntry(
        icon: LucideIcons.messageSquare,
        label: 'Send Feedback',
        trailing: LucideIcons.chevronRight,
        onTap: onFeedbackTap,
        isVisible: true,
      ),
      _TileEntry(
        icon: LucideIcons.star,
        label: 'Rate the App',
        trailing: LucideIcons.externalLink,
        onTap: onRateAppTap,
        isVisible: true,
      ),
      _TileEntry(
        icon: LucideIcons.lightbulb,
        label: 'Feature Request',
        trailing: LucideIcons.chevronRight,
        onTap: onFeatureRequestTap,
        isVisible: true,
      ),
      _TileEntry(
        icon: LucideIcons.creditCard,
        label: 'Cancel Subscription',
        trailing: LucideIcons.externalLink,
        onTap: onCancelSubscriptionTap,
        isVisible: isPremium,
      ),
    ];

    final visibleTiles = tiles.where((t) => t.isVisible).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: spacing.lg,
        right: spacing.lg,
        top: 40, // mt-10 = 40
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 16), // mb-4
            child: Text(
              'SUPPORT & RESOURCES',
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 11 * 0.15, // 0.15em
                color: kitColors.white40,
              ),
            ),
          ),

          // Tile container
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kitColors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < visibleTiles.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: kitColors.white05,
                      ),
                    ),
                  SettingsTile(
                    icon: visibleTiles[i].icon,
                    label: visibleTiles[i].label,
                    trailing: visibleTiles[i].trailing,
                    onTap: visibleTiles[i].onTap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal data class to pair tile parameters with visibility.
class _TileEntry {
  const _TileEntry({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
    required this.isVisible,
  });

  final IconData icon;
  final String label;
  final IconData trailing;
  final VoidCallback onTap;
  final bool isVisible;
}
