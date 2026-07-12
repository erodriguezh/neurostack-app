import 'package:mocktail/mocktail.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';

/// Shared fake classes for `registerFallbackValue()` in tests.
///
/// Import this file instead of re-declaring fakes inline.
/// For mock classes, see `mock_services.dart`.

class FakePendingSession extends Fake implements PendingSession {}
