import 'package:another_me/domains/avatar/animation.dart';
import 'package:ulid/ulid.dart';

import '../common.dart';
import '../common/identifier.dart';
import '../enum.dart';

class CharacterAnimationBindingIdentifierFactory
    extends ULIDBasedIdentifierFactory<CharacterAnimationBindingIdentifier> {
  CharacterAnimationBindingIdentifierFactory()
    : super((Ulid value) => CharacterAnimationBindingIdentifier(value: value));
}

class CharacterAnimationTagFactory extends EnumFactory<CharacterAnimationTag> {
  CharacterAnimationTagFactory() : super(CharacterAnimationTag.values);
}

typedef CharacterAnimationBindingOverrides = ({
  CharacterAnimationBindingIdentifier? binding,
  CharacterAnimationTag? tag,
  int? playbackOrder,
});

class CharacterAnimationBindingFactory
    extends
        Factory<CharacterAnimationBinding, CharacterAnimationBindingOverrides> {
  @override
  CharacterAnimationBinding create({
    CharacterAnimationBindingOverrides? overrides,
    required int seed,
  }) {
    final binding =
        overrides?.binding ??
        Builder(
          CharacterAnimationBindingIdentifierFactory(),
        ).buildWith(seed: seed);
    final tag =
        overrides?.tag ??
        Builder(CharacterAnimationTagFactory()).buildWith(seed: seed);
    final playbackOrder = overrides?.playbackOrder ?? (seed % 100);

    return CharacterAnimationBinding(
      binding: binding,
      tag: tag,
      playbackOrder: playbackOrder,
    );
  }

  @override
  CharacterAnimationBinding duplicate(
    CharacterAnimationBinding instance,
    CharacterAnimationBindingOverrides? overrides,
  ) {
    final binding =
        overrides?.binding ??
        Builder(
          CharacterAnimationBindingIdentifierFactory(),
        ).duplicate(instance: instance.binding, overrides: null);
    final tag =
        overrides?.tag ??
        Builder(
          CharacterAnimationTagFactory(),
        ).duplicate(instance: instance.tag, overrides: null);
    final playbackOrder = overrides?.playbackOrder ?? instance.playbackOrder;

    return CharacterAnimationBinding(
      binding: binding,
      tag: tag,
      playbackOrder: playbackOrder,
    );
  }
}
