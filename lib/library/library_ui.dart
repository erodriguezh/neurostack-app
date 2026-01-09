import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';
import 'package:neurostack/library/library_state.dart';

Color libraryEvidenceColor(BuildContext context, EvidenceLevel level) {
  final kitColors = context.kitColors;
  return switch (level) {
    EvidenceLevel.multipleRcts => kitColors.evidenceStrong,
    EvidenceLevel.singleRct => kitColors.evidenceStrong,
    EvidenceLevel.observational => kitColors.evidenceModerate,
    EvidenceLevel.expertConsensus => kitColors.evidenceWeak,
  };
}

String libraryStatusLabel(LibraryCardStatus status) {
  return switch (status) {
    LibraryCardStatus.inStack => 'In your stack',
    LibraryCardStatus.available => 'Tap to add',
    LibraryCardStatus.locked => 'Upgrade to unlock',
  };
}

Color libraryStatusColor(BuildContext context, LibraryCardStatus status) {
  final kitColors = context.kitColors;
  return switch (status) {
    LibraryCardStatus.inStack => kitColors.brandSky,
    LibraryCardStatus.available => kitColors.white40,
    LibraryCardStatus.locked => kitColors.yellow400.withValues(alpha: 0.8),
  };
}
