import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/telemetry/performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/telemetry/performance.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/telemetry/performance', () {
    ulidBasedIdentifierTest<PerformanceMonitorIdentifier, Ulid>(
      constructor: (Ulid value) => PerformanceMonitorIdentifier(value: value),
      generate: PerformanceMonitorIdentifier.generate,
      fromString: PerformanceMonitorIdentifier.fromString,
      fromBinary: PerformanceMonitorIdentifier.fromBinary,
    );

    valueObjectTest(
      constructor:
          (
            ({
              double averageCPU,
              double averageMemory,
              FramesPerSecond characterFPS,
              FramesPerSecond backgroundFPS,
              DateTime capturedAt,
            })
            props,
          ) => PerformanceSnapshot(
            averageCPU: props.averageCPU,
            averageMemory: props.averageMemory,
            characterFPS: props.characterFPS,
            backgroundFPS: props.backgroundFPS,
            capturedAt: props.capturedAt,
          ),
      generator: () => (
        averageCPU: 50.0,
        averageMemory: 200.0,
        characterFPS: FramesPerSecond(value: 30),
        backgroundFPS: FramesPerSecond(value: 24),
        capturedAt: DateTime.now(),
      ),
      variations:
          (
            ({
              double averageCPU,
              double averageMemory,
              FramesPerSecond characterFPS,
              FramesPerSecond backgroundFPS,
              DateTime capturedAt,
            })
            props,
          ) => [
            (
              averageCPU: props.averageCPU + 1.0,
              averageMemory: props.averageMemory,
              characterFPS: props.characterFPS,
              backgroundFPS: props.backgroundFPS,
              capturedAt: props.capturedAt,
            ),
            (
              averageCPU: props.averageCPU,
              averageMemory: props.averageMemory + 1.0,
              characterFPS: props.characterFPS,
              backgroundFPS: props.backgroundFPS,
              capturedAt: props.capturedAt,
            ),
            (
              averageCPU: props.averageCPU,
              averageMemory: props.averageMemory,
              characterFPS: FramesPerSecond(value: 48),
              backgroundFPS: props.backgroundFPS,
              capturedAt: props.capturedAt,
            ),
            (
              averageCPU: props.averageCPU,
              averageMemory: props.averageMemory,
              characterFPS: props.characterFPS,
              backgroundFPS: FramesPerSecond(value: 12),
              capturedAt: props.capturedAt,
            ),
            (
              averageCPU: props.averageCPU,
              averageMemory: props.averageMemory,
              characterFPS: props.characterFPS,
              backgroundFPS: props.backgroundFPS,
              capturedAt: props.capturedAt.add(const Duration(seconds: 1)),
            ),
          ],
      invalids:
          (
            ({
              double averageCPU,
              double averageMemory,
              FramesPerSecond characterFPS,
              FramesPerSecond backgroundFPS,
              DateTime capturedAt,
            })
            props,
          ) => [
            (
              averageCPU: -1.0,
              averageMemory: props.averageMemory,
              characterFPS: props.characterFPS,
              backgroundFPS: props.backgroundFPS,
              capturedAt: props.capturedAt,
            ),
            (
              averageCPU: 101.0,
              averageMemory: props.averageMemory,
              characterFPS: props.characterFPS,
              backgroundFPS: props.backgroundFPS,
              capturedAt: props.capturedAt,
            ),
            (
              averageCPU: props.averageCPU,
              averageMemory: -1.0,
              characterFPS: props.characterFPS,
              backgroundFPS: props.backgroundFPS,
              capturedAt: props.capturedAt,
            ),
          ],
    );

    valueObjectTest(
      constructor:
          (
            ({
              double cpu,
              double memory,
              FramesPerSecond character,
              FramesPerSecond background,
            })
            props,
          ) => PerformanceThresholds(
            cpu: props.cpu,
            memory: props.memory,
            character: props.character,
            background: props.background,
          ),
      generator: () => (
        cpu: 12.0,
        memory: 400.0,
        character: FramesPerSecond(value: 30),
        background: FramesPerSecond(value: 24),
      ),
      variations:
          (
            ({
              double cpu,
              double memory,
              FramesPerSecond character,
              FramesPerSecond background,
            })
            props,
          ) => [
            (
              cpu: props.cpu + 1.0,
              memory: props.memory,
              character: props.character,
              background: props.background,
            ),
            (
              cpu: props.cpu,
              memory: props.memory + 1.0,
              character: props.character,
              background: props.background,
            ),
            (
              cpu: props.cpu,
              memory: props.memory,
              character: FramesPerSecond(value: 48),
              background: props.background,
            ),
            (
              cpu: props.cpu,
              memory: props.memory,
              character: props.character,
              background: FramesPerSecond(value: 12),
            ),
          ],
      invalids:
          (
            ({
              double cpu,
              double memory,
              FramesPerSecond character,
              FramesPerSecond background,
            })
            props,
          ) => [
            (
              cpu: -1.0,
              memory: props.memory,
              character: props.character,
              background: props.background,
            ),
            (
              cpu: 101.0,
              memory: props.memory,
              character: props.character,
              background: props.background,
            ),
            (
              cpu: props.cpu,
              memory: -1.0,
              character: props.character,
              background: props.background,
            ),
          ],
      additionalTests: () {
        group('defaultThresholds', () {
          test('returns default threshold values.', () {
            final thresholds = PerformanceThresholds.defaultThresholds();

            expect(thresholds.cpu, equals(12.0));
            expect(thresholds.memory, equals(400.0));
            expect(thresholds.character.value, equals(30));
            expect(thresholds.background.value, equals(24));
          });
        });
      },
    );

    group('PerformanceMetricType', () {
      test('declares all defined enumerators.', () {
        expect(PerformanceMetricType.cpu, isA<PerformanceMetricType>());
        expect(PerformanceMetricType.memory, isA<PerformanceMetricType>());
        expect(
          PerformanceMetricType.characterFPS,
          isA<PerformanceMetricType>(),
        );
        expect(
          PerformanceMetricType.backgroundFPS,
          isA<PerformanceMetricType>(),
        );
      });
    });

    group('PerformanceMonitor', () {
      group('instantiate', () {
        group('successfully with', () {
          test('null currentSnapshot.', () {
            final monitor = PerformanceMonitor(
              identifier: PerformanceMonitorIdentifier.generate(),
              currentSnapshot: null,
              thresholds: PerformanceThresholds.defaultThresholds(),
            );

            expect(monitor.currentSnapshot, isNull);
            expect(monitor.thresholds, isNotNull);
          });

          test('non-null currentSnapshot.', () {
            final snapshot = Builder(
              PerformanceSnapshotFactory(),
            ).buildWith(seed: 1);
            final monitor = PerformanceMonitor(
              identifier: PerformanceMonitorIdentifier.generate(),
              currentSnapshot: snapshot,
              thresholds: PerformanceThresholds.defaultThresholds(),
            );

            expect(monitor.currentSnapshot, equals(snapshot));
          });
        });
      });

      group('recordSnapshot', () {
        test('updates currentSnapshot.', () {
          final thresholds = PerformanceThresholds(
            cpu: 50.0,
            memory: 500.0,
            character: FramesPerSecond(value: 24),
            background: FramesPerSecond(value: 24),
          );

          final monitor = PerformanceMonitor(
            identifier: PerformanceMonitorIdentifier.generate(),
            currentSnapshot: null,
            thresholds: thresholds,
          );

          expect(monitor.currentSnapshot, isNull);

          final snapshot = Builder(PerformanceSnapshotFactory()).buildWith(
            seed: 1,
            overrides: (
              averageCPU: 5.0,
              averageMemory: 100.0,
              characterFPS: FramesPerSecond(value: 30),
              backgroundFPS: FramesPerSecond(value: 30),
              capturedAt: null,
            ),
          );

          monitor.recordSnapshot(snapshot);

          expect(monitor.currentSnapshot, equals(snapshot));
          expect(monitor.events().length, equals(0));
        });

        test(
          'publishes PerformanceBudgetExceeded when CPU exceeds threshold.',
          () {
            final thresholds = PerformanceThresholds(
              cpu: 10.0,
              memory: 500.0,
              character: FramesPerSecond(value: 24),
              background: FramesPerSecond(value: 24),
            );

            final monitor = PerformanceMonitor(
              identifier: PerformanceMonitorIdentifier.generate(),
              currentSnapshot: null,
              thresholds: thresholds,
            );

            final snapshot = Builder(PerformanceSnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                averageCPU: 15.0,
                averageMemory: 100.0,
                characterFPS: FramesPerSecond(value: 30),
                backgroundFPS: FramesPerSecond(value: 30),
                capturedAt: null,
              ),
            );

            monitor.recordSnapshot(snapshot);

            final events = monitor.events();
            expect(events.length, equals(1));
            expect(events.first, isA<PerformanceBudgetExceeded>());

            final event = events.first as PerformanceBudgetExceeded;
            expect(event.monitor, equals(monitor.identifier));
            expect(event.metric, equals(PerformanceMetricType.cpu));
            expect(event.value, equals(15.0));
            expect(event.threshold, equals(10.0));
            expect(event.snapshot, equals(snapshot));
          },
        );

        test(
          'publishes PerformanceBudgetExceeded when memory exceeds threshold.',
          () {
            final thresholds = PerformanceThresholds(
              cpu: 50.0,
              memory: 100.0,
              character: FramesPerSecond(value: 24),
              background: FramesPerSecond(value: 24),
            );

            final monitor = PerformanceMonitor(
              identifier: PerformanceMonitorIdentifier.generate(),
              currentSnapshot: null,
              thresholds: thresholds,
            );

            final snapshot = Builder(PerformanceSnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                averageCPU: 10.0,
                averageMemory: 200.0,
                characterFPS: FramesPerSecond(value: 30),
                backgroundFPS: FramesPerSecond(value: 30),
                capturedAt: null,
              ),
            );

            monitor.recordSnapshot(snapshot);

            final events = monitor.events();
            expect(events.length, equals(1));
            expect(events.first, isA<PerformanceBudgetExceeded>());

            final event = events.first as PerformanceBudgetExceeded;
            expect(event.metric, equals(PerformanceMetricType.memory));
            expect(event.value, equals(200.0));
            expect(event.threshold, equals(100.0));
          },
        );

        test(
          'publishes PerformanceBudgetExceeded when characterFPS is below threshold.',
          () {
            final thresholds = PerformanceThresholds(
              cpu: 50.0,
              memory: 500.0,
              character: FramesPerSecond(value: 30),
              background: FramesPerSecond(value: 24),
            );

            final monitor = PerformanceMonitor(
              identifier: PerformanceMonitorIdentifier.generate(),
              currentSnapshot: null,
              thresholds: thresholds,
            );

            final snapshot = Builder(PerformanceSnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                averageCPU: 10.0,
                averageMemory: 100.0,
                characterFPS: FramesPerSecond(value: 12),
                backgroundFPS: FramesPerSecond(value: 30),
                capturedAt: null,
              ),
            );

            monitor.recordSnapshot(snapshot);

            final events = monitor.events();
            expect(events.length, equals(1));
            expect(events.first, isA<PerformanceBudgetExceeded>());

            final event = events.first as PerformanceBudgetExceeded;
            expect(event.metric, equals(PerformanceMetricType.characterFPS));
            expect(event.value, equals(12));
            expect(event.threshold, equals(30));
          },
        );

        test(
          'publishes PerformanceBudgetExceeded when backgroundFPS is below threshold.',
          () {
            final thresholds = PerformanceThresholds(
              cpu: 50.0,
              memory: 500.0,
              character: FramesPerSecond(value: 30),
              background: FramesPerSecond(value: 24),
            );

            final monitor = PerformanceMonitor(
              identifier: PerformanceMonitorIdentifier.generate(),
              currentSnapshot: null,
              thresholds: thresholds,
            );

            final snapshot = Builder(PerformanceSnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                averageCPU: 10.0,
                averageMemory: 100.0,
                characterFPS: FramesPerSecond(value: 48),
                backgroundFPS: FramesPerSecond(value: 12),
                capturedAt: null,
              ),
            );

            monitor.recordSnapshot(snapshot);

            final events = monitor.events();
            expect(events.length, equals(1));
            expect(events.first, isA<PerformanceBudgetExceeded>());

            final event = events.first as PerformanceBudgetExceeded;
            expect(event.metric, equals(PerformanceMetricType.backgroundFPS));
            expect(event.value, equals(12));
            expect(event.threshold, equals(24));
          },
        );

        test(
          'publishes multiple PerformanceBudgetExceeded events when multiple thresholds are exceeded.',
          () {
            final thresholds = PerformanceThresholds(
              cpu: 10.0,
              memory: 100.0,
              character: FramesPerSecond(value: 30),
              background: FramesPerSecond(value: 24),
            );

            final monitor = PerformanceMonitor(
              identifier: PerformanceMonitorIdentifier.generate(),
              currentSnapshot: null,
              thresholds: thresholds,
            );

            final snapshot = Builder(PerformanceSnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                averageCPU: 20.0,
                averageMemory: 200.0,
                characterFPS: FramesPerSecond(value: 12),
                backgroundFPS: FramesPerSecond(value: 12),
                capturedAt: null,
              ),
            );

            monitor.recordSnapshot(snapshot);

            final events = monitor.events();
            expect(events.length, equals(4));
            expect(events.every((e) => e is PerformanceBudgetExceeded), isTrue);
          },
        );
      });

      group('updateThresholds', () {
        test(
          'updates thresholds and publishes PerformanceThresholdsUpdated event.',
          () {
            final monitor = Builder(
              PerformanceMonitorFactory(),
            ).buildWith(seed: 1);

            final oldThresholds = monitor.thresholds;
            final newThresholds = PerformanceThresholds(
              cpu: 20.0,
              memory: 600.0,
              character: FramesPerSecond(value: 48),
              background: FramesPerSecond(value: 30),
            );

            monitor.updateThresholds(newThresholds);

            expect(monitor.thresholds, equals(newThresholds));
            expect(monitor.thresholds, isNot(equals(oldThresholds)));

            final events = monitor.events();
            expect(events.length, equals(1));
            expect(events.first, isA<PerformanceThresholdsUpdated>());

            final event = events.first as PerformanceThresholdsUpdated;
            expect(event.monitor, equals(monitor.identifier));
            expect(event.thresholds, equals(newThresholds));
          },
        );
      });
    });
  });
}
