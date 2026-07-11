import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/home/home_state.dart';
import 'package:neurostack/paywall/widgets/protocol_selection_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final items = [
    const ProtocolSelectionItem(
      protocolId: 'protocol-1',
      name: 'Protocol One',
      categoryLabel: 'EXERCISE',
      sessionCount: 3,
    ),
    const ProtocolSelectionItem(
      protocolId: 'protocol-2',
      name: 'Protocol Two',
      categoryLabel: 'MIND',
      sessionCount: 2,
    ),
    const ProtocolSelectionItem(
      protocolId: 'protocol-3',
      name: 'Protocol Three',
      categoryLabel: 'SLEEP',
      sessionCount: 1,
    ),
  ];

  Future<void> pumpModal(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(Brightness.dark),
        home: Scaffold(
          body: ProtocolSelectionModal(items: items),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Object?> captureHapticFeedback(WidgetTester tester) {
    final hapticTypes = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          hapticTypes.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return hapticTypes;
  }

  ProtocolSelectionItem selectionItem(String id, int sessionCount) {
    return ProtocolSelectionItem(
      protocolId: id,
      name: id,
      categoryLabel: 'MIND',
      sessionCount: sessionCount,
    );
  }

  group('ProtocolSelectionViewModel', () {
    final preselectionCases = [
      (
        scenario: 'withDistinctSessionCounts',
        items: [
          selectionItem('first', 1),
          selectionItem('second', 8),
          selectionItem('third', 5),
        ],
        expected: {'second', 'third'},
      ),
      (
        scenario: 'withTiedSessionCounts',
        items: [
          selectionItem('first', 4),
          selectionItem('second', 4),
          selectionItem('third', 4),
        ],
        expected: {'first', 'second'},
      ),
      (
        scenario: 'withZeroSessionCounts',
        items: [
          selectionItem('first', 0),
          selectionItem('second', 0),
          selectionItem('third', 0),
        ],
        expected: {'first', 'second'},
      ),
    ];

    for (final testCase in preselectionCases) {
      test('constructor_${testCase.scenario}_preselectsTopProtocols', () {
        final viewModel = ProtocolSelectionViewModel(items: testCase.items);
        addTearDown(viewModel.dispose);

        expect(viewModel.selectedProtocolIds.value, testCase.expected);
        expect(viewModel.canConfirm, isTrue);
      });
    }

    test('respectsInitialSelection', () {
      final viewModel = ProtocolSelectionViewModel(
        items: items,
        initialSelection: ['protocol-2', 'protocol-3'],
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.selectedProtocolIds.value, {
        'protocol-2',
        'protocol-3',
      });
    });

    test('toggle_atSelectionLimit_preservesSelection', () {
      final viewModel = ProtocolSelectionViewModel(items: items);
      addTearDown(viewModel.dispose);

      viewModel.toggle('protocol-3');

      expect(viewModel.selectedProtocolIds.value, {
        'protocol-1',
        'protocol-2',
      });
    });
  });

  group('ProtocolSelectionModal', () {
    testWidgets('toggleUpdatesCounterAndConfirmBoundary', (tester) async {
      await pumpModal(tester);

      expect(find.text('2/2 SELECTED'), findsOneWidget);

      await tester.tap(find.text('Protocol One'));
      await tester.pumpAndSettle();

      expect(find.text('1/2 SELECTED'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Confirm Selection'),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.text('Protocol Three'));
      await tester.pumpAndSettle();

      expect(find.text('2/2 SELECTED'), findsOneWidget);
      final enabledButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Confirm Selection'),
      );
      expect(enabledButton.onPressed, isNotNull);
    });

    testWidgets('tapProtocol_atSelectionLimit_emitsLightImpact', (
      tester,
    ) async {
      final hapticTypes = captureHapticFeedback(tester);
      await pumpModal(tester);

      await tester.tap(find.text('Protocol Three'));
      await tester.pumpAndSettle();

      expect(find.text('Protocol Three'), findsOneWidget);
      expect(find.text('2/2 SELECTED'), findsOneWidget);
      expect(hapticTypes, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('toggleAndConfirm_withValidSelection_emitsHaptics', (
      tester,
    ) async {
      final hapticTypes = captureHapticFeedback(tester);
      await pumpModal(tester);

      await tester.tap(find.text('Protocol One'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Protocol Three'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Selection'));
      await tester.pumpAndSettle();

      expect(hapticTypes, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    testWidgets('showDialogReturnsConfirmedSelection', (tester) async {
      List<String>? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildTheme(Brightness.dark),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showProtocolSelectionModal(
                      context,
                      items: items,
                    );
                  },
                  child: const Text('Show Modal'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Selection'));
      await tester.pumpAndSettle();

      expect(result, ['protocol-1', 'protocol-2']);
    });

    testWidgets('showDialogBlocksSystemBack', (tester) async {
      List<String>? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildTheme(Brightness.dark),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showProtocolSelectionModal(
                      context,
                      items: items,
                    );
                  },
                  child: const Text('Show Modal'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      final popped = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.text('Choose 2 Protocols to Keep'), findsOneWidget);
      expect(result, isNull);
    });
  });
}
