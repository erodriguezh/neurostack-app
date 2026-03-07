import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';
import 'package:neurostack/library/library_state.dart';

Color libraryEvidenceColor(BuildContext context, EvidenceLevel level) {
  final kitColors = context.kitColors;
  final semanticColors = context.semanticColors;
  final isLight = context.theme.brightness == Brightness.light;

  if (isLight) {
    // In light mode, saturated accent colors fail WCAG contrast against
    // light surfaces. Use semantic ink tokens for text readability.
    return switch (level) {
      EvidenceLevel.multipleRcts => semanticColors.ink,
      EvidenceLevel.singleRct => semanticColors.ink,
      EvidenceLevel.observational => semanticColors.inkSubtle,
      EvidenceLevel.expertConsensus => semanticColors.inkSubtle,
    };
  }

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
  final semanticColors = context.semanticColors;
  final isLight = context.theme.brightness == Brightness.light;

  if (isLight) {
    // In light mode, brandSky and yellow400 fail WCAG contrast against
    // light card surfaces. Use semantic ink tokens for text readability.
    return switch (status) {
      LibraryCardStatus.inStack => semanticColors.ink,
      LibraryCardStatus.available => semanticColors.inkSubtle,
      LibraryCardStatus.locked => semanticColors.inkSubtle,
    };
  }

  return switch (status) {
    LibraryCardStatus.inStack => kitColors.brandSky,
    LibraryCardStatus.available => semanticColors.inkSubtle,
    LibraryCardStatus.locked => kitColors.yellow400.withValues(alpha: 0.8),
  };
}
