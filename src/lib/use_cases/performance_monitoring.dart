import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/telemetry/performance.dart'
    as performance_domain;
import 'package:logger/logger.dart';

class PerformanceMonitoring {
  final performance_domain.PerformanceMetricsCollector _metricsCollector;
  final performance_domain.PerformanceMonitorRepository _monitorRepository;
  final Transaction _transaction;
  final Logger _logger;

  PerformanceMonitoring({
    required performance_domain.PerformanceMetricsCollector metricsCollector,
    required performance_domain.PerformanceMonitorRepository monitorRepository,
    required Transaction transaction,
    required Logger logger,
  }) : _metricsCollector = metricsCollector,
       _monitorRepository = monitorRepository,
       _transaction = transaction,
       _logger = logger;

  Future<void> execute() async {
    try {
      final snapshot = await _metricsCollector.collect();

      await _transaction.execute(() async {
        final monitor = await _monitorRepository.current();

        monitor.recordSnapshot(snapshot);

        await _monitorRepository.persist(monitor);

        _logger.d(
          'Performance snapshot recorded: CPU=${snapshot.averageCPU}%, Memory=${snapshot.averageMemory}MB',
        );
      });
    } catch (error) {
      _logger.e('Failed to collect performance metrics: $error');
    }
  }
}
