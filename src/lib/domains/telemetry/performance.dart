import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:ulid/ulid.dart';

class PerformanceMonitorIdentifier extends ULIDBasedIdentifier {
  PerformanceMonitorIdentifier({required Ulid value}) : super(value);

  factory PerformanceMonitorIdentifier.generate() =>
      PerformanceMonitorIdentifier(value: Ulid());

  factory PerformanceMonitorIdentifier.fromString(String value) =>
      PerformanceMonitorIdentifier(value: Ulid.parse(value));

  factory PerformanceMonitorIdentifier.fromBinary(Uint8List bytes) =>
      PerformanceMonitorIdentifier(value: Ulid.fromBytes(bytes));
}

class PerformanceSnapshot implements ValueObject {
  final double averageCPU;
  final double averageMemory;
  final FramesPerSecond characterFPS;
  final FramesPerSecond backgroundFPS;
  final DateTime capturedAt;

  PerformanceSnapshot({
    required this.averageCPU,
    required this.averageMemory,
    required this.characterFPS,
    required this.backgroundFPS,
    required this.capturedAt,
  }) {
    Invariant.range(
      value: averageCPU,
      name: 'averageCPU',
      min: 0.0,
      max: 100.0,
    );
    Invariant.range(value: averageMemory, name: 'averageMemory', min: 0.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PerformanceSnapshot) {
      return false;
    }

    if (averageCPU != other.averageCPU) {
      return false;
    }

    if (averageMemory != other.averageMemory) {
      return false;
    }

    if (characterFPS != other.characterFPS) {
      return false;
    }

    if (backgroundFPS != other.backgroundFPS) {
      return false;
    }

    if (capturedAt != other.capturedAt) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    averageCPU,
    averageMemory,
    characterFPS,
    backgroundFPS,
    capturedAt,
    runtimeType,
  );
}

class PerformanceThresholds implements ValueObject {
  final double cpu;
  final double memory;
  final FramesPerSecond character;
  final FramesPerSecond background;

  PerformanceThresholds({
    required this.cpu,
    required this.memory,
    required this.character,
    required this.background,
  }) {
    Invariant.range(value: cpu, name: 'cpu', min: 0.0, max: 100.0);
    Invariant.range(value: memory, name: 'memory', min: 0.0);
  }

  factory PerformanceThresholds.defaultThresholds() => PerformanceThresholds(
    cpu: 12.0,
    memory: 400.0,
    character: FramesPerSecond(value: 30),
    background: FramesPerSecond(value: 24),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PerformanceThresholds) {
      return false;
    }

    if (cpu != other.cpu) {
      return false;
    }

    if (memory != other.memory) {
      return false;
    }

    if (character != other.character) {
      return false;
    }

    if (background != other.background) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(cpu, memory, character, background);
}

enum PerformanceMetricType { cpu, memory, characterFPS, backgroundFPS }

class PerformanceEvent extends BaseEvent {
  PerformanceEvent({required DateTime occurredAt}) : super(occurredAt);
}

class PerformanceBudgetExceeded extends PerformanceEvent {
  final PerformanceMonitorIdentifier monitor;
  final PerformanceMetricType metric;
  final num value;
  final num threshold;
  final PerformanceSnapshot snapshot;

  PerformanceBudgetExceeded({
    required super.occurredAt,
    required this.monitor,
    required this.metric,
    required this.value,
    required this.threshold,
    required this.snapshot,
  });
}

class PerformanceThresholdsUpdated extends PerformanceEvent {
  final PerformanceMonitorIdentifier monitor;
  final PerformanceThresholds thresholds;

  PerformanceThresholdsUpdated({
    required super.occurredAt,
    required this.monitor,
    required this.thresholds,
  });
}

class PerformanceMonitor with Publishable<PerformanceEvent> {
  final PerformanceMonitorIdentifier identifier;
  PerformanceSnapshot? _currentSnapshot;
  PerformanceThresholds thresholds;

  PerformanceMonitor({
    required this.identifier,
    PerformanceSnapshot? currentSnapshot,
    required this.thresholds,
  }) : _currentSnapshot = currentSnapshot;

  PerformanceSnapshot? get currentSnapshot => _currentSnapshot;

  PerformanceThresholds get currentThresholds => thresholds;

  void recordSnapshot(PerformanceSnapshot snapshot) {
    _currentSnapshot = snapshot;

    if (_currentSnapshot!.averageCPU > thresholds.cpu) {
      publish(
        PerformanceBudgetExceeded(
          occurredAt: DateTime.now(),
          monitor: identifier,
          metric: PerformanceMetricType.cpu,
          value: _currentSnapshot!.averageCPU,
          threshold: thresholds.cpu,
          snapshot: _currentSnapshot!,
        ),
      );
    }

    if (_currentSnapshot!.averageMemory > thresholds.memory) {
      publish(
        PerformanceBudgetExceeded(
          occurredAt: DateTime.now(),
          monitor: identifier,
          metric: PerformanceMetricType.memory,
          value: _currentSnapshot!.averageMemory,
          threshold: thresholds.memory,
          snapshot: _currentSnapshot!,
        ),
      );
    }

    if (_currentSnapshot!.characterFPS.value < thresholds.character.value) {
      publish(
        PerformanceBudgetExceeded(
          occurredAt: DateTime.now(),
          monitor: identifier,
          metric: PerformanceMetricType.characterFPS,
          value: _currentSnapshot!.characterFPS.value,
          threshold: thresholds.character.value,
          snapshot: _currentSnapshot!,
        ),
      );
    }

    if (_currentSnapshot!.backgroundFPS.value < thresholds.background.value) {
      publish(
        PerformanceBudgetExceeded(
          occurredAt: DateTime.now(),
          monitor: identifier,
          metric: PerformanceMetricType.backgroundFPS,
          value: _currentSnapshot!.backgroundFPS.value,
          threshold: thresholds.background.value,
          snapshot: _currentSnapshot!,
        ),
      );
    }
  }

  void updateThresholds(PerformanceThresholds next) {
    thresholds = next;

    publish(
      PerformanceThresholdsUpdated(
        occurredAt: DateTime.now(),
        monitor: identifier,
        thresholds: thresholds,
      ),
    );
  }
}

abstract interface class PerformanceMetricsCollector {
  Future<PerformanceSnapshot> collect();
}

abstract interface class PerformanceMonitorRepository {
  Future<PerformanceMonitor> current();
  Future<void> persist(PerformanceMonitor monitor);
}
