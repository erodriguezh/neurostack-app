import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/constants/curves.dart';

/// A reusable PageView driven by an enum value.
///
/// Provides smooth horizontal page transitions when the enum value changes.
/// Used for onboarding flows and other multi-step UI patterns.
class EnumPageView<T extends Enum> extends StatefulWidget {
  const EnumPageView({
    required this.value,
    required this.values,
    required this.builder,
    super.key,
  });

  /// Current enum value (determines which page is shown).
  final T value;

  /// All possible enum values (defines the pages).
  final List<T> values;

  /// Builder for each page, called with the enum value.
  final Widget Function(T) builder;

  @override
  State<EnumPageView<T>> createState() => _EnumPageViewState<T>();
}

class _EnumPageViewState<T extends Enum> extends State<EnumPageView<T>> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.value.index);
  }

  @override
  void didUpdateWidget(EnumPageView<T> old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _controller.animateToPage(
        widget.value.index,
        duration: const Duration(milliseconds: 750),
        curve: CustomCurves.emphasizedDecelerate,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(), // Disable swipe
      children: widget.values
          .map(
            (v) => KeyedSubtree(
              key: PageStorageKey(v),
              child: widget.builder(v),
            ),
          )
          .toList(),
    );
  }
}
