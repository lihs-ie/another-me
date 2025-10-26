import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/animation/timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../../supports/factories/common.dart';
import '../../../../supports/factories/common/frame_rate.dart';
import 'identifier.dart';

void main() {
  group('Package domains/library/animation/timeline', () {
    group('TimelineLoopMode', () {
      test('declares all defined enumerators.', () {
        expect(TimelineLoopMode.single, isA<TimelineLoopMode>());
        expect(TimelineLoopMode.pingpong, isA<TimelineLoopMode>());
        expect(TimelineLoopMode.loop, isA<TimelineLoopMode>());
      });
    });

    ulidBasedIdentifierTest<TimelineIdentifier, Ulid>(
      constructor: (Ulid value) => TimelineIdentifier(value: value),
      generate: TimelineIdentifier.generate,
      fromString: TimelineIdentifier.fromString,
      fromBinary: TimelineIdentifier.fromBinary,
    );

    group('TimelineDefinition', () {
      group('instantiate', () {
        group('successfully with', () {
          final valids = [
            (
              identifier: TimelineIdentifier.generate(),
              name: 'idle_animation',
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 1),
              frameCount: 24,
              loopMode: TimelineLoopMode.loop,
              defaultNext: null,
            ),
            (
              identifier: TimelineIdentifier.generate(),
              name: 'walk_animation',
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 30), seed: 2),
              frameCount: 60,
              loopMode: TimelineLoopMode.pingpong,
              defaultNext: null,
            ),
            (
              identifier: TimelineIdentifier.generate(),
              name: 'single_shot',
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 3),
              frameCount: 24,
              loopMode: TimelineLoopMode.single,
              defaultNext: 'idle',
            ),
          ];

          for (final valid in valids) {
            test(
              'name: "${valid.name}", fps: ${valid.fps.value}, frameCount: ${valid.frameCount}, loopMode: ${valid.loopMode}.',
              () {
                final instance = TimelineDefinition(
                  identifier: valid.identifier,
                  name: valid.name,
                  fps: valid.fps,
                  frameCount: valid.frameCount,
                  loopMode: valid.loopMode,
                  defaultNext: valid.defaultNext,
                );

                expect(instance.identifier, equals(valid.identifier));
                expect(instance.name, equals(valid.name));
                expect(instance.fps, equals(valid.fps));
                expect(instance.frameCount, equals(valid.frameCount));
                expect(instance.loopMode, equals(valid.loopMode));
                expect(instance.defaultNext, equals(valid.defaultNext));
              },
            );
          }
        });

        group('unsuccessfully with', () {
          final invalids = [
            (
              name: '',
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 4),
              frameCount: 24,
              loopMode: TimelineLoopMode.loop,
              defaultNext: null,
            ),
            (
              name: 'invalid',
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 5),
              frameCount: 0,
              loopMode: TimelineLoopMode.loop,
              defaultNext: null,
            ),
            (
              name: 'invalid',
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 6),
              frameCount: 25,
              loopMode: TimelineLoopMode.loop,
              defaultNext: null,
            ),
            (
              name: 'invalid',
              fps: Builder(
                FramesPerSecondFactory(),
              ).buildWith(overrides: (value: 24), seed: 7),
              frameCount: 24,
              loopMode: TimelineLoopMode.single,
              defaultNext: null,
            ),
          ];

          for (final invalid in invalids) {
            test(
              'name: "${invalid.name}", fps: ${invalid.fps.value}, frameCount: ${invalid.frameCount}, loopMode: ${invalid.loopMode}, defaultNext: ${invalid.defaultNext}.',
              () {
                expect(
                  () => TimelineDefinition(
                    identifier: TimelineIdentifier.generate(),
                    name: invalid.name,
                    fps: invalid.fps,
                    frameCount: invalid.frameCount,
                    loopMode: invalid.loopMode,
                    defaultNext: invalid.defaultNext,
                  ),
                  throwsA(isA<InvariantViolationError>()),
                );
              },
            );
          }
        });
      });
    });
  });
}
