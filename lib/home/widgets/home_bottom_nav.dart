import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/ui/app_theme.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.activeTab,
    required this.onSelect,
  });

  final HomeBottomTab activeTab;
  final ValueChanged<HomeBottomTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final shadows = context.shadows;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: kitColors.background.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kitColors.white10),
            boxShadow: shadows.lg,
          ),
          child: Row(
            children: [
              _NavItem(
                label: 'Stack',
                icon: LucideIcons.layers,
                isActive: activeTab == HomeBottomTab.stack,
                onTap: () => onSelect(HomeBottomTab.stack),
              ),
              _NavItem(
                label: 'Library',
                icon: LucideIcons.bookOpen,
                isActive: activeTab == HomeBottomTab.library,
                onTap: () => onSelect(HomeBottomTab.library),
              ),
              _NavItem(
                label: 'Progress',
                icon: LucideIcons.chartLine,
                isActive: activeTab == HomeBottomTab.progress,
                onTap: () => onSelect(HomeBottomTab.progress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final shadows = context.shadows;
    final color = isActive ? kitColors.brandSky : kitColors.white40;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Positioned(
                top: 8,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kitColors.brandSky,
                    boxShadow: shadows.skyGlow,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: context.theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
