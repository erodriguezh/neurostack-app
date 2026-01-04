import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/onboarding_ghost_button.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/onboarding_scaffold.dart';

/// Screen 1: Hook - "You've read the studies"
///
/// Uses PAS framework to call out the pain - "you know what to do but aren't doing it"
class HookScreen extends StatefulWidget {
  const HookScreen({
    super.key,
    required this.onNext,
  });

  final VoidCallback onNext;

  @override
  State<HookScreen> createState() => _HookScreenState();
}

class _HookScreenState extends State<HookScreen> {
  bool _skipped = false;

  // Animation delays in milliseconds
  static const _headlineDelay = 0;
  static const _line1Delay = 400;
  static const _line2Delay = 700;
  static const _line3Delay = 1000;
  static const _kickerDelay = 1500;

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
      currentStep: 0,
      bottomCta: OnboardingGhostButton(
        label: "That's me",
        onPressed: widget.onNext,
      ),
      scrollableContent: GestureDetector(
        onTap: _skipAnimations,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: spacing.xxl * 2),
              // Headline
              _AnimatedText(
                delay: const Duration(milliseconds: _headlineDelay),
                duration: durations.duration500,
                skipped: _skipped,
                child: Text(
                  "You've read the studies.",
                  style: GoogleFonts.newsreader(
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                    color: kitColors.white90,
                    letterSpacing: -0.025 * 32,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(height: spacing.lg),
              // Body lines
              _AnimatedText(
                delay:  const Duration(milliseconds: _line1Delay),
                duration: durations.duration500,
                skipped: _skipped,
                child: Text(
                  "You know cold plunges work.",
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.sm),
              _AnimatedText(
                delay: const Duration(milliseconds: _line2Delay),
                duration: durations.duration500,
                skipped: _skipped,
                child: Text(
                  "You know zone 2 cardio extends lifespan.",
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.sm),
              _AnimatedText(
                delay: const Duration(milliseconds: _line3Delay),
                duration: durations.duration500,
                skipped: _skipped,
                child: Text.rich(
                  TextSpan(
                    text: "You know what you ",
                    children: [
                      TextSpan(
                        text: "should",
                        style: _bodyStyle(context).copyWith(
                          fontStyle: FontStyle.italic,
                          color: kitColors.white80,
                        ),
                      ),
                      const TextSpan(text: " be doing."),
                    ],
                  ),
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.xxl),
              // Kicker
              _AnimatedText(
                delay: const Duration(milliseconds: _kickerDelay),
                duration: durations.duration500,
                skipped: _skipped,
                useScale: true,
                child: Text(
                  "So why aren't you doing it?",
                  style: GoogleFonts.newsreader(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: kitColors.brandSky,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: kitColors.brandSky.withValues(alpha: 0.2),
                        blurRadius: 30,
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

  TextStyle _bodyStyle(BuildContext context) {
    final kitColors = context.kitColors;
    return context.theme.textTheme.bodyLarge!.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w300,
      color: kitColors.white60,
      height: 1.6,
    );
  }
}

/// Animated text with fade-in and slide-up effect.
class _AnimatedText extends StatefulWidget {
  const _AnimatedText({
    required this.delay,
    required this.duration,
    required this.skipped,
    required this.child,
    this.useScale = false,
  });

  final Duration delay;
  final Duration duration;
  final bool skipped;
  final Widget child;
  final bool useScale;

  @override
  State<_AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<_AnimatedText> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _scheduleAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedText old) {
    super.didUpdateWidget(old);
    if (widget.skipped && !_visible) {
      setState(() => _visible = true);
    }
  }

  void _scheduleAnimation() {
    Future.delayed(widget.delay, () {
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
      child: widget.useScale
          ? AnimatedScale(
              scale: isVisible ? 1.0 : 0.95,
              duration: widget.duration,
              child: widget.child,
            )
          : AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 0.1),
              duration: widget.duration,
              child: widget.child,
            ),
    );
  }
}
