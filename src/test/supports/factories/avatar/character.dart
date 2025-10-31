import 'package:another_me/domains/avatar/avatar.dart';
import 'package:another_me/domains/billing/billing.dart';
import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:logger/logger.dart';
import 'package:ulid/ulid.dart';

import '../billing/billing.dart';
import '../common.dart';
import '../common/identifier.dart';
import '../common/transaction.dart';
import '../enum.dart';
import '../logger.dart';
import '../string.dart' as string_factory;
import 'animation.dart';
import 'wardrobe.dart';

class CharacterIdentifierFactory
    extends ULIDBasedIdentifierFactory<CharacterIdentifier> {
  CharacterIdentifierFactory()
    : super((Ulid value) => CharacterIdentifier(value: value));
}

class CharacterStatusFactory extends EnumFactory<CharacterStatus> {
  CharacterStatusFactory() : super(CharacterStatus.values);
}

typedef ColorOverrides = ({int? red, int? green, int? blue, int? alpha});

class ColorFactory extends Factory<Color, ColorOverrides> {
  @override
  Color create({ColorOverrides? overrides, required int seed}) {
    final red = overrides?.red ?? (seed % 256);
    final green = overrides?.green ?? ((seed * 7) % 256);
    final blue = overrides?.blue ?? ((seed * 13) % 256);
    final alpha = overrides?.alpha ?? 255;

    return Color(red: red, green: green, blue: blue, alpha: alpha);
  }

  @override
  Color duplicate(Color instance, ColorOverrides? overrides) {
    final red = overrides?.red ?? instance.red;
    final green = overrides?.green ?? instance.green;
    final blue = overrides?.blue ?? instance.blue;
    final alpha = overrides?.alpha ?? instance.alpha;

    return Color(red: red, green: green, blue: blue, alpha: alpha);
  }
}

typedef ColorPaletteOverrides = ({Set<Color>? colors});

class ColorPaletteFactory extends Factory<ColorPalette, ColorPaletteOverrides> {
  @override
  ColorPalette create({ColorPaletteOverrides? overrides, required int seed}) {
    final colorCount = (seed % ColorPalette.maxColorsCount) + 1;
    final colors =
        overrides?.colors ??
        Builder(
          ColorFactory(),
        ).buildListWith(count: colorCount, seed: seed).toSet();

    return ColorPalette(colors: colors);
  }

  @override
  ColorPalette duplicate(
    ColorPalette instance,
    ColorPaletteOverrides? overrides,
  ) {
    final colors =
        overrides?.colors ??
        instance.colors
            .map(
              (color) => Builder(
                ColorFactory(),
              ).duplicate(instance: color, overrides: null),
            )
            .toSet();

    return ColorPalette(colors: colors);
  }
}

typedef CharacterOverrides = ({
  CharacterIdentifier? identifier,
  String? displayName,
  List<CharacterAnimationBinding>? bindings,
  WardrobeMap? wardrobes,
  ColorPalette? palette,
  CharacterStatus? status,
});

class CharacterFactory extends Factory<Character, CharacterOverrides> {
  @override
  Character create({CharacterOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(CharacterIdentifierFactory()).buildWith(seed: seed);
    final displayName =
        overrides?.displayName ??
        string_factory.StringFactory.createFromPattern(
          pattern: r'[A-Z][a-z]+(?: [A-Z][a-z]+)*',
          seed: seed,
          minimumLength: 5,
          maximumLength: 30,
        );
    final bindings =
        overrides?.bindings ??
        [
          Builder(CharacterAnimationBindingFactory()).buildWith(
            seed: seed,
            overrides: (
              tag: CharacterAnimationTag.typing,
              playbackOrder: 1,
              binding: null,
            ),
          ),
          Builder(CharacterAnimationBindingFactory()).buildWith(
            seed: seed,
            overrides: (
              tag: CharacterAnimationTag.coffee,
              playbackOrder: 2,
              binding: null,
            ),
          ),
        ];
    final wardrobes =
        overrides?.wardrobes ??
        Builder(WardrobeMapFactory()).buildWith(seed: seed);
    final palette =
        overrides?.palette ??
        Builder(ColorPaletteFactory()).buildWith(seed: seed);
    final status =
        overrides?.status ??
        Builder(CharacterStatusFactory()).buildWith(seed: seed);

    return Character(
      identifier: identifier,
      displayName: displayName,
      bindings: bindings,
      wardrobes: wardrobes,
      palette: palette,
      status: status,
    );
  }

  @override
  Character duplicate(Character instance, CharacterOverrides? overrides) {
    final identifier =
        overrides?.identifier ??
        Builder(
          CharacterIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);
    final displayName = overrides?.displayName ?? instance.displayName;
    final bindings =
        overrides?.bindings ??
        instance.bindings
            .map(
              (binding) => Builder(
                CharacterAnimationBindingFactory(),
              ).duplicate(instance: binding, overrides: null),
            )
            .toList();
    final wardrobes =
        overrides?.wardrobes ??
        Builder(
          WardrobeMapFactory(),
        ).duplicate(instance: instance.wardrobes, overrides: null);
    final palette =
        overrides?.palette ??
        Builder(
          ColorPaletteFactory(),
        ).duplicate(instance: instance.palette, overrides: null);
    final status =
        overrides?.status ??
        Builder(
          CharacterStatusFactory(),
        ).duplicate(instance: instance.status, overrides: null);

    return Character(
      identifier: identifier,
      displayName: displayName,
      bindings: bindings,
      wardrobes: wardrobes,
      palette: palette,
      status: status,
    );
  }
}

typedef CharacterSearchCriteriaOverrides = ({
  Set<CharacterStatus>? statuses,
  Set<CharacterAnimationTag>? tags,
});

class CharacterSearchCriteriaFactory
    extends Factory<CharacterSearchCriteria, CharacterSearchCriteriaOverrides> {
  @override
  CharacterSearchCriteria create({
    CharacterSearchCriteriaOverrides? overrides,
    required int seed,
  }) {
    final statuses = overrides?.statuses;
    final tags = overrides?.tags;

    return CharacterSearchCriteria(statuses: statuses, tags: tags);
  }

  @override
  CharacterSearchCriteria duplicate(
    CharacterSearchCriteria instance,
    CharacterSearchCriteriaOverrides? overrides,
  ) {
    final statuses = overrides?.statuses ?? instance.statuses;
    final tags = overrides?.tags ?? instance.tags;

    return CharacterSearchCriteria(statuses: statuses, tags: tags);
  }
}

class _CharacterRepository implements CharacterRepository {
  final Map<CharacterIdentifier, Character> _instances;
  final void Function(Character)? _onPersist;
  final Map<CharacterIdentifier, int> _versions;

  _CharacterRepository({
    required List<Character> instances,
    void Function(Character)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist,
       _versions = {};

  @override
  Future<Character> find(CharacterIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError('Character not found: $identifier');
    }

    return Future.value(instance);
  }

  @override
  Future<Character> findDefault() {
    final defaultCharacter = _instances.values.firstWhere(
      (character) => character.status == CharacterStatus.active,
      orElse: () => throw AggregateNotFoundError('No active character found.'),
    );

    return Future.value(defaultCharacter);
  }

  @override
  Future<List<Character>> all() {
    return Future.value(_instances.values.toList());
  }

  @override
  Future<List<Character>> search(CharacterSearchCriteria criteria) {
    final results = _instances.values.where((instance) {
      if (criteria.statuses != null &&
          !criteria.statuses!.contains(instance.status)) {
        return false;
      }

      if (criteria.tags != null) {
        final bindings = instance.bindings;

        final hasTag = bindings.any((binding) {
          return criteria.tags!.contains(binding.tag);
        });

        if (!hasTag) {
          return false;
        }
      }

      return true;
    }).toList();

    return Future.value(results);
  }

  @override
  Future<void> persist(Character character) {
    final currentVersion = _versions[character.identifier] ?? 0;

    _versions[character.identifier] = currentVersion + 1;
    _instances[character.identifier] = character;

    _onPersist?.call(character);

    return Future.value();
  }
}

typedef CharacterRepositoryOverrides = ({
  List<Character>? instances,
  void Function(Character)? onPersist,
});

class CharacterRepositoryFactory
    extends Factory<CharacterRepository, CharacterRepositoryOverrides> {
  @override
  CharacterRepository create({
    CharacterRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          CharacterFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _CharacterRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  CharacterRepository duplicate(
    CharacterRepository instance,
    CharacterRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef DayPeriodChangedSubscriberOverrides = ({
  CharacterRepository? characterRepository,
  Transaction? transaction,
  Logger? logger,
});

class DayPeriodChangedSubscriberFactory
    extends
        Factory<
          DayPeriodChangedSubscriber,
          DayPeriodChangedSubscriberOverrides
        > {
  @override
  DayPeriodChangedSubscriber create({
    DayPeriodChangedSubscriberOverrides? overrides,
    required int seed,
  }) {
    final characterRepository =
        overrides?.characterRepository ??
        Builder(CharacterRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return DayPeriodChangedSubscriber(
      characterRepository: characterRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  DayPeriodChangedSubscriber duplicate(
    DayPeriodChangedSubscriber instance,
    DayPeriodChangedSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef AssetCatalogUpdatedSubscriberOverrides = ({
  CharacterRepository? characterRepository,
  Transaction? transaction,
  Logger? logger,
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
    final characterRepository =
        overrides?.characterRepository ??
        Builder(CharacterRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return AssetCatalogUpdatedSubscriber(
      characterRepository: characterRepository,
      transaction: transaction,
      logger: logger,
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

typedef EntitlementChangedSubscriberOverrides = ({
  EntitlementRepository? entitlementRepository,
  CharacterRepository? characterRepository,
  Transaction? transaction,
  Logger? logger,
});

class EntitlementChangedSubscriberFactory
    extends
        Factory<
          EntitlementChangedSubscriber,
          EntitlementChangedSubscriberOverrides
        > {
  @override
  EntitlementChangedSubscriber create({
    EntitlementChangedSubscriberOverrides? overrides,
    required int seed,
  }) {
    final entitlementRepository =
        overrides?.entitlementRepository ??
        Builder(EntitlementRepositoryFactory()).buildWith(seed: seed);

    final characterRepository =
        overrides?.characterRepository ??
        Builder(CharacterRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return EntitlementChangedSubscriber(
      entitlementRepository: entitlementRepository,
      characterRepository: characterRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  EntitlementChangedSubscriber duplicate(
    EntitlementChangedSubscriber instance,
    EntitlementChangedSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
