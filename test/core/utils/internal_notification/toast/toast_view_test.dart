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

  /// Shows a toast and pumps, then runs [verify], then cleans up the
  /// pending auto-dismiss timer by clearing the event and pumping.
  Future<void> withToast(
    WidgetTester tester, {
    required Brightness brightness,
    required ToastEvent event,
    required Future<void> Function() verify,
  }) async {
    await tester.pumpWidget(wrap(brightness: brightness));
    notifyService.setToastEvent(event);
    await tester.pump(); // trigger rebuild with toast visible
    await tester.pump(const Duration(milliseconds: 200)); // animation settle

    await verify();

    // Clean up: clear the toast event so the pending Future.delayed timer
    // finds the event already cleared and does nothing.
    notifyService.clearToastEvent();
    await tester.pump(); // process the clear
    await tester.pump(const Duration(seconds: 5)); // elapse past timer
  }

  group('Toast semantic token migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'toast container uses semantic surfaceElevated and border',
          (tester) async {
            await withToast(
              tester,
              brightness: brightness,
              event: ToastEventSuccess(message: 'Done!'),
              verify: () async {
                final theme = AppTheme.buildTheme(brightness);
                final semanticColors =
                    theme.extension<AppSemanticColors>()!;

                final containers = tester.widgetList<Container>(
                  find.byType(Container),
                );
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
          },
        );

        testWidgets(
          'toast icon uses semantic ink color',
          (tester) async {
            await withToast(
              tester,
              brightness: brightness,
              event: ToastEventSuccess(message: 'Done!'),
              verify: () async {
                final theme = AppTheme.buildTheme(brightness);
                final semanticColors =
                    theme.extension<AppSemanticColors>()!;

                final icon = tester.widget<Icon>(find.byType(Icon));
                expect(icon.color, equals(semanticColors.ink));
              },
            );
          },
        );

        testWidgets(
          'toast text uses semantic ink color explicitly',
          (tester) async {
            await withToast(
              tester,
              brightness: brightness,
              event: ToastEventSuccess(message: 'Hello'),
              verify: () async {
                final theme = AppTheme.buildTheme(brightness);
                final semanticColors =
                    theme.extension<AppSemanticColors>()!;

                final text =
                    tester.widgetList<Text>(find.byType(Text)).last;
                expect(text.style?.color, equals(semanticColors.ink));
              },
            );
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
