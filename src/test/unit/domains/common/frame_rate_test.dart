import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';

import 'value_object.dart';

void main() {
  group('Package domains/common/frame_rate', () {
    valueObjectTest(
      constructor: (int value) => FramesPerSecond(value: value),
      generator: () => 24,
      variations: (value) => [12, 30, 48, 60, 96, 120],
      invalids: (value) => [0, 1, 10, 15, 25, 90, 144, -1],
      additionalTests: () {
        group('fromInteger', () {
          test('creates instance from integer.', () {
            final instance = FramesPerSecond.fromInteger(24);

            expect(instance.value, equals(24));
          });
        });

        group('frameDurationMs', () {
          test('calculates frame duration in milliseconds.', () {
            final fps24 = FramesPerSecond(value: 24);
            final fps30 = FramesPerSecond(value: 30);
            final fps60 = FramesPerSecond(value: 60);

            expect(fps24.frameDurationMs, equals(42));
            expect(fps30.frameDurationMs, equals(33));
            expect(fps60.frameDurationMs, equals(17));
          });
        });

        group('frameDurationMilliseconds', () {
          test('calculates precise frame duration.', () {
            final fps24 = FramesPerSecond(value: 24);
            final fps30 = FramesPerSecond(value: 30);
            final fps60 = FramesPerSecond(value: 60);

            expect(fps24.frameDurationMilliseconds(), closeTo(41.67, 0.01));
            expect(fps30.frameDurationMilliseconds(), closeTo(33.33, 0.01));
            expect(fps60.frameDurationMilliseconds(), closeTo(16.67, 0.01));
          });
        });

        group('totalDurationMilliseconds', () {
          test('calculates total duration for given frame count.', () {
            final fps24 = FramesPerSecond(value: 24);
            final fps30 = FramesPerSecond(value: 30);

            expect(fps24.totalDurationMilliseconds(24), closeTo(1000.0, 0.1));
            expect(fps30.totalDurationMilliseconds(30), closeTo(1000.0, 0.1));
            expect(fps24.totalDurationMilliseconds(48), closeTo(2000.0, 0.1));
          });
        });
      },
    );
  });
}
