/// Centralized test constants.
/// Cross-references document domain relationships.
abstract final class TestConstants {
  static const user = _User();
  static var protocol = _Protocol();
  static const session = _Session();
  static const citation = _Citation();
  static const subscription = _Subscription();
  static const trial = _Trial();
}

final class _Subscription {
  const _Subscription();

  final int freeProtocolLimit = 2; // INV-U1, INV-M5
  // Cross-reference: User.activateProtocol checks this limit
}

final class _Trial {
  const _Trial();

  final int durationDays = 7; // INV-M2
  // Cross-reference: TrialPeriod.trialDurationDays

  DateTime get startDate => DateTime(2025, 1, 1, 10, 0);
  DateTime get endDate => startDate.add(Duration(days: durationDays));
  DateTime get expiredCheckTime => endDate.add(const Duration(hours: 1));
  DateTime get activeCheckTime => startDate.add(const Duration(days: 3));
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
