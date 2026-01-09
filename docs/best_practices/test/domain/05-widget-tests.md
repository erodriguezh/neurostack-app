# Flutter Unit Testing: Widget Tests

> Flutter-specific patterns
> Uses: `flutter_test` package

---

## Widget Test Structure

```dart
testWidgets('{widget}_{scenario}_{expectedResult}', (tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(title: 'Test'),
    ),
  );

  // Act
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  // Assert
  expect(find.text('1'), findsOneWidget);
});
```

---

## The pump() Rules

| Method | When to Use |
|--------|------------|
| `pump()` | After any state change (tap, enter text) |
| `pump(duration)` | Advance specific time |
| `pumpAndSettle()` | Wait for all animations to complete |
| `pumpAndSettle(timeout)` | With timeout for long animations |

### ❌ Common Mistake

```dart
// BAD - missing pump after interaction
await tester.tap(find.byIcon(Icons.add));
expect(find.text('1'), findsOneWidget);  // FAILS - state not rebuilt
```

### ✅ Correct

```dart
// GOOD - pump rebuilds widget tree
await tester.tap(find.byIcon(Icons.add));
await tester.pump();  // Rebuild
expect(find.text('1'), findsOneWidget);
```

---

## Finders

```dart
// By text content
find.text('Submit')
find.textContaining('Hello')

// By widget type
find.byType(ElevatedButton)
find.byType(TextField)

// By key (preferred for test stability)
find.byKey(const Key('submit_button'))
find.byKey(const ValueKey('user_email_field'))

// By icon
find.byIcon(Icons.add)
find.byIcon(Icons.delete)

// By semantics
find.bySemanticsLabel('Close dialog')

// By widget predicate
find.byWidgetPredicate(
  (widget) => widget is Text && widget.data?.startsWith('Error') == true,
)

// Descendant/ancestor
find.descendant(
  of: find.byType(ListTile),
  matching: find.text('Item 1'),
)
```

---

## Matchers

```dart
// Count matchers
expect(find.text('Hello'), findsOneWidget);
expect(find.text('Hello'), findsNothing);
expect(find.byType(ListTile), findsNWidgets(3));
expect(find.byType(ListTile), findsAtLeast(1));

// Widget property matchers
expect(
  tester.widget<Text>(find.text('Hello')),
  isA<Text>().having((t) => t.style?.color, 'color', Colors.red),
);

// Enabled/disabled
expect(
  tester.widget<ElevatedButton>(find.byType(ElevatedButton)),
  isA<ElevatedButton>().having((b) => b.onPressed, 'onPressed', isNotNull),
);
```

---

## User Interactions

### Tap

```dart
await tester.tap(find.byIcon(Icons.add));
await tester.pump();

// Tap at specific position
await tester.tapAt(const Offset(100, 200));
await tester.pump();
```

### Text Input

```dart
await tester.enterText(find.byType(TextField), 'test@email.com');
await tester.pump();

// Clear and enter
await tester.enterText(find.byKey(const Key('email')), '');
await tester.enterText(find.byKey(const Key('email')), 'new@email.com');
await tester.pump();
```

### Scroll

```dart
// Drag to scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pumpAndSettle();

// Scroll until visible
await tester.scrollUntilVisible(
  find.text('Item 50'),
  500.0,
  scrollable: find.byType(Scrollable),
);
```

### Swipe/Dismiss

```dart
await tester.drag(
  find.byType(Dismissible).first,
  const Offset(500, 0),  // Swipe right
);
await tester.pumpAndSettle();
```

### Long Press

```dart
await tester.longPress(find.byType(ListTile).first);
await tester.pumpAndSettle();
```

---

## Testing with Dependencies

### Provider/Riverpod

```dart
testWidgets('counter increments', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        counterProvider.overrideWith((ref) => 0),
      ],
      child: const MaterialApp(home: CounterPage()),
    ),
  );

  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
});
```

### BLoC

```dart
testWidgets('shows loading then data', (tester) async {
  final mockBloc = MockUserBloc();
  whenListen(
    mockBloc,
    Stream.fromIterable([
      UserLoading(),
      UserLoaded(User(name: 'Test')),
    ]),
    initialState: UserInitial(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<UserBloc>.value(
        value: mockBloc,
        child: const UserPage(),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  await tester.pump();

  expect(find.text('Test'), findsOneWidget);
});
```

### Navigation

```dart
testWidgets('navigates to details on tap', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: const UserListPage(),
      routes: {
        '/details': (_) => const UserDetailsPage(),
      },
    ),
  );

  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle();

  expect(find.byType(UserDetailsPage), findsOneWidget);
});
```

---

## Golden Tests

```dart
testWidgets('matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyWidget(),
    ),
  );

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});

// Update goldens: flutter test --update-goldens
```

---

## Widget Test Factories

Apply the factory pattern to widget tests:

```dart
// test/factories/widget_factories.dart
abstract final class TestWidgetFactory {
  /// Wraps widget in MaterialApp with common setup.
  static Widget app(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: child,
    );
  }

  /// Wraps widget with providers for testing.
  static Widget withProviders(
    Widget child, {
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );
  }

  /// Creates a testable form widget.
  static Widget form(Widget child, {GlobalKey<FormState>? formKey}) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: child,
        ),
      ),
    );
  }
}

// Usage
testWidgets('email field validates', (tester) async {
  await tester.pumpWidget(
    TestWidgetFactory.form(
      EmailField(controller: TextEditingController()),
    ),
  );
  // ...
});
```

---

## Common Patterns

### Testing Form Validation

```dart
testWidgets('shows error when email invalid', (tester) async {
  final formKey = GlobalKey<FormState>();

  await tester.pumpWidget(
    TestWidgetFactory.form(
      EmailField(controller: TextEditingController()),
      formKey: formKey,
    ),
  );

  await tester.enterText(find.byType(TextField), 'invalid-email');
  formKey.currentState!.validate();
  await tester.pump();

  expect(find.text('Invalid email'), findsOneWidget);
});
```

### Testing Async Operations

```dart
testWidgets('shows loading then content', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FutureBuilder<String>(
        future: Future.delayed(
          const Duration(seconds: 1),
          () => 'Loaded',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return Text(snapshot.data!);
        },
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  await tester.pumpAndSettle();

  expect(find.text('Loaded'), findsOneWidget);
});
```

### Testing Dialogs

```dart
testWidgets('shows confirmation dialog', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: DeleteButton()),
  );

  await tester.tap(find.byIcon(Icons.delete));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('Are you sure?'), findsOneWidget);

  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsNothing);
});
```

---

## Pitfalls

| ❌ Never | ✅ Always |
|----------|-----------|
| Missing `pump()` after interaction | `pump()` after every `tap()`, `enterText()` |
| `pumpAndSettle()` for everything | Use `pump()` unless waiting for animations |
| Finding by text for dynamic content | Use `Key` for stable element identification |
| Hardcoded delays | Use `pump(duration)` or `pumpAndSettle()` |

---

## Checklist

- [ ] Name follows `{widget}_{scenario}_{expectedResult}`
- [ ] Widget wrapped in `MaterialApp` (or equivalent)
- [ ] `pump()` after every interaction
- [ ] `pumpAndSettle()` only for animations
- [ ] Keys for dynamic/repeated elements
- [ ] Dependencies mocked/provided
- [ ] No hardcoded delays
