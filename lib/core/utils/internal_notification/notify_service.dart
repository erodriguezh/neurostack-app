import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';

class NotifyService {
  final ValueNotifier<ToastEvent?> toastEvent = ValueNotifier<ToastEvent?>(
    null,
  );
  final ValueNotifier<HapticFeedbackEvent?> hapticFeedbackEvent =
      ValueNotifier<HapticFeedbackEvent?>(null);

  void setToastEvent(ToastEvent? event) {
    toastEvent.value = event;
  }

  void clearToastEvent() {
    toastEvent.value = null;
  }

  void setHapticFeedbackEvent(HapticFeedbackEvent? event) {
    hapticFeedbackEvent.value = event;
  }

  void clearHapticFeedbackEvent() {
    hapticFeedbackEvent.value = null;
  }
}
