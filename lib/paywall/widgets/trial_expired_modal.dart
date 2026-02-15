import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/spotlight_card.dart';

/// The user's choice when the trial expired modal is dismissed.
enum TrialExpiredChoice {
  /// User chose to subscribe to premium.
  keepEverything,

  /// User chose to continue with the free tier.
  continueWithFree,
}

/// Shows the trial expired modal dialog.
///
/// This is a blocking modal that requires the user to make a choice.
/// Returns [TrialExpiredChoice.keepEverything] if user wants to subscribe,
/// or [TrialExpiredChoice.continueWithFree] if user accepts the free tier.
///
/// Parameters:
/// - [context]: The build context for showing the dialog.
/// - [activeProtocolCount]: The number of active protocols the user has.
/// - [isTrialExpiration]: If true, shows "trial has ended" messaging.
///   If false, shows "subscription has lapsed" messaging for paid users.
Future<TrialExpiredChoice?> showTrialExpiredModal(
  BuildContext context, {
  required int activeProtocolCount,
  bool isTrialExpiration = true,
}) async {
  return showDialog<TrialExpiredChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xE6030303), // #030303 at 90%
    builder: (dialogContext) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: TrialExpiredModal(
          activeProtocolCount: activeProtocolCount,
          isTrialExpiration: isTrialExpiration,
        ),
      );
    },
  );
}

/// A blocking modal shown when the user's trial or subscription has expired.
///
/// Displays two options:
/// - "Keep Everything" - subscribe to premium
/// - "Continue with Free" - accept free tier limitations
class TrialExpiredModal extends StatefulWidget {
  const TrialExpiredModal({
    super.key,
    required this.activeProtocolCount,
    this.isTrialExpiration = true,
  });

  /// The number of active protocols the user currently has.
  final int activeProtocolCount;

  /// Whether this is a trial expiration (true) or paid subscription lapse (false).
  ///
  /// Controls the headline text shown to the user.
  final bool isTrialExpiration;

  @override
  State<TrialExpiredModal> createState() => _TrialExpiredModalState();
}

class _TrialExpiredModalState extends State<TrialExpiredModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false, // Block system back, allow programmatic pop
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Amber radial glow at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 260,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 0.8,
                          colors: [
                            kitColors.yellow400.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hourglass icon with glow
                      _HourglassIcon(),
                      SizedBox(height: spacing.xl),
                      // Headline
                      Text(
                        widget.isTrialExpiration
                            ? 'Your Premium Trial Has Ended'
                            : 'Your Subscription Has Lapsed',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.newsreader(
                          fontSize: 28,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: kitColors.white90,
                          letterSpacing: -0.025 * 28,
                          height: 1.2,
                        ),
                      ),
                      // Conditional subtext when activeProtocolCount > 2
                      if (widget.activeProtocolCount > 2) ...[
                        SizedBox(height: spacing.md),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            'You currently have ${widget.activeProtocolCount} active protocols. The free tier allows 2.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: kitColors.white50,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: spacing.xxl),
                      // Decision cards
                      _UpgradeCard(
                        onTap: () => Navigator.of(
                          context,
                        ).pop(TrialExpiredChoice.keepEverything),
                      ),
                      SizedBox(height: spacing.md),
                      _DowngradeCard(
                        onTap: () => Navigator.of(
                          context,
                        ).pop(TrialExpiredChoice.continueWithFree),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hourglass icon with amber stroke and glow effect (decorative).
class _HourglassIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    // Amber-400 color
    final amberColor = kitColors.yellow400;

    // Decorative icon - the headline provides the semantic meaning
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: amberColor.withValues(alpha: 0.2),
              blurRadius: 25,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          LucideIcons.hourglass,
          size: 72,
          color: amberColor,
        ),
      ),
    );
  }
}

/// Premium upgrade card with spotlight effect.
class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return Semantics(
      button: true,
      label: 'Keep Everything. Subscribe to Premium.',
      child: SpotlightCard(
        borderRadius: BorderRadius.circular(24),
        spotlightColor: kitColors.brandSky.withValues(alpha: 0.1),
        child: Material(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: kitColors.brandSky.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Crown icon with glow (decorative)
                  ExcludeSemantics(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: kitColors.brandSky.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.crown,
                        size: 28,
                        color: kitColors.brandSky,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    'Keep Everything',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: kitColors.white90,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'Subscribe to Premium',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: kitColors.brandSky,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  // Arrow (decorative)
                  ExcludeSemantics(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Free tier downgrade card (no spotlight effect).
class _DowngradeCard extends StatelessWidget {
  const _DowngradeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return Semantics(
      button: true,
      label: 'Continue with Free. Limited to 2 protocols.',
      child: Material(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: kitColors.white10,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Layers icon (decorative)
                ExcludeSemantics(
                  child: Icon(
                    LucideIcons.layers,
                    size: 28,
                    color: kitColors.white40,
                  ),
                ),
                SizedBox(height: spacing.sm),
                Text(
                  'Continue with Free',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: kitColors.white70,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  'Limited to 2 protocols',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: kitColors.white40,
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
