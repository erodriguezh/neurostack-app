import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';

import '../helpers/contrast_ratio.dart';

const _minGridLineContrastLight = 1.5;
const _minGridLineContrastDark = 1.02;

void main() {
  group('Adaptive route source audit', () {
    for (final route in _adaptiveRoutes) {
      test('${route.path} uses AppGridBackgroundMode.adaptive', () {
        final source = File(route.path).readAsStringSync();
        final appGridBackgroundCalls = RegExp(
          r'AppGridBackground\s*\(',
        ).allMatches(source).length;
        final adaptiveModeCalls = RegExp(
          r'AppGridBackground\s*\([\s\S]*?mode:\s*AppGridBackgroundMode\.adaptive',
        ).allMatches(source).length;

        expect(
          appGridBackgroundCalls,
          greaterThan(0),
          reason: '${route.path} should construct AppGridBackground',
        );
        expect(
          adaptiveModeCalls,
          equals(appGridBackgroundCalls),
          reason:
              'All AppGridBackground usages in ${route.path} should set '
              'AppGridBackgroundMode.adaptive',
        );
      });
    }
  });

  group('Adaptive route title style source audit', () {
    for (final route in _adaptiveRoutes) {
      test(
        '${route.titleStylePath} renders "${route.title}" with headlineLarge',
        () {
          final source = File(route.titleStylePath).readAsStringSync();
          expect(
            RegExp(route.titleStylePattern).hasMatch(source),
            isTrue,
            reason:
                '${route.title} should use textTheme.headlineLarge '
                'without a route-level explicit title color override',
          );
        },
      );
    }
  });

  group('Adaptive route title contrast', () {
    for (final route in _adaptiveRoutes) {
      testWidgets(
        '${route.name} title contrast >= 4.5:1 in both brightness modes',
        (tester) async {
          for (final brightness in Brightness.values) {
            final theme = AppTheme.buildTheme(brightness);
            final semanticColors = theme.extension<AppSemanticColors>()!;

            await tester.pumpWidget(
              _wrap(
                brightness: brightness,
                child: _RouteTitleShell(title: route.title),
              ),
            );

            final background = tester.widget<AppGridBackground>(
              find.byType(AppGridBackground),
            );
            expect(background.mode, AppGridBackgroundMode.adaptive);

            expect(find.text(route.title), findsOneWidget);

            final renderedTitle = tester.widget<Text>(find.text(route.title));
            final titleColor =
                renderedTitle.style?.color ??
                theme.textTheme.headlineLarge!.color!;

            final ratio = contrastRatio(
              titleColor,
              semanticColors.gridBackground,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAANormalText),
              reason:
                  '${route.name} title contrast in ${brightness.name} mode '
                  '(got $ratio)',
            );

            final gridLineRatio = contrastRatio(
              semanticColors.gridLine,
              semanticColors.gridBackground,
            );
            final minGridLineContrast = brightness == Brightness.light
                ? _minGridLineContrastLight
                : _minGridLineContrastDark;
            expect(
              gridLineRatio,
              greaterThanOrEqualTo(minGridLineContrast),
              reason:
                  '${route.name} grid line contrast in ${brightness.name} '
                  'mode (got $gridLineRatio)',
            );
          }
        },
      );
    }
  });
}

Widget _wrap({
  required Brightness brightness,
  required Widget child,
}) {
  return MaterialApp(
    key: ValueKey(brightness),
    theme: AppTheme.buildTheme(brightness),
    home: child,
  );
}

class _RouteTitleShell extends StatelessWidget {
  const _RouteTitleShell({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppGridBackground(
      mode: AppGridBackgroundMode.adaptive,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveRouteSpec {
  const _AdaptiveRouteSpec({
    required this.name,
    required this.path,
    required this.title,
    required this.titleStylePath,
    required this.titleStylePattern,
  });

  final String name;
  final String path;
  final String title;
  final String titleStylePath;
  final String titleStylePattern;
}

const _adaptiveRoutes = <_AdaptiveRouteSpec>[
  _AdaptiveRouteSpec(
    name: 'Home',
    path: 'lib/home/home_view.dart',
    title: 'Your Stack',
    titleStylePath: 'lib/home/widgets/home_header.dart',
    titleStylePattern:
        r"Text\(\s*'Your Stack'\s*,[\s\S]*?style:\s*context\.theme\.textTheme\.headlineLarge\s*,",
  ),
  _AdaptiveRouteSpec(
    name: 'Library',
    path: 'lib/library/library_view.dart',
    title: 'Protocol Library',
    titleStylePath: 'lib/library/library_view.dart',
    titleStylePattern:
        r"Text\(\s*'Protocol Library'\s*,[\s\S]*?style:\s*context\.theme\.textTheme\.headlineLarge\s*,",
  ),
  _AdaptiveRouteSpec(
    name: 'Progress',
    path: 'lib/progress/progress_view.dart',
    title: 'This Week',
    titleStylePath: 'lib/progress/progress_view.dart',
    titleStylePattern:
        r"Text\(\s*'This Week'\s*,[\s\S]*?style:\s*context\.theme\.textTheme\.headlineLarge\s*,",
  ),
  _AdaptiveRouteSpec(
    name: 'Settings',
    path: 'lib/settings/settings_view.dart',
    title: 'Settings',
    titleStylePath: 'lib/settings/settings_view.dart',
    titleStylePattern:
        r"Text\(\s*'Settings'\s*,[\s\S]*?style:\s*context\.theme\.textTheme\.headlineLarge\s*,",
  ),
  _AdaptiveRouteSpec(
    name: 'Contact',
    path: 'lib/settings/contact_view.dart',
    title: 'Contact Us',
    titleStylePath: 'lib/settings/contact_view.dart',
    titleStylePattern:
        r"Text\(\s*'Contact Us'\s*,[\s\S]*?style:\s*context\.theme\.textTheme\.headlineLarge\s*,",
  ),
];
