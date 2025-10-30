import 'package:another_me/domains/common/date.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/helper/math.dart';
import 'value_object.dart';

void main() {
  group('Package domains/common/date', () {
    group('DayPeriod', () {
      test('declares all defined enumerators.', () {
        expect(DayPeriod.morning, isA<DayPeriod>());
        expect(DayPeriod.noon, isA<DayPeriod>());
        expect(DayPeriod.night, isA<DayPeriod>());
      });
    });

    valueObjectTest(
      constructor: (int minutes) => OfflineGracePeriod(minutes: minutes),
      generator: () => randomInteger(min: 1, max: 256),
      variations: (minutes) => [minutes + 1, minutes + 10, minutes + 100],
      invalids: (minutes) => [0, -1, -minutes],
    );
  });
}
