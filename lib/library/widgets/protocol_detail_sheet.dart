import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/category_ui.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/library/library_state.dart';
import 'package:neurostack/library/library_ui.dart';

class ProtocolDetailSheet extends StatefulWidget {
  const ProtocolDetailSheet({
    super.key,
    required this.protocol,
    required this.status,
    required this.isOffline,
    required this.loadStats,
    required this.onAdd,
    required this.onRemove,
    required this.onUpgrade,
    required this.onLogSession,
  });

  final Protocol protocol;
  final LibraryCardStatus status;
  final bool isOffline;
  final Future<LibraryProtocolStats> Function() loadStats;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onUpgrade;
  final VoidCallback onLogSession;

  @override
  State<ProtocolDetailSheet> createState() => _ProtocolDetailSheetState();
}

class _ProtocolDetailSheetState extends State<ProtocolDetailSheet> {
  bool _showStats = false;
  Future<LibraryProtocolStats>? _statsFuture;

  void _toggleStats() {
    if (!_showStats) {
      _statsFuture ??= widget.loadStats();
    }
    setState(() => _showStats = !_showStats);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final semanticColors = context.semanticColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          key: const ValueKey('protocol-detail-sheet-surface'),
          decoration: BoxDecoration(
            color: semanticColors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            border: Border.all(color: semanticColors.borderSubtle),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.sm,
                spacing.lg,
                spacing.lg + bottomInset,
              ),
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: semanticColors.borderSubtle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: spacing.lg),
                _CategoryRow(protocol: widget.protocol),
                SizedBox(height: spacing.sm),
                Text(
                  widget.protocol.name.value,
                  style: context.theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    color: semanticColors.ink,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  widget.protocol.evidenceLevel.label,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: libraryEvidenceColor(
                      context,
                      widget.protocol.evidenceLevel,
                    ),
                  ),
                ),
                SizedBox(height: spacing.sm),
                Text(
                  widget.protocol.target.displayText,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: semanticColors.inkSubtle,
                  ),
                ),
                SizedBox(height: spacing.lg),
                _CitationSection(protocol: widget.protocol),
                if (widget.status == LibraryCardStatus.inStack) ...[
                  SizedBox(height: spacing.lg),
                  _StatsSection(
                    showStats: _showStats,
                    onToggle: _toggleStats,
                    statsFuture: _statsFuture,
                  ),
                ],
                SizedBox(height: spacing.lg),
                _ActionSection(
                  status: widget.status,
                  isOffline: widget.isOffline,
                  onAdd: widget.onAdd,
                  onRemove: widget.onRemove,
                  onUpgrade: widget.onUpgrade,
                  onLogSession: widget.onLogSession,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.protocol});

  final Protocol protocol;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final spacing = context.spacing;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: semanticColors.borderSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: semanticColors.borderSubtle),
          ),
          child: Icon(
            protocol.category.iconData,
            size: 18,
            color: semanticColors.ink,
          ),
        ),
        SizedBox(width: spacing.sm),
        Text(
          protocol.category.displayName,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: semanticColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CitationSection extends StatelessWidget {
  const _CitationSection({required this.protocol});

  final Protocol protocol;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;

    return Theme(
      data: context.theme.copyWith(dividerColor: Colors.transparent),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          iconColor: semanticColors.inkSubtle,
          collapsedIconColor: semanticColors.inkSubtle,
          title: Text(
            'Research citations',
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: semanticColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: protocol.citations
              .map(
                (citation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    citation.fullCitation,
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: semanticColors.inkSubtle,
                      height: 1.4,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.showStats,
    required this.onToggle,
    required this.statsFuture,
  });

  final bool showStats;
  final VoidCallback onToggle;
  final Future<LibraryProtocolStats>? statsFuture;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History',
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: semanticColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: onToggle,
              child: Text(showStats ? 'Hide History' : 'View History'),
            ),
          ],
        ),
        if (showStats)
          FutureBuilder<LibraryProtocolStats>(
            future: statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.only(top: spacing.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            kitColors.brandSky,
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Text(
                        'Loading stats...',
                        style: context.theme.textTheme.bodySmall?.copyWith(
                          color: semanticColors.inkSubtle,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.only(top: spacing.sm),
                  child: Text(
                    'Unable to load stats.',
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: semanticColors.inkSubtle,
                    ),
                  ),
                );
              }

              final stats = snapshot.data!;
              return Padding(
                padding: EdgeInsets.only(top: spacing.sm),
                child: Wrap(
                  spacing: spacing.md,
                  runSpacing: spacing.sm,
                  children: [
                    _StatTile(
                      label: 'Total sessions',
                      value: stats.totalSessions.toString(),
                    ),
                    _StatTile(
                      label: 'Current streak',
                      value: '${stats.currentStreakDays} days',
                    ),
                    _StatTile(
                      label: 'Last session',
                      value: stats.lastSessionAt == null
                          ? 'None'
                          : _formatDate(stats.lastSessionAt!),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: semanticColors.borderSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: semanticColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.theme.textTheme.bodySmall?.copyWith(
              color: semanticColors.inkSubtle,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: semanticColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.status,
    required this.isOffline,
    required this.onAdd,
    required this.onRemove,
    required this.onUpgrade,
    required this.onLogSession,
  });

  final LibraryCardStatus status;
  final bool isOffline;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onUpgrade;
  final VoidCallback onLogSession;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final isLight = context.theme.brightness == Brightness.light;
    final spacing = context.spacing;

    // Destructive color: kitColors.warning in dark mode for brand
    // consistency; a dark red in light mode for WCAG AA contrast
    // against surfaceElevated.
    final destructiveColor = isLight
        ? const Color(0xFFB71C1C)
        : kitColors.warning;

    switch (status) {
      case LibraryCardStatus.inStack:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPrimaryCta(
              label: 'Log Session',
              onPressed: onLogSession,
              enabled: !isOffline,
            ),
            SizedBox(height: spacing.sm),
            TextButton(
              onPressed: isOffline ? null : onRemove,
              style: TextButton.styleFrom().copyWith(
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return semanticColors.inkSubtle;
                  }
                  return destructiveColor;
                }),
              ),
              child: const Text('Remove from Stack'),
            ),
          ],
        );
      case LibraryCardStatus.available:
        return AppPrimaryCta(
          label: 'Add to Stack',
          onPressed: onAdd,
          enabled: !isOffline,
        );
      case LibraryCardStatus.locked:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPrimaryCta(
              label: 'Upgrade to Add',
              onPressed: onUpgrade,
              enabled: !isOffline,
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Free tier is limited to 2 active protocols.',
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: semanticColors.inkSubtle,
              ),
            ),
          ],
        );
    }
  }
}
