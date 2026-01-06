import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SpotlightCard extends StatefulWidget {
  const SpotlightCard({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.spotlightColor,
    this.duration = const Duration(milliseconds: 200),
    this.spotlightRadius = 0.9,
    this.enabled = true,
    this.onHoverChanged,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color spotlightColor;
  final Duration duration;
  final double spotlightRadius;
  final bool enabled;
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<SpotlightCard> {
  Offset? _hoverPosition;
  bool _isHovering = false;

  @override
  void didUpdateWidget(covariant SpotlightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isHovering) {
      _setHovering(false);
    }
  }

  void _updatePointer(PointerEvent event) {
    if (!widget.enabled) {
      return;
    }
    final shouldNotify = !_isHovering;
    setState(() {
      _hoverPosition = event.localPosition;
      _isHovering = true;
    });
    if (shouldNotify) {
      widget.onHoverChanged?.call(true);
    }
  }

  void _clearHover(PointerExitEvent event) {
    if (!widget.enabled) {
      return;
    }
    _setHovering(false);
  }

  void _setHovering(bool value, {bool notify = true}) {
    if (_isHovering == value) {
      return;
    }
    setState(() => _isHovering = value);
    if (notify) {
      widget.onHoverChanged?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _updatePointer,
      onExit: _clearHover,
      child: Listener(
        onPointerMove: _updatePointer,
        onPointerDown: _updatePointer,
        onPointerUp: (_) => _setHovering(false),
        onPointerCancel: (_) => _setHovering(false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final alignment = _alignmentFor(
              _hoverPosition,
              constraints.biggest,
            );

            return ClipRRect(
              borderRadius: widget.borderRadius,
              child: Stack(
                children: [
                  widget.child,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: widget.duration,
                        opacity: _isHovering ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: widget.borderRadius,
                            gradient: RadialGradient(
                              center: alignment,
                              radius: widget.spotlightRadius,
                              colors: [
                                widget.spotlightColor,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
