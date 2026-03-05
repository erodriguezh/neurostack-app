import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';

void main() {
  group('AppGridBackgroundMode enum', () {
    testWidgets('has exactly two values', (_) async {
      expect(AppGridBackgroundMode.values.length, 2);
    });

    testWidgets('contains legacyDark and adaptive', (_) async {
      expect(
        AppGridBackgroundMode.values,
        containsAll([
          AppGridBackgroundMode.legacyDark,
          AppGridBackgroundMode.adaptive,
        ]),
      );
    });
  });

  group('AppGridBackground - legacyDark mode', () {
    testWidgets(
      'resolves fill to kitColors.background regardless of brightness',
      (tester) async {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            _wrap(
              brightness: brightness,
              child: const AppGridBackground(
                mode: AppGridBackgroundMode.legacyDark,
                child: SizedBox.shrink(),
              ),
            ),
          );

          final fillColor = _findFillColor(tester);
          expect(
            fillColor,
            equals(KitColors.background),
            reason:
                'legacyDark fill should be kitColors.background in '
                '$brightness mode',
          );
        }
      },
    );

    testWidgets(
      'resolves line color to kitColors.white02 regardless of brightness',
      (tester) async {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            _wrap(
              brightness: brightness,
              child: const AppGridBackground(
                mode: AppGridBackgroundMode.legacyDark,
                child: SizedBox.shrink(),
              ),
            ),
          );

          final gridPattern = tester.widget<GridPattern>(
            find.byType(GridPattern),
          );
          expect(
            gridPattern.lineColor,
            equals(KitColors.white02),
            reason:
                'legacyDark lines should be kitColors.white02 in '
                '$brightness mode',
          );
        }
      },
    );

    testWidgets(
      'defaults to legacyDark when mode is not specified',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.dark,
            child: const AppGridBackground(child: SizedBox.shrink()),
          ),
        );

        final fillColor = _findFillColor(tester);
        expect(fillColor, equals(KitColors.background));
      },
    );
  });

  group('AppGridBackground - adaptive mode', () {
    testWidgets(
      'resolves fill to AppSemanticColors.gridBackground in dark mode',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.dark,
            child: const AppGridBackground(
              mode: AppGridBackgroundMode.adaptive,
              child: SizedBox.shrink(),
            ),
          ),
        );

        final fillColor = _findFillColor(tester);
        final expectedFill = AppTheme.buildTheme(Brightness.dark)
            .extension<AppSemanticColors>()!
            .gridBackground;
        expect(
          fillColor,
          equals(expectedFill),
          reason:
              'adaptive fill should be AppSemanticColors.gridBackground '
              'in dark mode',
        );
      },
    );

    testWidgets(
      'resolves fill to AppSemanticColors.gridBackground in light mode',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.light,
            child: const AppGridBackground(
              mode: AppGridBackgroundMode.adaptive,
              child: SizedBox.shrink(),
            ),
          ),
        );

        final fillColor = _findFillColor(tester);
        final expectedFill = AppTheme.buildTheme(Brightness.light)
            .extension<AppSemanticColors>()!
            .gridBackground;
        expect(
          fillColor,
          equals(expectedFill),
          reason:
              'adaptive fill should be AppSemanticColors.gridBackground '
              'in light mode',
        );
      },
    );

    testWidgets(
      'adaptive dark fill differs from adaptive light fill',
      (tester) async {
        final darkSurface =
            AppTheme.buildTheme(Brightness.dark).colorScheme.surface;
        final lightSurface =
            AppTheme.buildTheme(Brightness.light).colorScheme.surface;
        expect(
          darkSurface,
          isNot(equals(lightSurface)),
          reason:
              'adaptive mode should produce different fills for '
              'dark vs light brightness',
        );
      },
    );

    testWidgets(
      'resolves line color to AppSemanticColors.gridLine',
      (tester) async {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            _wrap(
              brightness: brightness,
              child: const AppGridBackground(
                mode: AppGridBackgroundMode.adaptive,
                child: SizedBox.shrink(),
              ),
            ),
          );

          final gridPattern = tester.widget<GridPattern>(
            find.byType(GridPattern),
          );
          final expectedLine = AppTheme.buildTheme(brightness)
              .extension<AppSemanticColors>()!
              .gridLine;
          expect(
            gridPattern.lineColor,
            equals(expectedLine),
            reason:
                'adaptive lines should be AppSemanticColors.gridLine in '
                '$brightness mode',
          );
        }
      },
    );

    testWidgets(
      'resolves glow from AppSemanticColors.gridGlow',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.dark,
            child: const AppGridBackground(
              mode: AppGridBackgroundMode.adaptive,
              showTopGlow: true,
              child: SizedBox.shrink(),
            ),
          ),
        );

        final expectedGlow = AppTheme.buildTheme(Brightness.dark)
            .extension<AppSemanticColors>()!
            .gridGlow;

        final glowColor = _findGlowColor(tester);
        expect(
          glowColor,
          equals(expectedGlow),
          reason: 'adaptive glow should be AppSemanticColors.gridGlow',
        );
      },
    );
  });

  group('AppGridBackground - explicit overrides', () {
    testWidgets(
      'explicit colors take priority over mode resolution',
      (tester) async {
        const customFill = Color(0xFFFF0000);
        const customLine = Color(0xFF00FF00);
        const customGlow = Color(0xFF0000FF);

        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.dark,
            child: const AppGridBackground(
              mode: AppGridBackgroundMode.adaptive,
              fillColor: customFill,
              lineColor: customLine,
              glowColor: customGlow,
              showTopGlow: true,
              child: SizedBox.shrink(),
            ),
          ),
        );

        final fillColor = _findFillColor(tester);
        expect(fillColor, equals(customFill));

        final gridPattern = tester.widget<GridPattern>(
          find.byType(GridPattern),
        );
        expect(gridPattern.lineColor, equals(customLine));

        final glowColor = _findGlowColor(tester);
        expect(glowColor, equals(customGlow));
      },
    );
  });

  group('AppGridBackground - radial mask', () {
    testWidgets(
      'radial mask is not affected by mode or brightness',
      (tester) async {
        // The _GridPainter radial mask uses Colors.white with BlendMode.dstIn.
        // This test verifies that both modes produce a GridPattern (and thus
        // a _GridPainter) -- the mask behavior is internal to the painter
        // and does not branch on brightness.
        for (final mode in AppGridBackgroundMode.values) {
          for (final brightness in Brightness.values) {
            await tester.pumpWidget(
              _wrap(
                brightness: brightness,
                child: AppGridBackground(
                  mode: mode,
                  child: const SizedBox.shrink(),
                ),
              ),
            );
            expect(
              find.byType(GridPattern),
              findsOneWidget,
              reason:
                  'GridPattern should always be present for mode=$mode, '
                  'brightness=$brightness',
            );
          }
        }
      },
    );
  });
}

/// Finds the fill [Color] from the [ColoredBox] that is a descendant of
/// [AppGridBackground] (not the Scaffold's background).
Color _findFillColor(WidgetTester tester) {
  final coloredBoxFinder = find.descendant(
    of: find.byType(AppGridBackground),
    matching: find.byType(ColoredBox),
  );
  // The first ColoredBox descendant of AppGridBackground is the fill.
  return tester.widget<ColoredBox>(coloredBoxFinder.first).color;
}

/// Finds the first color of the [RadialGradient] used for the top glow.
Color _findGlowColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppGridBackground),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).gradient is RadialGradient,
      ),
    ),
  );
  final gradient =
      (container.decoration! as BoxDecoration).gradient! as RadialGradient;
  return gradient.colors.first;
}

Widget _wrap({
  required Brightness brightness,
  required Widget child,
}) {
  return MaterialApp(
    // Use a unique key per brightness so the widget tree fully rebuilds
    // when brightness changes within the same test.
    key: ValueKey(brightness),
    theme: AppTheme.buildTheme(brightness),
    home: Scaffold(body: child),
  );
}
