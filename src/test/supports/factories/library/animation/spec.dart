import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/library/animation/common.dart';
import 'package:another_me/domains/library/animation/spec.dart';
import 'package:another_me/domains/library/asset.dart';

import '../../common.dart';
import '../../common/frame_rate.dart';
import '../../string.dart';
import '../asset.dart';
import 'common.dart';

class AnimationSpecIdentifierFactory
    extends Factory<AnimationSpecIdentifier, ({String? name})> {
  @override
  AnimationSpecIdentifier create({
    ({String? name})? overrides,
    required int seed,
  }) {
    final name =
        overrides?.name ??
        StringFactory.createFromPattern(
          pattern: r'^[a-z_][a-z0-9_]*$',
          minimumLength: 1,
          maximumLength: 100,
          seed: seed,
        );

    return AnimationSpecIdentifier(name: name);
  }

  @override
  AnimationSpecIdentifier duplicate(
    AnimationSpecIdentifier instance,
    ({String? name})? overrides,
  ) {
    final name = overrides?.name ?? instance.name;

    return AnimationSpecIdentifier(name: name);
  }
}

typedef AnimationSpecOverrides = ({
  AnimationSpecIdentifier? identifier,
  FramesPerSecond? fps,
  int? frames,
  String? next,
  Pivot? pivot,
  List<Hitbox>? hitboxes,
  int? safetyMargin,
});

class AnimationSpecFactory
    extends Factory<AnimationSpec, AnimationSpecOverrides> {
  @override
  AnimationSpec create({AnimationSpecOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(AnimationSpecIdentifierFactory()).buildWith(seed: seed);

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    final frames = overrides?.frames ?? (fps.value * ((seed % 10) + 1));

    final next =
        overrides?.next ??
        StringFactory.createFromPattern(
          pattern: r'^[a-z_][a-z0-9_]*$',
          minimumLength: 1,
          maximumLength: 100,
          seed: seed + 1,
        );

    final pivot =
        overrides?.pivot ?? Builder(PivotFactory()).buildWith(seed: seed);

    final hitboxes =
        overrides?.hitboxes ??
        Builder(HitboxFactory()).buildListWith(count: (seed % 5), seed: seed);

    final safetyMargin = overrides?.safetyMargin ?? ((seed % 100) + 8);

    return AnimationSpec(
      identifier: identifier,
      fps: fps,
      frames: frames,
      next: next,
      pivot: pivot,
      hitboxes: hitboxes,
      safetyMargin: safetyMargin,
    );
  }

  @override
  AnimationSpec duplicate(
    AnimationSpec instance,
    AnimationSpecOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          AnimationSpecIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).duplicate(instance: instance.fps);

    final frames = overrides?.frames ?? instance.frames;
    final next = overrides?.next ?? instance.next;

    final pivot =
        overrides?.pivot ??
        Builder(PivotFactory()).duplicate(instance: instance.pivot);

    final hitboxes =
        overrides?.hitboxes ??
        instance.hitboxes
            .map(
              (hitbox) => Builder(HitboxFactory()).duplicate(instance: hitbox),
            )
            .toList();

    final safetyMargin = overrides?.safetyMargin ?? instance.safetyMargin;

    return AnimationSpec(
      identifier: identifier,
      fps: fps,
      frames: frames,
      next: next,
      pivot: pivot,
      hitboxes: hitboxes,
      safetyMargin: safetyMargin,
    );
  }
}

typedef AnimationSpecRegisteredOverrides = ({
  DateTime? occurredAt,
  AnimationSpecIdentifier? animationSpec,
  FramesPerSecond? fps,
  int? frames,
});

class AnimationSpecRegisteredFactory
    extends Factory<AnimationSpecRegistered, AnimationSpecRegisteredOverrides> {
  @override
  AnimationSpecRegistered create({
    AnimationSpecRegisteredOverrides? overrides,
    required int seed,
  }) {
    final occurredAt = overrides?.occurredAt ?? DateTime.now();

    final animationSpec =
        overrides?.animationSpec ??
        Builder(AnimationSpecIdentifierFactory()).buildWith(seed: seed);

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).buildWith(seed: seed);

    final frames = overrides?.frames ?? (fps.value * ((seed % 10) + 1));

    return AnimationSpecRegistered(
      occurredAt: occurredAt,
      animationSpec: animationSpec,
      fps: fps,
      frames: frames,
    );
  }

  @override
  AnimationSpecRegistered duplicate(
    AnimationSpecRegistered instance,
    AnimationSpecRegisteredOverrides? overrides,
  ) {
    final occurredAt = overrides?.occurredAt ?? instance.occurredAt;

    final animationSpec =
        overrides?.animationSpec ??
        Builder(
          AnimationSpecIdentifierFactory(),
        ).duplicate(instance: instance.animationSpec);

    final fps =
        overrides?.fps ??
        Builder(FramesPerSecondFactory()).duplicate(instance: instance.fps);

    final frames = overrides?.frames ?? instance.frames;

    return AnimationSpecRegistered(
      occurredAt: occurredAt,
      animationSpec: animationSpec,
      fps: fps,
      frames: frames,
    );
  }
}

typedef AnimationSpecDeprecatedOverrides = ({
  DateTime? occurredAt,
  AnimationSpecIdentifier? animationSpec,
  String? reason,
});

class AnimationSpecDeprecatedFactory
    extends Factory<AnimationSpecDeprecated, AnimationSpecDeprecatedOverrides> {
  @override
  AnimationSpecDeprecated create({
    AnimationSpecDeprecatedOverrides? overrides,
    required int seed,
  }) {
    final occurredAt = overrides?.occurredAt ?? DateTime.now();

    final animationSpec =
        overrides?.animationSpec ??
        Builder(AnimationSpecIdentifierFactory()).buildWith(seed: seed);

    final reason = overrides?.reason ?? StringFactory.create(seed: seed);

    return AnimationSpecDeprecated(
      occurredAt: occurredAt,
      animationSpec: animationSpec,
      reason: reason,
    );
  }

  @override
  AnimationSpecDeprecated duplicate(
    AnimationSpecDeprecated instance,
    AnimationSpecDeprecatedOverrides? overrides,
  ) {
    final occurredAt = overrides?.occurredAt ?? instance.occurredAt;

    final animationSpec =
        overrides?.animationSpec ??
        Builder(
          AnimationSpecIdentifierFactory(),
        ).duplicate(instance: instance.animationSpec);

    final reason = overrides?.reason ?? instance.reason;

    return AnimationSpecDeprecated(
      occurredAt: occurredAt,
      animationSpec: animationSpec,
      reason: reason,
    );
  }
}

class _AssetValidator implements AssetValidator {
  FramesPerSecond _extractFps(AssetPackage package) {
    final jsonFile = package.resources.firstWhere(
      (resource) => resource.path.value.endsWith('.json'),
      orElse: () => throw StateError('JSON file not found'),
    );

    final fpsValue = (jsonFile.path.value.hashCode % 120) + 1;
    return FramesPerSecond(value: fpsValue);
  }

  int _extractFrameCount(AssetPackage package) {
    final jsonFile = package.resources.firstWhere(
      (resource) => resource.path.value.endsWith('.json'),
      orElse: () => throw StateError('JSON file not found'),
    );

    return (jsonFile.path.value.hashCode % 200) + 1;
  }

  Pivot _extractPivot(AssetPackage package) {
    final jsonFile = package.resources.firstWhere(
      (resource) => resource.path.value.endsWith('.json'),
      orElse: () => throw StateError('JSON file not found'),
    );

    final hash = jsonFile.path.value.hashCode;
    final gridSizeValue = [8, 16, 32][hash.abs() % 3];
    final gridSize = GridSize(value: gridSizeValue);
    final x = (hash.abs() % 10) * gridSizeValue;
    final y = ((hash.abs() ~/ 10) % 10) * gridSizeValue;

    return Pivot(x: x, y: y, gridSize: gridSize);
  }

  int _extractSafetyMargin(AssetPackage package) {
    final pngFile = package.resources.firstWhere(
      (resource) => resource.path.value.endsWith('.png'),
      orElse: () => throw StateError('PNG file not found'),
    );

    return (pngFile.path.value.hashCode.abs() % 100) + 8;
  }

  @override
  Future<ValidationResult> validate(
    AssetPackage package,
    AnimationSpec spec,
  ) async {
    try {
      if (package.animationSpecVersion != spec.identifier.name) {
        return ValidationResult.invalid(
          'animationSpecVersion mismatch: expected="${spec.identifier.name}", actual="${package.animationSpecVersion}"',
        );
      }

      final pngResources = package.resources.where(
        (resource) => resource.path.value.endsWith('.png'),
      );

      if (pngResources.isEmpty) {
        return const ValidationResult.invalid('PNG file not found');
      }

      final jsonResources = package.resources.where(
        (resource) => resource.path.value.endsWith('.json'),
      );

      if (jsonResources.isEmpty) {
        return const ValidationResult.invalid('JSON file not found');
      }

      final packageFps = _extractFps(package);
      if (packageFps.value != spec.fps.value) {
        return ValidationResult.invalid(
          'FPS mismatch: expected=${spec.fps.value}, actual=${packageFps.value}',
        );
      }

      final packageFrames = _extractFrameCount(package);
      if (packageFrames != spec.frames) {
        return ValidationResult.invalid(
          'Frame count mismatch: expected=${spec.frames}, actual=$packageFrames',
        );
      }

      final packagePivot = _extractPivot(package);
      if (packagePivot != spec.pivot) {
        return ValidationResult.invalid(
          'Pivot mismatch: expected=(${spec.pivot.x}, ${spec.pivot.y}), actual=(${packagePivot.x}, ${packagePivot.y})',
        );
      }

      final packageMargin = _extractSafetyMargin(package);
      if (packageMargin < spec.safetyMargin) {
        return ValidationResult.invalid(
          'Safety margin insufficient: expected=${spec.safetyMargin}px or more, actual=${packageMargin}px',
        );
      }

      return const ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Validation error: $e');
    }
  }

  @override
  Future<ValidationResult> validateAll(
    List<AssetPackage> packages,
    AnimationSpec spec,
  ) async {
    if (packages.isEmpty) {
      return const ValidationResult.invalid('No packages to validate');
    }

    for (final package in packages) {
      final result = await validate(package, spec);

      if (!result.isValid) {
        return result;
      }
    }

    return const ValidationResult.valid();
  }
}

class AssetValidatorFactory extends Factory<AssetValidator, void> {
  @override
  AssetValidator create({void overrides, required int seed}) {
    return _AssetValidator();
  }

  @override
  AssetValidator duplicate(AssetValidator instance, void overrides) {
    throw UnimplementedError();
  }
}

typedef AnimationSpecRepositoryOverrides = ({
  List<AnimationSpec>? instances,
  void Function(AnimationSpec instance)? onPersist,
});

class _AnimationSpecRepository implements AnimationSpecRepository {
  final Map<AnimationSpecIdentifier, AnimationSpec> _instances;
  final void Function(AnimationSpec instance)? _onPersist;
  final Map<AnimationSpecIdentifier, int> _versions = {};

  _AnimationSpecRepository({
    required List<AnimationSpec> instances,
    void Function(AnimationSpec instance)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<AnimationSpec> find(AnimationSpecIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError('AnimationSpec not found: $identifier');
    }

    return Future.value(instance);
  }

  @override
  Future<List<AnimationSpec>> all() {
    return Future.value(_instances.values.toList());
  }

  @override
  Future<void> persist(AnimationSpec spec) async {
    final currentVersion = _versions[spec.identifier] ?? 0;

    _versions[spec.identifier] = currentVersion + 1;
    _instances[spec.identifier] = spec;

    _onPersist?.call(spec);
  }
}

class AnimationSpecRepositoryFactory
    extends Factory<AnimationSpecRepository, AnimationSpecRepositoryOverrides> {
  @override
  AnimationSpecRepository create({
    AnimationSpecRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(AnimationSpecFactory()).buildList(count: (seed % 5) + 1);

    final onPersist = overrides?.onPersist;

    return _AnimationSpecRepository(instances: instances, onPersist: onPersist);
  }

  @override
  AnimationSpecRepository duplicate(
    AnimationSpecRepository instance,
    AnimationSpecRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef SpeckComplianceSubscriberOverrides = ({
  AnimationSpecRepository? animationSpecRepository,
  AssetCatalogRepository? assetCatalogRepository,
  AssetValidator? assetValidator,
});

class SpecComplianceSubscriberFactory
    extends
        Factory<SpecComplianceSubscriber, SpeckComplianceSubscriberOverrides> {
  @override
  SpecComplianceSubscriber create({
    SpeckComplianceSubscriberOverrides? overrides,
    required int seed,
  }) {
    final animationSpecRepository =
        overrides?.animationSpecRepository ??
        Builder(AnimationSpecRepositoryFactory()).buildWith(seed: seed);

    final assetCatalogRepository =
        overrides?.assetCatalogRepository ??
        Builder(AssetCatalogRepositoryFactory()).buildWith(seed: seed);

    final assetValidator =
        overrides?.assetValidator ??
        Builder(AssetValidatorFactory()).buildWith(seed: seed);

    return SpecComplianceSubscriber(
      animationSpecRepository: animationSpecRepository,
      assetCatalogRepository: assetCatalogRepository,
      assetValidator: assetValidator,
    );
  }

  @override
  SpecComplianceSubscriber duplicate(
    SpecComplianceSubscriber instance,
    SpeckComplianceSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
