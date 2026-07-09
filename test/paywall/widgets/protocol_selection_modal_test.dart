import 'package:flutter/material.dart';
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

  group('ProtocolSelectionViewModel', () {
    test('defaultsToFirstTwoProtocolsInStackOrder', () {
      final viewModel = ProtocolSelectionViewModel(items: items);
      addTearDown(viewModel.dispose);

      expect(viewModel.selectedProtocolIds.value, {
        'protocol-1',
        'protocol-2',
      });
      expect(viewModel.canConfirm, isTrue);
    });

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

    test('hardCapPreventsThirdSelection', () {
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

    testWidgets('hardCapThirdTapDoesNotChangeSelection', (tester) async {
      await pumpModal(tester);

      await tester.tap(find.text('Protocol Three'));
      await tester.pumpAndSettle();

      expect(find.text('Protocol Three'), findsOneWidget);
      expect(find.text('2/2 SELECTED'), findsOneWidget);
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
