import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/failures/domain_failure.dart';

/// Matches a Right (success) containing [expected].
Matcher isRightWith<R>(R expected) => _IsRight<R>(expected);

/// Matches a Left (failure) containing [expected] DomainFailure.
Matcher isLeftWith(DomainFailure expected) => _IsLeft(expected);

/// Matches any Right (success).
Matcher isRight<R>() => isA<Right<Object?, R>>();

/// Matches any Left (failure).
Matcher isLeft<L>() => isA<Left<L, Object?>>();

class _IsRight<R> extends Matcher {
  const _IsRight(this.expected);
  final R expected;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is Either) {
      return item.match(
        (_) => false,
        (r) => r == expected,
      );
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('is Right with value $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Either) {
      return item.match(
        (l) => mismatchDescription.add('is Left with error $l'),
        (r) => mismatchDescription.add('is Right with value $r'),
      );
    }
    return mismatchDescription.add('is not an Either');
  }
}

class _IsLeft extends Matcher {
  const _IsLeft(this.expected);
  final DomainFailure expected;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is Either) {
      return item.match(
        (l) => l == expected,
        (_) => false,
      );
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('is Left with error ${expected.code}');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Either) {
      return item.match(
        (l) => mismatchDescription.add('is Left with error $l'),
        (r) => mismatchDescription.add('is Right with value $r'),
      );
    }
    return mismatchDescription.add('is not an Either');
  }
}
