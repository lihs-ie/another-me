import 'dart:typed_data';

import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/animation/atlas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../../supports/factories/common.dart';
import '../../../../supports/factories/library/animation/common.dart';
import 'identifier.dart';

void main() {
  group('Package domains/library/animation/atlas', () {
    ulidBasedIdentifierTest<SpriteAtlasIdentifier, Ulid>(
      constructor: (Ulid value) => SpriteAtlasIdentifier(value: value),
      generate: SpriteAtlasIdentifier.generate,
      fromString: SpriteAtlasIdentifier.fromString,
      fromBinary: SpriteAtlasIdentifier.fromBinary,
    );

    group('SpriteAtlasDefinition', () {
      group('instantiate', () {
        group('successfully with', () {
          final valids = [
            (
              pngPath: FilePath(
                value: '/assets/sprite.png',
                os: OperatingSystem.macOS,
              ),
              jsonPath: FilePath(
                value: '/assets/sprite.json',
                os: OperatingSystem.macOS,
              ),
            ),
            (
              pngPath: FilePath(
                value: '/data/animations/character.png',
                os: OperatingSystem.macOS,
              ),
              jsonPath: FilePath(
                value: '/data/animations/character.json',
                os: OperatingSystem.macOS,
              ),
            ),
          ];

          for (final valid in valids) {
            test(
              'pngPath: "${valid.pngPath.value}", jsonPath: "${valid.jsonPath.value}".',
              () {
                final gridSize = Builder(
                  GridSizeFactory(),
                ).buildWith(overrides: (value: 8), seed: 1);
                final instance = SpriteAtlasDefinition(
                  identifier: SpriteAtlasIdentifier.generate(),
                  pngPath: valid.pngPath,
                  jsonPath: valid.jsonPath,
                  gridSize: gridSize,
                  pivot: Builder(PivotFactory()).buildWith(
                    overrides: (x: 0, y: 0, gridSize: gridSize),
                    seed: 1,
                  ),
                );

                expect(instance.pngPath, equals(valid.pngPath));
                expect(instance.jsonPath, equals(valid.jsonPath));
              },
            );
          }
        });

        group('unsuccessfully with', () {
          test('pngPath and jsonPath in different directories.', () {
            final gridSize = Builder(
              GridSizeFactory(),
            ).buildWith(overrides: (value: 8), seed: 2);
            expect(
              () => SpriteAtlasDefinition(
                identifier: SpriteAtlasIdentifier.generate(),
                pngPath: FilePath(
                  value: '/assets/sprite.png',
                  os: OperatingSystem.macOS,
                ),
                jsonPath: FilePath(
                  value: '/other/sprite.json',
                  os: OperatingSystem.macOS,
                ),
                gridSize: gridSize,
                pivot: Builder(PivotFactory()).buildWith(
                  overrides: (x: 0, y: 0, gridSize: gridSize),
                  seed: 2,
                ),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });
    });
  });
}
