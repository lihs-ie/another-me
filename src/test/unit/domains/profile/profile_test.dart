import 'package:another_me/domains/profile/profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/value_object.dart';

void main() {
  group('ProfileIdentifier', () {
    test('generate creates unique identifier.', () {
      final id1 = ProfileIdentifier.generate();
      final id2 = ProfileIdentifier.generate();

      expect(id1, isNot(equals(id2)));
    });
  });

  group('OutputDeviceIdentifier', () {
    test('generate creates unique identifier.', () {
      final id1 = OutputDeviceIdentifier.generate();
      final id2 = OutputDeviceIdentifier.generate();

      expect(id1, isNot(equals(id2)));
    });
  });

  group('PomodoroPolicy', () {
    valueObjectTest(
      constructor:
          (
            ({
              int workMinutes,
              int breakMinutes,
              int longBreakMinutes,
              int longBreakEvery,
              bool longBreakEnabled,
            })
            props,
          ) => PomodoroPolicy(
            workMinutes: props.workMinutes,
            breakMinutes: props.breakMinutes,
            longBreakMinutes: props.longBreakMinutes,
            longBreakEvery: props.longBreakEvery,
            longBreakEnabled: props.longBreakEnabled,
          ),
      generator: () => (
        workMinutes: 25,
        breakMinutes: 5,
        longBreakMinutes: 15,
        longBreakEvery: 4,
        longBreakEnabled: true,
      ),
      variations:
          (
            ({
              int workMinutes,
              int breakMinutes,
              int longBreakMinutes,
              int longBreakEvery,
              bool longBreakEnabled,
            })
            props,
          ) => [
            (
              workMinutes: props.workMinutes + 1,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes + 1,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes + 1,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery + 1,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: !props.longBreakEnabled,
            ),
          ],
      invalids:
          (
            ({
              int workMinutes,
              int breakMinutes,
              int longBreakMinutes,
              int longBreakEvery,
              bool longBreakEnabled,
            })
            props,
          ) => [
            (
              workMinutes: 0,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: 121,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: 0,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: 121,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: 0,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: 121,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: 0,
              longBreakEnabled: props.longBreakEnabled,
            ),
          ],
    );
  });
}
