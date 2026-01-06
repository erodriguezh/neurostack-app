import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/home/home_state.dart';
import 'package:neurostack/home/widgets/home_status_dot.dart';

class HomeProtocolCard extends StatefulWidget {
  const HomeProtocolCard({
    super.key,
    required this.model,
    required this.onLogSession,
  });

  final HomeProtocolCardModel model;
  final VoidCallback onLogSession;

  @override
  State<HomeProtocolCard> createState() => _HomeProtocolCardState();
}

class _HomeProtocolCardState extends State<HomeProtocolCard> {
  Offset? _hoverPosition;
  bool _isHovering = false;

  void _updatePointer(PointerEvent event) {
    setState(() {
      _hoverPosition = event.localPosition;
      _isHovering = true;
    });
  }

  void _clearHover(PointerExitEvent event) {
    setState(() {
      _isHovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;
    final isCompact = MediaQuery.of(context).size.width < context.breakpoints.sm;
    final borderColor = widget.model.isUnavailable
        ? kitColors.warning.withValues(alpha: 0.4)
        : (_isHovering ? kitColors.white20 : kitColors.white10);
    final backgroundColor = widget.model.isUnavailable
        ? kitColors.warning.withValues(alpha: 0.08)
        : kitColors.white02;

    return MouseRegion(
      onHover: _updatePointer,
      onExit: _clearHover,
      child: Listener(
        onPointerMove: _updatePointer,
        onPointerDown: _updatePointer,
        onPointerUp: (_) => setState(() => _isHovering = false),
        onPointerCancel: (_) => setState(() => _isHovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final alignment = _alignmentFor(
                _hoverPosition,
                constraints.biggest,
              );

              return Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isHovering ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: RadialGradient(
                              center: alignment,
                              radius: 0.9,
                              colors: [
                                kitColors.white05,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CategoryPill(label: widget.model.categoryLabel),
                            HomeStatusDot(active: widget.model.loggedToday),
                          ],
                        ),
                        SizedBox(height: spacing.md),
                        Text(
                          widget.model.title,
                          style: context.theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: widget.model.isUnavailable
                                ? kitColors.white60
                                : kitColors.white90,
                          ),
                        ),
                        SizedBox(height: spacing.xs),
                        Text(
                          widget.model.quickReference,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            height: 1.6,
                            color: kitColors.white50,
                          ),
                        ),
                        if (!widget.model.isUnavailable) ...[
                          SizedBox(height: spacing.md),
                          SizedBox(
                            width: isCompact ? double.infinity : null,
                            child: _LogButton(
                              onPressed: widget.onLogSession,
                              expand: isCompact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Alignment _alignmentFor(Offset? offset, Size size) {
    if (offset == null || size.width == 0 || size.height == 0) {
      return Alignment.center;
    }

    final dx = (offset.dx / size.width) * 2 - 1;
    final dy = (offset.dy / size.height) * 2 - 1;
    return Alignment(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textStyle = context.textStyles.mono.copyWith(
      fontSize: 10,
      color: kitColors.white50,
      letterSpacing: 1.5,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: kitColors.white05,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kitColors.white05),
      ),
      child: Text(label, style: textStyle),
    );
  }
}

class _LogButton extends StatefulWidget {
  const _LogButton({required this.onPressed, required this.expand});

  final VoidCallback onPressed;
  final bool expand;

  @override
  State<_LogButton> createState() => _LogButtonState();
}

class _LogButtonState extends State<_LogButton> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? kitColors.white10
                  : kitColors.white05,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _isHovered
                    ? kitColors.brandSky.withValues(alpha: 0.3)
                    : kitColors.white10,
              ),
            ),
            child: Row(
              mainAxisSize:
                  widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment:
                  widget.expand ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Text(
                  'Log Session',
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _isHovered ? kitColors.white90 : kitColors.white70,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: _isHovered ? const Offset(0.1, 0) : Offset.zero,
                  child: Icon(
                    LucideIcons.arrowRight,
                    size: 14,
                    color: _isHovered ? kitColors.brandSky : kitColors.white40,
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
