import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/core/ui/widgets/error_state_view.dart';

import '../../../helpers/contrast_ratio.dart';

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

  group('ErrorStateView semantic token migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'primary message uses semanticColors.inkSubtle',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: const ErrorStateView(message: 'Test error'),
              ),
            );

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            final texts = tester.widgetList<Text>(find.byType(Text));
            final primary = texts.first;
            expect(primary.style?.color, equals(semanticColors.inkSubtle));
          },
        );

        testWidgets(
          'subtitle uses semanticColors.inkSubtle',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: const ErrorStateView(),
              ),
            );

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            final texts = tester.widgetList<Text>(find.byType(Text));
            final subtitle = texts.last;
            expect(subtitle.style?.color, equals(semanticColors.inkSubtle));
          },
        );

        testWidgets(
          'primary text has adequate contrast against surface',
          (tester) async {
            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            final ratio = contrastRatio(
              semanticColors.inkSubtle,
              semanticColors.surface,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAALargeText),
              reason:
                  'Error message should meet WCAG AA large text '
                  'contrast in ${brightness.name} mode (got $ratio)',
            );
          },
        );
      });
    }

    test('source contains no kitColors.whiteXX references', () {
      final source = File(
        'lib/core/ui/widgets/error_state_view.dart',
      ).readAsStringSync();
      final matches = RegExp(
        r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
      ).allMatches(source);
      expect(
        matches,
        isEmpty,
        reason:
            'error_state_view.dart should not reference any '
            'kitColors.whiteXX tokens',
      );
    });
  });
}
