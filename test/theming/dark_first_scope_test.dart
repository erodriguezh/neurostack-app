import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/core/ui/widgets/dark_theme_scope.dart';

void main() {
  group('DarkThemeScope', () {
    testWidgets(
      'Theme.of(context).brightness returns Brightness.dark '
      'regardless of system theme',
      (tester) async {
        for (final systemBrightness in Brightness.values) {
          Brightness? capturedBrightness;

          await tester.pumpWidget(
            _wrap(
              brightness: systemBrightness,
              child: DarkThemeScope(
                child: Builder(
                  builder: (context) {
                    capturedBrightness = Theme.of(context).brightness;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );

          expect(
            capturedBrightness,
            Brightness.dark,
            reason:
                'DarkThemeScope should force Brightness.dark even when '
                'system brightness is $systemBrightness',
          );
        }
      },
    );

    testWidgets(
      'context.kitColors is accessible (not null) inside scope',
      (tester) async {
        KitColorsExtension? capturedKitColors;

        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.light,
            child: DarkThemeScope(
              child: Builder(
                builder: (context) {
                  capturedKitColors = context.kitColors;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(capturedKitColors, isNotNull);
      },
    );

    testWidgets(
      'all ThemeExtensions are accessible inside scope',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.light,
            child: DarkThemeScope(
              child: Builder(
                builder: (context) {
                  // Verify all registered extensions are available
                  expect(context.kitColors, isNotNull);
                  expect(context.textStyles, isNotNull);
                  expect(context.borderRadius, isNotNull);
                  expect(context.shadows, isNotNull);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets(
      'overrides a light parent theme to dark',
      (tester) async {
        Brightness? outerBrightness;
        Brightness? innerBrightness;

        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.light,
            child: Builder(
              builder: (outerContext) {
                outerBrightness = Theme.of(outerContext).brightness;
                return DarkThemeScope(
                  child: Builder(
                    builder: (innerContext) {
                      innerBrightness = Theme.of(innerContext).brightness;
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        );

        expect(outerBrightness, Brightness.light);
        expect(innerBrightness, Brightness.dark);
      },
    );
  });
}

/// Wraps a widget in a MaterialApp with a given brightness for testing.
Widget _wrap({required Brightness brightness, required Widget child}) {
  return MaterialApp(
    theme: AppTheme.buildTheme(brightness),
    home: child,
  );
}
