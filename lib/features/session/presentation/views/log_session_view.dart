import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_primary_cta.dart';
import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/session_draft.dart';
import '../view_models/log_session_state.dart';
import '../view_models/log_session_view_model.dart';

/// The Log Session modal view widget.
///
/// Displays a form for logging a session with:
/// - Date picker (constrained to last 7 days)
/// - Duration field (optional, numeric)
/// - Notes field (optional, max 140 chars)
///
/// Pattern: Follows [BackdateSessionSheet] and [ProtocolDetailSheet].
class LogSessionView extends StatefulWidget {
  const LogSessionView({
    super.key,
    required this.viewModel,
    required this.onSessionLogged,
  });

  /// The view model managing form state and submission.
  final LogSessionViewModel viewModel;

  /// Callback when a session is successfully logged.
  /// Receives the newly created [Session].
  final void Function(Session session) onSessionLogged;

  @override
  State<LogSessionView> createState() => _LogSessionViewState();
}

class _LogSessionViewState extends State<LogSessionView> {
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  final FocusNode _durationFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  String? _durationError;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController();
    _notesController = TextEditingController();

    // Sync controllers with ViewModel
    widget.viewModel.durationMinutes.addListener(_syncDuration);
    widget.viewModel.notes.addListener(_syncNotes);
    widget.viewModel.state.addListener(_handleStateChange);
  }

  @override
  void dispose() {
    widget.viewModel.durationMinutes.removeListener(_syncDuration);
    widget.viewModel.notes.removeListener(_syncNotes);
    widget.viewModel.state.removeListener(_handleStateChange);
    _durationController.dispose();
    _notesController.dispose();
    _durationFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _syncDuration() {
    final value = widget.viewModel.durationMinutes.value;
    final text = value?.toString() ?? '';
    if (_durationController.text != text) {
      _durationController.text = text;
    }
  }

  void _syncNotes() {
    final value = widget.viewModel.notes.value;
    if (_notesController.text != value) {
      _notesController.text = value;
    }
  }

  void _handleStateChange() {
    final state = widget.viewModel.state.value;
    final direction = Directionality.of(context);

    if (state is LogSessionSubmitting) {
      // Clear any previous duration error when starting submission
      if (_durationError != null) {
        setState(() => _durationError = null);
      }
      // Announce saving for accessibility
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Saving session',
        direction,
      );
      return;
    }

    if (state is LogSessionSuccess) {
      // Announce success for accessibility before popping
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Session logged',
        direction,
      );
      widget.onSessionLogged(state.session);
      Navigator.of(context).pop();
      return;
    }

    if (state is LogSessionError) {
      // Announce error for accessibility
      SemanticsService.sendAnnouncement(
        View.of(context),
        state.failure.message,
        direction,
      );

      // Check if it's a duration error for inline display
      if (state.failure.code == 'Session.DurationMustBePositive') {
        setState(() {
          _durationError = state.failure.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final spacing = context.spacing;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return ValueListenableBuilder<LogSessionState>(
      valueListenable: widget.viewModel.state,
      builder: (context, state, child) {
        if (state is LogSessionIneligible) {
          return _IneligibleView(
            failure: state.failure,
            onClose: () => Navigator.of(context).pop(),
          );
        }

        final isSubmitting = state is LogSessionSubmitting;
        final isInitial = state is LogSessionInitial;
        // Extract error message for general (non-duration) errors
        final generalErrorMessage =
            state is LogSessionError &&
                state.failure.code != 'Session.DurationMustBePositive'
            ? state.failure.message
            : null;

        return AnimatedPadding(
          duration: context.durations.duration150,
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Container(
            decoration: BoxDecoration(
              color: semanticColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.md,
                spacing.lg,
                spacing.lg + safeBottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: semanticColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.lg),

                  // Header row
                  _HeaderRow(
                    onClose: isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  SizedBox(height: spacing.xs),

                  // Protocol context
                  Text(
                    widget.viewModel.protocol.name.value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: kitColors.brandSky,
                    ),
                  ),

                  // General error banner (for non-duration errors)
                  if (generalErrorMessage != null) ...[
                    SizedBox(height: spacing.lg),
                    _InlineErrorBanner(message: generalErrorMessage),
                  ],

                  SizedBox(height: spacing.xl),

                  // Date field
                  _DateField(
                    viewModel: widget.viewModel,
                    enabled: !isSubmitting && !isInitial,
                  ),

                  SizedBox(height: spacing.lg),

                  // Duration field
                  _DurationField(
                    controller: _durationController,
                    focusNode: _durationFocusNode,
                    enabled: !isSubmitting && !isInitial,
                    error: _durationError,
                    onChanged: (value) {
                      setState(() => _durationError = null);
                      final parsed = int.tryParse(value);
                      widget.viewModel.updateDurationMinutes(
                        value.isEmpty ? null : parsed,
                      );
                    },
                  ),

                  SizedBox(height: spacing.lg),

                  // Notes field
                  _NotesField(
                    controller: _notesController,
                    focusNode: _notesFocusNode,
                    enabled: !isSubmitting && !isInitial,
                    onChanged: widget.viewModel.updateNotes,
                  ),

                  SizedBox(height: spacing.xl),

                  // Submit button
                  AppPrimaryCta(
                    label: 'Log Session',
                    loading: isSubmitting,
                    enabled: !isInitial,
                    onPressed: widget.viewModel.submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Log Session',
          style: GoogleFonts.newsreader(
            fontSize: 24,
            fontStyle: FontStyle.italic,
            color: semanticColors.ink,
          ),
        ),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            button: true,
            enabled: onClose != null,
            label: 'Close',
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: semanticColors.inkSubtle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.viewModel,
    required this.enabled,
  });

  final LogSessionViewModel viewModel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'WHEN'),
        SizedBox(height: spacing.sm),
        ValueListenableBuilder<DateTime>(
          valueListenable: viewModel.selectedDate,
          builder: (context, selectedDate, child) {
            return GestureDetector(
              onTap: enabled
                  ? () => _showDatePicker(context, selectedDate)
                  : null,
              child: Container(
                padding: EdgeInsets.all(spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: semanticColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(context, selectedDate),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: semanticColors.inkSubtle,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    final locale = Localizations.localeOf(context).toString();

    if (selectedDay == today) {
      return 'Today, ${DateFormat.MMMd(locale).format(date)}';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (selectedDay == yesterday) {
      return 'Yesterday, ${DateFormat.MMMd(locale).format(date)}';
    }

    return '${DateFormat.EEEE(locale).format(date)}, ${DateFormat.MMMd(locale).format(date)}';
  }

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime currentDate,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oldestAllowed = today.subtract(
      const Duration(days: SessionDraft.maxBackdateDays),
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: oldestAllowed,
      lastDate: today,
    );

    if (picked != null) {
      viewModel.updateSelectedDate(picked);
    }
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? error;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel(label: 'DURATION'),
            SizedBox(width: spacing.xs),
            Text(
              '(optional)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: semanticColors.inkSubtle,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? kitColors.red500.withValues(alpha: 0.5)
                  : semanticColors.border,
            ),
            boxShadow: hasError
                ? [
                    BoxShadow(
                      color: kitColors.red500.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: semanticColors.inkSubtle,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: spacing.sm),
                    isDense: true,
                  ),
                  onChanged: onChanged,
                ),
              ),
              Text(
                'min',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: semanticColors.inkSubtle,
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          SizedBox(height: spacing.xs),
          Text(
            error!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: kitColors.red400,
            ),
          ),
        ],
      ],
    );
  }
}

class _NotesField extends StatefulWidget {
  const _NotesField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final void Function(String) onChanged;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  static const _maxLength = 140;
  static const _showCounterThreshold = 100;
  static const _redCounterThreshold = 130;

  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller.text.length;
    widget.controller.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharCount);
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      _charCount = widget.controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    final showCounter = _charCount >= _showCounterThreshold;
    final isCounterRed = _charCount >= _redCounterThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel(label: 'NOTES'),
            SizedBox(width: spacing.xs),
            Text(
              '(optional)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: semanticColors.inkSubtle,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        Stack(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: semanticColors.border),
              ),
              constraints: const BoxConstraints(minHeight: 100),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                maxLines: null,
                minLines: 3,
                maxLength: _maxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'How did it go?',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: semanticColors.inkSubtle,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  counterText: '', // Hide default counter
                ),
                onChanged: widget.onChanged,
              ),
            ),
            if (showCounter)
              Positioned(
                right: spacing.sm,
                bottom: spacing.sm,
                child: Text(
                  '$_charCount/$_maxLength',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: isCounterRed
                        ? kitColors.red400
                        : semanticColors.inkSubtle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;

    return Text(
      label,
      style: GoogleFonts.robotoMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.65, // 0.15em
        color: semanticColors.inkSubtle,
      ),
    );
  }
}

/// Inline error banner for displaying non-field-specific errors.
class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    // Derive all error-banner colors from the same colorScheme.error slot
    // so the palette stays consistent across light/dark modes.
    final errorColor = colorScheme.error;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 18),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _IneligibleView extends StatelessWidget {
  const _IneligibleView({
    required this.failure,
    required this.onClose,
  });

  final DomainFailure failure;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final semanticColors = context.semanticColors;
    final spacing = context.spacing;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: semanticColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.md,
        spacing.lg,
        spacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: semanticColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: spacing.lg),

          // Header
          _HeaderRow(onClose: onClose),

          SizedBox(height: spacing.xxl),

          // Ineligible message
          Icon(
            Icons.lock_outline,
            size: 48,
            color: semanticColors.inkSubtle,
          ),
          SizedBox(height: spacing.md),
          Text(
            'Upgrade Required',
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: semanticColors.ink,
            ),
          ),
          SizedBox(height: spacing.sm),
          Text(
            'Free tier is limited to 2 active protocols.\nUpgrade to log sessions for more protocols.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: semanticColors.inkSubtle,
              height: 1.5,
            ),
          ),
          SizedBox(height: spacing.xl),

          // Close button
          TextButton(
            onPressed: onClose,
            child: Text(
              'Got it',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kitColors.brandSky,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
