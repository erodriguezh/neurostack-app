# Unit and Widget Testing Guidelines

Unit Tests: input <-> output
Widget Tests: action <-> result

## Unit tests

```dart
// lib/utils/validators.dart
bool isEmailValid(String email) {
  if (email.isEmpty) return false;
  // Basic check for demonstration
  return email.contains('@') && email.contains('.');
}
```

```dart
// test/utils/validators.dart
void main() {
  test('isEmailValid should return true for valid emails', () {
    expect(isEmailValid('test@example.com'), isTrue);
  });

  test('isEmailValid should return false for invalid emails', () {
    expect(isEmailValid('testexample.com'), isFalse);
    expect(isEmailValid('test@examplecom'), isFalse);
    expect(isEmailValid(''), isFalse);
  });
}
```

## Widget tests

```dart
// counter_view_model.dart
class CounterViewModel {
  final ValueNotifier<int> counter = ValueNotifier(0);

  void incrementCounter() {
    counter.value++;
  }

  void dispose() {
    counter.dispose();
  }
}
```

```dart
// counter_view.dart
class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final CounterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CounterViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _viewModel.counter,
            builder: (context, value, _) {
              return Text('Counter: $value');
            },
          ),
          ElevatedButton(
            onPressed: _viewModel.incrementCounter,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
```

```dart
// test/counter/counter_view_test.dart
void main() {
  testWidgets('CounterView increments counter when button is pressed', (WidgetTester tester) async {
    // Arrange: Pump the widget
    await tester.pumpWidget(MaterialApp(home: CounterView()));

    // Assert: Initial state (result)
    expect(find.text('Counter: 0'), findsOneWidget);

    // Act: Simulate user action (tap the button)
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Rebuild the widget tree

    // Assert: Final state (result after action)
    expect(find.text('Counter: 1'), findsOneWidget);
  });
}
```

## Testing Requirements

- Unit tests should focus on methods with clear input/output transformations
- Widget tests required for views.
- Follow Arrange-Act-Assert pattern in tests.
- Mock dependencies in tests using Fake classes.
- Widget tests should test the View with its real ViewModel (no mocking).
- Simple ViewModels with functionality covered by widget tests may not need separate unit tests
- Tests should verify behavior, not implementation details
