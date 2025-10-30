import 'dart:typed_data';

import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/import/import.dart';
import 'package:another_me/domains/library/asset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/date.dart';
import '../../../supports/factories/common/storage.dart';
import '../../../supports/factories/common/url.dart';
import '../../../supports/factories/import/catalog.dart';
import '../../../supports/factories/library/asset.dart';
import '../../../supports/factories/string.dart';
import '../../../supports/helper/math.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/library/animation/asset', () {
    group('FileResource', () {
      group('instantiate', () {
        group('successfully with', () {
          final valids = FileResource.allowedExtensions.map((String extension) {
            return (
              path: Builder(FilePathFactory()).build(
                overrides: (
                  value: '/assets/file.$extension',
                  os: OperatingSystem.macOS,
                ),
              ),
              sizeBytes: 1024,
            );
          }).toList();

          for (final valid in valids) {
            test(
              'path: "${valid.path.value}", sizeBytes: ${valid.sizeBytes}.',
              () {
                final instance = FileResource(
                  path: valid.path,
                  sizeBytes: valid.sizeBytes,
                  checksum: Builder(ChecksumFactory()).buildWith(
                    overrides: (
                      algorithm: ChecksumAlgorithm.sha256,
                      value: 'a' * 64,
                    ),
                    seed: 1,
                  ),
                );

                expect(instance.path, equals(valid.path));
                expect(instance.sizeBytes, equals(valid.sizeBytes));
              },
            );
          }
        });

        group('unsuccessfully with', () {
          final invalids = [
            (path: Builder(FilePathFactory()).build(), sizeBytes: 0),
            (
              path: Builder(FilePathFactory()).build(),
              sizeBytes: FileResource.maxFileSizeBytes + 1,
            ),
            (
              path: Builder(FilePathFactory()).build(
                overrides: (
                  value: '/assets/file.invalid',
                  os: OperatingSystem.macOS,
                ),
              ),
              sizeBytes: randomInteger(
                min: 1,
                max: FileResource.maxFileSizeBytes,
              ),
            ),
          ];

          for (final invalid in invalids) {
            test(
              'path: "${invalid.path.value}", sizeBytes: ${invalid.sizeBytes}.',
              () {
                expect(
                  () => FileResource(
                    path: invalid.path,
                    sizeBytes: invalid.sizeBytes,
                    checksum: Builder(ChecksumFactory()).buildWith(
                      overrides: (
                        algorithm: ChecksumAlgorithm.sha256,
                        value: 'a' * 64,
                      ),
                      seed: 2,
                    ),
                  ),
                  throwsA(isA<Object>()),
                );
              },
            );
          }
        });
      });

      group('equals', () {
        test('returns true with same values.', () {
          final path = FilePath(
            value: '/assets/file.txt',
            os: OperatingSystem.macOS,
          );
          final checksum = Builder(ChecksumFactory()).buildWith(
            overrides: (algorithm: ChecksumAlgorithm.sha256, value: 'a' * 64),
            seed: 3,
          );

          final instance1 = FileResource(
            path: path,
            sizeBytes: 1024,
            checksum: checksum,
          );
          final instance2 = FileResource(
            path: path,
            sizeBytes: 1024,
            checksum: checksum,
          );

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different path.', () {
          final checksums = Builder(ChecksumFactory()).buildList(count: 2);
          final paths = Builder(FilePathFactory()).buildList(count: 2);
          final sizeBytes = List.generate(2, (int index) => 1024 + index * 512);

          final pairs = <(FileResource, FileResource)>[];

          pairs.add((
            FileResource(
              path: paths[0],
              sizeBytes: sizeBytes[0],
              checksum: checksums[0],
            ),
            FileResource(
              path: paths[0],
              sizeBytes: sizeBytes[0],
              checksum: checksums[1],
            ),
          ));

          pairs.add((
            FileResource(
              path: paths[0],
              sizeBytes: sizeBytes[0],
              checksum: checksums[0],
            ),
            FileResource(
              path: paths[1],
              sizeBytes: sizeBytes[0],
              checksum: checksums[0],
            ),
          ));

          pairs.add((
            FileResource(
              path: paths[0],
              sizeBytes: sizeBytes[0],
              checksum: checksums[0],
            ),
            FileResource(
              path: paths[0],
              sizeBytes: sizeBytes[1],
              checksum: checksums[0],
            ),
          ));

          for (final pair in pairs) {
            expect(pair.$1 == pair.$2, isFalse);
          }
        });
      });
    });

    group('AssetPackageIdentifier', () {
      group('generate', () {
        test('creates new identifier.', () {
          final identifier = AssetPackageIdentifier.generate();

          expect(identifier.value, isA<Ulid>());
        });
      });

      group('fromString', () {
        test('creates identifier from ULID string.', () {
          final ulid = Ulid();
          final identifier = AssetPackageIdentifier.fromString(ulid.toString());

          expect(identifier.value, equals(ulid));
        });
      });

      group('fromBinary', () {
        test('creates identifier from ULID bytes.', () {
          final ulid = Ulid();
          final bytes = Uint8List.fromList(ulid.toBytes());
          final identifier = AssetPackageIdentifier.fromBinary(bytes);

          expect(identifier.value, equals(ulid));
        });
      });

      group('equals', () {
        test('returns true with same ULID.', () {
          final ulid = Ulid();
          final instance1 = AssetPackageIdentifier(value: ulid);
          final instance2 = AssetPackageIdentifier(value: ulid);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different ULID.', () {
          final instance1 = AssetPackageIdentifier.generate();
          final instance2 = AssetPackageIdentifier.generate();

          expect(instance1 == instance2, isFalse);
        });
      });
    });

    group('AssetPackageType', () {
      test('declares all defined enumerators.', () {
        expect(AssetPackageType.character, isA<AssetPackageType>());
        expect(AssetPackageType.scene, isA<AssetPackageType>());
        expect(AssetPackageType.ui, isA<AssetPackageType>());
        expect(AssetPackageType.sfx, isA<AssetPackageType>());
        expect(AssetPackageType.track, isA<AssetPackageType>());
      });
    });

    group('AssetPackage', () {
      group('instantiate', () {
        group('successfully with', () {
          test('non-track type.', () {
            final instance = AssetPackage(
              identifier: AssetPackageIdentifier.generate(),
              type: AssetPackageType.character,
              resources: [],
              checksum: Builder(ChecksumFactory()).buildWith(
                overrides: (
                  algorithm: ChecksumAlgorithm.sha256,
                  value: 'a' * 64,
                ),
                seed: 5,
              ),
              animationSpecVersion: 'v1',
              trackMetadata: null,
            );

            expect(instance.type, equals(AssetPackageType.character));
            expect(instance.animationSpecVersion, equals('v1'));
          });

          test('track type with trackMetadata.', () {
            final trackMetadata = Builder(
              TrackCatalogMetadataFactory(),
            ).build();

            final instance = AssetPackage(
              identifier: AssetPackageIdentifier.generate(),
              type: AssetPackageType.track,
              resources: [],
              checksum: Builder(ChecksumFactory()).buildWith(
                overrides: (
                  algorithm: ChecksumAlgorithm.sha256,
                  value: 'a' * 64,
                ),
                seed: 10,
              ),
              trackMetadata: trackMetadata,
            );

            expect(instance.type, equals(AssetPackageType.track));
            expect(instance.trackMetadata, equals(trackMetadata));
          });
        });

        group('unsuccessfully with', () {
          test('track type without trackMetadata.', () {
            expect(
              () => AssetPackage(
                identifier: AssetPackageIdentifier.generate(),
                type: AssetPackageType.track,
                resources: [],
                checksum: Builder(ChecksumFactory()).buildWith(
                  overrides: (
                    algorithm: ChecksumAlgorithm.sha256,
                    value: 'a' * 64,
                  ),
                  seed: 11,
                ),
                trackMetadata: null,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });

      group('extractTrackSeed', () {
        test('returns trackMetadata for track type.', () {
          final trackMetadata = Builder(TrackCatalogMetadataFactory()).build();

          final package = AssetPackage(
            identifier: Builder(AssetPackageIdentifierFactory()).build(),
            type: AssetPackageType.track,
            resources: [],
            checksum: Builder(ChecksumFactory()).build(),
            trackMetadata: trackMetadata,
          );

          final extracted = package.extractTrackSeed();

          expect(extracted, equals(trackMetadata));
        });

        test('throws StateError for non-track type.', () {
          final package = AssetPackage(
            identifier: AssetPackageIdentifier.generate(),
            type: AssetPackageType.character,
            resources: [],
            checksum: Builder(ChecksumFactory()).buildWith(
              overrides: (algorithm: ChecksumAlgorithm.sha256, value: 'a' * 64),
              seed: 13,
            ),
          );

          expect(() => package.extractTrackSeed(), throwsA(isA<StateError>()));
        });
      });
    });

    group('AssetCatalogIdentifier', () {
      group('generate', () {
        test('creates new identifier.', () {
          final identifier = AssetCatalogIdentifier.generate();

          expect(identifier.value, isA<Ulid>());
        });
      });

      group('fromString', () {
        test('creates identifier from ULID string.', () {
          final ulid = Ulid();
          final identifier = AssetCatalogIdentifier.fromString(ulid.toString());

          expect(identifier.value, equals(ulid));
        });
      });

      group('fromBinary', () {
        test('creates identifier from ULID bytes.', () {
          final ulid = Ulid();
          final bytes = Uint8List.fromList(ulid.toBytes());
          final identifier = AssetCatalogIdentifier.fromBinary(bytes);

          expect(identifier.value, equals(ulid));
        });
      });

      group('equals', () {
        test('returns true with same ULID.', () {
          final ulid = Ulid();
          final instance1 = AssetCatalogIdentifier(value: ulid);
          final instance2 = AssetCatalogIdentifier(value: ulid);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different ULID.', () {
          final instance1 = AssetCatalogIdentifier.generate();
          final instance2 = AssetCatalogIdentifier.generate();

          expect(instance1 == instance2, isFalse);
        });
      });
    });

    valueObjectTest(
      constructor: (({int major, int minor, int patch}) props) =>
          SemanticVersion(
            major: props.major,
            minor: props.minor,
            patch: props.patch,
          ),
      generator: () => (major: 1, minor: 2, patch: 3),
      variations: (({int major, int minor, int patch}) props) => [
        (major: props.major + 1, minor: props.minor, patch: props.patch),
        (major: props.major, minor: props.minor + 1, patch: props.patch),
        (major: props.major, minor: props.minor, patch: props.patch + 1),
      ],
      invalids: (({int major, int minor, int patch}) props) => [],
      additionalTests: () {
        group('fromString', () {
          group('successfully with', () {
            final valids = [
              (input: '0.0.1', expected: (major: 0, minor: 0, patch: 1)),
              (input: '1.2.3', expected: (major: 1, minor: 2, patch: 3)),
              (input: '10.20.30', expected: (major: 10, minor: 20, patch: 30)),
            ];

            for (final valid in valids) {
              test('input: "${valid.input}".', () {
                final instance = SemanticVersion.fromString(valid.input);
                expect(instance.major, equals(valid.expected.major));
                expect(instance.minor, equals(valid.expected.minor));
                expect(instance.patch, equals(valid.expected.patch));
              });
            }
          });

          group('unsuccessfully with', () {
            final invalids = [
              (input: '1.2'),
              (input: '1.2.3.4'),
              (input: 'invalid'),
              (input: ''),
            ];

            for (final invalid in invalids) {
              test('input: "${invalid.input}".', () {
                expect(
                  () => SemanticVersion.fromString(invalid.input),
                  throwsA(isA<Object>()),
                );
              });
            }
          });
        });
      },
    );

    group('CatalogStatus', () {
      test('declares all defined enumerators.', () {
        expect(CatalogStatus.draft, isA<CatalogStatus>());
        expect(CatalogStatus.published, isA<CatalogStatus>());
        expect(CatalogStatus.deprecated, isA<CatalogStatus>());
      });
    });

    group('AssetCatalog', () {
      group('addPackage', () {
        test('adds package to catalog.', () {
          final catalog = AssetCatalog(
            identifier: AssetCatalogIdentifier.generate(),
            version: SemanticVersion(major: 1, minor: 0, patch: 0),
            minimumAppVersion: SemanticVersion(major: 1, minor: 0, patch: 0),
            packages: [],
            publishedAt: DateTime.now(),
            status: CatalogStatus.draft,
          );

          final package = Builder(AssetPackageFactory()).buildWith(
            overrides: (
              identifier: AssetPackageIdentifier.generate(),
              type: AssetPackageType.character,
              resources: <FileResource>[],
              checksum: Builder(ChecksumFactory()).buildWith(
                overrides: (
                  algorithm: ChecksumAlgorithm.sha256,
                  value: 'a' * 64,
                ),
                seed: 14,
              ),
              animationSpecVersion: null,
              trackMetadata: null,
            ),
            seed: 14,
          );

          catalog.addPackage(package);

          expect(catalog.packages.length, equals(1));
          expect(catalog.packages.first, equals(package));
        });
      });

      group('deprecate', () {
        test('publishes AssetCatalogDeprecated event.', () {
          final catalog = AssetCatalog(
            identifier: Builder(AssetCatalogIdentifierFactory()).build(),
            version: Builder(
              SemanticVersionFactory(),
            ).build(overrides: (major: 1, minor: 0, patch: 0)),
            minimumAppVersion: Builder(
              SemanticVersionFactory(),
            ).build(overrides: (major: 1, minor: 0, patch: 0)),
            packages: [],
            publishedAt: Builder(DateTimeFactory()).build(),
            status: Builder(CatalogStatusFactory()).build(
              overrides: (exclusion: List.of([CatalogStatus.deprecated])),
            ),
          );

          final reason = 'Old version';
          catalog.deprecate(reason);

          expect(catalog.status, equals(CatalogStatus.deprecated));

          final events = catalog.events();
          expect(events.length, equals(1));
          expect(events.first, isA<AssetCatalogDeprecated>());

          final event = events.first as AssetCatalogDeprecated;
          expect(event.reason, equals(reason));
        });
      });
    });
  });
}
