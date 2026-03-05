import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_view.dart';
import 'package:neurostack/core/utils/locator.dart';

import '../../../../helpers/contrast_ratio.dart';

void main() {
  late NotifyService notifyService;

  setUp(() {
    notifyService = NotifyService();
    locator.reset();
    locator.registerMany([
      Module<NotifyService>(builder: () => notifyService, lazy: false),
    ]);
  });

  tearDown(() {
    locator.reset();
  });

  Widget wrap({
    required Brightness brightness,
  }) {
    return MaterialApp(
      key: ValueKey(brightness),
      theme: AppTheme.buildTheme(brightness),
      home: const ToastView(child: SizedBox.expand()),
    );
  }

  group('Toast semantic token migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'toast container uses semantic surfaceElevated and border',
          (tester) async {
            notifyService.setToastEvent(
              ToastEventSuccess(message: 'Done!'),
            );

            await tester.pumpWidget(wrap(brightness: brightness));
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            // Find the decorated container for the toast
            final containers = tester.widgetList<Container>(
              find.byType(Container),
            );
            // The toast container has a BoxDecoration with color + border
            final toastContainer = containers.firstWhere(
              (c) {
                final dec = c.decoration;
                return dec is BoxDecoration && dec.border != null;
              },
            );
            final decoration =
                toastContainer.decoration! as BoxDecoration;
            expect(
              decoration.color,
              equals(semanticColors.surfaceElevated),
            );
          },
        );

        testWidgets(
          'toast icon uses semantic ink color',
          (tester) async {
            notifyService.setToastEvent(
              ToastEventSuccess(message: 'Done!'),
            );

            await tester.pumpWidget(wrap(brightness: brightness));
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            final icon = tester.widget<Icon>(find.byType(Icon));
            expect(icon.color, equals(semanticColors.ink));
          },
        );

        testWidgets(
          'toast text has adequate contrast against surface',
          (tester) async {
            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            final ratio = contrastRatio(
              semanticColors.ink,
              semanticColors.surfaceElevated,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(wcagAALargeText),
              reason:
                  'Toast text should meet WCAG AA large text '
                  'contrast in ${brightness.name} mode (got $ratio)',
            );
          },
        );
      });
    }

    test('source contains no kitColors.whiteXX references', () {
      final source = File(
        'lib/core/utils/internal_notification/toast/toast_view.dart',
      ).readAsStringSync();
      final matches = RegExp(
        r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
      ).allMatches(source);
      expect(
        matches,
        isEmpty,
        reason:
            'toast_view.dart should not reference any '
            'kitColors.whiteXX tokens',
      );
    });

    test('source contains no isDark brightness branching', () {
      final source = File(
        'lib/core/utils/internal_notification/toast/toast_view.dart',
      ).readAsStringSync();
      final matches = RegExp(
        r'isDark|brightness\s*==\s*Brightness\.',
      ).allMatches(source);
      expect(
        matches,
        isEmpty,
        reason:
            'toast_view.dart should not branch on isDark or '
            'brightness directly',
      );
    });
  });
}
