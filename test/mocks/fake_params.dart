import 'package:mocktail/mocktail.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import 'package:neurostack/features/session/domain/use_cases/check_eligibility_use_case.dart';

/// Shared fake classes for `registerFallbackValue()` in tests.
///
/// Import this file instead of re-declaring fakes inline.
/// For mock classes, see `mock_services.dart`.

class FakeCheckEligibilityParams extends Fake
    implements CheckEligibilityParams {}

class FakePendingSession extends Fake implements PendingSession {}
