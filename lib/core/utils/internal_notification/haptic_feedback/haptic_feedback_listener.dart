import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';

enum HapticFeedbackEvent {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  success,
  error,
  warning,
}

class HapticFeedbackListener extends StatefulWidget {
  final Widget child;

  const HapticFeedbackListener({super.key, required this.child});

  @override
  State<HapticFeedbackListener> createState() => _HapticFeedbackListenerState();
}

class _HapticFeedbackListenerState extends State<HapticFeedbackListener> {
  late final NotifyService _notifyService = locator<NotifyService>();

  @override
  void initState() {
    super.initState();
    _notifyService.hapticFeedbackEvent.addListener(
      _onHapticFeedbackEventChanged,
    );
  }

  @override
  void dispose() {
    _notifyService.hapticFeedbackEvent.removeListener(
      _onHapticFeedbackEventChanged,
    );
    super.dispose();
  }

  void _onHapticFeedbackEventChanged() {
    final event = _notifyService.hapticFeedbackEvent.value;
    if (event == null) return;

    switch (event) {
      case HapticFeedbackEvent.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackEvent.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackEvent.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackEvent.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackEvent.success:
        // Consider a specific pattern or fallback to light/medium impact
        HapticFeedback.mediumImpact(); // Example, adjust as needed
        break;
      case HapticFeedbackEvent.error:
        // Consider a specific pattern or fallback to heavy impact
        HapticFeedback.heavyImpact(); // Example, adjust as needed
        break;
      case HapticFeedbackEvent.warning:
        // Consider a specific pattern or fallback to light impact
        HapticFeedback.lightImpact(); // Example, adjust as needed
        break;
    }
    // Clear the event after handling
    _notifyService.clearHapticFeedbackEvent();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
