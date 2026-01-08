import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/core/ui/extensions/category_ui.dart';
import 'package:neurostack/core/ui/widgets/dashed_rounded_border.dart';
import 'package:neurostack/core/ui/widgets/spotlight_card.dart';
import 'package:neurostack/library/library_state.dart';
import 'package:neurostack/library/library_ui.dart';

class LibraryProtocolCard extends StatefulWidget {
  const LibraryProtocolCard({
    super.key,
    required this.model,
    required this.onTapCard,
    this.onTapBadge,
  });

  final LibraryProtocolCardModel model;
  final VoidCallback onTapCard;
  final VoidCallback? onTapBadge;

  @override
  State<LibraryProtocolCard> createState() => _LibraryProtocolCardState();
}

class _LibraryProtocolCardState extends State<LibraryProtocolCard> {
  bool _isHovering = false;

  void _setHovering(bool value) {
    if (_isHovering == value) {
      return;
    }
    setState(() => _isHovering = value);
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;
    final borderRadius = context.borderRadius.r24;
    final status = widget.model.status;
    final isAvailable = status == LibraryCardStatus.available;
    final isLocked = status == LibraryCardStatus.locked;
    final isInStack = status == LibraryCardStatus.inStack;

    final borderColor = isInStack
        ? kitColors.brandSky.withValues(alpha: 0.3)
        : (_isHovering ? kitColors.white20 : kitColors.white10);

    final backgroundColor = switch (status) {
      LibraryCardStatus.inStack => kitColors.white02,
      LibraryCardStatus.available => kitColors.white02,
      LibraryCardStatus.locked => kitColors.white02.withValues(alpha: 0.5),
    };

    final cardContent = Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CategoryPill(
                label: widget.model.category.displayName.toUpperCase(),
                isMuted: isLocked,
                icon: widget.model.category.iconData,
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Text(
            widget.model.name,
            style: context.theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isLocked ? kitColors.white50 : kitColors.white90,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            widget.model.evidenceLevel.label,
            style: context.theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: isLocked
                  ? kitColors.white30
                  : libraryEvidenceColor(
                      context,
                      widget.model.evidenceLevel,
                    ),
            ),
          ),
          SizedBox(height: spacing.md),
          Text(
            _statusLabel(status),
            style: context.theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: _statusColor(context, status),
            ),
          ),
        ],
      ),
    );

    final decoratedCard = AnimatedContainer(
      duration: context.durations.duration200,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: isLocked ? null : Border.all(color: borderColor),
      ),
      child: cardContent,
    );

    final cardBody = isLocked
        ? DashedRoundedBorder(
            borderRadius: borderRadius,
            color: kitColors.white10,
            child: decoratedCard,
          )
        : decoratedCard;

    return Stack(
      children: [
        SpotlightCard(
          borderRadius: borderRadius,
          spotlightColor: kitColors.white05,
          enabled: isAvailable,
          onHoverChanged: isAvailable ? _setHovering : null,
          child: GestureDetector(
            onTap: widget.onTapCard,
            behavior: HitTestBehavior.opaque,
            child: cardBody,
          ),
        ),
        Positioned(
          top: spacing.md,
          right: spacing.md,
          child: _Badge(
            status: status,
            animate: widget.model.animateBadge,
            onTap: widget.onTapBadge ?? widget.onTapCard,
            isOfflineDisabled: widget.model.isOfflineDisabled,
          ),
        ),
      ],
    );
  }

  String _statusLabel(LibraryCardStatus status) {
    return switch (status) {
      LibraryCardStatus.inStack => 'In your stack',
      LibraryCardStatus.available => 'Tap to add',
      LibraryCardStatus.locked => 'Upgrade to unlock',
    };
  }

  Color _statusColor(BuildContext context, LibraryCardStatus status) {
    final kitColors = context.kitColors;
    return switch (status) {
      LibraryCardStatus.inStack => kitColors.brandSky,
      LibraryCardStatus.available => kitColors.white40,
      LibraryCardStatus.locked => kitColors.yellow400.withValues(alpha: 0.8),
    };
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isMuted,
    this.icon,
  });

  final String label;
  final bool isMuted;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textColor = isMuted ? kitColors.white30 : kitColors.white50;
    final textStyle = context.textStyles.mono.copyWith(
      fontSize: 10,
      color: textColor,
      letterSpacing: 1.5,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isMuted ? kitColors.white02 : kitColors.white05,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kitColors.white05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.status,
    required this.animate,
    required this.onTap,
    required this.isOfflineDisabled,
  });

  final LibraryCardStatus status;
  final bool animate;
  final VoidCallback onTap;
  final bool isOfflineDisabled;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final background = _badgeBackground(kitColors);
    final iconColor = kitColors.white90;

    return GestureDetector(
      onTap: isOfflineDisabled ? null : onTap,
      child: AnimatedScale(
        duration: context.durations.duration150,
        scale: animate ? 1.2 : 1.0,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: context.durations.duration150,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: _badgeShadows(kitColors),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: context.durations.duration150,
              child: Icon(
                _badgeIcon(),
                key: ValueKey('${status.name}-badge'),
                size: 14,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _badgeIcon() {
    return switch (status) {
      LibraryCardStatus.inStack => LucideIcons.check,
      LibraryCardStatus.available => LucideIcons.plus,
      LibraryCardStatus.locked => LucideIcons.lock,
    };
  }

  Color _badgeBackground(KitColorsExtension kitColors) {
    return switch (status) {
      LibraryCardStatus.inStack => kitColors.brandSky,
      LibraryCardStatus.available => kitColors.white30,
      LibraryCardStatus.locked => kitColors.white20,
    };
  }

  List<BoxShadow> _badgeShadows(KitColorsExtension kitColors) {
    if (status != LibraryCardStatus.inStack) {
      return const [];
    }

    return [
      BoxShadow(
        color: kitColors.brandSky.withValues(alpha: 0.3),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ];
  }
}
