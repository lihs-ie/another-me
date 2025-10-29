import 'package:another_me/domains/common/range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../supports/factories/common.dart';
import '../../../../supports/factories/common/date.dart';
import '../../../../supports/factories/common/range.dart';

void main() {
  group('Package test/supports/factories/common/range', () {
    group('RangeFactory<DateTime, ({int? drift})>', () {
      test('creates instance with seed', () {
        final factory = RangeFactory<DateTime, ({int? drift})>(
          DateTimeFactory(),
        );
        final instance = Builder(factory).buildWith(seed: 1);

        expect(instance, isA<Range<DateTime>>());
        expect(instance.start, isNotNull);
        expect(instance.end, isNotNull);
        expect(instance.end!.isAfter(instance.start!), isTrue);
      });

      test('creates instance with overrides', () {
        final factory = RangeFactory<DateTime, ({int? drift})>(
          DateTimeFactory(),
        );
        final customStart = DateTime(2024, 1, 1);
        final customEnd = DateTime(2024, 12, 31);
        final instance = Builder(
          factory,
        ).buildWith(seed: 1, overrides: (start: customStart, end: customEnd));

        expect(instance.start, equals(customStart));
        expect(instance.end, equals(customEnd));
      });

      test('creates different instances with different seeds', () {
        final factory = RangeFactory<DateTime, ({int? drift})>(
          DateTimeFactory(),
        );
        final instance1 = Builder(factory).buildWith(seed: 1);
        final instance2 = Builder(factory).buildWith(seed: 2);

        expect(instance1.start, isNot(equals(instance2.start)));
        expect(instance1.end, isNot(equals(instance2.end)));
      });

      test('duplicates instance', () {
        final factory = RangeFactory<DateTime, ({int? drift})>(
          DateTimeFactory(),
        );
        final original = Builder(factory).buildWith(seed: 1);
        final duplicated = Builder(factory).duplicate(instance: original);

        expect(duplicated.start, equals(original.start));
        expect(duplicated.end, equals(original.end));
      });

      test('duplicates instance with overrides', () {
        final factory = RangeFactory<DateTime, ({int? drift})>(
          DateTimeFactory(),
        );
        final original = Builder(factory).buildWith(seed: 1);
        final customEnd = DateTime(2025, 12, 31);
        final duplicated = Builder(factory).duplicate(
          instance: original,
          overrides: (start: null, end: customEnd),
        );

        expect(duplicated.start, equals(original.start));
        expect(duplicated.end, equals(customEnd));
      });
    });
  });
}
