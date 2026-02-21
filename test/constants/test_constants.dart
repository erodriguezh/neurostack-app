/// Centralized test constants.
/// Cross-references document domain relationships.
abstract final class TestConstants {
  static const user = _User();
  static var protocol = _Protocol();
  static const session = _Session();
  static const pendingSession = _PendingSession();
  static const citation = _Citation();
  static const subscription = _Subscription();
  static const dto = _Dto();
  static const postgrest = _Postgrest();
}

final class _Subscription {
  const _Subscription();

  final int freeProtocolLimit = 2; // INV-U1, INV-M5
  // Cross-reference: User.activateProtocol checks this limit
}

final class _User {
  const _User();

  final String id = 'user-001';
  DateTime get createdAt => DateTime(2025, 1, 1);

  // Cross-reference: limit comes from subscription
  int get protocolLimit => TestConstants.subscription.freeProtocolLimit;
}

final class _Protocol {
  _Protocol();

  final String id = 'protocol-001';
  final String validName = 'Norwegian 4x4 HIIT';
  final String emptyName = '';
  final String tooLongName = 'A' * 101; // > 100 chars

  // Description constants
  final String validDescription =
      'High-intensity interval training combining 4-minute intervals at 90-95% max HR.';
  final String emptyDescription = '';
  final String tooLongDescription = 'A' * 2001; // > 2000 chars
  final String maxLengthDescription = 'A' * 2000; // boundary: exactly 2000

  // INV-P3 violations
  final String researcherNamePossessive = "Huberman's Protocol";
  final String researcherNameDoctor = 'Dr. Sinclair Method';
  final String researcherNameThe = 'The Huberman Protocol';

  DateTime get createdAt => DateTime(2025, 1, 1);
}

final class _Session {
  const _Session();

  final String id = 'session-001';
  final String protocolId = 'protocol-001';

  DateTime get validCompletedAt => DateTime(2025, 1, 15, 10, 0);
  DateTime get currentTime => DateTime(2025, 1, 15, 12, 0);

  // INV-S2: Future timestamp
  DateTime get futureCompletedAt => currentTime.add(const Duration(hours: 1));

  // INV-S4: Too old timestamp (more than 7 days in the past)
  DateTime get tooOldCompletedAt =>
      currentTime.subtract(const Duration(days: 8));

  // Boundary: Exactly 7 days ago (should be valid)
  DateTime get exactlySevenDaysAgo =>
      currentTime.subtract(const Duration(days: 7));
}

final class _PendingSession {
  const _PendingSession();

  final String localId = 'pending-local-001';

  // Use session.currentTime for consistency
  DateTime get createdAt => TestConstants.session.currentTime;
}

final class _Citation {
  const _Citation();

  final String authors = 'Wisløff U, Støylen A, Loennechen JP';
  final int year = 2007;
  final String title =
      'Superior cardiovascular effect of aerobic interval training';
  final String journal = 'Circulation';
  final String doi = '10.1161/CIRCULATIONAHA.106.675041';
}

final class _Dto {
  const _Dto();

  // Default IDs for DTO testing
  final String defaultProtocolId = 'protocol-dto-001';
  final String defaultUserId = 'user-dto-001';

  // DateTime strings
  final String validIsoDateTime = '2025-01-15T10:00:00Z';
  final String invalidDateTime = 'not-a-date';

  // Invalid enum values for testing parse failures
  final String invalidCategory = 'invalidCategory';
  final String invalidEvidenceLevel = 'invalidLevel';
  final String invalidSubscriptionStatus = 'invalidStatus';
}

final class _Postgrest {
  const _Postgrest();

  // PostgreSQL/Supabase error codes
  final String notFound = 'PGRST116';
  final String uniqueViolation = '23505';
  final String foreignKeyViolation = '23503';
  final String rlsViolation = '42501';
  final String connectionFailed = 'PGRST301';
}
