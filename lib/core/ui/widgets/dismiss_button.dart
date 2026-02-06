import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// A compact 24x24 dismiss (X) button used in banners and alerts.
class DismissButton extends StatelessWidget {
  const DismissButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        iconSize: 14,
        constraints: const BoxConstraints(),
        icon: Icon(
          LucideIcons.x,
          color: kitColors.white60,
        ),
      ),
    );
  }
}
