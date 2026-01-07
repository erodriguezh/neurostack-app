import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';

Color libraryEvidenceColor(BuildContext context, EvidenceLevel level) {
  final kitColors = context.kitColors;
  return switch (level) {
    EvidenceLevel.multipleRcts => kitColors.evidenceStrong,
    EvidenceLevel.singleRct => kitColors.evidenceStrong,
    EvidenceLevel.observational => kitColors.evidenceModerate,
    EvidenceLevel.expertConsensus => kitColors.evidenceWeak,
  };
}
