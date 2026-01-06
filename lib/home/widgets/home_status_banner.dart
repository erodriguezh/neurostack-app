import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/home/home_state.dart';

class HomeStatusBanner extends StatelessWidget {
  const HomeStatusBanner({
    super.key,
    required this.banner,
    required this.onDismiss,
    required this.onTap,
  });

  final HomeBannerModel banner;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;
    final background = _backgroundColor(kitColors);
    final accent = _accentColor(kitColors);
    final isTappable = banner.isTappable && onTap != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isTappable ? onTap : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.lg,
                      vertical: spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      border: Border.all(color: kitColors.white10),
                    ),
                    child: Row(
                      children: [
                        _leadingIcon(accent),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            banner.message,
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: accent,
                            ),
                          ),
                        ),
                        if (banner.isTappable)
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: kitColors.white60,
                          ),
                        if (banner.isDismissible && onDismiss != null) ...[
                          SizedBox(width: spacing.xs),
                          _DismissButton(onTap: onDismiss),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accent.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadingIcon(Color accent) {
    final iconData = switch (banner.type) {
      HomeBannerType.trial => LucideIcons.clock,
      HomeBannerType.free => LucideIcons.layers,
      HomeBannerType.expired => Icons.warning_amber_rounded,
      HomeBannerType.grace => Icons.info_outline,
      HomeBannerType.offline => LucideIcons.wifiOff,
    };

    if (banner.type == HomeBannerType.trial) {
      return _PulsingIcon(iconData: iconData, color: accent);
    }

    return Icon(iconData, size: 16, color: accent);
  }

  Color _backgroundColor(KitColorsExtension kitColors) {
    return switch (banner.type) {
      HomeBannerType.trial => kitColors.brandSky.withValues(alpha: 0.1),
      HomeBannerType.free => kitColors.white05,
      HomeBannerType.expired => kitColors.warning.withValues(alpha: 0.1),
      HomeBannerType.grace => kitColors.info.withValues(alpha: 0.1),
      HomeBannerType.offline => kitColors.white05,
    };
  }

  Color _accentColor(KitColorsExtension kitColors) {
    return switch (banner.type) {
      HomeBannerType.trial => kitColors.brandSky,
      HomeBannerType.free => kitColors.white70,
      HomeBannerType.expired => kitColors.warning,
      HomeBannerType.grace => kitColors.info,
      HomeBannerType.offline => kitColors.white70,
    };
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onTap});

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

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({
    required this.iconData,
    required this.color,
  });

  final IconData iconData;
  final Color color;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.4, end: 0.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.8).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          Icon(widget.iconData, size: 16, color: widget.color),
        ],
      ),
    );
  }
}
