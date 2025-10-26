import 'package:another_me/domains/common/playback.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/helper/math.dart';
import 'value_object.dart';

void main() {
  group('Package domains/common/playback', () {
    group('LoopMode', () {
      test('declares all defined enumerators.', () {
        expect(LoopMode.playlist, isA<LoopMode>());
        expect(LoopMode.single, isA<LoopMode>());
      });
    });

    valueObjectTest(
      constructor: (int milliseconds) =>
          FadeDuration(milliseconds: milliseconds),
      generator: () => randomInteger(min: 0, max: 10000),
      variations: (milliseconds) => [milliseconds + 1, milliseconds + 100, 0],
      invalids: (milliseconds) => [-1, -100, -milliseconds - 1],
    );

    valueObjectTest(
      constructor: (({double value, bool isMuted}) props) =>
          VolumeLevel(value: props.value, isMuted: props.isMuted),
      generator: () => (
        value: randomDouble(min: 0.1, max: 0.9),
        isMuted: randomInteger(min: 1, max: 256) % 2 == 0,
      ),
      variations: (({double value, bool isMuted}) props) => [
        (value: props.value + 0.1, isMuted: props.isMuted),
      ],
      invalids: (({double value, bool isMuted}) props) => [
        (value: -0.1, isMuted: props.isMuted),
        (value: 1.1, isMuted: props.isMuted),
      ],
    );
  });
}
