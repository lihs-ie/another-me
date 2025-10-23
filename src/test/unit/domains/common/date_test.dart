import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/helper/math.dart';

void main() {
  group('Package domains/common/date', () {
    group('DayPeriod', () {
      test('declares all defined enumerators.', () {
        expect(DayPeriod.morning, isA<DayPeriod>());
        expect(DayPeriod.noon, isA<DayPeriod>());
        expect(DayPeriod.night, isA<DayPeriod>());
      });
    });

    group('OfflineGracePeriod', () {
      group('instantiate', () {
        test('successfully with valid value.', () {
          final int minutes = randomInteger(min: 1, max: 256);

          final instance = OfflineGracePeriod(minutes: minutes);

          expect(instance.minutes, equals(minutes));
        });

        test('unsuccessfully with non-positive value.', () {
          expect(
            () => OfflineGracePeriod(minutes: 0),
            throwsA(isA<InvariantViolationException>()),
          );

          expect(
            () => OfflineGracePeriod(minutes: -1),
            throwsA(isA<InvariantViolationException>()),
          );
        });
      });

      group('equals', () {
        test('returns true with same values.', () {
          final int minutes = randomInteger(min: 1, max: 256);

          final instance1 = OfflineGracePeriod(minutes: minutes);
          final instance2 = OfflineGracePeriod(minutes: minutes);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different values.', () {
          final instance1 = OfflineGracePeriod(minutes: 30);
          final instance2 = OfflineGracePeriod(minutes: 31);

          expect(instance1 == instance2, isFalse);
        });
      });
    });
  });
}
