import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/data/services/session_sync_service.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/session/domain/use_cases/check_eligibility_use_case.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/data/trial_reminder_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:uuid/uuid.dart';

/// Shared mock declarations for service and repository testing.
///
/// Import this file instead of re-declaring mocks inline.
/// For data-source mocks, see `data_source_mocks.dart`.

class MockNotifyService extends Mock implements NotifyService {}

class MockRouterService extends Mock implements RouterService {}

class MockAuthService extends Mock implements AuthService {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProtocolRepository extends Mock implements ProtocolRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockRevenueCatService extends Mock implements RevenueCatService {}

class MockCheckEligibilityUseCase extends Mock
    implements CheckEligibilityUseCase {}

class MockSessionSyncService extends Mock implements SessionSyncService {}

class MockUuid extends Mock implements Uuid {}

class MockTrialReminderService extends Mock implements TrialReminderService {}

class MockSubscriptionStatusResolver extends Mock
    implements SubscriptionStatusResolver {}
