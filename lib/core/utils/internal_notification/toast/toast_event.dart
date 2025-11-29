sealed class ToastEvent {
  final Duration duration;
  final String message;

  ToastEvent({
    required this.message,
    this.duration = const Duration(seconds: 4),
  });
}

class ToastEventSuccess extends ToastEvent {
  ToastEventSuccess({required super.message});
}

class ToastEventError extends ToastEvent {
  ToastEventError({required super.message});
}

class ToastEventWarning extends ToastEvent {
  ToastEventWarning({required super.message});
}

class ToastEventInfo extends ToastEvent {
  ToastEventInfo({required super.message});
}
