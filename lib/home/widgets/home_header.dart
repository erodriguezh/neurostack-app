import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textStyles = context.textStyles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Your Stack',
          style: context.theme.textTheme.headlineLarge?.copyWith(
            fontSize: textStyles.h1.fontSize,
            fontStyle: textStyles.h1.fontStyle,
            fontWeight: textStyles.h1.fontWeight,
            letterSpacing: -0.5,
            color: kitColors.white90,
          ),
        ),
        TextButton(
          onPressed: onAdd,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: const Size(44, 44),
          ),
          child: Text(
            '+ Add',
            style: context.theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kitColors.brandSky,
            ),
          ),
        ),
      ],
    );
  }
}
