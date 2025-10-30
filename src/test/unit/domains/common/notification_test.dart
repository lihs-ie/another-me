import 'package:another_me/domains/common/notification.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/notification.dart';
import '../../../supports/helper/math.dart';
import 'value_object.dart';

void main() {
  group('Package domains/common/notification', () {
    valueObjectTest(
      constructor: (({int hour, int minute}) props) =>
          LocalTime(hour: props.hour, minute: props.minute),
      generator: () => (
        hour: randomInteger(min: 0, max: 23),
        minute: randomInteger(min: 0, max: 59),
      ),
      variations: (({int hour, int minute}) props) => [
        (hour: props.hour == 23 ? 0 : props.hour + 1, minute: props.minute),
        (hour: props.hour, minute: props.minute == 59 ? 0 : props.minute + 1),
      ],
      invalids: (({int hour, int minute}) props) => [
        (hour: -1, minute: props.minute),
        (hour: 24, minute: props.minute),
        (hour: props.hour, minute: -1),
        (hour: props.hour, minute: 60),
      ],
      additionalTests: () {
        group('toMinutes', () {
          test('returns correct total minutes.', () {
            final instance = LocalTime(hour: 2, minute: 30);

            final totalMinutes = instance.toMinutes();

            expect(totalMinutes, equals(150));
          });
        });
      },
    );

    valueObjectTest(
      constructor: (({LocalTime start, LocalTime end}) props) =>
          QuietHours(start: props.start, end: props.end),
      generator: () {
        final start = Builder(LocalTimeFactory()).build(
          overrides: (hour: randomInteger(min: 0, max: 22), minute: null),
        );
        final end = Builder(
          LocalTimeFactory(),
        ).build(overrides: (hour: start.hour + 1, minute: null));
        return (start: start, end: end);
      },
      variations: (({LocalTime start, LocalTime end}) props) => [
        (
          start: LocalTime(
            hour: props.start.hour,
            minute: props.start.minute == 59 ? 0 : props.start.minute + 1,
          ),
          end: props.end,
        ),
        (
          start: props.start,
          end: LocalTime(
            hour: props.end.hour,
            minute: props.end.minute == 59 ? 0 : props.end.minute + 1,
          ),
        ),
      ],
      invalids: (({LocalTime start, LocalTime end}) props) => [
        (start: props.end, end: props.start),
      ],
    );
  });
}
