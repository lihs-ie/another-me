import 'dart:typed_data';

import 'package:another_me/domains/avatar/animation.dart';
import 'package:another_me/domains/avatar/wardrobe.dart';
import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:ulid/ulid.dart';

class CharacterIdentifier extends ULIDBasedIdentifier {
  CharacterIdentifier({required Ulid value}) : super(value);

  factory CharacterIdentifier.generate() => CharacterIdentifier(value: Ulid());

  factory CharacterIdentifier.fromString(String value) =>
      CharacterIdentifier(value: Ulid.parse(value));

  factory CharacterIdentifier.fromBinary(Uint8List bytes) =>
      CharacterIdentifier(value: Ulid.fromBytes(bytes));
}

enum CharacterStatus { active, deprecated, locked }

class Color implements ValueObject {
  final int red;
  final int green;
  final int blue;
  final int alpha;

  static const String rawHexPattern = r'^[0-9a-fA-F]{8}$';

  Color({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  }) {
    Invariant.range(value: red, name: 'red', min: 0, max: 255);
    Invariant.range(value: green, name: 'green', min: 0, max: 255);
    Invariant.range(value: blue, name: 'blue', min: 0, max: 255);
    Invariant.range(value: alpha, name: 'alpha', min: 0, max: 255);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Color) {
      return false;
    }

    if (red != other.red) {
      return false;
    }

    if (green != other.green) {
      return false;
    }

    if (blue != other.blue) {
      return false;
    }

    if (alpha != other.alpha) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  String toRawHex() {
    return '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}'
        '${alpha.toRadixString(16).padLeft(2, '0')}';
  }

  factory Color.fromRawHex(String hex) {
    Invariant.pattern(value: hex, name: 'hex', pattern: rawHexPattern);

    final red = int.parse(hex.substring(0, 2), radix: 16);
    final green = int.parse(hex.substring(2, 4), radix: 16);
    final blue = int.parse(hex.substring(4, 6), radix: 16);
    final alpha = int.parse(hex.substring(6, 8), radix: 16);

    return Color(red: red, green: green, blue: blue, alpha: alpha);
  }
}

class ColorPalette implements ValueObject {
  final Set<Color> colors;

  static const maxColorsCount = 24;

  ColorPalette({required this.colors}) {
    Invariant.range(
      value: colors.length,
      name: 'Colors count',
      min: 1,
      max: maxColorsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! ColorPalette) {
      return false;
    }

    if (colors.length != other.colors.length) {
      return false;
    }

    if (!colors.containsAll(other.colors)) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(colors);
}

class CharacterEvent extends BaseEvent {
  CharacterEvent({required DateTime occurredAt}) : super(occurredAt);
}

class CharacterRegistered extends CharacterEvent {
  final CharacterIdentifier identifier;
  final List<CharacterAnimationBindingIdentifier> bindings;
  final List<PaletteIdentifier> palettes;
  final CharacterStatus status;

  CharacterRegistered({
    required super.occurredAt,
    required this.identifier,
    required this.bindings,
    required this.palettes,
    required this.status,
  });
}

class CharacterUpdated extends CharacterEvent {
  final CharacterIdentifier character;
  final List<CharacterAnimationBindingIdentifier>? updatedBindings;
  final List<PaletteIdentifier>? updatedPalettes;

  CharacterUpdated({
    required super.occurredAt,
    required this.character,
    this.updatedBindings,
    this.updatedPalettes,
  });
}

class CharacterDeprecated extends CharacterEvent {
  final CharacterIdentifier character;
  final String reason;

  CharacterDeprecated({
    required super.occurredAt,
    required this.character,
    required this.reason,
  });
}

class CharacterUnlocked extends CharacterEvent {
  final CharacterIdentifier character;
  final String unlockSource;

  CharacterUnlocked({
    required super.occurredAt,
    required this.character,
    required this.unlockSource,
  });
}

class CharacterOutfitApplied extends CharacterEvent {
  final CharacterIdentifier character;
  final DayPeriod dayPeriod;
  final PaletteIdentifier palette;

  CharacterOutfitApplied({
    required super.occurredAt,
    required this.character,
    required this.palette,
    required this.dayPeriod,
  });
}

class Character with Publishable<CharacterEvent> {
  final CharacterIdentifier identifier;
  final String _displayName;
  final List<CharacterAnimationBinding> _bindings;
  WardrobeMap _wardrobes;
  final ColorPalette _palette;
  CharacterStatus _status;

  Character({
    required this.identifier,
    required String displayName,
    required List<CharacterAnimationBinding> bindings,
    required WardrobeMap wardrobes,
    required ColorPalette palette,
    required CharacterStatus status,
  }) : _displayName = displayName,
       _bindings = List.unmodifiable(bindings),
       _wardrobes = wardrobes,
       _palette = palette,
       _status = status {
    final requireTags = <CharacterAnimationTag>{};
    final playbackOrders = <int>{};

    for (final binding in bindings) {
      if (binding.tag == CharacterAnimationTag.typing ||
          binding.tag == CharacterAnimationTag.coffee) {
        requireTags.add(binding.tag);
      }

      playbackOrders.add(binding.playbackOrder);
    }

    if (requireTags.length != 2) {
      throw InvariantViolationError(
        'Character must have bindings with tags: $requireTags',
      );
    }

    if (playbackOrders.length != bindings.length) {
      throw InvariantViolationError(
        'Character bindings must have unique playback orders',
      );
    }
  }

  String get displayName => _displayName;

  List<CharacterAnimationBinding> get bindings => _bindings;

  WardrobeMap get wardrobes => _wardrobes;

  ColorPalette get palette => _palette;

  CharacterStatus get status => _status;

  void updateWardrobe(WardrobeMap next) {
    _wardrobes = next;

    publish(
      CharacterUpdated(
        occurredAt: DateTime.now(),
        character: identifier,
        updatedPalettes: null,
        updatedBindings: null,
      ),
    );
  }

  void deprecate(String reason) {
    _status = CharacterStatus.deprecated;

    publish(
      CharacterDeprecated(
        occurredAt: DateTime.now(),
        character: identifier,
        reason: reason,
      ),
    );
  }

  void unlock(String source) {
    _status = CharacterStatus.active;

    publish(
      CharacterUnlocked(
        occurredAt: DateTime.now(),
        character: identifier,
        unlockSource: source,
      ),
    );
  }
}

abstract interface class CharacterRepository {
  Future<Character> find(CharacterIdentifier identifier);
  Future<List<Character>> all();
  Future<List<Character>> search(CharacterSearchCriteria criteria);
  Future<void> persist(Character character);
}

class CharacterSearchCriteria implements ValueObject {
  final Set<CharacterStatus>? statuses;
  final Set<CharacterAnimationTag>? tags;

  CharacterSearchCriteria({this.statuses, this.tags});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! CharacterSearchCriteria) {
      return false;
    }

    if (statuses != null) {
      if (statuses != other.statuses) {
        return false;
      }
    } else if (other.statuses != null) {
      return false;
    }

    if (tags != null) {
      if (tags != other.tags) {
        return false;
      }
    } else if (other.tags != null) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(statuses, tags);
}

class DayPeriodChangedSubscriber implements EventSubscriber {
  @override
  void subscribe(EventBroker broker) {}

  void Function(DayPeriodChanged event) _onDayPeriodChanged(
    EventBroker broker,
  ) {
    return (DayPeriodChanged event) {};
  }
}
