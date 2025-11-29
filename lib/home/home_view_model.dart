import 'package:flutter/foundation.dart';
import 'package:neurostack/core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/l10n/translate.dart';

class HomeViewModel {
  HomeViewModel({required NotifyService notifyService})
    : _notifyService = notifyService;

  final NotifyService _notifyService;

  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  void increment() {
    counter.value++;

    if (counter.value % 10 == 0) {
      _notifyService.setToastEvent(
        ToastEventSuccess(message: Translate.current.success),
      );
      _notifyService.setHapticFeedbackEvent(HapticFeedbackEvent.success);
    }
  }

  void dispose() {
    counter.dispose();
  }
}
