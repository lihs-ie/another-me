import 'package:another_me/domains/common/notification.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/notification.dart';
import '../../../supports/helper/math.dart';

void main() {
  group('group name', () {});
  (
    'Package domains/common/notification',
    () {
      group('LocalTime', () {
        group('instantiate', () {
          test('successfully with valid values.', () {
            final hour = randomInteger(min: 0, max: 23);
            final minute = randomInteger(min: 0, max: 59);

            final instance = LocalTime(hour: hour, minute: minute);

            expect(instance.hour, equals(hour));
            expect(instance.minute, equals(minute));
          });
        });

        group('instantiate unsuccessfully with', () {
          final invalids = [
            (hour: -1, minute: 0),
            (hour: 24, minute: 0),
            (hour: 0, minute: -1),
            (hour: 0, minute: 60),
          ];

          for (final invalid in invalids) {
            test('hour: ${invalid.hour}, minute: ${invalid.minute}.', () {
              expect(
                () => LocalTime(hour: invalid.hour, minute: invalid.minute),
                throwsA(isA<InvariantViolationException>()),
              );
            });
          }
        });

        group('toMinutes', () {
          test('returns correct total minutes.', () {
            final instance = LocalTime(hour: 2, minute: 30);

            final totalMinutes = instance.toMinutes();

            expect(totalMinutes, equals(150));
          });
        });

        group('equals', () {
          test('returns true with same instances.', () {
            final hour = randomInteger(min: 0, max: 23);
            final minute = randomInteger(min: 0, max: 59);

            final instance1 = LocalTime(hour: hour, minute: minute);
            final instance2 = LocalTime(hour: hour, minute: minute);

            expect(instance1 == instance2, isTrue);
          });

          test('returns false with different instances.', () {
            const differentPairs = [
              (hour1: 1, minute1: 0, hour2: 2, minute2: 0),
              (hour1: 0, minute1: 30, hour2: 0, minute2: 45),
            ];

            for (final pair in differentPairs) {
              final instance1 = LocalTime(
                hour: pair.hour1,
                minute: pair.minute1,
              );
              final instance2 = LocalTime(
                hour: pair.hour2,
                minute: pair.minute2,
              );

              expect(instance1 == instance2, isFalse);
            }
          });
        });
      });

      group('QuietHours', () {
        group('instantiate', () {
          test('successfully with valid values.', () {
            final start = Builder(LocalTimeFactory()).build(
              overrides: (hour: randomInteger(min: 0, max: 22), minute: null),
            );
            final end = Builder(
              LocalTimeFactory(),
            ).build(overrides: (hour: start.hour + 1, minute: null));

            final instance = QuietHours(start: start, end: end);

            expect(instance.start, equals(start));
            expect(instance.end, equals(end));
          });

          test('unsuccessfully with invalid values.', () {
            final start = Builder(LocalTimeFactory()).build(
              overrides: (hour: randomInteger(min: 1, max: 23), minute: null),
            );
            final end = Builder(
              LocalTimeFactory(),
            ).build(overrides: (hour: start.hour - 1, minute: null));

            expect(
              () => QuietHours(start: start, end: end),
              throwsA(isA<InvariantViolationException>()),
            );
          });
        });
      });

      group('equals', () {
        test('returns true with same instances.', () {
          final start = Builder(LocalTimeFactory()).build();
          final end = Builder(LocalTimeFactory()).build();

          final instance1 = QuietHours(start: start, end: end);
          final instance2 = QuietHours(start: start, end: end);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different instances.', () {
          final start1 = Builder(LocalTimeFactory()).build();
          final end1 = Builder(LocalTimeFactory()).build();
          final start2 = Builder(LocalTimeFactory()).build();
          final end2 = Builder(LocalTimeFactory()).build();

          final instance1 = QuietHours(start: start1, end: end1);
          final instance2 = QuietHours(start: start2, end: end2);

          expect(instance1 == instance2, isFalse);
        });
      });
    },
  );
}
