import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/dark_theme_scope.dart';
import 'package:neurostack/home/home_state.dart';

const _selectionLimit = 2;
const _modalBackgroundColor = Color(0xFF030303);

class ProtocolSelectionViewModel {
  ProtocolSelectionViewModel({
    required List<ProtocolSelectionItem> items,
    List<String>? initialSelection,
  }) : _items = items,
       _activeProtocolIds = items.map((item) => item.protocolId).toSet() {
    selectedProtocolIds = ValueNotifier<Set<String>>(
      _initialProtocolIds(initialSelection),
    );
  }

  final List<ProtocolSelectionItem> _items;
  final Set<String> _activeProtocolIds;
  late final ValueNotifier<Set<String>> selectedProtocolIds;

  bool get canConfirm => selectedProtocolIds.value.length == _selectionLimit;

  void toggle(String protocolId) {
    if (!_activeProtocolIds.contains(protocolId)) {
      return;
    }

    final next = Set<String>.from(selectedProtocolIds.value);
    if (next.contains(protocolId)) {
      next.remove(protocolId);
    } else {
      if (next.length >= _selectionLimit) {
        return;
      }
      next.add(protocolId);
    }
    selectedProtocolIds.value = Set<String>.unmodifiable(next);
  }

  List<String>? confirm() {
    if (!canConfirm) {
      return null;
    }
    return selectedProtocolIds.value.toList(growable: false);
  }

  Set<String> _initialProtocolIds(List<String>? initialSelection) {
    final seeded = initialSelection
        ?.where(_activeProtocolIds.contains)
        .take(_selectionLimit)
        .toSet();
    if (seeded != null && seeded.isNotEmpty) {
      return Set<String>.unmodifiable(seeded);
    }

    return Set<String>.unmodifiable(
      _items.take(_selectionLimit).map((item) => item.protocolId),
    );
  }

  void dispose() {
    selectedProtocolIds.dispose();
  }
}

Future<List<String>?> showProtocolSelectionModal(
  BuildContext context, {
  required List<ProtocolSelectionItem> items,
  List<String>? initialSelection,
}) {
  return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    useSafeArea: false,
    barrierColor: _modalBackgroundColor,
    builder: (context) => ProtocolSelectionModal(
      items: items,
      initialSelection: initialSelection,
    ),
  );
}

class ProtocolSelectionModal extends StatefulWidget {
  const ProtocolSelectionModal({
    super.key,
    required this.items,
    this.initialSelection,
  });

  final List<ProtocolSelectionItem> items;
  final List<String>? initialSelection;

  @override
  State<ProtocolSelectionModal> createState() => _ProtocolSelectionModalState();
}

class _ProtocolSelectionModalState extends State<ProtocolSelectionModal> {
  late final ProtocolSelectionViewModel _viewModel = ProtocolSelectionViewModel(
    items: widget.items,
    initialSelection: widget.initialSelection,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textStyles = context.textStyles;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return DarkThemeScope(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: _modalBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: _viewModel.selectedProtocolIds,
              builder: (context, selectedIds, child) {
                final selectedCount = selectedIds.length;
                final complete = selectedCount == _selectionLimit;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        children: [
                          Text(
                            'Choose 2 Protocols to Keep',
                            textAlign: TextAlign.center,
                            style: textStyles.h2.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: complete
                                  ? kitColors.brandSky.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: complete
                                    ? kitColors.brandSky.withValues(alpha: 0.28)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              '$selectedCount/$_selectionLimit SELECTED',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                                color: complete
                                    ? kitColors.brandSky
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                        itemCount: widget.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return _ProtocolSelectionRow(
                            item: item,
                            selected: selectedIds.contains(item.protocolId),
                            onTap: () => _viewModel.toggle(item.protocolId),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        40 + bottomInset,
                      ),
                      child: _ConfirmButton(
                        enabled: _viewModel.canConfirm,
                        onPressed: () {
                          final result = _viewModel.confirm();
                          if (result == null) {
                            return;
                          }
                          Navigator.of(context).pop(result);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProtocolSelectionRow extends StatelessWidget {
  const _ProtocolSelectionRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ProtocolSelectionItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final borderColor = selected
        ? kitColors.brandSky.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: kitColors.brandSky.withValues(alpha: 0.12),
                      blurRadius: 18,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                scale: selected ? 1.05 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? kitColors.brandSky
                        : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      width: 2,
                      color: selected
                          ? kitColors.brandSky
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: kitColors.brandSky.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : const [],
                  ),
                  child: selected
                      ? const Icon(
                          LucideIcons.check,
                          color: _modalBackgroundColor,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.categoryLabel,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.activity,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.sessionCount} sessions logged',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: enabled
            ? kitColors.brandSky
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled
              ? kitColors.brandSky
              : Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: kitColors.brandSky.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ]
            : const [],
      ),
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: enabled
              ? _modalBackgroundColor
              : Colors.white.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
          shape: const StadiumBorder(),
        ),
        child: Text(
          'Confirm Selection',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
