import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';

import '../../../helpers/contrast_ratio.dart';

void main() {
  // AppTheme.buildTheme uses GoogleFonts internally, which requires the test
  // binding for font loading. We use testWidgets for any test that calls it.

  group('AppSemanticColors', () {
    group('registration in AppTheme', () {
      testWidgets('is registered for both brightness variants', (_) async {
        for (final brightness in Brightness.values) {
          final theme = AppTheme.buildTheme(brightness);
          final semanticColors = theme.extension<AppSemanticColors>();
          expect(
            semanticColors,
            isNotNull,
            reason:
                'AppSemanticColors should be registered in '
                '${brightness.name} theme',
          );
        }
      });

      testWidgets('is accessible via context.semanticColors', (tester) async {
        late AppSemanticColors captured;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.buildTheme(Brightness.dark),
            home: Builder(
              builder: (context) {
                captured = context.semanticColors;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(captured, isA<AppSemanticColors>());
      });
    });

    group('contrast - ink on surface', () {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${brightness.name}: ink-on-surface contrast >= $wcagAANormalText:1',
          (_) async {
            final theme = AppTheme.buildTheme(brightness);
            final colors = theme.extension<AppSemanticColors>()!;
            final ratio = contrastRatio(colors.ink, colors.surface);
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAANormalText),
              reason:
                  '${brightness.name} ink (${colors.ink}) on surface '
                  '(${colors.surface}) contrast ratio $ratio must be >= '
                  '$wcagAANormalText for WCAG AA',
            );
          },
        );

        testWidgets(
          '${brightness.name}: inkSubtle-on-surface contrast >= $wcagAALargeText:1',
          (_) async {
            final theme = AppTheme.buildTheme(brightness);
            final colors = theme.extension<AppSemanticColors>()!;
            final ratio = contrastRatio(colors.inkSubtle, colors.surface);
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAALargeText),
              reason:
                  '${brightness.name} inkSubtle (${colors.inkSubtle}) on '
                  'surface (${colors.surface}) contrast ratio $ratio must be '
                  '>= $wcagAALargeText for WCAG AA large text',
            );
          },
        );
      }
    });

    group('contrast - grid tokens', () {
      testWidgets(
        'light: gridLine-on-gridBackground contrast >= 1.5:1',
        (_) async {
          final theme = AppTheme.buildTheme(Brightness.light);
          final colors = theme.extension<AppSemanticColors>()!;
          final ratio = contrastRatio(
            colors.gridLine,
            colors.gridBackground,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(1.5),
            reason:
                'light gridLine (${colors.gridLine}) on '
                'gridBackground (${colors.gridBackground}) contrast ratio '
                '$ratio must be >= 1.5',
          );
        },
      );

      testWidgets(
        'dark: gridLine matches legacyDark line token for visual continuity',
        (_) async {
          final theme = AppTheme.buildTheme(Brightness.dark);
          final colors = theme.extension<AppSemanticColors>()!;
          expect(
            colors.gridLine,
            equals(KitColors.white02),
            reason:
                'dark mode gridLine should match legacyDark '
                '(KitColors.white02) to avoid route visual regressions',
          );
        },
      );
    });

    group('dark mode visual continuity', () {
      testWidgets('dark surface matches ColorScheme.surface', (_) async {
        final theme = AppTheme.buildTheme(Brightness.dark);
        final colors = theme.extension<AppSemanticColors>()!;
        expect(
          colors.surface,
          equals(theme.colorScheme.surface),
          reason:
              'dark mode surface should match ColorScheme.surface for '
              'visual continuity',
        );
      });

      testWidgets('dark ink matches ColorScheme.onSurface', (_) async {
        final theme = AppTheme.buildTheme(Brightness.dark);
        final colors = theme.extension<AppSemanticColors>()!;
        expect(
          colors.ink,
          equals(theme.colorScheme.onSurface),
          reason:
              'dark mode ink should match ColorScheme.onSurface for '
              'visual continuity',
        );
      });
    });

    group('copyWith', () {
      testWidgets('returns new instance with overridden values', (_) async {
        final theme = AppTheme.buildTheme(Brightness.dark);
        final original = theme.extension<AppSemanticColors>()!;
        const override = Color(0xFFFF00FF);

        final modified = original.copyWith(ink: override);
        expect(modified.ink, equals(override));
        expect(modified.surface, equals(original.surface));
        expect(modified.gridLine, equals(original.gridLine));
      });

      testWidgets('preserves all values when called with no arguments', (
        _,
      ) async {
        final theme = AppTheme.buildTheme(Brightness.light);
        final original = theme.extension<AppSemanticColors>()!;
        final copy = original.copyWith();

        expect(copy.surface, equals(original.surface));
        expect(copy.surfaceElevated, equals(original.surfaceElevated));
        expect(copy.ink, equals(original.ink));
        expect(copy.inkSubtle, equals(original.inkSubtle));
        expect(copy.border, equals(original.border));
        expect(copy.borderSubtle, equals(original.borderSubtle));
        expect(copy.gridLine, equals(original.gridLine));
        expect(copy.gridBackground, equals(original.gridBackground));
        expect(copy.gridGlow, equals(original.gridGlow));
      });
    });

    group('lerp', () {
      testWidgets('returns this when other is not AppSemanticColors', (
        _,
      ) async {
        final theme = AppTheme.buildTheme(Brightness.dark);
        final original = theme.extension<AppSemanticColors>()!;
        final result = original.lerp(null, 0.5);
        expect(result.ink, equals(original.ink));
      });

      testWidgets('interpolates between two instances at t=0.5', (_) async {
        final light = AppTheme.buildTheme(
          Brightness.light,
        ).extension<AppSemanticColors>()!;
        final dark = AppTheme.buildTheme(
          Brightness.dark,
        ).extension<AppSemanticColors>()!;

        final mid = light.lerp(dark, 0.5);

        final expectedInk = Color.lerp(light.ink, dark.ink, 0.5)!;
        expect(mid.ink, equals(expectedInk));
      });

      testWidgets('returns self at t=0', (_) async {
        final light = AppTheme.buildTheme(
          Brightness.light,
        ).extension<AppSemanticColors>()!;
        final dark = AppTheme.buildTheme(
          Brightness.dark,
        ).extension<AppSemanticColors>()!;

        final result = light.lerp(dark, 0.0);
        expect(result.ink, equals(light.ink));
        expect(result.surface, equals(light.surface));
      });

      testWidgets('returns other at t=1', (_) async {
        final light = AppTheme.buildTheme(
          Brightness.light,
        ).extension<AppSemanticColors>()!;
        final dark = AppTheme.buildTheme(
          Brightness.dark,
        ).extension<AppSemanticColors>()!;

        final result = light.lerp(dark, 1.0);
        expect(result.ink, equals(dark.ink));
        expect(result.surface, equals(dark.surface));
      });
    });
  });

  group('highlightColor', () {
    testWidgets(
      'is derived from colorScheme.onSurface, not Colors.white',
      (_) async {
        for (final brightness in Brightness.values) {
          final theme = AppTheme.buildTheme(brightness);
          final expected = theme.colorScheme.onSurface.withValues(alpha: .1);
          expect(
            theme.highlightColor,
            equals(expected),
            reason:
                '${brightness.name} highlightColor should derive from '
                'colorScheme.onSurface',
          );
        }
      },
    );
  });
}
