import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/onboarding_scaffold.dart';

/// Screen 3: Offer - "What if you just... did the thing?"
///
/// Presents the solution with trial offer. Uses brandSky/10 top glow.
class OfferScreen extends StatefulWidget {
  const OfferScreen({
    super.key,
    required this.onNext,
  });

  final VoidCallback onNext;

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  bool _skipped = false;

  void _skipAnimations() {
    if (!_skipped) {
      setState(() => _skipped = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;
    final durations = context.durations;

    return OnboardingScaffold(
      currentStep: 2, // Step index 2 shows top glow
      bottomCta: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPrimaryCta(
            label: "Get started",
            onPressed: widget.onNext,
          ),
          SizedBox(height: spacing.sm),
          // Secondary link
          GestureDetector(
            onTap: widget.onNext,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.sm),
              child: Text(
                "Sign in instead",
                style: context.theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: kitColors.white30,
                ),
              ),
            ),
          ),
        ],
      ),
      scrollableContent: GestureDetector(
        onTap: _skipAnimations,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          child: Column(
            children: [
              SizedBox(height: spacing.xl),
              // Headline
              _AnimatedItem(
                index: 0,
                skipped: _skipped,
                duration: durations.duration500,
                child: Column(
                  children: [
                    Text(
                      "What if you just...",
                      style: GoogleFonts.newsreader(
                        fontSize: 28,
                        fontStyle: FontStyle.italic,
                        color: kitColors.white70,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "did the thing?",
                      style: GoogleFonts.newsreader(
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        color: kitColors.white90,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: kitColors.brandSky.withValues(alpha: 0.15),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.md),
              // Subhead
              _AnimatedItem(
                index: 1,
                skipped: _skipped,
                duration: durations.duration500,
                child: SizedBox(
                  width: 300,
                  child: Text(
                    "NeuroStack is the simplest way to stick with science-backed protocols.",
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: kitColors.white50,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: spacing.xl),
              // Value props card
              _AnimatedItem(
                index: 2,
                skipped: _skipped,
                duration: durations.duration500,
                child: _ValuePropsCard(),
              ),
              SizedBox(height: spacing.lg),
              // Trial offer card
              _AnimatedItem(
                index: 3,
                skipped: _skipped,
                duration: durations.duration500,
                child: _TrialOfferCard(),
              ),
              SizedBox(height: spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValuePropsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: kitColors.white02,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kitColors.white05),
      ),
      child: Column(
        children: [
          const _ValuePropRow(
            icon: LucideIcons.eye,
            text: "See exactly what to do today",
          ),
          SizedBox(height: spacing.md),
          const _ValuePropRow(
            icon: LucideIcons.flame,
            text: "Build streaks that feel good to maintain",
          ),
          SizedBox(height: spacing.md),
          const _ValuePropRow(
            icon: LucideIcons.sparkles,
            text: "Actually become the person who does this stuff",
          ),
        ],
      ),
    );
  }
}

class _ValuePropRow extends StatelessWidget {
  const _ValuePropRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: kitColors.brandSky,
        ),
        SizedBox(width: spacing.md),
        Expanded(
          child: Text(
            text,
            style: context.theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: kitColors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrialOfferCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: kitColors.brandSky.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kitColors.brandSky.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            "7-day free trial",
            style: context.theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: kitColors.brandSky,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            "Payment method required \u2022 cancel anytime",
            style: context.theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: kitColors.white50,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated item with 150ms stagger.
class _AnimatedItem extends StatefulWidget {
  const _AnimatedItem({
    required this.index,
    required this.skipped,
    required this.duration,
    required this.child,
  });

  final int index;
  final bool skipped;
  final Duration duration;
  final Widget child;

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _scheduleAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedItem old) {
    super.didUpdateWidget(old);
    if (widget.skipped && !_visible) {
      setState(() => _visible = true);
    }
  }

  void _scheduleAnimation() {
    final delay = Duration(milliseconds: widget.index * 150);
    Future.delayed(delay, () {
      if (mounted && !_visible) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = _visible || widget.skipped;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: widget.duration,
      child: widget.child,
    );
  }
}
