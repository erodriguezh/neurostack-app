/// Scientific backing strength for protocols.
///
/// Higher strength values indicate more rigorous evidence.
enum EvidenceLevel {
  multipleRcts(4, 'Multiple RCTs'),
  singleRct(3, 'Single RCT'),
  observational(2, 'Observational'),
  expertConsensus(1, 'Expert Consensus');

  const EvidenceLevel(this.strength, this.label);

  final int strength;
  final String label;

  /// Evidence is considered high quality if strength >= 3 (RCT-level).
  bool get isHighEvidence => strength >= 3;
}
