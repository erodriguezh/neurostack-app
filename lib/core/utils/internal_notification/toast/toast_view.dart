import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_view_model.dart';

class ToastView extends StatefulWidget {
  final Widget child;

  const ToastView({super.key, required this.child});

  @override
  State<ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<ToastView> {
  late final ToastViewModel _viewModel = ToastViewModel(
    notifyService: locator<NotifyService>(),
  );

  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.toastEvent.addListener(_onToastEventChanged);
  }

  @override
  void dispose() {
    _viewModel.toastEvent.removeListener(_onToastEventChanged);
    super.dispose();
  }

  void _onToastEventChanged() {
    final toastEvent = _viewModel.toastEvent.value;
    if (toastEvent != null) {
      Future.delayed(toastEvent.duration, () {
        if (mounted && _viewModel.toastEvent.value == toastEvent) {
          _viewModel.clearToastEvent();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<ToastEvent?>(
          valueListenable: _viewModel.toastEvent,
          builder: (context, toastEvent, _) {
            return AnimatedSwitcher(
              duration: context.durations.duration200,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                            reverseCurve: Curves.easeIn,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: toastEvent == null
                  ? const SizedBox.shrink()
                  : _Toast(
                      key: ValueKey(toastEvent),
                      toastEvent: toastEvent,
                      onDismiss: () {
                        _viewModel.clearToastEvent();
                      },
                      onVerticalDragStart: (_) => _dragOffset = 0,
                      onVerticalDragUpdate: (details) {
                        _dragOffset += details.primaryDelta!;
                        if (_dragOffset < -20) {
                          _viewModel.clearToastEvent();
                        }
                      },
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  final ToastEvent toastEvent;
  final VoidCallback onDismiss;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;

  const _Toast({
    super.key,
    required this.toastEvent,
    required this.onDismiss,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final radius = context.borderRadius.lg;

    final iconData = switch (toastEvent) {
      ToastEventSuccess() => Icons.check_circle_rounded,
      ToastEventError() => Icons.error_rounded,
      ToastEventWarning() => Icons.warning_rounded,
      ToastEventInfo() => null,
    };

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.breakpoints.sm),
          child: GestureDetector(
            onVerticalDragStart: onVerticalDragStart,
            onVerticalDragUpdate: onVerticalDragUpdate,
            child: Container(
              margin: EdgeInsets.all(context.spacing.md),
              decoration: BoxDecoration(
                color: semanticColors.surfaceElevated,
                border: Border.all(
                  color: semanticColors.border,
                  width: 1,
                ),
                borderRadius: radius,
                boxShadow: context.shadows.md,
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: radius,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.md,
                    vertical: context.spacing.md,
                  ),
                  child: Row(
                    children: [
                      if (iconData != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData,
                              color: semanticColors.ink,
                            ),
                            SizedBox(width: context.spacing.sm),
                          ],
                        ),
                      Expanded(
                        child: Text(
                          toastEvent.message,
                          style: context.textStyles.standard.copyWith(
                            color: semanticColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
