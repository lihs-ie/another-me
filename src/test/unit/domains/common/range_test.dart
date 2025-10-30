import 'package:another_me/domains/common/range.dart';
import 'package:flutter_test/flutter_test.dart';

import 'value_object.dart';

void main() {
  group('Package domains/common/range', () {
    valueObjectTest(
      constructor: (({DateTime? start, DateTime? end}) props) =>
          Range<DateTime>(start: props.start, end: props.end),
      generator: () {
        final now = DateTime.now();
        return (start: now, end: now.add(const Duration(days: 10)));
      },
      variations: (({DateTime? start, DateTime? end}) props) {
        if (props.start == null) {
          return [(start: DateTime.now(), end: props.end)];
        }
        return [
          (start: props.start!.add(const Duration(days: 1)), end: props.end),
          (start: props.start, end: props.end?.add(const Duration(days: 1))),
        ];
      },
      invalids: (({DateTime? start, DateTime? end}) props) {
        if (props.start == null || props.end == null) {
          return [];
        }
        return [
          (start: props.end, end: props.start),
          (start: props.start, end: props.start),
        ];
      },
      additionalTests: () {
        group('isLessThan', () {
          test('returns true when end is less than value.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: now,
              end: now.add(const Duration(days: 10)),
            );

            expect(range.isLessThan(now.add(const Duration(days: 20))), isTrue);
            expect(range.isLessThan(now.add(const Duration(days: 11))), isTrue);
          });

          test('returns false when end is greater than or equal to value.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: now,
              end: now.add(const Duration(days: 10)),
            );

            expect(
              range.isLessThan(now.add(const Duration(days: 10))),
              isFalse,
            );
            expect(range.isLessThan(now.add(const Duration(days: 5))), isFalse);
            expect(range.isLessThan(now), isFalse);
          });

          test('returns false when end is null.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(start: now, end: null);

            expect(
              range.isLessThan(now.add(const Duration(days: 100))),
              isFalse,
            );
          });
        });

        group('isGreaterThan', () {
          test('returns true when start is greater than value.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: now.add(const Duration(days: 10)),
              end: now.add(const Duration(days: 20)),
            );

            expect(range.isGreaterThan(now), isTrue);
            expect(
              range.isGreaterThan(now.add(const Duration(days: 9))),
              isTrue,
            );
          });

          test('returns false when start is less than or equal to value.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: now.add(const Duration(days: 10)),
              end: now.add(const Duration(days: 20)),
            );

            expect(
              range.isGreaterThan(now.add(const Duration(days: 10))),
              isFalse,
            );
            expect(
              range.isGreaterThan(now.add(const Duration(days: 15))),
              isFalse,
            );
            expect(
              range.isGreaterThan(now.add(const Duration(days: 20))),
              isFalse,
            );
          });

          test('returns false when start is null.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: null,
              end: now.add(const Duration(days: 100)),
            );

            expect(range.isGreaterThan(now), isFalse);
          });
        });

        group('includes', () {
          test('returns true when value is within range.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: now,
              end: now.add(const Duration(days: 20)),
            );

            expect(range.includes(now), isTrue);
            expect(range.includes(now.add(const Duration(days: 10))), isTrue);
            expect(range.includes(now.add(const Duration(days: 20))), isTrue);
          });

          test('returns false when value is outside range.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: now,
              end: now.add(const Duration(days: 20)),
            );

            expect(
              range.includes(now.subtract(const Duration(days: 1))),
              isFalse,
            );
            expect(range.includes(now.add(const Duration(days: 21))), isFalse);
          });

          test('works with unbounded start.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(
              start: null,
              end: now.add(const Duration(days: 20)),
            );

            expect(range.includes(now), isTrue);
            expect(
              range.includes(now.subtract(const Duration(days: 100))),
              isTrue,
            );
            expect(range.includes(now.add(const Duration(days: 20))), isTrue);
            expect(range.includes(now.add(const Duration(days: 21))), isFalse);
          });

          test('works with unbounded end.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(start: now, end: null);

            expect(range.includes(now), isTrue);
            expect(range.includes(now.add(const Duration(days: 20))), isTrue);
            expect(range.includes(now.add(const Duration(days: 100))), isTrue);
            expect(
              range.includes(now.subtract(const Duration(days: 1))),
              isFalse,
            );
          });

          test('works with unbounded range.', () {
            final now = DateTime.now();
            final range = Range<DateTime>(start: null, end: null);

            expect(range.includes(now), isTrue);
            expect(range.includes(now.add(const Duration(days: 100))), isTrue);
            expect(
              range.includes(now.subtract(const Duration(days: 100))),
              isTrue,
            );
          });
        });
      },
    );
  });
}
