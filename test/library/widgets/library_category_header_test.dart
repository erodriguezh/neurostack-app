import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/library/widgets/library_category_header.dart';

void main() {
  testWidgets(
    'libraryCategoryHeader_whenLabelProvided_rendersLabel',
    (tester) async {
      // Arrange
      const label = 'EXERCISE';

      // Act
      await tester.pumpWidget(
        _wrap(const LibraryCategoryHeader(label: label)),
      );

      // Assert
      expect(find.text(label), findsOneWidget);
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.buildTheme(Brightness.dark),
    home: Scaffold(body: child),
  );
}
