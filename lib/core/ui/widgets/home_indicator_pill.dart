import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// A fake home indicator pill rendered at the bottom of tab screens.
///
/// Placed inside a [Positioned] at the bottom of a [Stack], it mimics
/// the iOS home indicator with a semi-transparent capsule shape.
/// Used by Home, Library, Progress, and Settings views.
class HomeIndicatorPill extends StatelessWidget {
  const HomeIndicatorPill({super.key, required this.bottomInset});

  /// The bottom safe-area inset from [MediaQuery.of(context).padding.bottom].
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset > 0 ? bottomInset / 2 : 4,
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: kitColors.white90.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
