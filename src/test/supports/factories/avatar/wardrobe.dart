import 'package:another_me/domains/avatar/animation.dart';
import 'package:another_me/domains/avatar/wardrobe.dart';
import 'package:another_me/domains/common/date.dart';
import 'package:ulid/ulid.dart';

import '../common.dart';
import '../common/identifier.dart';
import '../enum.dart';
import '../string.dart' as string_factory;
import 'animation.dart';

class PaletteIdentifierFactory
    extends ULIDBasedIdentifierFactory<PaletteIdentifier> {
  PaletteIdentifierFactory()
    : super((Ulid value) => PaletteIdentifier(value: value));
}

typedef AtlasFrameNameOverrides = ({String? value});

class AtlasFrameNameFactory
    extends Factory<AtlasFrameName, AtlasFrameNameOverrides> {
  @override
  AtlasFrameName create({
    AtlasFrameNameOverrides? overrides,
    required int seed,
  }) {
    final value =
        overrides?.value ??
        string_factory.StringFactory.createFromPattern(
          pattern: r'[a-z][a-z0-9_]*',
          seed: seed,
          minimumLength: 3,
          maximumLength: 20,
        );

    return AtlasFrameName(value: value);
  }

  @override
  AtlasFrameName duplicate(
    AtlasFrameName instance,
    AtlasFrameNameOverrides? overrides,
  ) {
    final value = overrides?.value ?? instance.value;

    return AtlasFrameName(value: value);
  }
}

class AccessorySlotFactory extends EnumFactory<AccessorySlot> {
  AccessorySlotFactory() : super(AccessorySlot.values);
}

typedef AccessoryOverrides = ({
  AccessorySlot? slot,
  AtlasFrameName? atlasFrame,
  String? displayName,
});

class AccessoryFactory extends Factory<Accessory, AccessoryOverrides> {
  @override
  Accessory create({AccessoryOverrides? overrides, required int seed}) {
    final slot =
        overrides?.slot ??
        Builder(AccessorySlotFactory()).buildWith(seed: seed);
    final atlasFrame =
        overrides?.atlasFrame ??
        Builder(AtlasFrameNameFactory()).buildWith(seed: seed);
    final displayName =
        overrides?.displayName ??
        string_factory.StringFactory.createFromPattern(
          pattern: r'[A-Z][a-z]+(?: [A-Z][a-z]+)*',
          seed: seed,
          minimumLength: 5,
          maximumLength: 30,
        );

    return Accessory(
      slot: slot,
      atlasFrame: atlasFrame,
      displayName: displayName,
    );
  }

  @override
  Accessory duplicate(Accessory instance, AccessoryOverrides? overrides) {
    final slot =
        overrides?.slot ??
        Builder(
          AccessorySlotFactory(),
        ).duplicate(instance: instance.slot, overrides: null);
    final atlasFrame =
        overrides?.atlasFrame ??
        Builder(
          AtlasFrameNameFactory(),
        ).duplicate(instance: instance.atlasFrame, overrides: null);
    final displayName = overrides?.displayName ?? instance.displayName;

    return Accessory(
      slot: slot,
      atlasFrame: atlasFrame,
      displayName: displayName,
    );
  }
}

typedef OutfitVariantOverrides = ({
  CharacterAnimationBindingIdentifier? binding,
  PaletteIdentifier? palette,
  AtlasFrameName? atlasFrame,
  Map<AccessorySlot, Accessory>? accessories,
});

class OutfitVariantFactory
    extends Factory<OutfitVariant, OutfitVariantOverrides> {
  @override
  OutfitVariant create({OutfitVariantOverrides? overrides, required int seed}) {
    final binding =
        overrides?.binding ??
        Builder(
          CharacterAnimationBindingIdentifierFactory(),
        ).buildWith(seed: seed);
    final palette =
        overrides?.palette ??
        Builder(PaletteIdentifierFactory()).buildWith(seed: seed);
    final atlasFrame =
        overrides?.atlasFrame ??
        Builder(AtlasFrameNameFactory()).buildWith(seed: seed);
    final accessories = overrides?.accessories ?? <AccessorySlot, Accessory>{};

    return OutfitVariant(
      binding: binding,
      palette: palette,
      atlasFrame: atlasFrame,
      accessories: accessories,
    );
  }

  @override
  OutfitVariant duplicate(
    OutfitVariant instance,
    OutfitVariantOverrides? overrides,
  ) {
    final binding =
        overrides?.binding ??
        Builder(
          CharacterAnimationBindingIdentifierFactory(),
        ).duplicate(instance: instance.binding, overrides: null);
    final palette =
        overrides?.palette ??
        Builder(
          PaletteIdentifierFactory(),
        ).duplicate(instance: instance.palette, overrides: null);
    final atlasFrame =
        overrides?.atlasFrame ??
        Builder(
          AtlasFrameNameFactory(),
        ).duplicate(instance: instance.atlasFrame, overrides: null);
    final accessories = overrides?.accessories ?? instance.accessories;

    return OutfitVariant(
      binding: binding,
      palette: palette,
      atlasFrame: atlasFrame,
      accessories: accessories,
    );
  }
}

typedef WardrobeMapOverrides = ({Map<DayPeriod, OutfitVariant>? outfits});

class WardrobeMapFactory extends Factory<WardrobeMap, WardrobeMapOverrides> {
  @override
  WardrobeMap create({WardrobeMapOverrides? overrides, required int seed}) {
    final outfits =
        overrides?.outfits ??
        {
          for (final period in DayPeriod.values)
            period: Builder(OutfitVariantFactory()).buildWith(seed: seed),
        };

    return WardrobeMap(outfits: outfits);
  }

  @override
  WardrobeMap duplicate(WardrobeMap instance, WardrobeMapOverrides? overrides) {
    final outfits =
        overrides?.outfits ??
        {
          for (final period in DayPeriod.values)
            period: Builder(
              OutfitVariantFactory(),
            ).duplicate(instance: instance.resolve(period), overrides: null),
        };

    return WardrobeMap(outfits: outfits);
  }
}
