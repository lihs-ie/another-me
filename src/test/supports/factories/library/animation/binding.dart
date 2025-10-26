import 'package:another_me/domains/library/animation/atlas.dart';
import 'package:another_me/domains/library/animation/binding.dart';
import 'package:another_me/domains/library/animation/timeline.dart';

import '../../common.dart';
import '../../common/error.dart';
import '../../common/identifier.dart';
import '../../enum.dart';
import 'atlas.dart';
import 'timeline.dart';

class AnimationBindingIdentifierFactory
    extends ULIDBasedIdentifierFactory<AnimationBindingIdentifier> {
  AnimationBindingIdentifierFactory()
    : super((value) => AnimationBindingIdentifier(value: value));
}

class AnimationBindingTagFactory extends EnumFactory<AnimationBindingTag> {
  AnimationBindingTagFactory() : super(AnimationBindingTag.values);
}

typedef FrameRangeOverrides = ({int? start, int? end});

class FrameRangeFactory extends Factory<FrameRange, FrameRangeOverrides> {
  @override
  FrameRange create({FrameRangeOverrides? overrides, required int seed}) {
    final start = overrides?.start ?? (seed % 100);
    final end = overrides?.end ?? ((seed % 100) + (seed % 50) + 1);

    return FrameRange(start: start, end: end);
  }

  @override
  FrameRange duplicate(FrameRange instance, FrameRangeOverrides? overrides) {
    final start = overrides?.start ?? instance.start;
    final end = overrides?.end ?? instance.end;

    return FrameRange(start: start, end: end);
  }
}

typedef AnimationBindingManifestOverrides = ({
  AnimationBindingIdentifier? identifier,
  TimelineIdentifier? timeline,
  SpriteAtlasIdentifier? spriteAtlas,
  FrameRange? frameRange,
  int? frameCount,
  Set<AnimationBindingTag>? tags,
});

class AnimationBindingManifestFactory
    extends
        Factory<AnimationBindingManifest, AnimationBindingManifestOverrides> {
  @override
  AnimationBindingManifest create({
    AnimationBindingManifestOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(AnimationBindingIdentifierFactory()).buildWith(seed: seed);

    final timeline =
        overrides?.timeline ??
        Builder(TimelineIdentifierFactory()).buildWith(seed: seed);

    final spriteAtlas =
        overrides?.spriteAtlas ??
        Builder(SpriteAtlasIdentifierFactory()).buildWith(seed: seed);

    final frameCount = overrides?.frameCount ?? ((seed % 100) + 10);

    final frameRange =
        overrides?.frameRange ??
        Builder(
          FrameRangeFactory(),
        ).buildWith(overrides: (start: 0, end: frameCount - 1), seed: seed);

    final tags =
        overrides?.tags ??
        {Builder(AnimationBindingTagFactory()).buildWith(seed: seed)};

    return AnimationBindingManifest(
      identifier: identifier,
      timeline: timeline,
      spriteAtlas: spriteAtlas,
      frameRange: frameRange,
      frameCount: frameCount,
      tags: tags,
    );
  }

  @override
  AnimationBindingManifest duplicate(
    AnimationBindingManifest instance,
    AnimationBindingManifestOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          AnimationBindingIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final timeline =
        overrides?.timeline ??
        Builder(
          TimelineIdentifierFactory(),
        ).duplicate(instance: instance.timeline);

    final spriteAtlas =
        overrides?.spriteAtlas ??
        Builder(
          SpriteAtlasIdentifierFactory(),
        ).duplicate(instance: instance.spriteAtlas);

    final frameRange =
        overrides?.frameRange ??
        Builder(FrameRangeFactory()).duplicate(instance: instance.frameRange);

    final frameCount = overrides?.frameCount ?? instance.frameCount;

    final tags =
        overrides?.tags ??
        instance.tags
            .map(
              (tag) => Builder(
                AnimationBindingTagFactory(),
              ).duplicate(instance: tag),
            )
            .toSet();

    return AnimationBindingManifest(
      identifier: identifier,
      timeline: timeline,
      spriteAtlas: spriteAtlas,
      frameRange: frameRange,
      frameCount: frameCount,
      tags: tags,
    );
  }
}

typedef CriteriaOverrides = ({Set<AnimationBindingTag>? tags});

class CriteriaFactory extends Factory<Criteria, CriteriaOverrides> {
  @override
  Criteria create({CriteriaOverrides? overrides, required int seed}) {
    Set<AnimationBindingTag>? tags = overrides?.tags;

    if (tags == null && seed % 2 == 0) {
      tags = {Builder(AnimationBindingTagFactory()).buildWith(seed: seed)};
    }

    return Criteria(tags: tags);
  }

  @override
  Criteria duplicate(Criteria instance, CriteriaOverrides? overrides) {
    final tags =
        overrides?.tags ??
        instance.tags
            ?.map(
              (tag) => Builder(
                AnimationBindingTagFactory(),
              ).duplicate(instance: tag),
            )
            .toSet();

    return Criteria(tags: tags);
  }
}

typedef AnimationBindingManifestUpdatedOverrides = ({
  DateTime? occurredAt,
  AnimationBindingIdentifier? binding,
  TimelineIdentifier? timeline,
  SpriteAtlasIdentifier? spriteAtlas,
  FrameRange? frameRange,
});

class AnimationBindingManifestUpdatedFactory
    extends
        Factory<
          AnimationBindingManifestUpdated,
          AnimationBindingManifestUpdatedOverrides
        > {
  @override
  AnimationBindingManifestUpdated create({
    AnimationBindingManifestUpdatedOverrides? overrides,
    required int seed,
  }) {
    final occurredAt = overrides?.occurredAt ?? DateTime.now();

    final binding =
        overrides?.binding ??
        Builder(AnimationBindingIdentifierFactory()).buildWith(seed: seed);

    final timeline =
        overrides?.timeline ??
        Builder(TimelineIdentifierFactory()).buildWith(seed: seed);

    final spriteAtlas =
        overrides?.spriteAtlas ??
        Builder(SpriteAtlasIdentifierFactory()).buildWith(seed: seed);

    final frameRange =
        overrides?.frameRange ??
        Builder(FrameRangeFactory()).buildWith(seed: seed);

    return AnimationBindingManifestUpdated(
      occurredAt: occurredAt,
      binding: binding,
      timeline: timeline,
      spriteAtlas: spriteAtlas,
      frameRange: frameRange,
    );
  }

  @override
  AnimationBindingManifestUpdated duplicate(
    AnimationBindingManifestUpdated instance,
    AnimationBindingManifestUpdatedOverrides? overrides,
  ) {
    final occurredAt = overrides?.occurredAt ?? instance.occurredAt;

    final binding =
        overrides?.binding ??
        Builder(
          AnimationBindingIdentifierFactory(),
        ).duplicate(instance: instance.binding);

    final timeline =
        overrides?.timeline ??
        Builder(
          TimelineIdentifierFactory(),
        ).duplicate(instance: instance.timeline);

    final spriteAtlas =
        overrides?.spriteAtlas ??
        Builder(
          SpriteAtlasIdentifierFactory(),
        ).duplicate(instance: instance.spriteAtlas);

    final frameRange =
        overrides?.frameRange ??
        Builder(FrameRangeFactory()).duplicate(instance: instance.frameRange);

    return AnimationBindingManifestUpdated(
      occurredAt: occurredAt,
      binding: binding,
      timeline: timeline,
      spriteAtlas: spriteAtlas,
      frameRange: frameRange,
    );
  }
}

class _AnimationBindingManifestRepository
    implements AnimationBindingManifestRepository {
  final Map<AnimationBindingIdentifier, AnimationBindingManifest> _instances;
  final void Function(AnimationBindingManifest instance)? _onPersist;
  final Map<AnimationBindingIdentifier, int> _versions = {};

  _AnimationBindingManifestRepository({
    required List<AnimationBindingManifest> instances,
    void Function(AnimationBindingManifest instance)? onPersist,
  }) : _instances = {
         for (var instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<AnimationBindingManifest> find(AnimationBindingIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'AnimationBindingManifest not found: $identifier',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<List<AnimationBindingManifest>> search(Criteria criteria) {
    final instances = _instances.values.where((
      AnimationBindingManifest instance,
    ) {
      if (criteria.tags != null) {
        return criteria.tags!.every((tag) => instance.tags.contains(tag));
      }

      return true;
    });

    return Future.value(instances.toList());
  }

  @override
  Future<void> persist(AnimationBindingManifest manifest) {
    final currentVersion = _versions[manifest.identifier] ?? 0;

    _versions[manifest.identifier] = currentVersion + 1;
    _instances[manifest.identifier] = manifest;

    _onPersist?.call(manifest);

    return Future.value();
  }
}
