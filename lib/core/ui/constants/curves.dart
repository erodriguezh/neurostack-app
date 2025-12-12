import 'package:flutter/material.dart';

class CustomCurves {
  CustomCurves._();
  static final CustomCurves instance = CustomCurves._();

  /// Standard ease-out - entrances, modal slides
  static const Curve easeOut = Curves.easeOut;

  /// Standard ease-in-out - pulse, breathing
  static const Curve easeInOut = Curves.easeInOut;

  /// Linear - continuous rotations
  static const Curve linear = Curves.linear;

  /// Spring - bouncy interactions, checkbox
  static const Curve spring = Cubic(0.25, 1.0, 0.5, 1.0);

  /// Material emphasized - complex transitions
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Emphasized decelerate - enter animations
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized accelerate - exit animations
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
}
