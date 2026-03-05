import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/kit_colors.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/home/home_state.dart';
import 'package:neurostack/home/widgets/home_bottom_nav.dart';
import 'package:neurostack/home/widgets/home_empty_state.dart';
import 'package:neurostack/home/widgets/home_header.dart';
import 'package:neurostack/home/widgets/home_protocol_card.dart';
import 'package:neurostack/home/widgets/home_status_banner.dart';
import 'package:neurostack/home/widgets/home_status_dot.dart';

import '../../helpers/contrast_ratio.dart';

void main() {
  Widget wrap({
    required Brightness brightness,
    required Widget child,
  }) {
    return MaterialApp(
      key: ValueKey(brightness),
      theme: AppTheme.buildTheme(brightness),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Home widgets brightness migration', () {
    // --- HomeBottomNav ---
    group('HomeBottomNav', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeBottomNav(
                    activeTab: HomeBottomTab.stack,
                    onSelect: (_) {},
                  ),
                ),
              );

              expect(find.text('Stack'), findsOneWidget);
              expect(find.text('Library'), findsOneWidget);
              expect(find.text('Progress'), findsOneWidget);
              expect(find.text('Settings'), findsOneWidget);
            },
          );

          testWidgets(
            'nav background uses semantic surface',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeBottomNav(
                    activeTab: HomeBottomTab.stack,
                    onSelect: (_) {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors =
                  theme.extension<AppSemanticColors>()!;

              // Find the container with the nav background decoration
              final containers = tester.widgetList<Container>(
                find.byType(Container),
              );
              final navContainer = containers.firstWhere(
                (c) =>
                    c.constraints?.maxHeight == 64 ||
                    (c.decoration is BoxDecoration &&
                        (c.decoration as BoxDecoration).color ==
                            semanticColors.surface.withValues(alpha: 0.85)),
                orElse: () => containers.first,
              );
              final decoration = navContainer.decoration as BoxDecoration?;
              expect(
                decoration?.color,
                equals(semanticColors.surface.withValues(alpha: 0.85)),
              );
            },
          );

          testWidgets(
            'inactive nav item uses semantic inkSubtle',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeBottomNav(
                    activeTab: HomeBottomTab.stack,
                    onSelect: (_) {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors =
                  theme.extension<AppSemanticColors>()!;

              // "Library" is an inactive tab (Stack is active)
              final libraryText = tester.widget<Text>(
                find.text('Library'),
              );
              final color =
                  (libraryText.style as TextStyle).color;
              expect(color, equals(semanticColors.inkSubtle));
            },
          );
        });
      }
    });

    // --- HomeEmptyState ---
    group('HomeEmptyState', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeEmptyState(onBrowse: () {}),
                ),
              );

              expect(find.text('Add your first protocol'), findsOneWidget);
              expect(find.text('Browse Library'), findsOneWidget);
            },
          );

          testWidgets(
            'text uses semantic tokens',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeEmptyState(onBrowse: () {}),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors =
                  theme.extension<AppSemanticColors>()!;

              final protocolText = tester.widget<Text>(
                find.text('Add your first protocol'),
              );
              expect(
                (protocolText.style as TextStyle).color,
                equals(semanticColors.inkSubtle),
              );
            },
          );
        });
      }
    });

    // --- HomeHeader ---
    group('HomeHeader', () {
      for (final brightness in Brightness.values) {
        testWidgets(
          'renders without error in ${brightness.name} mode',
          (tester) async {
            await tester.pumpWidget(
              wrap(
                brightness: brightness,
                child: HomeHeader(onAdd: () {}),
              ),
            );

            expect(find.text('Your Stack'), findsOneWidget);
            expect(find.text('+ Add'), findsOneWidget);
          },
        );
      }

      testWidgets(
        'header text contrast >= 4.5:1 in both modes',
        (tester) async {
          for (final brightness in Brightness.values) {
            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;
            // HomeHeader uses textTheme.headlineLarge which resolves to
            // onSurface-equivalent text color
            final headerTextColor = theme.textTheme.headlineLarge!.color!;
            final surfaceColor = semanticColors.surface;

            final ratio = contrastRatio(headerTextColor, surfaceColor);
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAANormalText),
              reason:
                  'HomeHeader title contrast in ${brightness.name} mode '
                  '(got $ratio)',
            );
          }
        },
      );
    });

    // --- HomeProtocolCard ---
    group('HomeProtocolCard', () {
      HomeProtocolCardModel makeModel({bool isUnavailable = false}) {
        return HomeProtocolCardModel(
          protocolId: 'test-id',
          title: 'Test Protocol',
          categoryLabel: 'FOCUS',
          quickReference: 'A test protocol',
          loggedToday: false,
          isUnavailable: isUnavailable,
        );
      }

      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders available card without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeProtocolCard(
                    model: makeModel(),
                    onLogSession: () {},
                  ),
                ),
              );

              expect(find.text('Test Protocol'), findsOneWidget);
              expect(find.text('FOCUS'), findsOneWidget);
              expect(find.text('Log Session'), findsOneWidget);
            },
          );

          testWidgets(
            'title text uses semantic ink',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeProtocolCard(
                    model: makeModel(),
                    onLogSession: () {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors =
                  theme.extension<AppSemanticColors>()!;

              final titleText = tester.widget<Text>(
                find.text('Test Protocol'),
              );
              expect(
                (titleText.style as TextStyle).color,
                equals(semanticColors.ink),
              );
            },
          );

          testWidgets(
            'title text contrast >= 4.5:1',
            (tester) async {
              final theme = AppTheme.buildTheme(brightness);
              final semanticColors =
                  theme.extension<AppSemanticColors>()!;

              final ratio = contrastRatio(
                semanticColors.ink,
                semanticColors.surface,
              );
              expect(
                ratio,
                greaterThanOrEqualTo(wcagAANormalText),
                reason:
                    'Protocol card title contrast in ${brightness.name} '
                    'mode (got $ratio)',
              );
            },
          );

          testWidgets(
            'renders unavailable card without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: HomeProtocolCard(
                    model: makeModel(isUnavailable: true),
                    onLogSession: () {},
                  ),
                ),
              );

              expect(find.text('Test Protocol'), findsOneWidget);
              // Log Session button should not be visible for unavailable
              expect(find.text('Log Session'), findsNothing);
            },
          );
        });
      }
    });

    // --- HomeStatusBanner ---
    group('HomeStatusBanner', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          for (final bannerType in HomeBannerType.values) {
            testWidgets(
              'renders ${bannerType.name} banner without error',
              (tester) async {
                await tester.pumpWidget(
                  wrap(
                    brightness: brightness,
                    child: HomeStatusBanner(
                      banner: HomeBannerModel(
                        type: bannerType,
                        message: 'Test message',
                        isTappable: true,
                        isDismissible: true,
                      ),
                      onDismiss: () {},
                      onTap: () {},
                    ),
                  ),
                );

                expect(find.text('Test message'), findsOneWidget);
              },
            );
          }
        });
      }
    });

    // --- HomeStatusDot ---
    group('HomeStatusDot', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders inactive dot with semantic borderSubtle',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: const HomeStatusDot(active: false),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors =
                  theme.extension<AppSemanticColors>()!;

              // Find the single Container with a BoxDecoration (the dot)
              final containers = tester.widgetList<Container>(
                find.byType(Container),
              );
              final dotContainer = containers.firstWhere(
                (c) =>
                    c.decoration is BoxDecoration &&
                    (c.decoration as BoxDecoration).shape ==
                        BoxShape.circle,
              );
              final decoration = dotContainer.decoration as BoxDecoration;
              expect(decoration.color, equals(semanticColors.borderSubtle));
            },
          );

          testWidgets(
            'renders active dot with success color',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: const HomeStatusDot(active: true),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final kitColors = theme.extension<KitColorsExtension>()!;

              final containers = tester.widgetList<Container>(
                find.byType(Container),
              );
              final dotContainer = containers.firstWhere(
                (c) =>
                    c.decoration is BoxDecoration &&
                    (c.decoration as BoxDecoration).shape ==
                        BoxShape.circle,
              );
              final decoration = dotContainer.decoration as BoxDecoration;
              expect(decoration.color, equals(kitColors.success));
            },
          );
        });
      }
    });

    // --- Source file whiteXX audits ---
    group('source file whiteXX audits', () {
      final whiteXXPattern = RegExp(
        r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
      );

      final files = [
        'lib/home/widgets/home_bottom_nav.dart',
        'lib/home/widgets/home_empty_state.dart',
        'lib/home/widgets/home_header.dart',
        'lib/home/widgets/home_protocol_card.dart',
        'lib/home/widgets/home_status_banner.dart',
        'lib/home/widgets/home_status_dot.dart',
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

      test('home_view.dart contains no kitColors.panel references', () {
        final source = File('lib/home/home_view.dart').readAsStringSync();
        final matches =
            RegExp(r'kitColors\.panel').allMatches(source);
        expect(
          matches,
          isEmpty,
          reason:
              'home_view.dart should not reference kitColors.panel '
              'for dialog backgrounds',
        );
      });
    });
  });
}
