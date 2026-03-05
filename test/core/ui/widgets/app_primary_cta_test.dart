import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';

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

  group('AppPrimaryCta semantic token migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'disabled state uses semantic surface background',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: AppPrimaryCta(
                  label: 'Continue',
                  onPressed: () {},
                  enabled: false,
                ),
              ),
            );

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            // Find the FilledButton and verify its resolved background
            final button = tester.widget<FilledButton>(
              find.byType(FilledButton),
            );
            final style = button.style!;

            final bgColor = style.backgroundColor!.resolve(
              {WidgetState.disabled},
            );
            expect(bgColor, equals(semanticColors.surface));

            final fgColor = style.foregroundColor!.resolve(
              {WidgetState.disabled},
            );
            expect(fgColor, equals(semanticColors.inkSubtle));

            final side = style.side!.resolve(
              {WidgetState.disabled},
            );
            expect(side?.color, equals(semanticColors.borderSubtle));
          },
        );

        testWidgets(
          'disabled text has adequate contrast against surface',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: AppPrimaryCta(
                  label: 'Continue',
                  onPressed: () {},
                  enabled: false,
                ),
              ),
            );

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
                  'Disabled text should meet WCAG AA large text '
                  'contrast in ${brightness.name} mode (got $ratio)',
            );
          },
        );

        testWidgets(
          'uses no whiteXX tokens (enabled state preserves brandSky)',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: AppPrimaryCta(
                  label: 'Continue',
                  onPressed: () {},
                ),
              ),
            );

            final button = tester.widget<FilledButton>(
              find.byType(FilledButton),
            );
            final style = button.style!;

            // Enabled state should still use brandSky
            final bgColor = style.backgroundColor!.resolve(<WidgetState>{});
            expect(bgColor, equals(const Color(0xFF38BDF8)));
          },
        );
      });
    }

    test('source contains no kitColors.whiteXX references', () {
      final source = File(
        'lib/core/ui/widgets/app_primary_cta.dart',
      ).readAsStringSync();
      final matches = RegExp(
        r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
      ).allMatches(source);
      expect(
        matches,
        isEmpty,
        reason:
            'app_primary_cta.dart should not reference any '
            'kitColors.whiteXX tokens',
      );
    });
  });
}
