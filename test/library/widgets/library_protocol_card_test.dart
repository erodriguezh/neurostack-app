import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';
import 'package:neurostack/library/library_state.dart';
import 'package:neurostack/library/widgets/library_protocol_card.dart';
import '../../constants/test_constants.dart';

void main() {
  testWidgets(
    'libraryProtocolCard_whenInStack_rendersInYourStackLabel',
    (tester) async {
      // Arrange
      final model = _buildModel(status: LibraryCardStatus.inStack);

      // Act
      await tester.pumpWidget(
        _wrap(
          LibraryProtocolCard(
            model: model,
            onTapCard: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('In your stack'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.byIcon(LucideIcons.dumbbell), findsOneWidget);
    },
  );

  testWidgets(
    'libraryProtocolCard_whenAvailable_rendersTapToAddLabel',
    (tester) async {
      // Arrange
      final model = _buildModel(status: LibraryCardStatus.available);

      // Act
      await tester.pumpWidget(
        _wrap(
          LibraryProtocolCard(
            model: model,
            onTapCard: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tap to add'), findsOneWidget);
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    },
  );

  testWidgets(
    'libraryProtocolCard_whenLocked_rendersUpgradeLabelAndLockIcon',
    (tester) async {
      // Arrange
      final model = _buildModel(status: LibraryCardStatus.locked);

      // Act
      await tester.pumpWidget(
        _wrap(
          LibraryProtocolCard(
            model: model,
            onTapCard: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Upgrade to unlock'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.buildTheme(Brightness.dark),
    home: Scaffold(body: child),
  );
}

LibraryProtocolCardModel _buildModel({
  LibraryCardStatus status = LibraryCardStatus.available,
}) {
  return LibraryProtocolCardModel(
    protocolId: TestConstants.protocol.id,
    name: TestConstants.protocol.validName,
    category: Category.exercise,
    evidenceLevel: EvidenceLevel.multipleRcts,
    status: status,
  );
}
