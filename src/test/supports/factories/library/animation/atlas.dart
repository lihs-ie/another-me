import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/library/animation/atlas.dart';
import 'package:another_me/domains/library/animation/common.dart';

import '../../common.dart';
import '../../common/error.dart';
import '../../common/identifier.dart';
import '../../common/storage.dart';
import 'common.dart';

class SpriteAtlasIdentifierFactory
    extends ULIDBasedIdentifierFactory<SpriteAtlasIdentifier> {
  SpriteAtlasIdentifierFactory()
    : super((value) => SpriteAtlasIdentifier(value: value));
}

typedef SpriteAtlasDefinitionOverrides = ({
  SpriteAtlasIdentifier? identifier,
  FilePath? pngPath,
  FilePath? jsonPath,
  GridSize? gridSize,
  Pivot? pivot,
});

class SpriteAtlasDefinitionFactory
    extends Factory<SpriteAtlasDefinition, SpriteAtlasDefinitionOverrides> {
  @override
  SpriteAtlasDefinition create({
    SpriteAtlasDefinitionOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(SpriteAtlasIdentifierFactory()).buildWith(seed: seed);

    final basePath = '/assets/sprite_atlas_$seed';

    final pngPath =
        overrides?.pngPath ??
        Builder(
          FilePathFactory(),
        ).buildWith(overrides: (value: '$basePath.png', os: null), seed: seed);

    final jsonPath =
        overrides?.jsonPath ??
        Builder(
          FilePathFactory(),
        ).buildWith(overrides: (value: '$basePath.json', os: null), seed: seed);

    final gridSize =
        overrides?.gridSize ?? Builder(GridSizeFactory()).buildWith(seed: seed);

    final pivot =
        overrides?.pivot ?? Builder(PivotFactory()).buildWith(seed: seed);

    return SpriteAtlasDefinition(
      identifier: identifier,
      pngPath: pngPath,
      jsonPath: jsonPath,
      gridSize: gridSize,
      pivot: pivot,
    );
  }

  @override
  SpriteAtlasDefinition duplicate(
    SpriteAtlasDefinition instance,
    SpriteAtlasDefinitionOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          SpriteAtlasIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final pngPath =
        overrides?.pngPath ??
        Builder(FilePathFactory()).duplicate(instance: instance.pngPath);

    final jsonPath =
        overrides?.jsonPath ??
        Builder(FilePathFactory()).duplicate(instance: instance.jsonPath);

    final gridSize =
        overrides?.gridSize ??
        Builder(GridSizeFactory()).duplicate(instance: instance.gridSize);

    final pivot =
        overrides?.pivot ??
        Builder(PivotFactory()).duplicate(instance: instance.pivot);

    return SpriteAtlasDefinition(
      identifier: identifier,
      pngPath: pngPath,
      jsonPath: jsonPath,
      gridSize: gridSize,
      pivot: pivot,
    );
  }
}

typedef SpriteAtlasRegisteredOverrides = ({
  DateTime? occurredAt,
  SpriteAtlasIdentifier? spriteAtlas,
  GridSize? gridSize,
  Pivot? pivot,
});

class SpriteAtlasRegisteredFactory
    extends Factory<SpriteAtlasRegistered, SpriteAtlasRegisteredOverrides> {
  @override
  SpriteAtlasRegistered create({
    SpriteAtlasRegisteredOverrides? overrides,
    required int seed,
  }) {
    final occurredAt = overrides?.occurredAt ?? DateTime.now();

    final spriteAtlas =
        overrides?.spriteAtlas ??
        Builder(SpriteAtlasIdentifierFactory()).buildWith(seed: seed);

    final gridSize =
        overrides?.gridSize ?? Builder(GridSizeFactory()).buildWith(seed: seed);

    final pivot =
        overrides?.pivot ?? Builder(PivotFactory()).buildWith(seed: seed);

    return SpriteAtlasRegistered(
      occurredAt: occurredAt,
      spriteAtlas: spriteAtlas,
      gridSize: gridSize,
      pivot: pivot,
    );
  }

  @override
  SpriteAtlasRegistered duplicate(
    SpriteAtlasRegistered instance,
    SpriteAtlasRegisteredOverrides? overrides,
  ) {
    final occurredAt = overrides?.occurredAt ?? instance.occurredAt;

    final spriteAtlas =
        overrides?.spriteAtlas ??
        Builder(
          SpriteAtlasIdentifierFactory(),
        ).duplicate(instance: instance.spriteAtlas);

    final gridSize =
        overrides?.gridSize ??
        Builder(GridSizeFactory()).duplicate(instance: instance.gridSize);

    final pivot =
        overrides?.pivot ??
        Builder(PivotFactory()).duplicate(instance: instance.pivot);

    return SpriteAtlasRegistered(
      occurredAt: occurredAt,
      spriteAtlas: spriteAtlas,
      gridSize: gridSize,
      pivot: pivot,
    );
  }
}

typedef SpriteAtlasDefinitionRepositoryOverrides = ({
  List<SpriteAtlasDefinition>? instances,
  void Function(SpriteAtlasDefinition instance)? onPersist,
});

class _SpriteAtlasDefinitionRepository
    implements SpriteAtlasDefinitionRepository {
  final Map<SpriteAtlasIdentifier, SpriteAtlasDefinition> _instances;
  final void Function(SpriteAtlasDefinition instance)? _onPersist;
  final Map<SpriteAtlasIdentifier, int> _versions = {};

  _SpriteAtlasDefinitionRepository({
    required List<SpriteAtlasDefinition> instances,
    void Function(SpriteAtlasDefinition instance)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<SpriteAtlasDefinition> find(SpriteAtlasIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'SpriteAtlasDefinition not found: $identifier',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<void> persist(SpriteAtlasDefinition definition) async {
    final currentVersion = _versions[definition.identifier] ?? 0;

    _versions[definition.identifier] = currentVersion + 1;
    _instances[definition.identifier] = definition;

    _onPersist?.call(definition);
  }
}

class SpriteAtlasDefinitionRepositoryFactory
    extends
        Factory<
          SpriteAtlasDefinitionRepository,
          SpriteAtlasDefinitionRepositoryOverrides
        > {
  @override
  SpriteAtlasDefinitionRepository create({
    SpriteAtlasDefinitionRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          SpriteAtlasDefinitionFactory(),
        ).buildList(count: (seed % 5) + 1);
    final onPersist = overrides?.onPersist;

    return _SpriteAtlasDefinitionRepository(
      instances: instances,
      onPersist: onPersist,
    );
  }

  @override
  SpriteAtlasDefinitionRepository duplicate(
    SpriteAtlasDefinitionRepository instance,
    SpriteAtlasDefinitionRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
