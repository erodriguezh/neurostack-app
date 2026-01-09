# Flutter Unit Testing: Parameterized Tests

> Use for: Edge cases, boundary conditions, input validation
> Requires: Dart 3.0+ (records)

---

## Problem

Testing multiple edge cases creates duplicate code:

```dart
test('time range overlap - exact overlap', () {
  final r1 = TimeRange(start: 1, end: 3);
  final r2 = TimeRange(start: 1, end: 3);
  expect(r1.overlaps(r2), true);
});

test('time range overlap - partial end', () {
  final r1 = TimeRange(start: 1, end: 3);
  final r2 = TimeRange(start: 2, end: 4);
  expect(r1.overlaps(r2), true);
});

// ... 5 more nearly identical tests
```

**Problems:**

- Repetitive boilerplate
- Easy to miss cases
- Maintenance nightmare

---

## Solution: Parameterized Test Pattern

```dart
group('TimeRange.overlaps', () {
  final overlapCases = [
    (s1: 1, e1: 3, s2: 1, e2: 3, desc: 'exact overlap'),
    (s1: 1, e1: 3, s2: 2, e2: 3, desc: 'second inside first'),
    (s1: 1, e1: 3, s2: 2, e2: 4, desc: 'partial overlap at end'),
    (s1: 1, e1: 3, s2: 0, e2: 2, desc: 'partial overlap at start'),
    (s1: 1, e1: 3, s2: 0, e2: 4, desc: 'first inside second'),
  ];

  for (final c in overlapCases) {
    test('returns true when ${c.desc}', () {
      // Arrange
      final range1 = TimeRangeFactory.fromHours(c.s1, c.e1);
      final range2 = TimeRangeFactory.fromHours(c.s2, c.e2);

      // Act & Assert
      expect(range1.overlaps(range2), true);
    });
  }
});
```

---

## Pattern Structure

```dart
group('{MethodUnderTest}', () {
  // 1. Define cases as list of records
  final cases = [
    (input1: value, input2: value, expected: result, desc: 'description'),
    // ...
  ];

  // 2. Loop generates one test per case
  for (final c in cases) {
    test('{verb} when ${c.desc}', () {
      // 3. Test body uses case values
      final result = methodUnderTest(c.input1, c.input2);
      expect(result, c.expected);
    });
  }
});
```

---

## Use Cases

### 1. Overlap/Collision Detection

```dart
group('TimeRange.overlaps', () {
  // Document each case with comments
  final overlapCases = [
    (s1: 1, e1: 3, s2: 1, e2: 3, desc: 'exact overlap'),
    (s1: 1, e1: 3, s2: 2, e2: 3, desc: 'second starts inside first'),
    (s1: 1, e1: 3, s2: 2, e2: 4, desc: 'second overlaps end'),
    (s1: 1, e1: 3, s2: 0, e2: 2, desc: 'second overlaps start'),
    (s1: 1, e1: 3, s2: 0, e2: 4, desc: 'first completely inside second'),
  ];

  for (final c in overlapCases) {
    test('returns true when ${c.desc}', () {
      final r1 = TimeRangeFactory.fromHours(c.s1, c.e1);
      final r2 = TimeRangeFactory.fromHours(c.s2, c.e2);

      expect(r1.overlaps(r2), true);
    });
  }

  final noOverlapCases = [
    (s1: 1, e1: 3, s2: 4, e2: 6, desc: 'second completely after'),
    (s1: 4, e1: 6, s2: 1, e2: 3, desc: 'second completely before'),
    (s1: 1, e1: 3, s2: 3, e2: 5, desc: 'adjacent (no overlap)'),
  ];

  for (final c in noOverlapCases) {
    test('returns false when ${c.desc}', () {
      final r1 = TimeRangeFactory.fromHours(c.s1, c.e1);
      final r2 = TimeRangeFactory.fromHours(c.s2, c.e2);

      expect(r1.overlaps(r2), false);
    });
  }
});
```

### 2. Input Validation

```dart
group('Email.validate', () {
  final validEmails = [
    (email: 'user@example.com', desc: 'standard format'),
    (email: 'user.name@example.com', desc: 'with dot'),
    (email: 'user+tag@example.com', desc: 'with plus'),
    (email: 'user@sub.example.com', desc: 'subdomain'),
  ];

  for (final c in validEmails) {
    test('accepts ${c.desc}', () {
      expect(Email.isValid(c.email), true);
    });
  }

  final invalidEmails = [
    (email: 'userexample.com', desc: 'missing @'),
    (email: '@example.com', desc: 'missing local part'),
    (email: 'user@', desc: 'missing domain'),
    (email: 'user @example.com', desc: 'space in local'),
    (email: '', desc: 'empty string'),
  ];

  for (final c in invalidEmails) {
    test('rejects ${c.desc}', () {
      expect(Email.isValid(c.email), false);
    });
  }
});
```

### 3. Boundary Conditions

```dart
group('Cart.addItem', () {
  final boundaryCases = [
    (maxItems: 1, addCount: 1, shouldSucceed: true, desc: 'at limit'),
    (maxItems: 1, addCount: 2, shouldSucceed: false, desc: 'over limit'),
    (maxItems: 0, addCount: 1, shouldSucceed: false, desc: 'zero limit'),
    (maxItems: 100, addCount: 100, shouldSucceed: true, desc: 'large limit'),
  ];

  for (final c in boundaryCases) {
    test('${c.shouldSucceed ? "succeeds" : "fails"} when ${c.desc}', () {
      // Arrange
      final cart = CartFactory.create(maxItems: c.maxItems);

      // Act
      late Result lastResult;
      for (var i = 0; i < c.addCount; i++) {
        lastResult = cart.addItem(ItemFactory.create(id: 'item-$i'));
      }

      // Assert
      expect(lastResult.isSuccess, c.shouldSucceed);
    });
  }
});
```

### 4. Error Code Mapping

```dart
group('ApiError.fromStatusCode', () {
  final errorCases = [
    (status: 400, error: ApiError.badRequest, desc: '400'),
    (status: 401, error: ApiError.unauthorized, desc: '401'),
    (status: 403, error: ApiError.forbidden, desc: '403'),
    (status: 404, error: ApiError.notFound, desc: '404'),
    (status: 500, error: ApiError.serverError, desc: '500'),
    (status: 503, error: ApiError.serviceUnavailable, desc: '503'),
  ];

  for (final c in errorCases) {
    test('maps ${c.desc} to ${c.error}', () {
      expect(ApiError.fromStatusCode(c.status), c.error);
    });
  }
});
```

---

## Grouping Success and Failure Cases

Split cases by expected outcome for clarity:

```dart
group('Session.scheduleAt', () {
  group('succeeds', () {
    final successCases = [
      (hour: 8, desc: 'morning slot'),
      (hour: 12, desc: 'noon slot'),
      (hour: 20, desc: 'evening slot'),
    ];

    for (final c in successCases) {
      test('when ${c.desc}', () {
        final room = RoomFactory.create();
        final result = room.scheduleSession(
          SessionFactory.createAtTime(c.hour, c.hour + 1),
        );
        expect(result.isSuccess, true);
      });
    }
  });

  group('fails', () {
    final failureCases = [
      (hour: 6, error: SessionErrors.tooEarly, desc: 'before opening'),
      (hour: 23, error: SessionErrors.tooLate, desc: 'after closing'),
    ];

    for (final c in failureCases) {
      test('with ${c.error} when ${c.desc}', () {
        final room = RoomFactory.create();
        final result = room.scheduleSession(
          SessionFactory.createAtTime(c.hour, c.hour + 1),
        );
        expect(result.isFailure, true);
        expect(result.error, c.error);
      });
    }
  });
});
```

---

## When to Use

| Use Parameterized Tests | Use Individual Tests |
|------------------------|---------------------|
| Same logic, different inputs | Different setup per test |
| Boundary conditions | Complex multi-step scenarios |
| Validation rules | Integration tests |
| Mapping/transformation | Tests needing unique mocks |
| ≥3 similar test cases | ≤2 similar cases |

---

## Anti-Patterns

### ❌ Too Complex Cases

```dart
// BAD - case record is hard to read
final cases = [
  (a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, expected: 28, desc: '...'),
];
```

**Fix:** If >5 parameters, use a helper class or split tests.

### ❌ Missing Descriptions

```dart
// BAD - test names are meaningless
final cases = [
  (s1: 1, e1: 3, s2: 2, e2: 4),  // What does this test?
];

for (final c in cases) {
  test('case ${cases.indexOf(c)}', () { ... });  // Useless name
}
```

**Fix:** Always include `desc` field.

### ❌ Hiding Logic in Cases

```dart
// BAD - expected value computation hides bugs
final cases = [
  (a: 2, b: 3, expected: 2 * 3),  // If multiply() is broken, test passes
];
```

**Fix:** Use literal expected values: `expected: 6`.

---

## Checklist

- [ ] Cases as list of records with `desc` field
- [ ] Group by expected outcome (success/failure)
- [ ] Test name includes `${c.desc}`
- [ ] ≤5 parameters per case
- [ ] Literal expected values (not computed)
- [ ] Comments for non-obvious cases
