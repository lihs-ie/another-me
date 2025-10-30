import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/number.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/theme.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/library/animation/binding.dart';
import 'package:another_me/domains/library/animation/timeline.dart';
import 'package:another_me/domains/scene/scene.dart';
import 'package:ulid/ulid.dart';

import '../common.dart';
import '../common/identifier.dart';
import '../common/number.dart';
import '../common/theme.dart';
import '../common/transaction.dart';
import '../enum.dart';
import '../library/animation/binding.dart';
import '../library/animation/timeline.dart';

class SceneIdentifierFactory
    extends ULIDBasedIdentifierFactory<SceneIdentifier> {
  SceneIdentifierFactory()
    : super((Ulid value) => SceneIdentifier(value: value));
}

class LightingHintFactory extends EnumFactory<LightingHint> {
  LightingHintFactory() : super(LightingHint.values);
}

typedef SceneAnimationBindingOverrides = ({
  AnimationBindingIdentifier? binding,
  LightingHint? lighting,
});

class SceneAnimationBindingFactory
    extends Factory<SceneAnimationBinding, SceneAnimationBindingOverrides> {
  @override
  SceneAnimationBinding create({
    SceneAnimationBindingOverrides? overrides,
    required int seed,
  }) {
    final binding =
        overrides?.binding ??
        Builder(AnimationBindingIdentifierFactory()).buildWith(seed: seed);

    final lighting =
        overrides?.lighting ??
        Builder(LightingHintFactory()).buildWith(seed: seed);

    return SceneAnimationBinding(binding: binding, lighting: lighting);
  }

  @override
  SceneAnimationBinding duplicate(
    SceneAnimationBinding instance,
    SceneAnimationBindingOverrides? overrides,
  ) {
    final binding =
        overrides?.binding ??
        Builder(
          AnimationBindingIdentifierFactory(),
        ).duplicate(instance: instance.binding);

    final lighting =
        overrides?.lighting ??
        Builder(LightingHintFactory()).duplicate(instance: instance.lighting);

    return SceneAnimationBinding(binding: binding, lighting: lighting);
  }
}

class ParallaxLayerIdentifierFactory
    extends ULIDBasedIdentifierFactory<ParallaxLayerIdentifier> {
  ParallaxLayerIdentifierFactory()
    : super((Ulid value) => ParallaxLayerIdentifier(value: value));
}

typedef ParallaxLayerOverrides = ({
  ParallaxLayerIdentifier? identifier,
  Rational? speedRatio,
  Range<num>? assetFrameRange,
  AnimationBindingIdentifier? binding,
});

class ParallaxLayerFactory
    extends Factory<ParallaxLayer, ParallaxLayerOverrides> {
  @override
  ParallaxLayer create({ParallaxLayerOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(ParallaxLayerIdentifierFactory()).buildWith(seed: seed);

    final speedRatio =
        overrides?.speedRatio ??
        Builder(RationalFactory()).buildWith(
          overrides: (
            numerator: BigInt.from((seed % 10) + 1),
            denominator: BigInt.from((seed % 5) + 2),
          ),
          seed: seed,
        );

    final assetFrameRange =
        overrides?.assetFrameRange ??
        Range<num>(start: seed % 24, end: (seed % 24) + 24);

    final binding =
        overrides?.binding ??
        Builder(AnimationBindingIdentifierFactory()).buildWith(seed: seed);

    return ParallaxLayer(
      identifier: identifier,
      speedRatio: speedRatio,
      assetFrameRange: assetFrameRange,
      binding: binding,
    );
  }

  @override
  ParallaxLayer duplicate(
    ParallaxLayer instance,
    ParallaxLayerOverrides? overrides,
  ) {
    throw UnimplementedError(
      'ParallaxLayer.duplicate is not implemented because _speedRatio is private. '
      'Use create with overrides instead.',
    );
  }
}

typedef SceneAnchorOverrides = ({
  double? relativeX,
  double? relativeY,
  int? offsetX,
  int? offsetY,
});

class SceneAnchorFactory extends Factory<SceneAnchor, SceneAnchorOverrides> {
  @override
  SceneAnchor create({SceneAnchorOverrides? overrides, required int seed}) {
    final relativeX = overrides?.relativeX ?? (seed % 100) / 100.0;
    final relativeY = overrides?.relativeY ?? ((seed + 1) % 100) / 100.0;
    final offsetX = overrides?.offsetX ?? ((seed % 10) * 16);
    final offsetY = overrides?.offsetY ?? (((seed + 1) % 10) * 16);

    return SceneAnchor(
      relativeX: relativeX,
      relativeY: relativeY,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }

  @override
  SceneAnchor duplicate(SceneAnchor instance, SceneAnchorOverrides? overrides) {
    final relativeX = overrides?.relativeX ?? instance.relativeX;
    final relativeY = overrides?.relativeY ?? instance.relativeY;
    final offsetX = overrides?.offsetX ?? instance.offsetX;
    final offsetY = overrides?.offsetY ?? instance.offsetY;

    return SceneAnchor(
      relativeX: relativeX,
      relativeY: relativeY,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }
}

class SceneEffectElementFactory extends EnumFactory<SceneEffectElement> {
  SceneEffectElementFactory() : super(SceneEffectElement.values);
}

typedef LightingProfileOverrides = ({ThemeMode? mode, double? darkeningFactor});

class LightingProfileFactory
    extends Factory<LightingProfile, LightingProfileOverrides> {
  @override
  LightingProfile create({
    LightingProfileOverrides? overrides,
    required int seed,
  }) {
    final mode =
        overrides?.mode ?? Builder(ThemeModeFactory()).buildWith(seed: seed);

    final darkeningFactor =
        overrides?.darkeningFactor ??
        (mode == ThemeMode.night ? 0.5 : (seed % 10) / 10.0);

    return LightingProfile(mode: mode, darkeningFactor: darkeningFactor);
  }

  @override
  LightingProfile duplicate(
    LightingProfile instance,
    LightingProfileOverrides? overrides,
  ) {
    final mode =
        overrides?.mode ??
        Builder(ThemeModeFactory()).duplicate(instance: instance.mode);

    final darkeningFactor =
        overrides?.darkeningFactor ?? instance.darkeningFactor;

    return LightingProfile(mode: mode, darkeningFactor: darkeningFactor);
  }
}

class SceneStatusFactory extends EnumFactory<SceneStatus> {
  SceneStatusFactory() : super(SceneStatus.values);
}

class SceneTypeFactory extends EnumFactory<SceneType> {
  SceneTypeFactory() : super(SceneType.values);
}

typedef SceneRepositoryOverrides = ({
  List<Scene>? instances,
  void Function(Scene)? onPersist,
});

class _SceneRepository implements SceneRepository {
  final Map<SceneIdentifier, Scene> _instances;
  final void Function(Scene)? _onPersist;

  _SceneRepository({
    required List<Scene> instances,
    void Function(Scene)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<Scene> find(SceneIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'Scene with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<List<Scene>> search(SceneSearchCriteria criteria) {
    var filtered = _instances.values.where((scene) {
      if (criteria.statuses != null &&
          !criteria.statuses!.contains(scene.status)) {
        return false;
      }

      if (criteria.types != null && !criteria.types!.contains(scene.type)) {
        return false;
      }

      return true;
    });

    return Future.value(filtered.toList());
  }

  @override
  Future<void> persist(Scene scene) {
    _instances[scene.identifier] = scene;

    if (_onPersist != null) {
      _onPersist(scene);
    }

    return Future.value();
  }

  @override
  Future<List<Scene>> all() {
    return Future.value(_instances.values.toList());
  }
}

class SceneRepositoryFactory
    extends Factory<SceneRepository, SceneRepositoryOverrides> {
  @override
  SceneRepository create({
    SceneRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances = overrides?.instances ?? <Scene>[];

    return _SceneRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  SceneRepository duplicate(
    SceneRepository instance,
    SceneRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef AssetCatalogUpdatedSubscriberOverrides = ({
  SceneRepository? sceneRepository,
  AnimationBindingManifestRepository? animationBindingManifestRepository,
  TimelineDefinitionRepository? timelineDefinitionRepository,
  Transaction? transaction,
});

class AssetCatalogUpdatedSubscriberFactory
    extends
        Factory<
          AssetCatalogUpdatedSubscriber,
          AssetCatalogUpdatedSubscriberOverrides
        > {
  @override
  AssetCatalogUpdatedSubscriber create({
    AssetCatalogUpdatedSubscriberOverrides? overrides,
    required int seed,
  }) {
    final sceneRepository =
        overrides?.sceneRepository ??
        Builder(SceneRepositoryFactory()).buildWith(seed: seed);

    final animationBindingManifestRepository =
        overrides?.animationBindingManifestRepository ??
        Builder(
          AnimationBindingManifestRepositoryFactory(),
        ).buildWith(seed: seed);

    final timelineDefinitionRepository =
        overrides?.timelineDefinitionRepository ??
        Builder(TimelineDefinitionRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    return AssetCatalogUpdatedSubscriber(
      sceneRepository,
      animationBindingManifestRepository,
      timelineDefinitionRepository,
      transaction,
    );
  }

  @override
  AssetCatalogUpdatedSubscriber duplicate(
    AssetCatalogUpdatedSubscriber instance,
    AssetCatalogUpdatedSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
