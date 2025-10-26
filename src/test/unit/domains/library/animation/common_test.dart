import 'package:another_me/domains/library/animation/common.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../supports/factories/common.dart';
import '../../../../supports/factories/library/animation/common.dart';
import '../../common/value_object.dart';

void main() {
  group('Package domains/library/animation/common', () {
    valueObjectTest(
      constructor: (int value) => GridSize(value: value),
      generator: () => 16,
      variations: (value) => [8, 32],
      invalids: (value) => [0, 1, 4, 64, -8],
    );

    valueObjectTest(
      constructor: (({int x, int y, GridSize gridSize}) props) =>
          Pivot(x: props.x, y: props.y, gridSize: props.gridSize),
      generator: () => (
        x: 16,
        y: 32,
        gridSize: Builder(
          GridSizeFactory(),
        ).buildWith(overrides: (value: 8), seed: 1),
      ),
      variations: (({int x, int y, GridSize gridSize}) props) => [
        (x: props.x + 8, y: props.y, gridSize: props.gridSize),
        (x: props.x, y: props.y + 8, gridSize: props.gridSize),
        (
          x: props.x,
          y: props.y,
          gridSize: Builder(
            GridSizeFactory(),
          ).buildWith(overrides: (value: 16), seed: 2),
        ),
      ],
      invalids: (({int x, int y, GridSize gridSize}) props) => [
        (x: -1, y: props.y, gridSize: props.gridSize),
        (x: props.x, y: -1, gridSize: props.gridSize),
        (x: 15, y: props.y, gridSize: props.gridSize),
        (x: props.x, y: 15, gridSize: props.gridSize),
      ],
      additionalTests: () {
        group('normalize', () {
          test('returns normalized coordinates.', () {
            final pivot = Pivot(
              x: 16,
              y: 32,
              gridSize: Builder(
                GridSizeFactory(),
              ).buildWith(overrides: (value: 8), seed: 10),
            );
            final (normalizedX, normalizedY) = pivot.normalize(64, 128);
            expect(normalizedX, equals(0.25));
            expect(normalizedY, equals(0.25));
          });
        });
      },
    );

    group('HitboxPurpose', () {
      test('declares all defined enumerators.', () {
        expect(HitboxPurpose.interaction, isA<HitboxPurpose>());
        expect(HitboxPurpose.effect, isA<HitboxPurpose>());
        expect(HitboxPurpose.boundingBox, isA<HitboxPurpose>());
      });
    });

    valueObjectTest(
      constructor:
          (
            ({
              int originX,
              int originY,
              int width,
              int height,
              HitboxPurpose purpose,
            })
            props,
          ) => Hitbox(
            originX: props.originX,
            originY: props.originY,
            width: props.width,
            height: props.height,
            purpose: props.purpose,
          ),
      generator: () => (
        originX: 10,
        originY: 20,
        width: 30,
        height: 40,
        purpose: HitboxPurpose.interaction,
      ),
      variations:
          (
            ({
              int originX,
              int originY,
              int width,
              int height,
              HitboxPurpose purpose,
            })
            props,
          ) => [
            (
              originX: props.originX + 5,
              originY: props.originY,
              width: props.width,
              height: props.height,
              purpose: props.purpose,
            ),
            (
              originX: props.originX,
              originY: props.originY + 5,
              width: props.width,
              height: props.height,
              purpose: props.purpose,
            ),
          ],
      invalids:
          (
            ({
              int originX,
              int originY,
              int width,
              int height,
              HitboxPurpose purpose,
            })
            props,
          ) => [
            (
              originX: -1,
              originY: props.originY,
              width: props.width,
              height: props.height,
              purpose: props.purpose,
            ),
            (
              originX: props.originX,
              originY: -1,
              width: props.width,
              height: props.height,
              purpose: props.purpose,
            ),
            (
              originX: props.originX,
              originY: props.originY,
              width: 0,
              height: props.height,
              purpose: props.purpose,
            ),
            (
              originX: props.originX,
              originY: props.originY,
              width: props.width,
              height: 0,
              purpose: props.purpose,
            ),
          ],
      additionalTests: () {
        group('contains', () {
          test('returns true when point is inside hitbox.', () {
            final hitbox = Hitbox(
              originX: 10,
              originY: 20,
              width: 30,
              height: 40,
              purpose: HitboxPurpose.interaction,
            );
            expect(hitbox.contains(10, 20), isTrue);
            expect(hitbox.contains(25, 40), isTrue);
            expect(hitbox.contains(39, 59), isTrue);
          });

          test('returns false when point is outside hitbox.', () {
            final hitbox = Hitbox(
              originX: 10,
              originY: 20,
              width: 30,
              height: 40,
              purpose: HitboxPurpose.interaction,
            );
            expect(hitbox.contains(9, 20), isFalse);
            expect(hitbox.contains(10, 19), isFalse);
            expect(hitbox.contains(40, 40), isFalse);
            expect(hitbox.contains(25, 60), isFalse);
          });
        });
      },
    );

    valueObjectTest(
      constructor: (({int count, int durationMilliseconds}) props) =>
          FrameSequence(
            count: props.count,
            durationMilliseconds: props.durationMilliseconds,
          ),
      generator: () => (count: 10, durationMilliseconds: 100),
      variations: (({int count, int durationMilliseconds}) props) => [
        (
          count: props.count + 10,
          durationMilliseconds: props.durationMilliseconds,
        ),
        (
          count: props.count,
          durationMilliseconds: props.durationMilliseconds + 100,
        ),
      ],
      invalids: (({int count, int durationMilliseconds}) props) => [
        (count: 0, durationMilliseconds: props.durationMilliseconds),
        (count: props.count, durationMilliseconds: 0),
        (count: -1, durationMilliseconds: props.durationMilliseconds),
        (count: props.count, durationMilliseconds: -1),
      ],
      additionalTests: () {
        group('frameDurationMilliseconds', () {
          test('calculates frame duration correctly.', () {
            final sequence = FrameSequence(
              count: 10,
              durationMilliseconds: 100,
            );
            expect(sequence.frameDurationMilliseconds, equals(10.0));
          });
        });
      },
    );
  });
}
