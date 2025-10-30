import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/animation/atlas.dart';
import 'package:another_me/domains/library/animation/binding.dart';
import 'package:another_me/domains/library/animation/timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import 'identifier.dart';
import '../../common/value_object.dart';

void main() {
  group('Package domains/library/animation/binding', () {
    ulidBasedIdentifierTest<AnimationBindingIdentifier, Ulid>(
      constructor: (Ulid value) => AnimationBindingIdentifier(value: value),
      generate: AnimationBindingIdentifier.generate,
      fromString: AnimationBindingIdentifier.fromString,
      fromBinary: AnimationBindingIdentifier.fromBinary,
    );

    group('AnimationBindingTag', () {
      test('declares all defined enumerators.', () {
        expect(AnimationBindingTag.typing, isA<AnimationBindingTag>());
        expect(AnimationBindingTag.coffee, isA<AnimationBindingTag>());
        expect(AnimationBindingTag.ambient, isA<AnimationBindingTag>());
        expect(AnimationBindingTag.wardrobe, isA<AnimationBindingTag>());
      });
    });

    valueObjectTest(
      constructor: (({int start, int end}) props) =>
          FrameRange(start: props.start, end: props.end),
      generator: () => (start: 0, end: 10),
      variations: (({int start, int end}) props) => [
        (start: props.start + 5, end: props.end),
        (start: props.start, end: props.end + 5),
      ],
      invalids: (({int start, int end}) props) => [
        (start: -1, end: props.end),
        (start: props.start, end: -1),
        (start: props.end + 1, end: props.start),
      ],
    );

    group('AnimationBindingManifest', () {
      group('instantiate', () {
        group('successfully with', () {
          final valids = [
            (
              frameRange: FrameRange(start: 0, end: 9),
              frameCount: 10,
              tags: {AnimationBindingTag.typing},
            ),
            (
              frameRange: FrameRange(start: 0, end: 23),
              frameCount: 24,
              tags: {AnimationBindingTag.typing, AnimationBindingTag.coffee},
            ),
          ];

          for (final valid in valids) {
            test(
              'frameRange: (${valid.frameRange.start}, ${valid.frameRange.end}), frameCount: ${valid.frameCount}, tags: ${valid.tags.length}.',
              () {
                final instance = AnimationBindingManifest(
                  identifier: AnimationBindingIdentifier.generate(),
                  timeline: TimelineIdentifier.generate(),
                  spriteAtlas: SpriteAtlasIdentifier.generate(),
                  frameRange: valid.frameRange,
                  frameCount: valid.frameCount,
                  tags: valid.tags,
                );

                expect(instance.frameRange, equals(valid.frameRange));
                expect(instance.frameCount, equals(valid.frameCount));
                expect(instance.tags, equals(valid.tags));
              },
            );
          }
        });

        group('unsuccessfully with', () {
          final invalids = [
            (
              frameRange: FrameRange(start: 0, end: 10),
              frameCount: 10,
              tags: {AnimationBindingTag.typing},
            ),
            (
              frameRange: FrameRange(start: 0, end: 9),
              frameCount: 10,
              tags: <AnimationBindingTag>{},
            ),
          ];

          for (final invalid in invalids) {
            test(
              'frameRange: (${invalid.frameRange.start}, ${invalid.frameRange.end}), frameCount: ${invalid.frameCount}, tags: ${invalid.tags.length}.',
              () {
                expect(
                  () => AnimationBindingManifest(
                    identifier: AnimationBindingIdentifier.generate(),
                    timeline: TimelineIdentifier.generate(),
                    spriteAtlas: SpriteAtlasIdentifier.generate(),
                    frameRange: invalid.frameRange,
                    frameCount: invalid.frameCount,
                    tags: invalid.tags,
                  ),
                  throwsA(isA<InvariantViolationError>()),
                );
              },
            );
          }
        });
      });

      group('extractMetadata', () {
        test('returns timeline, spriteAtlas, and frameRange.', () {
          final timeline = TimelineIdentifier.generate();
          final spriteAtlas = SpriteAtlasIdentifier.generate();
          final frameRange = FrameRange(start: 0, end: 9);

          final manifest = AnimationBindingManifest(
            identifier: AnimationBindingIdentifier.generate(),
            timeline: timeline,
            spriteAtlas: spriteAtlas,
            frameRange: frameRange,
            frameCount: 10,
            tags: {AnimationBindingTag.typing},
          );

          final (extractedTimeline, extractedSpriteAtlas, extractedFrameRange) =
              manifest.extractMetadata();

          expect(extractedTimeline, equals(timeline));
          expect(extractedSpriteAtlas, equals(spriteAtlas));
          expect(extractedFrameRange, equals(frameRange));
        });
      });
    });

    valueObjectTest<
      Criteria,
      Set<AnimationBindingTag>?,
      Set<AnimationBindingTag>?
    >(
      constructor: (Set<AnimationBindingTag>? tags) => Criteria(tags: tags),
      generator: () => {AnimationBindingTag.typing},
      variations: (Set<AnimationBindingTag>? tags) => [
        {AnimationBindingTag.coffee},
        {AnimationBindingTag.typing, AnimationBindingTag.coffee},
        null,
      ],
      invalids: (Set<AnimationBindingTag>? tags) => [],
    );
  });
}
