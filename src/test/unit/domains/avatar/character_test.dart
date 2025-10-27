import 'package:another_me/domains/avatar/avatar.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/avatar/animation.dart';
import '../../../supports/factories/avatar/character.dart';
import '../../../supports/factories/avatar/wardrobe.dart';
import '../../../supports/factories/common.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/avatar/character', () {
    ulidBasedIdentifierTest<CharacterIdentifier, Ulid>(
      constructor: (Ulid value) => CharacterIdentifier(value: value),
      generate: CharacterIdentifier.generate,
      fromString: CharacterIdentifier.fromString,
      fromBinary: CharacterIdentifier.fromBinary,
    );

    group('CharacterStatus', () {
      test('declares all defined enumerators.', () {
        expect(CharacterStatus.active, isA<CharacterStatus>());
        expect(CharacterStatus.deprecated, isA<CharacterStatus>());
        expect(CharacterStatus.locked, isA<CharacterStatus>());
      });
    });

    valueObjectTest(
      constructor: (({int red, int green, int blue, int alpha}) props) => Color(
        red: props.red,
        green: props.green,
        blue: props.blue,
        alpha: props.alpha,
      ),
      generator: () => (red: 128, green: 64, blue: 32, alpha: 255),
      variations: (({int red, int green, int blue, int alpha}) props) => [
        (
          red: props.red + 1,
          green: props.green,
          blue: props.blue,
          alpha: props.alpha,
        ),
        (
          red: props.red,
          green: props.green + 1,
          blue: props.blue,
          alpha: props.alpha,
        ),
        (
          red: props.red,
          green: props.green,
          blue: props.blue + 1,
          alpha: props.alpha,
        ),
        (
          red: props.red,
          green: props.green,
          blue: props.blue,
          alpha: props.alpha - 1,
        ),
      ],
      invalids: (({int red, int green, int blue, int alpha}) props) => [
        (red: -1, green: props.green, blue: props.blue, alpha: props.alpha),
        (red: 256, green: props.green, blue: props.blue, alpha: props.alpha),
        (red: props.red, green: -1, blue: props.blue, alpha: props.alpha),
        (red: props.red, green: 256, blue: props.blue, alpha: props.alpha),
        (red: props.red, green: props.green, blue: -1, alpha: props.alpha),
        (red: props.red, green: props.green, blue: 256, alpha: props.alpha),
        (red: props.red, green: props.green, blue: props.blue, alpha: -1),
        (red: props.red, green: props.green, blue: props.blue, alpha: 256),
      ],
      additionalTests: () {
        group('toRawHex', () {
          test('returns hex string.', () {
            final color = Color(red: 255, green: 128, blue: 64, alpha: 32);
            final hex = color.toRawHex();

            expect(hex, equals('ff804020'));
          });

          test('pads zeros correctly.', () {
            final color = Color(red: 0, green: 1, blue: 15, alpha: 16);
            final hex = color.toRawHex();

            expect(hex, equals('00010f10'));
          });
        });

        group('fromRawHex', () {
          group('successfully with', () {
            final valids = [
              (
                input: '00000000',
                expected: (red: 0, green: 0, blue: 0, alpha: 0),
              ),
              (
                input: 'ff804020',
                expected: (red: 255, green: 128, blue: 64, alpha: 32),
              ),
              (
                input: 'ABCDEF12',
                expected: (red: 171, green: 205, blue: 239, alpha: 18),
              ),
            ];

            for (final valid in valids) {
              test('input: "${valid.input}".', () {
                final color = Color.fromRawHex(valid.input);

                expect(color.red, equals(valid.expected.red));
                expect(color.green, equals(valid.expected.green));
                expect(color.blue, equals(valid.expected.blue));
                expect(color.alpha, equals(valid.expected.alpha));
              });
            }
          });

          group('unsuccessfully with', () {
            final invalids = [
              (input: ''),
              (input: '1234567'),
              (input: '123456789'),
              (input: 'GHIJKLMN'),
            ];

            for (final invalid in invalids) {
              test('input: "${invalid.input}".', () {
                expect(
                  () => Color.fromRawHex(invalid.input),
                  throwsA(isA<Object>()),
                );
              });
            }
          });
        });
      },
    );

    valueObjectTest(
      constructor: (({Set<Color> colors}) props) =>
          ColorPalette(colors: props.colors),
      generator: () => (
        colors: Builder(
          ColorFactory(),
        ).buildListWith(count: 3, seed: 1).toSet(),
      ),
      variations: (({Set<Color> colors}) props) => [
        (
          colors: Builder(
            ColorFactory(),
          ).buildListWith(count: 4, seed: 2).toSet(),
        ),
        (
          colors: {
            ...props.colors,
            Builder(ColorFactory()).buildWith(seed: 999),
          },
        ),
      ],
      invalids: (({Set<Color> colors}) props) => [
        (colors: <Color>{}),
        (
          colors: Builder(ColorFactory())
              .buildListWith(count: ColorPalette.maxColorsCount + 1, seed: 100)
              .toSet(),
        ),
      ],
    );

    group('Character', () {
      group('instantiate', () {
        group('successfully with', () {
          test('valid bindings with typing and coffee tags.', () {
            final bindings = [
              Builder(CharacterAnimationBindingFactory()).buildWith(
                seed: 1,
                overrides: (
                  binding: null,
                  tag: CharacterAnimationTag.typing,
                  playbackOrder: 1,
                ),
              ),
              Builder(CharacterAnimationBindingFactory()).buildWith(
                seed: 2,
                overrides: (
                  binding: null,
                  tag: CharacterAnimationTag.coffee,
                  playbackOrder: 2,
                ),
              ),
            ];

            final character = Character(
              identifier: CharacterIdentifier.generate(),
              displayName: 'Test Character',
              bindings: bindings,
              wardrobes: Builder(WardrobeMapFactory()).buildWith(seed: 1),
              palette: Builder(ColorPaletteFactory()).buildWith(seed: 1),
              status: CharacterStatus.active,
            );

            expect(character.bindings.length, equals(2));
            expect(character.status, equals(CharacterStatus.active));
          });
        });

        group('unsuccessfully with', () {
          test('missing typing tag.', () {
            final bindings = [
              Builder(CharacterAnimationBindingFactory()).buildWith(
                seed: 1,
                overrides: (
                  binding: null,
                  tag: CharacterAnimationTag.coffee,
                  playbackOrder: 1,
                ),
              ),
            ];

            expect(
              () => Character(
                identifier: CharacterIdentifier.generate(),
                displayName: 'Test Character',
                bindings: bindings,
                wardrobes: Builder(WardrobeMapFactory()).buildWith(seed: 1),
                palette: Builder(ColorPaletteFactory()).buildWith(seed: 1),
                status: CharacterStatus.active,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('missing coffee tag.', () {
            final bindings = [
              Builder(CharacterAnimationBindingFactory()).buildWith(
                seed: 1,
                overrides: (
                  binding: null,
                  tag: CharacterAnimationTag.typing,
                  playbackOrder: 1,
                ),
              ),
            ];

            expect(
              () => Character(
                identifier: CharacterIdentifier.generate(),
                displayName: 'Test Character',
                bindings: bindings,
                wardrobes: Builder(WardrobeMapFactory()).buildWith(seed: 1),
                palette: Builder(ColorPaletteFactory()).buildWith(seed: 1),
                status: CharacterStatus.active,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('duplicate playback orders.', () {
            final bindings = [
              Builder(CharacterAnimationBindingFactory()).buildWith(
                seed: 1,
                overrides: (
                  binding: null,
                  tag: CharacterAnimationTag.typing,
                  playbackOrder: 1,
                ),
              ),
              Builder(CharacterAnimationBindingFactory()).buildWith(
                seed: 2,
                overrides: (
                  binding: null,
                  tag: CharacterAnimationTag.coffee,
                  playbackOrder: 1,
                ),
              ),
            ];

            expect(
              () => Character(
                identifier: CharacterIdentifier.generate(),
                displayName: 'Test Character',
                bindings: bindings,
                wardrobes: Builder(WardrobeMapFactory()).buildWith(seed: 1),
                palette: Builder(ColorPaletteFactory()).buildWith(seed: 1),
                status: CharacterStatus.active,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });

      group('updateWardrobe', () {
        test('updates wardrobe and publishes CharacterUpdated event.', () {
          final character = Builder(CharacterFactory()).buildWith(seed: 1);
          final newWardrobe = Builder(
            WardrobeMapFactory(),
          ).buildWith(seed: 999);

          character.updateWardrobe(newWardrobe);

          expect(character.wardrobes, equals(newWardrobe));

          final events = character.events();
          expect(events.length, equals(1));
          expect(events.first, isA<CharacterUpdated>());

          final event = events.first as CharacterUpdated;
          expect(event.character, equals(character.identifier));
        });
      });

      group('deprecate', () {
        test(
          'changes status to deprecated and publishes CharacterDeprecated event.',
          () {
            final character = Builder(CharacterFactory()).buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                displayName: null,
                bindings: null,
                wardrobes: null,
                palette: null,
                status: CharacterStatus.active,
              ),
            );

            final reason = 'Outdated design';
            character.deprecate(reason);

            expect(character.status, equals(CharacterStatus.deprecated));

            final events = character.events();
            expect(events.length, equals(1));
            expect(events.first, isA<CharacterDeprecated>());

            final event = events.first as CharacterDeprecated;
            expect(event.character, equals(character.identifier));
            expect(event.reason, equals(reason));
          },
        );
      });

      group('unlock', () {
        test(
          'changes status to active and publishes CharacterUnlocked event.',
          () {
            final character = Builder(CharacterFactory()).buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                displayName: null,
                bindings: null,
                wardrobes: null,
                palette: null,
                status: CharacterStatus.locked,
              ),
            );

            final source = 'Purchase';
            character.unlock(source);

            expect(character.status, equals(CharacterStatus.active));

            final events = character.events();
            expect(events.length, equals(1));
            expect(events.first, isA<CharacterUnlocked>());

            final event = events.first as CharacterUnlocked;
            expect(event.character, equals(character.identifier));
            expect(event.unlockSource, equals(source));
          },
        );
      });
    });

    valueObjectTest(
      constructor:
          (
            ({Set<CharacterStatus>? statuses, Set<CharacterAnimationTag>? tags})
            props,
          ) => CharacterSearchCriteria(
            statuses: props.statuses,
            tags: props.tags,
          ),
      generator: () => (
        statuses: {CharacterStatus.active},
        tags: {CharacterAnimationTag.typing},
      ),
      variations:
          (
            ({Set<CharacterStatus>? statuses, Set<CharacterAnimationTag>? tags})
            props,
          ) => [
            (statuses: {CharacterStatus.deprecated}, tags: props.tags),
            (statuses: props.statuses, tags: {CharacterAnimationTag.coffee}),
            (statuses: null, tags: props.tags),
            (statuses: props.statuses, tags: null),
            (statuses: null, tags: null),
          ],
      invalids:
          (
            ({Set<CharacterStatus>? statuses, Set<CharacterAnimationTag>? tags})
            props,
          ) => [],
    );
  });
}
