import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/settings/widgets/settings_support_section.dart';
import 'package:neurostack/settings/widgets/settings_tile.dart';
import 'package:neurostack/settings/widgets/settings_upgrade_banner.dart';

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

  group('Settings widgets brightness migration', () {
    // --- SettingsTile ---
    group('SettingsTile', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsTile(
                    icon: Icons.mail,
                    label: 'Contact Us',
                    trailing: Icons.chevron_right,
                    onTap: () {},
                  ),
                ),
              );

              expect(find.text('Contact Us'), findsOneWidget);
            },
          );

          testWidgets(
            'label uses semantic ink color',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsTile(
                    icon: Icons.mail,
                    label: 'Contact Us',
                    trailing: Icons.chevron_right,
                    onTap: () {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final labelText = tester.widget<Text>(
                find.text('Contact Us'),
              );
              expect(
                (labelText.style as TextStyle).color,
                equals(semanticColors.ink),
              );
            },
          );

          testWidgets(
            'leading icon uses semantic inkSubtle color',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsTile(
                    icon: Icons.mail,
                    label: 'Contact Us',
                    trailing: Icons.chevron_right,
                    onTap: () {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              // Leading icon is the first Icon with size 20
              final icons = tester.widgetList<Icon>(find.byType(Icon));
              final leadingIcon = icons.firstWhere((i) => i.size == 20);
              expect(leadingIcon.color, equals(semanticColors.inkSubtle));
            },
          );

          testWidgets(
            'trailing icon uses semantic inkSubtle color',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsTile(
                    icon: Icons.mail,
                    label: 'Contact Us',
                    trailing: Icons.chevron_right,
                    onTap: () {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final icons = tester.widgetList<Icon>(find.byType(Icon));
              final trailingIcon = icons.firstWhere((i) => i.size == 16);
              expect(
                trailingIcon.color,
                equals(semanticColors.inkSubtle),
              );
            },
          );

          testWidgets(
            'label contrast >= 4.5:1 against surfaceElevated',
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
                    'SettingsTile label contrast in ${brightness.name} '
                    'mode (got $ratio)',
              );
            },
          );
        });
      }
    });

    // --- SettingsUpgradeBanner ---
    group('SettingsUpgradeBanner', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsUpgradeBanner(onTap: () {}),
                ),
              );

              expect(
                find.text('Unlock All Protocols'),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            'headline uses semantic ink color',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsUpgradeBanner(onTap: () {}),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final headlineText = tester.widget<Text>(
                find.text('Unlock All Protocols'),
              );
              expect(
                (headlineText.style as TextStyle).color,
                equals(semanticColors.ink),
              );
            },
          );

          testWidgets(
            'subtitle uses semantic inkSubtle color',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsUpgradeBanner(onTap: () {}),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final subtitleText = tester.widget<Text>(
                find.text('Unlimited protocols, all future updates'),
              );
              expect(
                (subtitleText.style as TextStyle).color,
                equals(semanticColors.inkSubtle),
              );
            },
          );

          testWidgets(
            'headline contrast >= 4.5:1 against surfaceElevated',
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
                    'SettingsUpgradeBanner headline contrast in '
                    '${brightness.name} mode (got $ratio)',
              );
            },
          );
        });
      }
    });

    // --- SettingsSupportSection ---
    group('SettingsSupportSection', () {
      for (final brightness in Brightness.values) {
        group('in ${brightness.name} mode', () {
          testWidgets(
            'renders all tiles without error',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsSupportSection(
                    isPremium: true,
                    onContactTap: () {},
                    onFeedbackTap: () {},
                    onRateAppTap: () {},
                    onFeatureRequestTap: () {},
                    onCancelSubscriptionTap: () {},
                  ),
                ),
              );

              expect(
                find.text('SUPPORT & RESOURCES'),
                findsOneWidget,
              );
              expect(find.text('Contact Us'), findsOneWidget);
              expect(find.text('Cancel Subscription'), findsOneWidget);
            },
          );

          testWidgets(
            'section header uses semantic inkSubtle',
            (tester) async {
              await tester.pumpWidget(
                wrap(
                  brightness: brightness,
                  child: SettingsSupportSection(
                    isPremium: false,
                    onContactTap: () {},
                    onFeedbackTap: () {},
                    onRateAppTap: () {},
                    onFeatureRequestTap: () {},
                    onCancelSubscriptionTap: () {},
                  ),
                ),
              );

              final theme = AppTheme.buildTheme(brightness);
              final semanticColors = theme.extension<AppSemanticColors>()!;

              final headerText = tester.widget<Text>(
                find.text('SUPPORT & RESOURCES'),
              );
              expect(
                (headerText.style as TextStyle).color,
                equals(semanticColors.inkSubtle),
              );
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
        'lib/settings/widgets/settings_tile.dart',
        'lib/settings/widgets/settings_support_section.dart',
        'lib/settings/widgets/settings_upgrade_banner.dart',
        'lib/settings/contact_view.dart',
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
    });

    // --- ContactView source audit ---
    group('ContactView source audit', () {
      test(
        'contact_view.dart AppGridBackground mode is adaptive',
        () {
          final source = File(
            'lib/settings/contact_view.dart',
          ).readAsStringSync();
          expect(
            RegExp(r'mode:\s*AppGridBackgroundMode\.adaptive').hasMatch(source),
            isTrue,
            reason:
                'contact_view.dart should explicitly set '
                'AppGridBackgroundMode.adaptive',
          );
        },
      );
    });
  });
}
