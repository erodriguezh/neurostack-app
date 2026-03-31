import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// A single interactive tile in the Settings support section.
///
/// Displays a leading [icon], a text [label], and a [trailing] icon
/// (typically a chevron or external-link indicator). Uses [InkWell] for
/// Material semantics and accessibility, with a subtle press animation
/// (`scale(0.99)` over 150 ms) driven by highlight state and a
/// `bg-white/[0.03]` highlight overlay.
///
/// This widget is specific to the Settings screen and intentionally
/// not extracted into `core/ui`.
class SettingsTile extends StatefulWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  /// Leading icon data (20 px, stroke-width 1.5, semanticColors.inkSubtle).
  final IconData icon;

  /// Tile label text (Inter 15 px, w400, semanticColors.ink).
  final String label;

  /// Trailing icon data (16 px, semanticColors.inkSubtle) -- chevron-right or external-link.
  /// When `null`, no trailing icon is rendered.
  final IconData? trailing;

  /// Called when the user taps the tile.
  final VoidCallback onTap;

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (highlighted) {
          if (!mounted) return;
          setState(() => _pressed = highlighted);
        },
        highlightColor: colorScheme.onSurface.withValues(alpha: 0.03),
        splashFactory: NoSplash.splashFactory,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Leading icon
                Icon(
                  widget.icon,
                  size: 20,
                  color: semanticColors.inkSubtle,
                ),
                const SizedBox(width: 16),

                // Label
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: semanticColors.ink,
                    ),
                  ),
                ),
                // Trailing icon
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    widget.trailing,
                    size: 16,
                    color: semanticColors.inkSubtle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
