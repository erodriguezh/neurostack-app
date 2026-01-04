import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/onboarding_scaffold.dart';

/// Screen 2: Agitate - "The gap between knowing and doing"
///
/// Agitates the problem and introduces the transformation gap.
class AgitateScreen extends StatefulWidget {
  const AgitateScreen({
    super.key,
    required this.onNext,
  });

  final VoidCallback onNext;

  @override
  State<AgitateScreen> createState() => _AgitateScreenState();
}

class _AgitateScreenState extends State<AgitateScreen> {
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
      currentStep: 1,
      bottomCta: _AgitateGhostButton(
        label: "Too familiar",
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
              SizedBox(height: spacing.xxl),
              // Headline part 1
              _AnimatedParagraph(
                index: 0,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text(
                  "The gap between knowing and doing",
                  style: GoogleFonts.newsreader(
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    color: kitColors.white90,
                    letterSpacing: -0.025 * 26,
                    height: 1.3,
                  ),
                ),
              ),
              // Headline part 2 with warning color
              _AnimatedParagraph(
                index: 1,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text.rich(
                  TextSpan(
                    text: "is where results ",
                    children: [
                      TextSpan(
                        text: "go to die.",
                        style: GoogleFonts.newsreader(
                          fontSize: 26,
                          fontStyle: FontStyle.italic,
                          color: kitColors.warning,
                          letterSpacing: -0.025 * 26,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: kitColors.warning.withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  style: GoogleFonts.newsreader(
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    color: kitColors.white90,
                    letterSpacing: -0.025 * 26,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(height: spacing.xl),
              // Body paragraphs
              _AnimatedParagraph(
                index: 2,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text(
                  "You start strong.",
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.xs),
              _AnimatedParagraph(
                index: 3,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text.rich(
                  TextSpan(
                    text: "Week one, you're ",
                    children: [
                      TextSpan(
                        text: "locked in.",
                        style: _bodyStyle(context).copyWith(
                          color: kitColors.white80,
                        ),
                      ),
                    ],
                  ),
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.md),
              _AnimatedParagraph(
                index: 4,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text(
                  "Week two, life gets busy.",
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.md),
              _AnimatedParagraph(
                index: 5,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text(
                  "Week three, you forgot which day you're supposed to do what.",
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.md),
              _AnimatedParagraph(
                index: 6,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text(
                  "By month two, that protocol you were excited about?",
                  style: _bodyStyle(context),
                ),
              ),
              SizedBox(height: spacing.xs),
              _AnimatedParagraph(
                index: 7,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text(
                  "Just another abandoned experiment.",
                  style: _bodyStyle(context).copyWith(
                    color: kitColors.white40,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: spacing.xl),
              // Hook question
              _AnimatedParagraph(
                index: 8,
                skipped: _skipped,
                duration: durations.duration500,
                child: Text(
                  "Sound familiar?",
                  style: context.theme.textTheme.bodyLarge!.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: kitColors.white80,
                  ),
                ),
              ),
              SizedBox(height: spacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context) {
    final kitColors = context.kitColors;
    return context.theme.textTheme.bodyMedium!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: kitColors.white60,
      height: 1.8,
    );
  }
}

/// Ghost button with emphasized border (white/20 instead of white/10).
class _AgitateGhostButton extends StatefulWidget {
  const _AgitateGhostButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_AgitateGhostButton> createState() => _AgitateGhostButtonState();
}

class _AgitateGhostButtonState extends State<_AgitateGhostButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final durations = context.durations;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: kitColors.white05,
        shape: RoundedRectangleBorder(
          borderRadius: context.borderRadius.full,
          side: BorderSide(color: kitColors.white20), // Emphasized border
        ),
        child: InkWell(
          onTap: widget.onPressed,
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

/// Animated paragraph with 200ms stagger.
class _AnimatedParagraph extends StatefulWidget {
  const _AnimatedParagraph({
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
  State<_AnimatedParagraph> createState() => _AnimatedParagraphState();
}

class _AnimatedParagraphState extends State<_AnimatedParagraph> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _scheduleAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedParagraph old) {
    super.didUpdateWidget(old);
    if (widget.skipped && !_visible) {
      setState(() => _visible = true);
    }
  }

  void _scheduleAnimation() {
    final delay = Duration(milliseconds: widget.index * 200);
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
