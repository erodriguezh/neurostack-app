import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';

/// State management for the Log Session Modal.
///
/// States:
/// - [LogSessionInitial]: Initial state before eligibility check
/// - [LogSessionReady]: User is eligible to log a session
/// - [LogSessionSubmitting]: Form submission in progress
/// - [LogSessionSuccess]: Session logged successfully
/// - [LogSessionError]: Validation or submission error occurred
/// - [LogSessionIneligible]: User cannot log sessions (e.g., too many active protocols)
sealed class LogSessionState {
  const LogSessionState();
}

/// Initial state before eligibility check has completed.
class LogSessionInitial extends LogSessionState {
  const LogSessionInitial();
}

/// User is eligible to log a session; form is ready for input.
class LogSessionReady extends LogSessionState {
  const LogSessionReady();
}

/// Form submission is in progress.
class LogSessionSubmitting extends LogSessionState {
  const LogSessionSubmitting();
}

/// Session was logged successfully.
class LogSessionSuccess extends LogSessionState {
  const LogSessionSuccess(this.session);

  /// The newly logged session.
  final Session session;
}

/// A validation or submission error occurred.
///
/// The user can retry submission after addressing the error.
class LogSessionError extends LogSessionState {
  const LogSessionError(this.failure);

  /// The failure that caused the error.
  final DomainFailure failure;
}

/// User is not eligible to log sessions.
///
/// This occurs when the user has too many active protocols
/// or other eligibility requirements are not met.
/// The UI should show an upgrade prompt or similar guidance.
class LogSessionIneligible extends LogSessionState {
  const LogSessionIneligible(this.failure);

  /// The failure describing why the user is ineligible.
  final DomainFailure failure;
}
