import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/telemetry/performance.dart'
    as performance_domain;
import 'package:another_me/use_cases/performance_monitoring.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/common.dart';
import '../../supports/factories/common/transaction.dart'
    as transaction_factory;
import '../../supports/factories/logger.dart';
import '../../supports/factories/telemetry/performance.dart'
    as performance_factory;

void main() {
  group('PerformanceMonitoring', () {
    group('execute', () {
      test('records performance snapshot successfully.', () async {
        final monitor = Builder(performance_factory.PerformanceMonitorFactory())
            .buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                currentSnapshot: null,
                thresholds:
                    Builder(
                      performance_factory.PerformanceThresholdsFactory(),
                    ).buildWith(
                      seed: 1,
                      overrides: (
                        cpu: 80.0,
                        memory: 1000.0,
                        character: FramesPerSecond(value: 30),
                        background: FramesPerSecond(value: 24),
                      ),
                    ),
              ),
            );

        monitor.events();

        var persistCallCount = 0;
        performance_domain.PerformanceMonitor? persistedMonitor;

        final monitorRepository =
            Builder(
              performance_factory.PerformanceMonitorRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                current: monitor,
                onPersist: (m) {
                  persistCallCount++;
                  persistedMonitor = m;
                },
              ),
            );

        final collectedSnapshot = performance_domain.PerformanceSnapshot(
          averageCPU: 50.0,
          averageMemory: 500.0,
          characterFPS: FramesPerSecond(value: 60),
          backgroundFPS: FramesPerSecond(value: 30),
          capturedAt: DateTime.now(),
        );

        final metricsCollector = Builder(
          performance_factory.PerformanceMetricsCollectorFactory(),
        ).buildWith(seed: 1, overrides: (onCollect: () => collectedSnapshot));

        final useCase = PerformanceMonitoring(
          metricsCollector: metricsCollector,
          monitorRepository: monitorRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        await useCase.execute();

        expect(persistCallCount, equals(1));
        expect(persistedMonitor, isNotNull);
        expect(persistedMonitor!.currentSnapshot, equals(collectedSnapshot));
      });

      test(
        'fires PerformanceBudgetExceeded event when CPU exceeds threshold.',
        () async {
          final monitor =
              Builder(
                performance_factory.PerformanceMonitorFactory(),
              ).buildWith(
                seed: 1,
                overrides: (
                  identifier: null,
                  currentSnapshot: null,
                  thresholds:
                      Builder(
                        performance_factory.PerformanceThresholdsFactory(),
                      ).buildWith(
                        seed: 1,
                        overrides: (
                          cpu: 50.0,
                          memory: 1000.0,
                          character: FramesPerSecond(value: 30),
                          background: FramesPerSecond(value: 24),
                        ),
                      ),
                ),
              );

          monitor.events();

          var persistCallCount = 0;
          performance_domain.PerformanceMonitor? persistedMonitor;

          final monitorRepository =
              Builder(
                performance_factory.PerformanceMonitorRepositoryFactory(),
              ).buildWith(
                seed: 1,
                overrides: (
                  current: monitor,
                  onPersist: (m) {
                    persistCallCount++;
                    persistedMonitor = m;
                  },
                ),
              );

          final collectedSnapshot = performance_domain.PerformanceSnapshot(
            averageCPU: 80.0,
            averageMemory: 500.0,
            characterFPS: FramesPerSecond(value: 60),
            backgroundFPS: FramesPerSecond(value: 30),
            capturedAt: DateTime.now(),
          );

          final metricsCollector = Builder(
            performance_factory.PerformanceMetricsCollectorFactory(),
          ).buildWith(seed: 1, overrides: (onCollect: () => collectedSnapshot));

          final useCase = PerformanceMonitoring(
            metricsCollector: metricsCollector,
            monitorRepository: monitorRepository,
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
            logger: Builder(LoggerFactory()).buildWith(seed: 1),
          );

          await useCase.execute();

          expect(persistCallCount, equals(1));
          expect(persistedMonitor, isNotNull);

          final events = persistedMonitor!.events();
          expect(events.length, equals(1));
          expect(
            events.first,
            isA<performance_domain.PerformanceBudgetExceeded>(),
          );

          final budgetExceeded =
              events.first as performance_domain.PerformanceBudgetExceeded;
          expect(
            budgetExceeded.metric,
            equals(performance_domain.PerformanceMetricType.cpu),
          );
          expect(budgetExceeded.value, equals(80.0));
          expect(budgetExceeded.threshold, equals(50.0));
        },
      );

      test(
        'fires PerformanceBudgetExceeded event when memory exceeds threshold.',
        () async {
          final monitor =
              Builder(
                performance_factory.PerformanceMonitorFactory(),
              ).buildWith(
                seed: 1,
                overrides: (
                  identifier: null,
                  currentSnapshot: null,
                  thresholds:
                      Builder(
                        performance_factory.PerformanceThresholdsFactory(),
                      ).buildWith(
                        seed: 1,
                        overrides: (
                          cpu: 80.0,
                          memory: 500.0,
                          character: FramesPerSecond(value: 30),
                          background: FramesPerSecond(value: 24),
                        ),
                      ),
                ),
              );

          monitor.events();

          var persistCallCount = 0;
          performance_domain.PerformanceMonitor? persistedMonitor;

          final monitorRepository =
              Builder(
                performance_factory.PerformanceMonitorRepositoryFactory(),
              ).buildWith(
                seed: 1,
                overrides: (
                  current: monitor,
                  onPersist: (m) {
                    persistCallCount++;
                    persistedMonitor = m;
                  },
                ),
              );

          final collectedSnapshot = performance_domain.PerformanceSnapshot(
            averageCPU: 50.0,
            averageMemory: 1000.0,
            characterFPS: FramesPerSecond(value: 60),
            backgroundFPS: FramesPerSecond(value: 30),
            capturedAt: DateTime.now(),
          );

          final metricsCollector = Builder(
            performance_factory.PerformanceMetricsCollectorFactory(),
          ).buildWith(seed: 1, overrides: (onCollect: () => collectedSnapshot));

          final useCase = PerformanceMonitoring(
            metricsCollector: metricsCollector,
            monitorRepository: monitorRepository,
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
            logger: Builder(LoggerFactory()).buildWith(seed: 1),
          );

          await useCase.execute();

          expect(persistCallCount, equals(1));
          expect(persistedMonitor, isNotNull);

          final events = persistedMonitor!.events();
          expect(events.length, equals(1));
          expect(
            events.first,
            isA<performance_domain.PerformanceBudgetExceeded>(),
          );

          final budgetExceeded =
              events.first as performance_domain.PerformanceBudgetExceeded;
          expect(
            budgetExceeded.metric,
            equals(performance_domain.PerformanceMetricType.memory),
          );
          expect(budgetExceeded.value, equals(1000.0));
          expect(budgetExceeded.threshold, equals(500.0));
        },
      );

      test('handles metrics collection failure gracefully.', () async {
        final monitor = Builder(
          performance_factory.PerformanceMonitorFactory(),
        ).buildWith(seed: 1);

        final monitorRepository = Builder(
          performance_factory.PerformanceMonitorRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (current: monitor, onPersist: null));

        final metricsCollector =
            Builder(
              performance_factory.PerformanceMetricsCollectorFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                onCollect: () => throw Exception('Collection failed'),
              ),
            );

        final useCase = PerformanceMonitoring(
          metricsCollector: metricsCollector,
          monitorRepository: monitorRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        await useCase.execute();
      });
    });
  });
}
