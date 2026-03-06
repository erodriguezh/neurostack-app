import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/extensions/app_semantic_colors.dart';
import 'package:neurostack/features/session/presentation/view_models/log_session_view_model.dart';
import 'package:neurostack/features/session/presentation/views/log_session_view.dart';

import '../../../constants/test_constants.dart';
import '../../../factories/protocol_factory.dart';
import '../../../helpers/contrast_ratio.dart';
import '../../../mocks/fake_params.dart';
import '../../../mocks/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeCheckEligibilityParams());
    registerFallbackValue(FakePendingSession());
  });

  late MockCheckEligibilityUseCase mockCheckEligibility;
  late MockSessionLocalDataSource mockLocalDataSource;
  late MockSessionSyncService mockSyncService;
  late MockNotifyService mockNotifyService;
  late MockUuid mockUuid;

  setUp(() {
    mockCheckEligibility = MockCheckEligibilityUseCase();
    mockLocalDataSource = MockSessionLocalDataSource();
    mockSyncService = MockSessionSyncService();
    mockNotifyService = MockNotifyService();
    mockUuid = MockUuid();

    when(
      () => mockNotifyService.setHapticFeedbackEvent(any()),
    ).thenAnswer((_) {});
    when(() => mockNotifyService.setToastEvent(any())).thenAnswer((_) {});

    // Default: eligible
    when(
      () => mockCheckEligibility.execute(any()),
    ).thenAnswer((_) async => right(unit));
  });

  LogSessionViewModel createViewModel() {
    return LogSessionViewModel(
      protocol: ProtocolFactory.reconstitute(),
      initialDate: DateTime.now(),
      userId: TestConstants.user.id,
      checkEligibilityUseCase: mockCheckEligibility,
      sessionLocalDataSource: mockLocalDataSource,
      sessionSyncService: mockSyncService,
      notifyService: mockNotifyService,
      uuid: mockUuid,
    );
  }

  Widget wrap({
    required Brightness brightness,
    required LogSessionViewModel viewModel,
  }) {
    return MaterialApp(
      key: ValueKey(brightness),
      theme: AppTheme.buildTheme(brightness),
      home: Scaffold(
        body: LogSessionView(
          viewModel: viewModel,
          onSessionLogged: (_) {},
        ),
      ),
    );
  }

  group('LogSessionView brightness migration', () {
    for (final brightness in Brightness.values) {
      group('in ${brightness.name} mode', () {
        testWidgets(
          'renders without error',
          (tester) async {
            final vm = createViewModel();
            await tester.pumpWidget(wrap(
              brightness: brightness,
              viewModel: vm,
            ));
            await tester.pumpAndSettle();

            expect(find.text('Log Session'), findsAtLeast(1));

            vm.dispose();
          },
        );

        testWidgets(
          'header title uses semantic ink color',
          (tester) async {
            final vm = createViewModel();
            await tester.pumpWidget(wrap(
              brightness: brightness,
              viewModel: vm,
            ));
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            // "Log Session" appears in both header and CTA button.
            // The header uses Newsreader italic font, so find it by style.
            final titleTexts =
                tester.widgetList<Text>(find.text('Log Session'));
            final headerTitle = titleTexts.firstWhere(
              (t) => t.style?.fontStyle == FontStyle.italic,
            );
            expect(
              headerTitle.style?.color,
              equals(semanticColors.ink),
            );

            vm.dispose();
          },
        );

        testWidgets(
          'field labels use semantic inkSubtle color',
          (tester) async {
            final vm = createViewModel();
            await tester.pumpWidget(wrap(
              brightness: brightness,
              viewModel: vm,
            ));
            await tester.pumpAndSettle();

            final theme = AppTheme.buildTheme(brightness);
            final semanticColors =
                theme.extension<AppSemanticColors>()!;

            final whenLabel = tester.widget<Text>(find.text('WHEN'));
            expect(
              (whenLabel.style as TextStyle).color,
              equals(semanticColors.inkSubtle),
            );

            vm.dispose();
          },
        );

        testWidgets(
          'header title contrast >= 4.5:1 against surface',
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
                  'LogSessionView title contrast in ${brightness.name} '
                  'mode (got $ratio)',
            );
          },
        );
      });
    }

    // --- Source file whiteXX audits ---
    group('source file whiteXX audits', () {
      final whiteXXPattern = RegExp(
        r'kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)',
      );

      test(
        'log_session_view.dart contains no kitColors.whiteXX references',
        () {
          final source = File(
            'lib/features/session/presentation/views/log_session_view.dart',
          ).readAsStringSync();
          final matches = whiteXXPattern.allMatches(source);
          expect(
            matches,
            isEmpty,
            reason:
                'log_session_view.dart should not reference any '
                'kitColors.whiteXX tokens',
          );
        },
      );
    });

    // --- Barrier color audit ---
    group('log_session_modal.dart barrier color audit', () {
      test('does not contain hardcoded barrier color', () {
        final source = File(
          'lib/features/session/presentation/log_session_modal.dart',
        ).readAsStringSync();
        expect(
          source.contains('0xCC030303'),
          isFalse,
          reason:
              'log_session_modal.dart should derive barrier color from theme',
        );
      });
    });

    // --- DarkThemeScope audit ---
    group('trial_expired_modal.dart DarkThemeScope audit', () {
      test('wraps content in DarkThemeScope', () {
        final source = File(
          'lib/paywall/widgets/trial_expired_modal.dart',
        ).readAsStringSync();
        expect(
          source.contains('DarkThemeScope'),
          isTrue,
          reason:
              'trial_expired_modal.dart should wrap content in DarkThemeScope',
        );
      });
    });
  });
}
