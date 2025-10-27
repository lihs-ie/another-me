import 'package:another_me/domains/avatar/avatar.dart';
import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/avatar/animation.dart';
import '../../../supports/factories/avatar/wardrobe.dart';
import '../../../supports/factories/common.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/avatar/wardrobe', () {
    ulidBasedIdentifierTest<PaletteIdentifier, Ulid>(
      constructor: (Ulid value) => PaletteIdentifier(value: value),
      generate: PaletteIdentifier.generate,
      fromString: PaletteIdentifier.fromString,
      fromBinary: PaletteIdentifier.fromBinary,
    );

    valueObjectTest(
      constructor: (({String value}) props) =>
          AtlasFrameName(value: props.value),
      generator: () => (value: 'test_frame'),
      variations: (({String value}) props) => [
        (value: 'another_frame'),
        (value: 'frame123'),
      ],
      invalids: (({String value}) props) => [
        (value: ''),
        (value: 'A' * 101),
        (value: 'Invalid-Frame'),
        (value: '123invalid'),
        (value: 'Invalid Frame'),
      ],
    );

    group('AccessorySlot', () {
      test('declares all defined enumerators.', () {
        expect(AccessorySlot.glasses, isA<AccessorySlot>());
        expect(AccessorySlot.hat, isA<AccessorySlot>());
        expect(AccessorySlot.scarf, isA<AccessorySlot>());
        expect(AccessorySlot.earrings, isA<AccessorySlot>());
        expect(AccessorySlot.necklace, isA<AccessorySlot>());
        expect(AccessorySlot.watch, isA<AccessorySlot>());
      });
    });

    valueObjectTest(
      constructor:
          (
            ({
              AccessorySlot slot,
              AtlasFrameName atlasFrame,
              String displayName,
            })
            props,
          ) => Accessory(
            slot: props.slot,
            atlasFrame: props.atlasFrame,
            displayName: props.displayName,
          ),
      generator: () => (
        slot: AccessorySlot.glasses,
        atlasFrame: AtlasFrameName(value: 'glasses_01'),
        displayName: 'Stylish Glasses',
      ),
      variations:
          (
            ({
              AccessorySlot slot,
              AtlasFrameName atlasFrame,
              String displayName,
            })
            props,
          ) => [
            (
              slot: AccessorySlot.hat,
              atlasFrame: props.atlasFrame,
              displayName: props.displayName,
            ),
            (
              slot: props.slot,
              atlasFrame: AtlasFrameName(value: 'glasses_02'),
              displayName: props.displayName,
            ),
            (
              slot: props.slot,
              atlasFrame: props.atlasFrame,
              displayName: 'Cool Glasses',
            ),
          ],
      invalids:
          (
            ({
              AccessorySlot slot,
              AtlasFrameName atlasFrame,
              String displayName,
            })
            props,
          ) => [
            (slot: props.slot, atlasFrame: props.atlasFrame, displayName: ''),
            (
              slot: props.slot,
              atlasFrame: props.atlasFrame,
              displayName: 'A' * (Accessory.displayNameMaxLength + 1),
            ),
          ],
    );

    group('OutfitVariant', () {
      group('instantiate', () {
        group('successfully with', () {
          test('matching accessory slots.', () {
            final accessories = <AccessorySlot, Accessory>{
              AccessorySlot.glasses: Accessory(
                slot: AccessorySlot.glasses,
                atlasFrame: AtlasFrameName(value: 'glasses_01'),
                displayName: 'Glasses',
              ),
            };

            final variant = OutfitVariant(
              binding: Builder(
                CharacterAnimationBindingFactory(),
              ).buildWith(seed: 1).binding,
              palette: PaletteIdentifier.generate(),
              atlasFrame: AtlasFrameName(value: 'outfit_01'),
              accessories: accessories,
            );

            expect(variant.accessories.length, equals(1));
          });
        });

        group('unsuccessfully with', () {
          test('mismatched accessory slot key and value.', () {
            final accessories = <AccessorySlot, Accessory>{
              AccessorySlot.glasses: Accessory(
                slot: AccessorySlot.hat,
                atlasFrame: AtlasFrameName(value: 'hat_01'),
                displayName: 'Hat',
              ),
            };

            expect(
              () => OutfitVariant(
                binding: Builder(
                  CharacterAnimationBindingFactory(),
                ).buildWith(seed: 1).binding,
                palette: PaletteIdentifier.generate(),
                atlasFrame: AtlasFrameName(value: 'outfit_01'),
                accessories: accessories,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });

      group('getAccessory', () {
        test('returns accessory for slot.', () {
          final accessory = Accessory(
            slot: AccessorySlot.glasses,
            atlasFrame: AtlasFrameName(value: 'glasses_01'),
            displayName: 'Glasses',
          );

          final variant = OutfitVariant(
            binding: Builder(
              CharacterAnimationBindingFactory(),
            ).buildWith(seed: 1).binding,
            palette: PaletteIdentifier.generate(),
            atlasFrame: AtlasFrameName(value: 'outfit_01'),
            accessories: {AccessorySlot.glasses: accessory},
          );

          final result = variant.getAccessory(AccessorySlot.glasses);

          expect(result, equals(accessory));
        });

        test('returns null for empty slot.', () {
          final variant = OutfitVariant(
            binding: Builder(
              CharacterAnimationBindingFactory(),
            ).buildWith(seed: 1).binding,
            palette: PaletteIdentifier.generate(),
            atlasFrame: AtlasFrameName(value: 'outfit_01'),
            accessories: {},
          );

          final result = variant.getAccessory(AccessorySlot.glasses);

          expect(result, isNull);
        });
      });

      group('putOn', () {
        test('adds new accessory.', () {
          final variant = OutfitVariant(
            binding: Builder(
              CharacterAnimationBindingFactory(),
            ).buildWith(seed: 1).binding,
            palette: PaletteIdentifier.generate(),
            atlasFrame: AtlasFrameName(value: 'outfit_01'),
            accessories: {},
          );

          final accessory = Accessory(
            slot: AccessorySlot.glasses,
            atlasFrame: AtlasFrameName(value: 'glasses_01'),
            displayName: 'Glasses',
          );

          final newVariant = variant.putOn(accessory);

          expect(newVariant.accessories.length, equals(1));
          expect(
            newVariant.accessories[AccessorySlot.glasses],
            equals(accessory),
          );
        });

        test('replaces existing accessory in same slot.', () {
          final oldAccessory = Accessory(
            slot: AccessorySlot.glasses,
            atlasFrame: AtlasFrameName(value: 'glasses_01'),
            displayName: 'Old Glasses',
          );

          final variant = OutfitVariant(
            binding: Builder(
              CharacterAnimationBindingFactory(),
            ).buildWith(seed: 1).binding,
            palette: PaletteIdentifier.generate(),
            atlasFrame: AtlasFrameName(value: 'outfit_01'),
            accessories: {AccessorySlot.glasses: oldAccessory},
          );

          final newAccessory = Accessory(
            slot: AccessorySlot.glasses,
            atlasFrame: AtlasFrameName(value: 'glasses_02'),
            displayName: 'New Glasses',
          );

          final newVariant = variant.putOn(newAccessory);

          expect(newVariant.accessories.length, equals(1));
          expect(
            newVariant.accessories[AccessorySlot.glasses],
            equals(newAccessory),
          );
        });
      });

      group('takeOff', () {
        test('removes accessory.', () {
          final accessory = Accessory(
            slot: AccessorySlot.glasses,
            atlasFrame: AtlasFrameName(value: 'glasses_01'),
            displayName: 'Glasses',
          );

          final variant = OutfitVariant(
            binding: Builder(
              CharacterAnimationBindingFactory(),
            ).buildWith(seed: 1).binding,
            palette: PaletteIdentifier.generate(),
            atlasFrame: AtlasFrameName(value: 'outfit_01'),
            accessories: {AccessorySlot.glasses: accessory},
          );

          final newVariant = variant.takeOff(AccessorySlot.glasses);

          expect(newVariant.accessories.length, equals(0));
        });

        test('returns same instance if slot is empty.', () {
          final variant = OutfitVariant(
            binding: Builder(
              CharacterAnimationBindingFactory(),
            ).buildWith(seed: 1).binding,
            palette: PaletteIdentifier.generate(),
            atlasFrame: AtlasFrameName(value: 'outfit_01'),
            accessories: {},
          );

          final newVariant = variant.takeOff(AccessorySlot.glasses);

          expect(identical(variant, newVariant), isTrue);
        });
      });
    });

    group('WardrobeMap', () {
      group('instantiate', () {
        group('successfully with', () {
          test('all day periods.', () {
            final outfits = {
              for (final period in DayPeriod.values)
                period: Builder(OutfitVariantFactory()).buildWith(seed: 1),
            };

            final wardrobeMap = WardrobeMap(outfits: outfits);

            expect(wardrobeMap, isA<WardrobeMap>());
          });
        });

        group('unsuccessfully with', () {
          test('missing day periods.', () {
            final outfits = {
              DayPeriod.morning: Builder(
                OutfitVariantFactory(),
              ).buildWith(seed: 1),
            };

            expect(
              () => WardrobeMap(outfits: outfits),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });

      group('resolve', () {
        test('returns outfit for period.', () {
          final morningOutfit = Builder(
            OutfitVariantFactory(),
          ).buildWith(seed: 1);
          final outfits = {
            for (final period in DayPeriod.values)
              period: period == DayPeriod.morning
                  ? morningOutfit
                  : Builder(OutfitVariantFactory()).buildWith(seed: 2),
          };

          final wardrobeMap = WardrobeMap(outfits: outfits);

          final result = wardrobeMap.resolve(DayPeriod.morning);

          expect(result, equals(morningOutfit));
        });
      });

      group('equals', () {
        test('returns true with same outfits.', () {
          final outfits = {
            for (final period in DayPeriod.values)
              period: Builder(OutfitVariantFactory()).buildWith(seed: 1),
          };

          final instance1 = WardrobeMap(outfits: outfits);
          final instance2 = WardrobeMap(outfits: outfits);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different outfits.', () {
          final outfits1 = {
            for (final period in DayPeriod.values)
              period: Builder(OutfitVariantFactory()).buildWith(seed: 1),
          };

          final outfits2 = {
            for (final period in DayPeriod.values)
              period: Builder(OutfitVariantFactory()).buildWith(seed: 2),
          };

          final instance1 = WardrobeMap(outfits: outfits1);
          final instance2 = WardrobeMap(outfits: outfits2);

          expect(instance1 == instance2, isFalse);
        });
      });
    });
  });
}
