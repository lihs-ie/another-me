import 'package:another_me/domains/common/value_object.dart';
import 'package:flutter_test/flutter_test.dart';

class EqualValueObjectMatcher extends Matcher {
  final ValueObject expected;

  const EqualValueObjectMatcher(this.expected);

  @override
  bool matches(dynamic actual, Map matchState) {
    if (actual is ValueObject) {
      return expected == actual;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('equals $expected');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) => mismatchDescription.add('was $item');
}

Matcher equalsValueObject<T extends ValueObject>(T expected) =>
    EqualValueObjectMatcher(expected);
