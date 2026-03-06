import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';

Future<void> showBackdateSessionSheet({
  required BuildContext context,
  required String protocolName,
  required DateTime day,
  required Future<void> Function() onConfirm,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BackdateSessionSheet(
      protocolName: protocolName,
      day: day,
      onConfirm: onConfirm,
    ),
  );
}

class _BackdateSessionSheet extends StatefulWidget {
  const _BackdateSessionSheet({
    required this.protocolName,
    required this.day,
    required this.onConfirm,
  });

  final String protocolName;
  final DateTime day;
  final Future<void> Function() onConfirm;

  @override
  State<_BackdateSessionSheet> createState() => _BackdateSessionSheetState();
}

class _BackdateSessionSheetState extends State<_BackdateSessionSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final semanticColors = context.semanticColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, 0, spacing.md, spacing.md),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          spacing.md,
          spacing.lg,
          spacing.lg + bottomInset,
        ),
        decoration: BoxDecoration(
          color: semanticColors.surfaceElevated,
          borderRadius: context.borderRadius.r32,
          border: Border.all(color: semanticColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: semanticColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: spacing.lg),
            Text(
              _buildPrompt(context),
              textAlign: TextAlign.center,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: semanticColors.ink,
                height: 1.4,
              ),
            ),
            SizedBox(height: spacing.lg),
            AppPrimaryCta(
              label: 'Log session',
              loading: _isLoading,
              onPressed: _handleConfirm,
            ),
            SizedBox(height: spacing.sm),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: context.theme.textTheme.labelLarge?.copyWith(
                  color: semanticColors.inkSubtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPrompt(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat.EEEE(locale).format(widget.day);
    final dateLabel = DateFormat.MMMd(locale).format(widget.day);
    return 'Log ${widget.protocolName} session for $dayLabel, $dateLabel?';
  }

  Future<void> _handleConfirm() async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
