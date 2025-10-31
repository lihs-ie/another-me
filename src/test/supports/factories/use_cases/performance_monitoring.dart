import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/telemetry/performance.dart';
import 'package:another_me/use_cases/performance_monitoring.dart' as use_case;
import 'package:logger/logger.dart';

import '../common.dart';
import '../common/transaction.dart' as transaction_factory;
import '../logger.dart';
import '../telemetry/performance.dart' as performance_factory;

typedef PerformanceMonitoringOverrides = ({
  PerformanceMetricsCollector? metricsCollector,
  PerformanceMonitorRepository? monitorRepository,
  Transaction? transaction,
  Logger? logger,
});

class PerformanceMonitoringFactory
    extends
        Factory<
          use_case.PerformanceMonitoring,
          PerformanceMonitoringOverrides
        > {
  @override
  use_case.PerformanceMonitoring create({
    PerformanceMonitoringOverrides? overrides,
    required int seed,
  }) {
    final metricsCollector =
        overrides?.metricsCollector ??
        Builder(
          performance_factory.PerformanceMetricsCollectorFactory(),
        ).buildWith(seed: seed);

    final monitorRepository =
        overrides?.monitorRepository ??
        Builder(
          performance_factory.PerformanceMonitorRepositoryFactory(),
        ).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(transaction_factory.TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return use_case.PerformanceMonitoring(
      metricsCollector: metricsCollector,
      monitorRepository: monitorRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  use_case.PerformanceMonitoring duplicate(
    use_case.PerformanceMonitoring instance,
    PerformanceMonitoringOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
