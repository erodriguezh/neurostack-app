import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/core/ui/widgets/home_indicator_pill.dart';

void main() {
  Widget wrap({
    required Brightness brightness,
    required Widget child,
  }) {
    return MaterialApp(
      key: ValueKey(brightness),
      theme: AppTheme.buildTheme(brightness),
      home: Scaffold(
        body: Stack(children: [child]),
      ),
    );
  }

  group('HomeIndicatorPill semantic token migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'pill color uses semanticColors.ink with alpha 0.3',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: const HomeIndicatorPill(bottomInset: 20),
              ),
            );

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            final container = tester.widget<Container>(
              find.byType(Container),
            );
            final decoration = container.decoration! as BoxDecoration;
            expect(
              decoration.color,
              equals(
                semanticColors.ink.withValues(alpha: 0.3),
              ),
            );
          },
        );

        testWidgets(
          'pill renders as a 134x5 capsule',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: const HomeIndicatorPill(bottomInset: 20),
              ),
            );

            final container = tester.widget<Container>(
              find.byType(Container),
            );
            expect(container.constraints?.maxWidth, equals(134));
            expect(container.constraints?.maxHeight, equals(5));
          },
        );
      });
    }

    test('source contains no kitColors.whiteXX references', () {
      final source = File(
        'lib/core/ui/widgets/home_indicator_pill.dart',
      ).readAsStringSync();
      final matches = RegExp(
        r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
      ).allMatches(source);
      expect(
        matches,
        isEmpty,
        reason:
            'home_indicator_pill.dart should not reference any '
            'kitColors.whiteXX tokens',
      );
    });
  });
}
