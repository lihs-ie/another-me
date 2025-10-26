import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/animation/common.dart';
import 'package:another_me/domains/library/animation/spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../supports/factories/common.dart';
import '../../../../supports/factories/common/frame_rate.dart';
import '../../../../supports/factories/library/animation/common.dart';
import '../../../../supports/factories/library/animation/spec.dart';
import '../../../../supports/factories/library/asset.dart';
import '../../common/value_object.dart';

void main() {
  group('Package domains/library/animation/spec', () {
    valueObjectTest(
      constructor: (String name) => AnimationSpecIdentifier(name: name),
      generator: () => 'idle',
      variations: (name) => ['walk_forward', 'run_fast_123'],
      invalids: (name) => [
        '',
        'InvalidName',
        '123invalid',
        'invalid-name',
        'invalid name',
        'invalid.name',
        'a' * 101,
      ],
      additionalTests: () {
        group('toString', () {
          test('returns name.', () {
            final identifier = AnimationSpecIdentifier(name: 'test_animation');
            expect(identifier.toString(), equals('test_animation'));
          });
        });
      },
    );

    group('AnimationSpec', () {
      group('instantiate', () {
        group('successfully with', () {
          final valids = [
            (
              identifier: AnimationSpecIdentifier(name: 'idle'),
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 1),
              frames: 24,
              next: 'walk',
              pivot: Builder(PivotFactory()).buildWith(seed: 1),
              hitboxes: <Hitbox>[],
              safetyMargin: 8,
            ),
            (
              identifier: AnimationSpecIdentifier(name: 'walk'),
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 30), seed: 2),
              frames: 60,
              next: 'idle',
              pivot: Builder(PivotFactory()).buildWith(seed: 2),
              hitboxes: Builder(
                HitboxFactory(),
              ).buildListWith(count: 1, seed: 1),
              safetyMargin: 16,
            ),
          ];

          for (final valid in valids) {
            test(
              'identifier: ${valid.identifier.name}, fps: ${valid.fps.value}, frames: ${valid.frames}.',
              () {
                final instance = AnimationSpec(
                  identifier: valid.identifier,
                  fps: valid.fps,
                  frames: valid.frames,
                  next: valid.next,
                  pivot: valid.pivot,
                  hitboxes: valid.hitboxes,
                  safetyMargin: valid.safetyMargin,
                );

                expect(instance.identifier, equals(valid.identifier));
                expect(instance.fps, equals(valid.fps));
                expect(instance.frames, equals(valid.frames));
                expect(instance.next, equals(valid.next));
                expect(instance.pivot, equals(valid.pivot));
                expect(instance.hitboxes, equals(valid.hitboxes));
                expect(instance.safetyMargin, equals(valid.safetyMargin));
                expect(instance.name, equals(valid.identifier.name));
              },
            );
          }
        });

        group('unsuccessfully with', () {
          final invalids = [
            (
              identifier: AnimationSpecIdentifier(name: 'invalid'),
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 3),
              frames: 0,
              safetyMargin: 8,
            ),
            (
              identifier: AnimationSpecIdentifier(name: 'invalid'),
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 4),
              frames: 25,
              safetyMargin: 8,
            ),
            (
              identifier: AnimationSpecIdentifier(name: 'invalid'),
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 5),
              frames: 24,
              safetyMargin: 7,
            ),
          ];

          for (final invalid in invalids) {
            test(
              'identifier: ${invalid.identifier.name}, fps: ${invalid.fps.value}, frames: ${invalid.frames}, safetyMargin: ${invalid.safetyMargin}.',
              () {
                expect(
                  () => AnimationSpec(
                    identifier: invalid.identifier,
                    fps: invalid.fps,
                    frames: invalid.frames,
                    next: 'next',
                    pivot: Builder(PivotFactory()).buildWith(seed: 3),
                    hitboxes: [],
                    safetyMargin: invalid.safetyMargin,
                  ),
                  throwsA(isA<InvariantViolationError>()),
                );
              },
            );
          }
        });
      });

      group('register', () {
        test('publishes AnimationSpecRegistered event.', () {
          final spec = AnimationSpec(
            identifier: AnimationSpecIdentifier(name: 'test'),
            fps: Builder(
              FramesPerSecondFactory(),
            ).buildWith(overrides: (value: 24), seed: 6),
            frames: 24,
            next: 'next',
            pivot: Builder(PivotFactory()).buildWith(seed: 4),
            hitboxes: [],
            safetyMargin: 8,
          );

          spec.register();

          final events = spec.events();
          expect(events.length, equals(1));
          expect(events.first, isA<AnimationSpecRegistered>());

          final event = events.first as AnimationSpecRegistered;
          expect(event.animationSpec, equals(spec.identifier));
          expect(event.fps, equals(spec.fps));
          expect(event.frames, equals(spec.frames));
        });
      });

      group('deprecate', () {
        test('publishes AnimationSpecDeprecated event.', () {
          final spec = AnimationSpec(
            identifier: AnimationSpecIdentifier(name: 'test'),
            fps: Builder(
              FramesPerSecondFactory(),
            ).buildWith(overrides: (value: 24), seed: 7),
            frames: 24,
            next: 'next',
            pivot: Builder(PivotFactory()).buildWith(seed: 5),
            hitboxes: [],
            safetyMargin: 8,
          );

          final reason = 'No longer supported';
          spec.deprecate(reason);

          final events = spec.events();
          expect(events.length, equals(1));
          expect(events.first, isA<AnimationSpecDeprecated>());

          final event = events.first as AnimationSpecDeprecated;
          expect(event.animationSpec, equals(spec.identifier));
          expect(event.reason, equals(reason));
        });
      });
    });
  });

  group('SpecComplianceSubscriber', () {
    group('instantiate', () {
      test('successfully with valid values.', () {
        final animationSpecRepository = Builder(
          AnimationSpecRepositoryFactory(),
        ).build();

        final assetCatalogRepository = Builder(
          AssetCatalogRepositoryFactory(),
        ).build();

        final assetValidator = Builder(AssetValidatorFactory()).build();

        final instance = SpecComplianceSubscriber(
          animationSpecRepository: animationSpecRepository,
          assetCatalogRepository: assetCatalogRepository,
          assetValidator: assetValidator,
        );

        expect(instance.runtimeType, equals(SpecComplianceSubscriber));
      });
    });
  });
}
