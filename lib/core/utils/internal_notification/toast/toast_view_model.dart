import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';

class ToastViewModel {
  ToastViewModel({required NotifyService notifyService})
    : _notifyService = notifyService;

  final NotifyService _notifyService;

  ValueNotifier<ToastEvent?> get toastEvent => _notifyService.toastEvent;

  late final clearToastEvent = _notifyService.clearToastEvent;
}
