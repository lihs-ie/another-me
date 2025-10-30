import 'dart:typed_data';

import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:ulid/ulid.dart';

class CharacterAnimationBindingIdentifier extends ULIDBasedIdentifier {
  CharacterAnimationBindingIdentifier({required Ulid value}) : super(value);

  factory CharacterAnimationBindingIdentifier.generate() =>
      CharacterAnimationBindingIdentifier(value: Ulid());

  factory CharacterAnimationBindingIdentifier.fromString(String value) =>
      CharacterAnimationBindingIdentifier(value: Ulid.parse(value));

  factory CharacterAnimationBindingIdentifier.fromBinary(Uint8List bytes) =>
      CharacterAnimationBindingIdentifier(value: Ulid.fromBytes(bytes));
}

enum CharacterAnimationTag { typing, coffee, idle, preview }

class CharacterAnimationBinding implements ValueObject {
  final CharacterAnimationBindingIdentifier binding;
  final CharacterAnimationTag tag;
  final int playbackOrder;

  CharacterAnimationBinding({
    required this.binding,
    required this.tag,
    required this.playbackOrder,
  }) {
    Invariant.range(value: playbackOrder, name: 'playbackOrder', min: 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! CharacterAnimationBinding) {
      return false;
    }

    if (binding != other.binding) {
      return false;
    }

    if (tag != other.tag) {
      return false;
    }

    if (playbackOrder != other.playbackOrder) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(binding, tag, playbackOrder);
}
