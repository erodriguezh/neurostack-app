import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/utils/internal_notification/notify_service.dart';
import '../../../core/utils/locator.dart';
import '../../protocol/domain/entities/protocol.dart';
import '../data/data_sources/session_local_data_source.dart';
import '../data/services/session_sync_service.dart';
import '../domain/entities/session.dart';
import '../domain/use_cases/check_eligibility_use_case.dart';
import 'view_models/log_session_view_model.dart';
import 'views/log_session_view.dart';

/// Shows the Log Session modal bottom sheet.
///
/// The modal allows users to log a session for the given [protocol].
/// When a session is successfully logged, [onSessionLogged] is called
/// with the new session.
///
/// Parameters:
/// - [context]: The build context for showing the modal.
/// - [protocol]: The protocol to log a session for.
/// - [userId]: The current user's ID.
/// - [initialDate]: Optional initial date for the session (defaults to today).
/// - [onSessionLogged]: Callback invoked when a session is successfully logged.
///
/// Example:
/// ```dart
/// await showLogSessionModal(
///   context,
///   protocol: myProtocol,
///   userId: currentUserId,
///   onSessionLogged: (session) {
///     // Handle the new session
///     viewModel.refresh();
///   },
/// );
/// ```
Future<void> showLogSessionModal(
  BuildContext context, {
  required Protocol protocol,
  required String userId,
  DateTime? initialDate,
  required void Function(Session session) onSessionLogged,
}) async {
  // Create the view model with dependencies from locator
  final viewModel = LogSessionViewModel(
    protocol: protocol,
    initialDate: initialDate ?? DateTime.now(),
    userId: userId,
    checkEligibilityUseCase: locator<CheckEligibilityUseCase>(),
    sessionLocalDataSource: locator<SessionLocalDataSource>(),
    sessionSyncService: locator<SessionSyncService>(),
    notifyService: locator<NotifyService>(),
  );

  // Initialize the view model asynchronously (runs eligibility check)
  // This happens while the modal is showing, so the UI shows initial state first
  unawaited(viewModel.init());

  // Show the modal
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xCC030303), // #030303 at 80%
    builder: (modalContext) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: LogSessionView(
            viewModel: viewModel,
            onSessionLogged: onSessionLogged,
          ),
        ),
      );
    },
  );

  // Clean up
  viewModel.dispose();
}
