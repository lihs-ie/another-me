import 'package:another_me/domains/avatar/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/avatar/animation.dart';
import '../../../supports/factories/common.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/avatar/animation', () {
    ulidBasedIdentifierTest<CharacterAnimationBindingIdentifier, Ulid>(
      constructor: (Ulid value) =>
          CharacterAnimationBindingIdentifier(value: value),
      generate: CharacterAnimationBindingIdentifier.generate,
      fromString: CharacterAnimationBindingIdentifier.fromString,
      fromBinary: CharacterAnimationBindingIdentifier.fromBinary,
    );

    group('CharacterAnimationTag', () {
      test('declares all defined enumerators.', () {
        expect(CharacterAnimationTag.typing, isA<CharacterAnimationTag>());
        expect(CharacterAnimationTag.coffee, isA<CharacterAnimationTag>());
        expect(CharacterAnimationTag.idle, isA<CharacterAnimationTag>());
        expect(CharacterAnimationTag.preview, isA<CharacterAnimationTag>());
      });
    });

    valueObjectTest(
      constructor:
          (
            ({
              CharacterAnimationBindingIdentifier binding,
              CharacterAnimationTag tag,
              int playbackOrder,
            })
            props,
          ) => CharacterAnimationBinding(
            binding: props.binding,
            tag: props.tag,
            playbackOrder: props.playbackOrder,
          ),
      generator: () => (
        binding: Builder(
          CharacterAnimationBindingIdentifierFactory(),
        ).buildWith(seed: 1),
        tag: CharacterAnimationTag.typing,
        playbackOrder: 1,
      ),
      variations:
          (
            ({
              CharacterAnimationBindingIdentifier binding,
              CharacterAnimationTag tag,
              int playbackOrder,
            })
            props,
          ) => [
            (
              binding: Builder(
                CharacterAnimationBindingIdentifierFactory(),
              ).buildWith(seed: 2),
              tag: props.tag,
              playbackOrder: props.playbackOrder,
            ),
            (
              binding: props.binding,
              tag: CharacterAnimationTag.coffee,
              playbackOrder: props.playbackOrder,
            ),
            (
              binding: props.binding,
              tag: props.tag,
              playbackOrder: props.playbackOrder + 1,
            ),
          ],
      invalids:
          (
            ({
              CharacterAnimationBindingIdentifier binding,
              CharacterAnimationTag tag,
              int playbackOrder,
            })
            props,
          ) => [(binding: props.binding, tag: props.tag, playbackOrder: -1)],
    );
  });
}
