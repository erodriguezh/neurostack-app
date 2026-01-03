import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.showTopGlow = true,
  });

  final Widget child;
  final bool showTopGlow;

  @override
  Widget build(BuildContext context) {
    return AppGridBackground(
      showTopGlow: showTopGlow,
      child: child,
    );
  }
}
