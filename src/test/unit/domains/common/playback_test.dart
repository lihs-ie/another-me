import 'package:another_me/domains/common/playback.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/helper/math.dart';

void main() {
  group('Package domains/common/playback', () {
    group('LoopMode', () {
      test('declares all defined enumerators.', () {
        expect(LoopMode.playlist, isA<LoopMode>());
        expect(LoopMode.single, isA<LoopMode>());
      });
    });

    group('FadeDuration', () {
      group('instantiate', () {
        test('successfully with valid value.', () {
          final milliseconds = randomInteger(min: 0, max: 10000);
          final instance = FadeDuration(milliseconds: milliseconds);

          expect(instance.milliseconds, equals(milliseconds));
        });

        test('unsuccessfully with negative value.', () {
          expect(
            () => FadeDuration(milliseconds: -1),
            throwsA(isA<InvariantViolationException>()),
          );
        });
      });

      group('equals', () {
        test('returns true with same values.', () {
          final milliseconds = randomInteger(min: 0, max: 10000);
          final instance1 = FadeDuration(milliseconds: milliseconds);
          final instance2 = FadeDuration(milliseconds: milliseconds);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different values.', () {
          final milliseconds = randomInteger(min: 0, max: 10000);
          final instance1 = FadeDuration(milliseconds: milliseconds);
          final instance2 = FadeDuration(milliseconds: milliseconds + 1);

          expect(instance1 == instance2, isFalse);
        });
      });
    });

    group('VolumeLevel', () {
      group('instantiate', () {
        test('successfully with valid values.', () {
          final value = 0.5;
          final isMuted = false;

          final instance = VolumeLevel(value: value, isMuted: isMuted);

          expect(instance.value, equals(value));
          expect(instance.isMuted, equals(isMuted));
        });

        group('unsuccessfully with out-of-range value.', () {
          final invalids = [-0.1, 1.1];

          for (final invalid in invalids) {
            test('value: $invalid.', () {
              expect(
                () => VolumeLevel(value: invalid, isMuted: false),
                throwsA(isA<InvariantViolationException>()),
              );
            });
          }
        });
      });

      group('equals', () {
        test('returns true with same values.', () {
          final value = randomDouble(min: 0, max: 1);
          final isMuted = randomInteger(min: 1, max: 256) % 2 == 0;

          final instance1 = VolumeLevel(value: value, isMuted: isMuted);
          final instance2 = VolumeLevel(value: value, isMuted: isMuted);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different values.', () {
          final value = randomDouble(min: 0, max: 0.9);
          final isMuted = randomInteger(min: 1, max: 256) % 2 == 0;

          final instance1 = VolumeLevel(value: value, isMuted: isMuted);
          final instance2 = VolumeLevel(value: value + 0.1, isMuted: isMuted);

          expect(instance1 == instance2, isFalse);
        });
      });
    });
  });
}
