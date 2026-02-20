import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/dismiss_button.dart';
import 'package:neurostack/paywall/widgets/trial_reminder_alert.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrialReminderAlert', () {
    late bool upgradeTapped;
    late bool dismissTapped;

    setUp(() {
      upgradeTapped = false;
      dismissTapped = false;
    });

    Widget buildSubject() {
      return _wrap(
        TrialReminderAlert(
          onUpgrade: () => upgradeTapped = true,
          onDismiss: () => dismissTapped = true,
        ),
      );
    }

    group('Rendering', () {
      testWidgets(
        'trialReminderAlert_whenRendered_showsTrialEndsText',
        (tester) async {
          // Arrange & Act
          await tester.pumpWidget(buildSubject());

          // Assert
          expect(find.text('Your trial ends soon'), findsOneWidget);
        },
      );

      testWidgets(
        'trialReminderAlert_whenRendered_showsUpgradeNowButton',
        (tester) async {
          // Arrange & Act
          await tester.pumpWidget(buildSubject());

          // Assert
          expect(find.text('Upgrade Now'), findsOneWidget);
        },
      );

      testWidgets(
        'trialReminderAlert_whenRendered_showsClockIcon',
        (tester) async {
          // Arrange & Act
          await tester.pumpWidget(buildSubject());

          // Assert
          expect(find.byIcon(LucideIcons.clock), findsOneWidget);
        },
      );

      testWidgets(
        'trialReminderAlert_whenRendered_showsDismissButton',
        (tester) async {
          // Arrange & Act
          await tester.pumpWidget(buildSubject());

          // Assert
          expect(find.byType(DismissButton), findsOneWidget);
        },
      );
    });

    group('Interactions', () {
      testWidgets(
        'trialReminderAlert_whenUpgradeNowTapped_callsOnUpgrade',
        (tester) async {
          // Arrange
          await tester.pumpWidget(buildSubject());

          // Act
          await tester.tap(find.text('Upgrade Now'));
          await tester.pump();

          // Assert
          expect(upgradeTapped, isTrue);
          expect(dismissTapped, isFalse);
        },
      );

      testWidgets(
        'trialReminderAlert_whenDismissButtonTapped_callsOnDismiss',
        (tester) async {
          // Arrange
          await tester.pumpWidget(buildSubject());

          // Act
          await tester.tap(find.byType(DismissButton));
          await tester.pump();

          // Assert
          expect(dismissTapped, isTrue);
          expect(upgradeTapped, isFalse);
        },
      );
    });

    group('Layout', () {
      testWidgets(
        'trialReminderAlert_whenRendered_containsAllKeyElements',
        (tester) async {
          // Arrange & Act
          await tester.pumpWidget(buildSubject());

          // Assert — all key elements are descendants of TrialReminderAlert
          expect(
            find.descendant(
              of: find.byType(TrialReminderAlert),
              matching: find.byIcon(LucideIcons.clock),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(TrialReminderAlert),
              matching: find.text('Your trial ends soon'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(TrialReminderAlert),
              matching: find.text('Upgrade Now'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(TrialReminderAlert),
              matching: find.byType(DismissButton),
            ),
            findsOneWidget,
          );
        },
      );
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.buildTheme(Brightness.dark),
    home: Scaffold(body: child),
  );
}
