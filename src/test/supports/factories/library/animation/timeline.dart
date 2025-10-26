import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/library/animation/timeline.dart';

import '../../common.dart';
import '../../common/error.dart';
import '../../common/frame_rate.dart';
import '../../common/identifier.dart';
import '../../enum.dart';
import '../../string.dart';

class TimelineIdentifierFactory
    extends ULIDBasedIdentifierFactory<TimelineIdentifier> {
  TimelineIdentifierFactory()
    : super((value) => TimelineIdentifier(value: value));
}

class TimelineLoopModeFactory extends EnumFactory<TimelineLoopMode> {
  TimelineLoopModeFactory() : super(TimelineLoopMode.values);
}

typedef TimelineDefinitionOverrides = ({
  TimelineIdentifier? identifier,
  String? name,
  FramesPerSecond? fps,
  int? frameCount,
  TimelineLoopMode? loopMode,
  String? defaultNext,
});

class TimelineDefinitionFactory
    extends Factory<TimelineDefinition, TimelineDefinitionOverrides> {
  @override
  TimelineDefinition create({
    TimelineDefinitionOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(TimelineIdentifierFactory()).buildWith(seed: seed);

    final name = overrides?.name ?? StringFactory.create(seed: seed);

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    final frameCount = overrides?.frameCount ?? (fps.value * ((seed % 10) + 1));

    final loopMode =
        overrides?.loopMode ??
        Builder(TimelineLoopModeFactory()).buildWith(seed: seed);

    String? defaultNext = overrides?.defaultNext;

    if (loopMode == TimelineLoopMode.single && defaultNext == null) {
      defaultNext = StringFactory.createFromPattern(
        pattern: r'^[a-z_][a-z0-9_]*$',
        minimumLength: 1,
        maximumLength: 100,
        seed: seed + 1,
      );
    }

    return TimelineDefinition(
      identifier: identifier,
      name: name,
      fps: fps,
      frameCount: frameCount,
      loopMode: loopMode,
      defaultNext: defaultNext,
    );
  }

  @override
  TimelineDefinition duplicate(
    TimelineDefinition instance,
    TimelineDefinitionOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          TimelineIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final name = overrides?.name ?? instance.name;

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).duplicate(instance: instance.fps);

    final frameCount = overrides?.frameCount ?? instance.frameCount;

    final loopMode =
        overrides?.loopMode ??
        Builder(
          TimelineLoopModeFactory(),
        ).duplicate(instance: instance.loopMode);

    final defaultNext = overrides?.defaultNext ?? instance.defaultNext;

    return TimelineDefinition(
      identifier: identifier,
      name: name,
      fps: fps,
      frameCount: frameCount,
      loopMode: loopMode,
      defaultNext: defaultNext,
    );
  }
}

typedef TimelineDefinitionRegisteredOverrides = ({
  DateTime? occurredAt,
  TimelineIdentifier? timeline,
  FramesPerSecond? fps,
  int? frameCount,
});

class TimelineDefinitionRegisteredFactory
    extends
        Factory<
          TimelineDefinitionRegistered,
          TimelineDefinitionRegisteredOverrides
        > {
  @override
  TimelineDefinitionRegistered create({
    TimelineDefinitionRegisteredOverrides? overrides,
    required int seed,
  }) {
    final occurredAt = overrides?.occurredAt ?? DateTime.now();

    final timeline =
        overrides?.timeline ??
        Builder(TimelineIdentifierFactory()).buildWith(seed: seed);

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    final frameCount = overrides?.frameCount ?? (fps.value * ((seed % 10) + 1));

    return TimelineDefinitionRegistered(
      occurredAt: occurredAt,
      timeline: timeline,
      fps: fps,
      frameCount: frameCount,
    );
  }

  @override
  TimelineDefinitionRegistered duplicate(
    TimelineDefinitionRegistered instance,
    TimelineDefinitionRegisteredOverrides? overrides,
  ) {
    final occurredAt = overrides?.occurredAt ?? instance.occurredAt;

    final timeline =
        overrides?.timeline ??
        Builder(
          TimelineIdentifierFactory(),
        ).duplicate(instance: instance.timeline);

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).duplicate(instance: instance.fps);

    final frameCount = overrides?.frameCount ?? instance.frameCount;

    return TimelineDefinitionRegistered(
      occurredAt: occurredAt,
      timeline: timeline,
      fps: fps,
      frameCount: frameCount,
    );
  }
}

class _TimelineDefinitionRepository implements TimelineDefinitionRepository {
  final Map<TimelineIdentifier, TimelineDefinition> _instances;
  final void Function(TimelineDefinition instance)? _onPersist;
  final Map<TimelineIdentifier, int> _versions = {};

  _TimelineDefinitionRepository({
    required List<TimelineDefinition> instances,
    void Function(TimelineDefinition instance)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<TimelineDefinition> find(TimelineIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError('TimelineDefinition not found: $identifier');
    }

    return Future.value(instance);
  }

  @override
  Future<void> persist(TimelineDefinition definition) {
    final currentVersion = _versions[definition.identifier] ?? 0;

    _versions[definition.identifier] = currentVersion + 1;

    _onPersist?.call(definition);

    return Future.value();
  }
}

typedef TimelineDefinitionRepositoryOverrides = ({
  List<TimelineDefinition>? instances,
  void Function(TimelineDefinition instance)? onPersist,
});

class TimelineDefinitionRepositoryFactory
    extends
        Factory<
          TimelineDefinitionRepository,
          TimelineDefinitionRepositoryOverrides
        > {
  @override
  TimelineDefinitionRepository create({
    TimelineDefinitionRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(TimelineDefinitionFactory()).buildList(count: (seed % 5) + 1);
    final onPersist = overrides?.onPersist;

    return _TimelineDefinitionRepository(
      instances: instances,
      onPersist: onPersist,
    );
  }

  @override
  TimelineDefinitionRepository duplicate(
    TimelineDefinitionRepository instance,
    TimelineDefinitionRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
