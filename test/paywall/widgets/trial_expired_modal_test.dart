import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/paywall/widgets/trial_expired_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrialExpiredModal', () {
    /// Sets up test viewport size for all tests in this group.
    void setUpTestViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
    }

    /// Resets test viewport after each test.
    void tearDownTestViewport(WidgetTester tester) {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }

    /// Pumps the modal using showTrialExpiredModal.
    Future<void> pumpModal(
      WidgetTester tester, {
      required int activeProtocolCount,
    }) async {
      setUpTestViewport(tester);
      addTearDown(() => tearDownTestViewport(tester));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildTheme(Brightness.dark),
          home: Builder(
            builder: (context) {
              // Schedule the dialog to show after the first frame
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await showTrialExpiredModal(
                  context,
                  activeProtocolCount: activeProtocolCount,
                );
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      // Allow the post-frame callback to execute
      await tester.pump();
      // Let the dialog and animations settle
      await tester.pumpAndSettle();
    }

    group('Headline rendering', () {
      testWidgets(
        'trialExpiredModal_whenRendered_showsHeadline',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 1);

          // Assert
          expect(
            find.text('Your Premium Trial Has Ended'),
            findsOneWidget,
          );
        },
      );
    });

    group('Subtext visibility based on activeProtocolCount', () {
      testWidgets(
        'trialExpiredModal_whenActiveProtocolCountIs1_hidesSubtext',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 1);

          // Assert - subtext about protocol count should not be visible
          expect(
            find.textContaining('active protocols'),
            findsNothing,
          );
        },
      );

      testWidgets(
        'trialExpiredModal_whenActiveProtocolCountIs2_hidesSubtext',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 2);

          // Assert - subtext about protocol count should not be visible
          expect(
            find.textContaining('active protocols'),
            findsNothing,
          );
        },
      );

      testWidgets(
        'trialExpiredModal_whenActiveProtocolCountIs3_showsSubtext',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 3);

          // Assert - subtext should show the count
          expect(
            find.text(
              'You currently have 3 active protocols. The free tier allows 2.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'trialExpiredModal_whenActiveProtocolCountIs5_showsSubtextWithCount',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 5);

          // Assert - subtext should show the count
          expect(
            find.text(
              'You currently have 5 active protocols. The free tier allows 2.',
            ),
            findsOneWidget,
          );
        },
      );
    });

    group('Decision card interactions', () {
      testWidgets(
        'trialExpiredModal_whenKeepEverythingTapped_returnsKeepEverything',
        (tester) async {
          // Arrange
          setUpTestViewport(tester);
          addTearDown(() => tearDownTestViewport(tester));

          TrialExpiredChoice? result;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.buildTheme(Brightness.dark),
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result = await showTrialExpiredModal(
                          context,
                          activeProtocolCount: 2,
                        );
                      },
                      child: const Text('Show Modal'),
                    ),
                  );
                },
              ),
            ),
          );

          // Open the modal
          await tester.tap(find.text('Show Modal'));
          await tester.pumpAndSettle();

          // Act - tap "Keep Everything" card
          await tester.tap(find.text('Keep Everything'));
          await tester.pumpAndSettle();

          // Assert
          expect(result, equals(TrialExpiredChoice.keepEverything));
        },
      );

      testWidgets(
        'trialExpiredModal_whenContinueWithFreeTapped_returnsContinueWithFree',
        (tester) async {
          // Arrange
          setUpTestViewport(tester);
          addTearDown(() => tearDownTestViewport(tester));

          TrialExpiredChoice? result;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.buildTheme(Brightness.dark),
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result = await showTrialExpiredModal(
                          context,
                          activeProtocolCount: 2,
                        );
                      },
                      child: const Text('Show Modal'),
                    ),
                  );
                },
              ),
            ),
          );

          // Open the modal
          await tester.tap(find.text('Show Modal'));
          await tester.pumpAndSettle();

          // Act - tap "Continue with Free" card
          await tester.tap(find.text('Continue with Free'));
          await tester.pumpAndSettle();

          // Assert
          expect(result, equals(TrialExpiredChoice.continueWithFree));
        },
      );
    });

    group('Modal dismissal behavior', () {
      testWidgets(
        'trialExpiredModal_hasNonDismissibleBarrier',
        (tester) async {
          // Arrange
          await pumpModal(tester, activeProtocolCount: 2);

          // Assert - verify the modal barrier is not dismissible
          // The showDialog is configured with barrierDismissible: false
          // Check for either ModalBarrier or AnimatedModalBarrier
          final barrierFinder = find.byWidgetPredicate(
            (widget) =>
                (widget is ModalBarrier && widget.dismissible == false) ||
                (widget is AnimatedModalBarrier && widget.dismissible == false),
          );
          expect(barrierFinder, findsAtLeast(1));
        },
      );
    });

    group('Accessibility', () {
      testWidgets(
        'trialExpiredModal_upgradeCard_hasButtonSemantics',
        (tester) async {
          // Arrange - set up viewport
          setUpTestViewport(tester);
          addTearDown(() => tearDownTestViewport(tester));

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.buildTheme(Brightness.dark),
              home: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await showTrialExpiredModal(
                      context,
                      activeProtocolCount: 2,
                    );
                  });
                  return const Scaffold(body: SizedBox.shrink());
                },
              ),
            ),
          );

          await tester.pump();
          await tester.pumpAndSettle();

          // Assert - verify the Semantics widget exists with button property
          final finder = find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.button == true &&
                widget.properties.label ==
                    'Keep Everything. Subscribe to Premium.',
          );
          expect(finder, findsOneWidget);
        },
      );

      testWidgets(
        'trialExpiredModal_downgradeCard_hasButtonSemantics',
        (tester) async {
          // Arrange - set up viewport
          setUpTestViewport(tester);
          addTearDown(() => tearDownTestViewport(tester));

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.buildTheme(Brightness.dark),
              home: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await showTrialExpiredModal(
                      context,
                      activeProtocolCount: 2,
                    );
                  });
                  return const Scaffold(body: SizedBox.shrink());
                },
              ),
            ),
          );

          await tester.pump();
          await tester.pumpAndSettle();

          // Assert - verify the Semantics widget exists with button property
          final finder = find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.button == true &&
                widget.properties.label ==
                    'Continue with Free. Limited to 2 protocols.',
          );
          expect(finder, findsOneWidget);
        },
      );

      testWidgets(
        'trialExpiredModal_decorativeIcons_areWrappedInExcludeSemantics',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 2);

          // Assert - each decorative icon should be wrapped in ExcludeSemantics
          // Hourglass icon (top of modal)
          expect(
            find.ancestor(
              of: find.byIcon(LucideIcons.hourglass),
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
          );

          // Crown icon (upgrade card)
          expect(
            find.ancestor(
              of: find.byIcon(LucideIcons.crown),
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
          );

          // Layers icon (downgrade card)
          expect(
            find.ancestor(
              of: find.byIcon(LucideIcons.layers),
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
          );

          // Arrow icon (upgrade card)
          expect(
            find.ancestor(
              of: find.byIcon(Icons.arrow_forward),
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
          );
        },
      );
    });

    group('Widget rendering', () {
      testWidgets(
        'trialExpiredModal_whenRendered_showsUpgradeCard',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 2);

          // Assert
          expect(find.text('Keep Everything'), findsOneWidget);
          expect(find.text('Subscribe to Premium'), findsOneWidget);
        },
      );

      testWidgets(
        'trialExpiredModal_whenRendered_showsDowngradeCard',
        (tester) async {
          // Arrange & Act
          await pumpModal(tester, activeProtocolCount: 2);

          // Assert
          expect(find.text('Continue with Free'), findsOneWidget);
          expect(find.text('Limited to 2 protocols'), findsOneWidget);
        },
      );
    });
  });
}
