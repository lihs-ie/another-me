import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/number.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/theme.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/animation/binding.dart';
import 'package:another_me/domains/library/animation/timeline.dart';
import 'package:another_me/domains/library/asset.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:ulid/ulid.dart';

class SceneIdentifier extends ULIDBasedIdentifier {
  SceneIdentifier({required Ulid value}) : super(value);

  factory SceneIdentifier.generate() => SceneIdentifier(value: Ulid());

  factory SceneIdentifier.fromString(String value) =>
      SceneIdentifier(value: Ulid.parse(value));

  factory SceneIdentifier.fromBinary(Uint8List bytes) =>
      SceneIdentifier(value: Ulid.fromBytes(bytes));
}

enum LightingHint { day, night, auto }

class SceneAnimationBinding implements ValueObject {
  final AnimationBindingIdentifier binding;
  final LightingHint lighting;

  SceneAnimationBinding({required this.binding, required this.lighting});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SceneAnimationBinding) {
      return false;
    }

    if (binding != other.binding) {
      return false;
    }

    if (lighting != other.lighting) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(binding, lighting);
}

class ParallaxLayerIdentifier extends ULIDBasedIdentifier {
  ParallaxLayerIdentifier({required Ulid value}) : super(value);

  factory ParallaxLayerIdentifier.generate() =>
      ParallaxLayerIdentifier(value: Ulid());

  factory ParallaxLayerIdentifier.fromString(String value) =>
      ParallaxLayerIdentifier(value: Ulid.parse(value));

  factory ParallaxLayerIdentifier.fromBinary(Uint8List bytes) =>
      ParallaxLayerIdentifier(value: Ulid.fromBytes(bytes));
}

class ParallaxLayer {
  final ParallaxLayerIdentifier identifier;
  final AnimationBindingIdentifier binding;
  Rational _speedRatio;
  final Range<num> assetFrameRange;

  ParallaxLayer({
    required this.identifier,
    required Rational speedRatio,
    required this.assetFrameRange,
    required this.binding,
  }) : _speedRatio = speedRatio {
    if (_speedRatio <= 0) {
      throw InvariantViolationError(
        'speedRatio must be a positive rational number.',
      );
    }
  }

  void changeSpeedRatio(Rational next) {
    if (next <= 0) {
      throw InvariantViolationError(
        'speedRatio must be a positive rational number.',
      );
    }

    _speedRatio = next;
  }
}

class SceneAnchor implements ValueObject {
  final double relativeX;
  final double relativeY;
  final int offsetX;
  final int offsetY;

  SceneAnchor({
    required this.relativeX,
    required this.relativeY,
    required this.offsetX,
    required this.offsetY,
  }) {
    Invariant.range(value: relativeX, name: 'relativeX', min: 0.0, max: 1.0);
    Invariant.range(value: relativeY, name: 'relativeY', min: 0.0, max: 1.0);

    if (offsetX % 16 != 0) {
      throw InvariantViolationError('offsetX must be a multiple of 16 pixels.');
    }

    if (offsetY % 16 != 0) {
      throw InvariantViolationError('offsetY must be a multiple of 16 pixels.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SceneAnchor) {
      return false;
    }

    if (relativeX != other.relativeX) {
      return false;
    }

    if (relativeY != other.relativeY) {
      return false;
    }

    if (offsetX != other.offsetX) {
      return false;
    }

    if (offsetY != other.offsetY) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(relativeX, relativeY, offsetX, offsetY);

  (int absoluteX, int absoluteY) toAbsolute({
    required int sceneWidth,
    required int sceneHeight,
  }) {
    final absoluteX = (relativeX * sceneWidth).round() + offsetX;
    final absoluteY = (relativeY * sceneHeight).round() + offsetY;

    return (absoluteX, absoluteY);
  }
}

enum SceneEffectElement { pedestrians, steam, clouds, printerActivity }

class LightingProfile implements ValueObject {
  final ThemeMode mode;
  final double darkeningFactor;

  LightingProfile({required this.mode, required this.darkeningFactor}) {
    Invariant.range(
      value: darkeningFactor,
      name: 'darkeningFactor',
      min: 0.0,
      max: 1.0,
    );

    if (mode == ThemeMode.night && darkeningFactor < 0.4) {
      throw InvariantViolationError(
        'For night mode, darkeningFactor must be at least 0.4.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LightingProfile) {
      return false;
    }

    if (mode != other.mode) {
      return false;
    }

    if (darkeningFactor != other.darkeningFactor) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(mode, darkeningFactor);

  factory LightingProfile.fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.day:
        return LightingProfile(mode: mode, darkeningFactor: 0.0);
      case ThemeMode.night:
        return LightingProfile(mode: mode, darkeningFactor: 0.5);
      case ThemeMode.auto:
        return LightingProfile(mode: mode, darkeningFactor: 0.0);
    }
  }
}

enum SceneStatus { active, deprecated }

enum SceneType { room, office, cafe }

class SceneEvent extends BaseEvent {
  SceneEvent({required DateTime occurredAt}) : super(occurredAt);
}

class SceneRegistered extends SceneEvent {
  final SceneIdentifier identifier;
  final AnimationBindingIdentifier binding;
  final Set<SceneEffectElement> effects;

  SceneRegistered({
    required this.identifier,
    required this.binding,
    required this.effects,
    required super.occurredAt,
  });
}

class SceneUpdated extends SceneEvent {
  final SceneIdentifier identifier;
  final AnimationBindingIdentifier binding;
  final LightingProfile lightingProfile;
  final List<ParallaxLayer> parallaxLayers;

  SceneUpdated({
    required this.identifier,
    required this.binding,
    required this.lightingProfile,
    required this.parallaxLayers,
    required super.occurredAt,
  });
}

class SceneDeprecated extends SceneEvent {
  final SceneIdentifier identifier;
  final String reason;

  SceneDeprecated({
    required this.identifier,
    required this.reason,
    required super.occurredAt,
  });
}

class SceneLightingChanged extends SceneEvent {
  final SceneIdentifier identifier;
  final LightingProfile profile;

  SceneLightingChanged({
    required this.identifier,
    required this.profile,
    required super.occurredAt,
  });
}

class SceneSearchCriteria implements ValueObject {
  final Set<SceneStatus>? statuses;
  final Set<SceneType>? types;

  SceneSearchCriteria({this.statuses, this.types}) {
    if (statuses != null && statuses!.isEmpty) {
      throw InvariantViolationError(
        'If statuses is specified, it must not be an empty set.',
      );
    }

    if (types != null && types!.isEmpty) {
      throw InvariantViolationError(
        'If types is specified, it must not be an empty set.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SceneSearchCriteria) {
      return false;
    }

    if (statuses != other.statuses) {
      return false;
    }

    if (types != other.types) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(statuses, types);
}

class Scene with Publishable<SceneEvent> {
  final SceneIdentifier identifier;
  final String name;
  final SceneType type;
  final SceneAnimationBinding animationBinding;
  final List<ParallaxLayer> _parallaxLayers;
  final SceneAnchor characterAnchor;
  final Set<SceneEffectElement> effects;
  LightingProfile _lightingProfile;
  SceneStatus _status;

  List<ParallaxLayer> get parallaxLayers => List.unmodifiable(_parallaxLayers);

  LightingProfile get lightingProfile => _lightingProfile;

  SceneStatus get status => _status;

  Scene({
    required this.identifier,
    required this.name,
    required this.type,
    required this.animationBinding,
    required List<ParallaxLayer> parallaxLayers,
    required this.effects,
    required LightingProfile lightingProfile,
    required SceneStatus status,
    required this.characterAnchor,
  }) : _parallaxLayers = parallaxLayers,
       _lightingProfile = lightingProfile,
       _status = status {
    final layerIdentifiers = parallaxLayers
        .map((layer) => layer.identifier)
        .toSet();

    if (layerIdentifiers.length != parallaxLayers.length) {
      throw InvariantViolationError(
        'Parallax layers must have unique identifiers.',
      );
    }

    if (animationBinding.lighting == LightingHint.night &&
        lightingProfile.darkeningFactor < 0.4) {
      throw InvariantViolationError(
        'If animation binding lighting is night, darkening factor must be at least 0.4.',
      );
    }
  }

  void changeLighting(LightingProfile next) {
    if (animationBinding.lighting == LightingHint.night &&
        next.darkeningFactor < 0.4) {
      throw InvariantViolationError(
        'If animation binding lighting is night, darkening factor must be at least 0.4.',
      );
    }

    _lightingProfile = next;

    publish(
      SceneLightingChanged(
        identifier: identifier,
        profile: next,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void reduceParallaxSpeed(double reductionRatio) {
    Invariant.range(
      value: reductionRatio,
      name: 'reductionRatio',
      min: 0.0,
      max: 1.0,
    );

    final nextLayers = _parallaxLayers.map((layer) {
      final currentSpeed = layer._speedRatio;
      final nextSpeed = Rational.fromDouble(
        currentSpeed.toDouble() * (1.0 - reductionRatio),
      );

      layer.changeSpeedRatio(nextSpeed);

      return layer;
    }).toList();

    _parallaxLayers
      ..clear()
      ..addAll(nextLayers);

    publish(
      SceneUpdated(
        identifier: identifier,
        binding: animationBinding.binding,
        lightingProfile: _lightingProfile,
        parallaxLayers: _parallaxLayers,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void removeParallaxLayer(ParallaxLayerIdentifier layer) {
    final existingLayerIndex = _parallaxLayers.indexWhere(
      (candidate) => candidate.identifier == layer,
    );

    if (existingLayerIndex < 0) {
      throw InvariantViolationError(
        'Parallax layer with the specified identifier does not exist.',
      );
    }

    _parallaxLayers.removeAt(existingLayerIndex);

    publish(
      SceneUpdated(
        identifier: identifier,
        binding: animationBinding.binding,
        lightingProfile: _lightingProfile,
        parallaxLayers: _parallaxLayers,
        occurredAt: DateTime.now(),
      ),
    );
  }

  ParallaxLayerIdentifier removeFastestParallaxLayer() {
    if (_parallaxLayers.isEmpty) {
      throw InvariantViolationError('There are no parallax layers to remove.');
    }

    _parallaxLayers.sort((a, b) {
      return b._speedRatio.compareTo(a._speedRatio);
    });

    final removedLayer = _parallaxLayers.removeAt(0);

    publish(
      SceneUpdated(
        identifier: identifier,
        binding: animationBinding.binding,
        lightingProfile: _lightingProfile,
        parallaxLayers: _parallaxLayers,
        occurredAt: DateTime.now(),
      ),
    );

    return removedLayer.identifier;
  }

  void deprecate(String reason) {
    _status = SceneStatus.deprecated;

    publish(
      SceneDeprecated(
        identifier: identifier,
        reason: reason,
        occurredAt: DateTime.now(),
      ),
    );
  }
}

class SceneFactory {
  final AnimationBindingManifestRepository _animationBindingManifestRepository;
  final TimelineDefinitionRepository _timelineDefinitionRepository;

  static const Set<int> _allowedLoopFrameCounts = {24, 48, 96, 192};

  SceneFactory({
    required AnimationBindingManifestRepository
    animationBindingManifestRepository,
    required TimelineDefinitionRepository timelineDefinitionRepository,
  }) : _animationBindingManifestRepository = animationBindingManifestRepository,
       _timelineDefinitionRepository = timelineDefinitionRepository;

  Future<Scene> create({
    required SceneIdentifier identifier,
    required String name,
    required SceneType type,
    required SceneAnimationBinding animationBinding,
    required List<ParallaxLayer> parallaxLayers,
    required SceneAnchor characterAnchor,
    required Set<SceneEffectElement> effects,
    required LightingProfile lightingProfile,
  }) async {
    final bindingManifest = await _animationBindingManifestRepository.find(
      animationBinding.binding,
    );

    final timeline = await _timelineDefinitionRepository.find(
      bindingManifest.timeline,
    );

    if (timeline.fps != FramesPerSecond(value: 24)) {
      throw StateError(
        'AnimationBindingManifest must reference a TimelineDefinition with 24fps.',
      );
    }

    if (!bindingManifest.tags.contains(AnimationBindingTag.ambient)) {
      throw StateError('AnimationBindingManifest must have the "ambient" tag.');
    }

    if (!_allowedLoopFrameCounts.contains(timeline.frameCount)) {
      throw StateError(
        'TimelineDefinition frameCount must be one of the predefined loop lengths: '
        '${_allowedLoopFrameCounts.join(', ')}.',
      );
    }

    return Scene(
      identifier: identifier,
      name: name,
      type: type,
      animationBinding: animationBinding,
      parallaxLayers: parallaxLayers,
      characterAnchor: characterAnchor,
      effects: effects,
      lightingProfile: lightingProfile,
      status: SceneStatus.active,
    );
  }
}

abstract interface class SceneRepository {
  Future<Scene> find(SceneIdentifier identifier);
  Future<List<Scene>> search(SceneSearchCriteria criteria);
  Future<void> persist(Scene scene);
  Future<List<Scene>> all();
}

class ThemeChangedSubscriber implements EventSubscriber {
  final SceneRepository _sceneRepository;
  final Transaction _transaction;

  ThemeChangedSubscriber(this._sceneRepository, this._transaction);

  @override
  void subscribe(EventBroker broker) {
    broker.listen<ThemeChanged>(_onThemeChanged(broker));
  }

  void Function(ThemeChanged event) _onThemeChanged(EventBroker broker) {
    return (ThemeChanged event) async {
      _transaction.execute(() async {
        final scenes = await _sceneRepository.search(
          SceneSearchCriteria(statuses: {SceneStatus.active}),
        );

        final nextLightning = LightingProfile.fromThemeMode(event.mode);

        for (final scene in scenes) {
          scene.changeLighting(nextLightning);

          await _sceneRepository.persist(scene);

          broker.publishAll(scene.events());
        }
      });
    };
  }
}

class AssetCatalogUpdatedSubscriber implements EventSubscriber {
  final SceneRepository _sceneRepository;
  final AnimationBindingManifestRepository _animationBindingManifestRepository;
  final TimelineDefinitionRepository _timelineDefinitionRepository;
  final Transaction _transaction;

  static const Set<int> _allowedLoopFrameCounts = {24, 48, 96, 192};

  AssetCatalogUpdatedSubscriber(
    this._sceneRepository,
    this._animationBindingManifestRepository,
    this._timelineDefinitionRepository,
    this._transaction,
  );

  @override
  void subscribe(EventBroker broker) {
    broker.listen<AssetCatalogUpdated>(_onAssetCatalogUpdated(broker));
  }

  void Function(AssetCatalogUpdated event) _onAssetCatalogUpdated(
    EventBroker broker,
  ) {
    return (AssetCatalogUpdated event) async {
      _transaction.execute(() async {
        final scenePackages = event.updatedPackages.where(
          (package) => package.type == AssetPackageType.scene,
        );

        if (scenePackages.isEmpty) {
          return;
        }

        final scenes = await _sceneRepository.all();

        for (final scene in scenes) {
          try {
            await _validateScene(scene);

            await _sceneRepository.persist(scene);

            broker.publish(
              SceneUpdated(
                identifier: scene.identifier,
                binding: scene.animationBinding.binding,
                lightingProfile: scene.lightingProfile,
                parallaxLayers: scene.parallaxLayers.toList(),
                occurredAt: DateTime.now(),
              ),
            );
          } catch (error) {
            scene.deprecate(error.toString());

            await _sceneRepository.persist(scene);

            broker.publishAll(scene.events());
          }
        }
      });
    };
  }

  Future<void> _validateScene(Scene scene) async {
    final bindingManifest = await _animationBindingManifestRepository.find(
      scene.animationBinding.binding,
    );

    final timeline = await _timelineDefinitionRepository.find(
      bindingManifest.timeline,
    );

    if (timeline.fps != FramesPerSecond(value: 24)) {
      throw StateError(
        'AnimationBindingManifest must reference a TimelineDefinition with 24fps.',
      );
    }

    if (!bindingManifest.tags.contains(AnimationBindingTag.ambient)) {
      throw StateError('AnimationBindingManifest must have the "ambient" tag.');
    }

    if (!_allowedLoopFrameCounts.contains(timeline.frameCount)) {
      throw StateError(
        'TimelineDefinition frameCount must be one of the predefined loop lengths: '
        '${_allowedLoopFrameCounts.join(', ')}.',
      );
    }

    for (final layer in scene.parallaxLayers) {
      final layerManifest = await _animationBindingManifestRepository.find(
        layer.binding,
      );

      final layerTimeline = await _timelineDefinitionRepository.find(
        layerManifest.timeline,
      );

      if (layerTimeline.fps != FramesPerSecond(value: 24)) {
        throw StateError(
          'ParallaxLayer AnimationBindingManifest must reference a TimelineDefinition with 24fps.',
        );
      }

      if (!layerManifest.tags.contains(AnimationBindingTag.ambient)) {
        throw StateError(
          'ParallaxLayer AnimationBindingManifest must have the "ambient" tag.',
        );
      }

      if (!_allowedLoopFrameCounts.contains(layerTimeline.frameCount)) {
        throw StateError(
          'ParallaxLayer TimelineDefinition frameCount must be one of the predefined loop lengths.',
        );
      }
    }
  }
}

class PerformanceBudgetSubscriber implements EventSubscriber {
  @override
  void subscribe(EventBroker broker) {
    // TODO: implement subscribe
  }
}
