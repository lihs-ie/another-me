import 'dart:typed_data';

import 'package:another_me/domains/avatar/animation.dart';
import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:ulid/ulid.dart';

class PaletteIdentifier extends ULIDBasedIdentifier {
  PaletteIdentifier({required Ulid value}) : super(value);

  factory PaletteIdentifier.generate() => PaletteIdentifier(value: Ulid());

  factory PaletteIdentifier.fromString(String value) =>
      PaletteIdentifier(value: Ulid.parse(value));

  factory PaletteIdentifier.fromBinary(Uint8List bytes) =>
      PaletteIdentifier(value: Ulid.fromBytes(bytes));
}

class AtlasFrameName implements ValueObject {
  final String value;
  static const String pattern = r'^[a-z][a-z0-9_]*$';

  AtlasFrameName({required this.value}) {
    Invariant.length(value: value, name: 'value', min: 1, max: 100);
    Invariant.pattern(value: value, name: 'value', pattern: pattern);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AtlasFrameName) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

enum AccessorySlot { glasses, hat, scarf, earrings, necklace, watch }

enum OutfitMode { auto, manual }

class Accessory implements ValueObject {
  static const int displayNameMaxLength = 50;

  final AccessorySlot slot;
  final AtlasFrameName atlasFrame;
  final String displayName;

  Accessory({
    required this.slot,
    required this.atlasFrame,
    required this.displayName,
  }) {
    Invariant.length(
      value: displayName,
      name: 'displayName',
      min: 1,
      max: displayNameMaxLength,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Accessory) {
      return false;
    }

    if (slot != other.slot) {
      return false;
    }

    if (atlasFrame != other.atlasFrame) {
      return false;
    }

    if (displayName != other.displayName) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode {
    return Object.hash(slot, atlasFrame, displayName);
  }
}

class OutfitVariant implements ValueObject {
  final CharacterAnimationBindingIdentifier binding;
  final PaletteIdentifier palette;
  final AtlasFrameName atlasFrame;
  final Map<AccessorySlot, Accessory> accessories;

  OutfitVariant({
    required this.binding,
    required this.palette,
    required this.atlasFrame,
    required this.accessories,
  }) {
    for (final entry in accessories.entries) {
      if (entry.key != entry.value.slot) {
        throw InvariantViolationError(
          'Accessory slot key (${entry.key}) does not match accessory slot (${entry.value.slot})',
        );
      }
    }
  }

  Accessory? getAccessory(AccessorySlot slot) {
    return accessories[slot];
  }

  OutfitVariant putOn(Accessory accessory) {
    final next = Map<AccessorySlot, Accessory>.unmodifiable({
      ...accessories,
      accessory.slot: accessory,
    });

    return OutfitVariant(
      binding: binding,
      palette: palette,
      atlasFrame: atlasFrame,
      accessories: next,
    );
  }

  OutfitVariant takeOff(AccessorySlot slot) {
    if (!accessories.containsKey(slot)) {
      return this;
    }

    final next = Map<AccessorySlot, Accessory>.from(accessories);
    next.remove(slot);

    return OutfitVariant(
      binding: binding,
      palette: palette,
      atlasFrame: atlasFrame,
      accessories: Map.unmodifiable(next),
    );
  }
}

class WardrobeMap implements ValueObject {
  final Map<DayPeriod, OutfitVariant> _outfits;

  WardrobeMap({required Map<DayPeriod, OutfitVariant> outfits})
    : _outfits = Map.unmodifiable(outfits) {
    if (_outfits.length != DayPeriod.values.length) {
      throw InvariantViolationError(
        'Outfits must contain all DayPeriod values',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! WardrobeMap) {
      return false;
    }

    for (final entry in _outfits.entries) {
      final otherValue = other._outfits[entry.key];

      if (otherValue == null || entry.value != otherValue) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    return Object.hashAll(
      _outfits.entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
  }

  OutfitVariant resolve(DayPeriod period) {
    return _outfits[period]!;
  }
}
