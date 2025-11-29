import 'package:neurostack/core/utils/locator.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper classes for testing (no static counters needed)
class TestServiceA {
  int counter = 0;

  void increment() {
    counter++;
  }
}

class TestServiceB {
  int counter = 0;

  void increment() {
    counter++;
  }
}

void main() {
  tearDown(() {
    locator.reset();
  });

  group('ModuleLocator Tests', () {
    test('Register and retrieve lazy module returns same instance', () {
      // Arrange
      final module = Module<TestServiceA>(
        builder: () => TestServiceA(),
        lazy: true,
      );
      locator.registerMany([module]);

      // Act
      final instance1 = locator<TestServiceA>();
      final instance2 = locator<TestServiceA>();
      instance1.increment();

      // Assert
      expect(instance1, isA<TestServiceA>());
      expect(instance2, isA<TestServiceA>());
      expect(instance1.counter, 1);
      expect(instance2.counter, 1);
    });

    test(
      'Register and retrieve non-lazy module returns new instance each time',
      () {
        // Arrange
        final module = Module<TestServiceA>(
          builder: () => TestServiceA(),
          lazy: false,
        );
        locator.registerMany([module]);

        // Act
        final instance1 = locator<TestServiceA>();
        final instance2 = locator<TestServiceA>();
        instance1.increment();

        // Assert
        expect(instance1, isA<TestServiceA>());
        expect(instance2, isA<TestServiceA>());
        expect(instance1.counter, 1);
        expect(instance2.counter, 1);
      },
    );

    test('Register multiple modules with mixed lazy types', () {
      // Arrange
      final moduleA = Module<TestServiceA>(
        builder: () => TestServiceA(),
        lazy: true,
      ); // Lazy
      final moduleB = Module<TestServiceB>(
        builder: () => TestServiceB(),
        lazy: false,
      ); // Non-lazy (factory)

      // Act
      locator.registerMany([moduleA, moduleB]);

      // Act & Assert - retrieve instances
      final instanceA1 = locator<TestServiceA>();
      final instanceA2 = locator<TestServiceA>();
      instanceA1.increment();
      expect(instanceA1, isA<TestServiceA>());
      expect(instanceA1.counter, 1);
      expect(instanceA2.counter, 1);

      final instanceB1 = locator<TestServiceB>();
      final instanceB2 = locator<TestServiceB>();
      expect(instanceB1, isA<TestServiceB>());
      expect(instanceB1.counter, 0);
      expect(instanceB2.counter, 0);
    });

    test('Retrieve unregistered module throws exception', () {
      // Arrange (no registration)

      // Act & Assert
      expect(
        () => locator<TestServiceA>(),
        throwsA(isA<ModuleNotFoundException>()),
      );
    });

    test('Reset clears registered modules', () {
      // Arrange
      final module = Module<TestServiceA>(
        builder: () => TestServiceA(),
        lazy: false,
      );
      locator.registerMany([module]);

      // Act
      locator.reset();

      // Assert
      expect(
        () => locator<TestServiceA>(),
        throwsA(isA<ModuleNotFoundException>()),
        reason: 'Should throw after reset',
      );
    });
  });
}
