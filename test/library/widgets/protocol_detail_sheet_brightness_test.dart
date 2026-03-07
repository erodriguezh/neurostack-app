import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/library/library_state.dart';
import 'package:neurostack/library/widgets/library_category_header.dart';
import 'package:neurostack/library/widgets/library_protocol_card.dart';
import 'package:neurostack/library/widgets/protocol_detail_sheet.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';

import '../../constants/test_constants.dart';
import '../../factories/protocol_factory.dart';
import '../../helpers/contrast_ratio.dart';

void main() {
  Widget wrap({
    required Brightness brightness,
    required Widget child,
  }) {
    return MaterialApp(
      key: ValueKey(brightness),
      theme: AppTheme.buildTheme(brightness),
      home: Scaffold(body: child),
    );
  }

  group('ProtocolDetailSheet brightness migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'renders sheet without error',
          (tester) async {
            final protocol = ProtocolFactory.valid();

            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: ProtocolDetailSheet(
                  protocol: protocol,
                  status: LibraryCardStatus.available,
                  isOffline: false,
                  loadStats: () async => const LibraryProtocolStats(
                    totalSessions: 0,
                    currentStreakDays: 0,
                    lastSessionAt: null,
                  ),
                  onAdd: () {},
                  onRemove: () {},
                  onUpgrade: () {},
                  onLogSession: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              find.text(protocol.name.value),
              findsOneWidget,
            );
            expect(find.text('Add to Stack'), findsOneWidget);
          },
        );

        testWidgets(
          'sheet surface uses semantic surfaceElevated',
          (tester) async {
            final protocol = ProtocolFactory.valid();

            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: ProtocolDetailSheet(
                  protocol: protocol,
                  status: LibraryCardStatus.available,
                  isOffline: false,
                  loadStats: () async => const LibraryProtocolStats(
                    totalSessions: 0,
                    currentStreakDays: 0,
                    lastSessionAt: null,
                  ),
                  onAdd: () {},
                  onRemove: () {},
                  onUpgrade: () {},
                  onLogSession: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;

            // Find the sheet Container by its key
            final sheetContainer = tester.widget<Container>(
              find.byKey(
                const ValueKey('protocol-detail-sheet-surface'),
              ),
            );
            final decoration = sheetContainer.decoration as BoxDecoration;
            expect(
              decoration.color,
              equals(semanticColors.surfaceElevated),
            );
          },
        );

        testWidgets(
          'title text uses semantic ink',
          (tester) async {
            final protocol = ProtocolFactory.valid();

            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: ProtocolDetailSheet(
                  protocol: protocol,
                  status: LibraryCardStatus.available,
                  isOffline: false,
                  loadStats: () async => const LibraryProtocolStats(
                    totalSessions: 0,
                    currentStreakDays: 0,
                    lastSessionAt: null,
                  ),
                  onAdd: () {},
                  onRemove: () {},
                  onUpgrade: () {},
                  onLogSession: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;

            final titleText = tester.widget<Text>(
              find.text(protocol.name.value),
            );
            expect(
              (titleText.style as TextStyle).color,
              equals(semanticColors.ink),
            );
          },
        );

        testWidgets(
          'title text contrast >= 4.5:1 against sheet surface',
          (tester) async {
            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;

            final ratio = contrastRatio(
              semanticColors.ink,
              semanticColors.surfaceElevated,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAANormalText),
              reason:
                  'Sheet title contrast in ${brightness.name} mode '
                  '(got $ratio)',
            );
          },
        );

        testWidgets(
          'subtitle text contrast >= 4.5:1 against sheet surface',
          (tester) async {
            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;

            final ratio = contrastRatio(
              semanticColors.inkSubtle,
              semanticColors.surfaceElevated,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAANormalText),
              reason:
                  'Sheet subtitle contrast in ${brightness.name} mode '
                  '(got $ratio)',
            );
          },
        );
      });
    }
  });

  group('LibraryCategoryHeader brightness migration', () {
    for (final brightness in Brightness.values) {
      testWidgets(
        'renders without error in ${brightness.name} mode',
        (tester) async {
          await tester.pumpWidget(
            wrap(
              brightness: brightness,
              child: const LibraryCategoryHeader(label: 'EXERCISE'),
            ),
          );

          expect(find.text('EXERCISE'), findsOneWidget);
        },
      );

      testWidgets(
        'text uses semantic inkSubtle in ${brightness.name} mode',
        (tester) async {
          await tester.pumpWidget(
            wrap(
              brightness: brightness,
              child: const LibraryCategoryHeader(label: 'EXERCISE'),
            ),
          );

          final theme = AppTheme.buildTheme(brightness);
          final semanticColors = theme.extension<AppSemanticColors>()!;

          final text = tester.widget<Text>(find.text('EXERCISE'));
          expect(
            (text.style as TextStyle).color,
            equals(semanticColors.inkSubtle),
          );
        },
      );
    }
  });

  group('LibraryProtocolCard brightness migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'title uses semantic ink for available card',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: LibraryProtocolCard(
                  model: _buildCardModel(status: LibraryCardStatus.available),
                  onTapCard: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;

            final titleText = tester.widget<Text>(
              find.text(TestConstants.protocol.validName),
            );
            expect(
              (titleText.style as TextStyle).color,
              equals(semanticColors.ink),
            );
          },
        );

        testWidgets(
          'title text contrast >= 4.5:1 against card bg',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: LibraryProtocolCard(
                  model: _buildCardModel(status: LibraryCardStatus.available),
                  onTapCard: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;

            // Read actual card background color via key
            final cardContainer = tester.widget<AnimatedContainer>(
              find.byKey(const ValueKey('library-card-surface')),
            );
            final decoration = cardContainer.decoration as BoxDecoration;
            final cardBg = compositedOver(
              decoration.color!,
              semanticColors.surface,
            );

            final ratio = contrastRatio(semanticColors.ink, cardBg);
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAANormalText),
              reason:
                  'Library card title contrast against card bg in '
                  '${brightness.name} mode (got $ratio)',
            );
          },
        );
      });
    }
  });

  group('source file whiteXX audits', () {
    final whiteXXPattern = RegExp(
      r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
    );

    final files = [
      'lib/library/widgets/library_category_header.dart',
      'lib/library/widgets/library_protocol_card.dart',
      'lib/library/widgets/protocol_detail_sheet.dart',
    ];

    for (final path in files) {
      test('$path contains no kitColors.whiteXX references', () {
        final source = File(path).readAsStringSync();
        final matches = whiteXXPattern.allMatches(source);
        expect(
          matches,
          isEmpty,
          reason: '$path should not reference any kitColors.whiteXX tokens',
        );
      });
    }

    test('library_view.dart contains no kitColors.panel references', () {
      final source = File('lib/library/library_view.dart').readAsStringSync();
      final panelMatches = RegExp(r'kitColors\.panel').allMatches(source);
      expect(
        panelMatches,
        isEmpty,
        reason:
            'library_view.dart should not reference kitColors.panel '
            'for dialog backgrounds',
      );
    });

    test(
      'library_view.dart _EmptyState contains no kitColors.whiteXX references',
      () {
        final source = File('lib/library/library_view.dart').readAsStringSync();
        // Check that white60/white40 are gone from the file entirely
        final matches = whiteXXPattern.allMatches(source);
        expect(
          matches,
          isEmpty,
          reason:
              'library_view.dart should not reference any '
              'kitColors.whiteXX tokens',
        );
      },
    );

    test(
      'library_view.dart AppGridBackground mode is adaptive',
      () {
        final source = File('lib/library/library_view.dart').readAsStringSync();
        expect(
          RegExp(r'mode:\s*AppGridBackgroundMode\.adaptive').hasMatch(source),
          isTrue,
          reason:
              'library_view.dart should explicitly set '
              'AppGridBackgroundMode.adaptive',
        );
      },
    );
  });
}

LibraryProtocolCardModel _buildCardModel({
  LibraryCardStatus status = LibraryCardStatus.available,
}) {
  return LibraryProtocolCardModel(
    protocolId: TestConstants.protocol.id,
    name: TestConstants.protocol.validName,
    category: Category.exercise,
    evidenceLevel: EvidenceLevel.multipleRcts,
    status: status,
  );
}
