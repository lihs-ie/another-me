import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/telemetry/performance.dart';
import 'package:ulid/ulid.dart';

import '../common.dart';
import '../common/date.dart';
import '../common/frame_rate.dart';
import '../common/identifier.dart';
import '../enum.dart';

class PerformanceMonitorIdentifierFactory
    extends ULIDBasedIdentifierFactory<PerformanceMonitorIdentifier> {
  PerformanceMonitorIdentifierFactory()
    : super((Ulid value) => PerformanceMonitorIdentifier(value: value));
}

typedef PerformanceSnapshotOverrides = ({
  double? averageCPU,
  double? averageMemory,
  FramesPerSecond? characterFPS,
  FramesPerSecond? backgroundFPS,
  DateTime? capturedAt,
});

class PerformanceSnapshotFactory
    extends Factory<PerformanceSnapshot, PerformanceSnapshotOverrides> {
  @override
  PerformanceSnapshot create({
    PerformanceSnapshotOverrides? overrides,
    required int seed,
  }) {
    final averageCPU = overrides?.averageCPU ?? ((seed % 101) / 1.0);

    final averageMemory = overrides?.averageMemory ?? ((seed % 1000) / 1.0);

    final characterFPS =
        overrides?.characterFPS ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    final backgroundFPS =
        overrides?.backgroundFPS ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    final capturedAt =
        overrides?.capturedAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return PerformanceSnapshot(
      averageCPU: averageCPU,
      averageMemory: averageMemory,
      characterFPS: characterFPS,
      backgroundFPS: backgroundFPS,
      capturedAt: capturedAt,
    );
  }

  @override
  PerformanceSnapshot duplicate(
    PerformanceSnapshot instance,
    PerformanceSnapshotOverrides? overrides,
  ) {
    final averageCPU = overrides?.averageCPU ?? instance.averageCPU;

    final averageMemory = overrides?.averageMemory ?? instance.averageMemory;

    final characterFPS =
        overrides?.characterFPS ??
        Builder(
          FramesPerSecondFactory(),
        ).duplicate(instance: instance.characterFPS, overrides: null);

    final backgroundFPS =
        overrides?.backgroundFPS ??
        Builder(
          FramesPerSecondFactory(),
        ).duplicate(instance: instance.backgroundFPS, overrides: null);

    final capturedAt =
        overrides?.capturedAt ??
        Builder(
          DateTimeFactory(),
        ).duplicate(instance: instance.capturedAt, overrides: null);

    return PerformanceSnapshot(
      averageCPU: averageCPU,
      averageMemory: averageMemory,
      characterFPS: characterFPS,
      backgroundFPS: backgroundFPS,
      capturedAt: capturedAt,
    );
  }
}

typedef PerformanceThresholdsOverrides = ({
  double? cpu,
  double? memory,
  FramesPerSecond? character,
  FramesPerSecond? background,
});

class PerformanceThresholdsFactory
    extends Factory<PerformanceThresholds, PerformanceThresholdsOverrides> {
  @override
  PerformanceThresholds create({
    PerformanceThresholdsOverrides? overrides,
    required int seed,
  }) {
    final cpu = overrides?.cpu ?? ((seed % 100) + 1) / 1.0;

    final memory = overrides?.memory ?? ((seed % 1000) + 1) / 1.0;

    final character =
        overrides?.character ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    final background =
        overrides?.background ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    return PerformanceThresholds(
      cpu: cpu,
      memory: memory,
      character: character,
      background: background,
    );
  }

  @override
  PerformanceThresholds duplicate(
    PerformanceThresholds instance,
    PerformanceThresholdsOverrides? overrides,
  ) {
    final cpu = overrides?.cpu ?? instance.cpu;

    final memory = overrides?.memory ?? instance.memory;

    final character =
        overrides?.character ??
        Builder(
          FramesPerSecondFactory(),
        ).duplicate(instance: instance.character, overrides: null);

    final background =
        overrides?.background ??
        Builder(
          FramesPerSecondFactory(),
        ).duplicate(instance: instance.background, overrides: null);

    return PerformanceThresholds(
      cpu: cpu,
      memory: memory,
      character: character,
      background: background,
    );
  }
}

class PerformanceMetricTypeFactory extends EnumFactory<PerformanceMetricType> {
  PerformanceMetricTypeFactory() : super(PerformanceMetricType.values);
}

typedef PerformanceMonitorOverrides = ({
  PerformanceMonitorIdentifier? identifier,
  PerformanceSnapshot? currentSnapshot,
  PerformanceThresholds? thresholds,
});

class PerformanceMonitorFactory
    extends Factory<PerformanceMonitor, PerformanceMonitorOverrides> {
  @override
  PerformanceMonitor create({
    PerformanceMonitorOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(PerformanceMonitorIdentifierFactory()).buildWith(seed: seed);

    final currentSnapshot =
        overrides?.currentSnapshot ??
        (seed % 2 == 0
            ? Builder(PerformanceSnapshotFactory()).buildWith(seed: seed)
            : null);

    final thresholds =
        overrides?.thresholds ??
        Builder(PerformanceThresholdsFactory()).buildWith(seed: seed);

    return PerformanceMonitor(
      identifier: identifier,
      currentSnapshot: currentSnapshot,
      thresholds: thresholds,
    );
  }

  @override
  PerformanceMonitor duplicate(
    PerformanceMonitor instance,
    PerformanceMonitorOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          PerformanceMonitorIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);

    final currentSnapshot =
        overrides?.currentSnapshot ??
        (instance.currentSnapshot != null
            ? Builder(
                PerformanceSnapshotFactory(),
              ).duplicate(instance: instance.currentSnapshot!, overrides: null)
            : null);

    final thresholds =
        overrides?.thresholds ??
        Builder(
          PerformanceThresholdsFactory(),
        ).duplicate(instance: instance.thresholds, overrides: null);

    return PerformanceMonitor(
      identifier: identifier,
      currentSnapshot: currentSnapshot,
      thresholds: thresholds,
    );
  }
}

class _PerformanceMonitorRepository implements PerformanceMonitorRepository {
  PerformanceMonitor _current;
  final void Function(PerformanceMonitor)? _onPersist;

  _PerformanceMonitorRepository({
    required PerformanceMonitor current,
    void Function(PerformanceMonitor)? onPersist,
  }) : _current = current,
       _onPersist = onPersist;

  @override
  Future<PerformanceMonitor> current() {
    return Future.value(_current);
  }

  @override
  Future<void> persist(PerformanceMonitor monitor) {
    _current = monitor;

    _onPersist?.call(monitor);

    return Future.value();
  }
}

typedef PerformanceMonitorRepositoryOverrides = ({
  PerformanceMonitor? current,
  void Function(PerformanceMonitor)? onPersist,
});

class PerformanceMonitorRepositoryFactory
    extends
        Factory<
          PerformanceMonitorRepository,
          PerformanceMonitorRepositoryOverrides
        > {
  @override
  PerformanceMonitorRepository create({
    PerformanceMonitorRepositoryOverrides? overrides,
    required int seed,
  }) {
    final current =
        overrides?.current ??
        Builder(PerformanceMonitorFactory()).buildWith(seed: seed);

    return _PerformanceMonitorRepository(
      current: current,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  PerformanceMonitorRepository duplicate(
    PerformanceMonitorRepository instance,
    PerformanceMonitorRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

class _PerformanceMetricsCollector implements PerformanceMetricsCollector {
  final PerformanceSnapshot Function()? _onCollect;

  _PerformanceMetricsCollector({PerformanceSnapshot Function()? onCollect})
    : _onCollect = onCollect;

  @override
  Future<PerformanceSnapshot> collect() {
    if (_onCollect != null) {
      return Future.value(_onCollect());
    }

    return Future.value(
      PerformanceSnapshot(
        averageCPU: 10.0,
        averageMemory: 200.0,
        characterFPS: FramesPerSecond(value: 60),
        backgroundFPS: FramesPerSecond(value: 30),
        capturedAt: DateTime.now(),
      ),
    );
  }
}

typedef PerformanceMetricsCollectorOverrides = ({
  PerformanceSnapshot Function()? onCollect,
});

class PerformanceMetricsCollectorFactory
    extends
        Factory<
          PerformanceMetricsCollector,
          PerformanceMetricsCollectorOverrides
        > {
  @override
  PerformanceMetricsCollector create({
    PerformanceMetricsCollectorOverrides? overrides,
    required int seed,
  }) {
    return _PerformanceMetricsCollector(onCollect: overrides?.onCollect);
  }

  @override
  PerformanceMetricsCollector duplicate(
    PerformanceMetricsCollector instance,
    PerformanceMetricsCollectorOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
