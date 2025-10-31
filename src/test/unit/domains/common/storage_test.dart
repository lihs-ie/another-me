import 'package:another_me/domains/common/storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/storage.dart';
import '../../../supports/factories/string.dart';
import 'value_object.dart';

void main() {
  group('Package domains/common/storage', () {
    group('OperatingSystem', () {
      test('declares all defined enumerators.', () {
        expect(OperatingSystem.windows, isA<OperatingSystem>());
        expect(OperatingSystem.macOS, isA<OperatingSystem>());
        expect(OperatingSystem.android, isA<OperatingSystem>());
        expect(OperatingSystem.iOS, isA<OperatingSystem>());
      });
    });

    valueObjectTest(
      constructor: (({String value, OperatingSystem os}) props) =>
          FilePath(value: props.value, os: props.os),
      generator: () {
        final value = StringFactory.createFromPattern(
          pattern: FilePath.macOSValuePattern,
          minimumLength: 10,
          maximumLength: 100,
        );
        return (value: value, os: OperatingSystem.macOS);
      },
      variations: (({String value, OperatingSystem os}) props) => [
        (
          value: StringFactory.createFromPattern(
            pattern: FilePath.iOSValuePattern,
            minimumLength: 10,
            maximumLength: 100,
          ),
          os: OperatingSystem.iOS,
        ),
        (value: '/valid/path/to/different/file.txt', os: props.os),
      ],
      invalids: (({String value, OperatingSystem os}) props) => [
        (os: OperatingSystem.windows, value: '/invalid/path'),
        (os: OperatingSystem.windows, value: 'invalid|path'),
        (os: props.os, value: ''),
        (
          os: OperatingSystem.macOS,
          value:
              '/${StringFactory.create(min: FilePath.maxLength, max: FilePath.maxLength, candidates: StringFactory.alphanumeric)}',
        ),
      ],
    );

    group('FilePath', () {
      group('combine', () {
        test(
          'combines directory path with filename using forward slash on macOS.',
          () {
            final dirPath = FilePath(
              value: '/Users/test/Documents',
              os: OperatingSystem.macOS,
            );
            final result = dirPath.combine('file.txt');

            expect(result.value, equals('/Users/test/Documents/file.txt'));
            expect(result.os, equals(OperatingSystem.macOS));
          },
        );

        test(
          'combines directory path with filename using forward slash on iOS.',
          () {
            final dirPath = FilePath(
              value: '/var/mobile/Documents',
              os: OperatingSystem.iOS,
            );
            final result = dirPath.combine('audio.mp3');

            expect(result.value, equals('/var/mobile/Documents/audio.mp3'));
            expect(result.os, equals(OperatingSystem.iOS));
          },
        );

        test(
          'combines directory path with filename using forward slash on Android.',
          () {
            final dirPath = FilePath(
              value: '/data/data/com.example/files',
              os: OperatingSystem.android,
            );
            final result = dirPath.combine('data.json');

            expect(
              result.value,
              equals('/data/data/com.example/files/data.json'),
            );
            expect(result.os, equals(OperatingSystem.android));
          },
        );

        test(
          'combines directory path with filename using backslash on Windows.',
          () {
            final dirPath = FilePath(
              value: r'C:\Users\Test\Documents',
              os: OperatingSystem.windows,
            );
            final result = dirPath.combine('file.txt');

            expect(result.value, equals(r'C:\Users\Test\Documents\file.txt'));
            expect(result.os, equals(OperatingSystem.windows));
          },
        );

        test(
          'adds separator when directory path does not end with separator.',
          () {
            final dirPath = FilePath(
              value: '/Users/test/Documents',
              os: OperatingSystem.macOS,
            );
            final result = dirPath.combine('file.txt');

            expect(result.value, equals('/Users/test/Documents/file.txt'));
          },
        );

        test(
          'does not add extra separator when directory path ends with separator.',
          () {
            final dirPath = FilePath(
              value: '/Users/test/Documents/',
              os: OperatingSystem.macOS,
            );
            final result = dirPath.combine('file.txt');

            expect(result.value, equals('/Users/test/Documents/file.txt'));
          },
        );

        test('works with Windows path ending with backslash.', () {
          final dirPath = FilePath(
            value: r'C:\Users\Test\Documents\',
            os: OperatingSystem.windows,
          );
          final result = dirPath.combine('file.txt');

          expect(result.value, equals(r'C:\Users\Test\Documents\file.txt'));
        });
      });
    });

    group('ChecksumAlgorithm', () {
      test('declares all defined enumerators.', () {
        expect(ChecksumAlgorithm.sha256, isA<ChecksumAlgorithm>());
        expect(ChecksumAlgorithm.blake3, isA<ChecksumAlgorithm>());
      });

      test('has expected hex length for sha256.', () {
        expect(ChecksumAlgorithm.sha256.expectedHexLength, equals(64));
      });

      test('has expected hex length for blake3.', () {
        expect(ChecksumAlgorithm.blake3.expectedHexLength, equals(64));
      });

      test('returns algorithm name for sha256.', () {
        expect(ChecksumAlgorithm.sha256.algorithmName, equals('sha256'));
      });

      test('returns algorithm name for blake3.', () {
        expect(ChecksumAlgorithm.blake3.algorithmName, equals('blake3'));
      });

      test('can parse from string.', () {
        expect(
          ChecksumAlgorithmExtension.fromString('sha256'),
          equals(ChecksumAlgorithm.sha256),
        );
        expect(
          ChecksumAlgorithmExtension.fromString('blake3'),
          equals(ChecksumAlgorithm.blake3),
        );
      });

      test('throws error for unsupported algorithm.', () {
        expect(
          () => ChecksumAlgorithmExtension.fromString('unsupported'),
          throwsA(isA<Exception>()),
        );
      });
    });

    valueObjectTest(
      constructor: (({ChecksumAlgorithm algorithm, String value}) props) =>
          Checksum(algorithm: props.algorithm, value: props.value),
      generator: () {
        final value = '0' * 64;
        return (algorithm: ChecksumAlgorithm.sha256, value: value);
      },
      variations: (({ChecksumAlgorithm algorithm, String value}) props) => [
        (algorithm: ChecksumAlgorithm.blake3, value: 'a' * 64),
        (algorithm: props.algorithm, value: '1' * 64),
        (algorithm: props.algorithm, value: 'A' * 32 + 'b' * 32),
      ],
      invalids: (({ChecksumAlgorithm algorithm, String value}) props) => [
        (algorithm: props.algorithm, value: '0' * 63),
        (algorithm: props.algorithm, value: '0' * 65),
        (algorithm: props.algorithm, value: 'g' * 64),
        (algorithm: props.algorithm, value: ''),
      ],
    );

    group('ApplicationStoragePathProvider', () {
      test('returns application support directory.', () async {
        final provider = Builder(
          ApplicationStoragePathProviderFactory(),
        ).build();
        final path = await provider.getApplicationSupportDirectory();

        expect(path, isA<FilePath>());
        expect(path.value, isNotEmpty);
      });

      test('returns cache directory.', () async {
        final provider = Builder(
          ApplicationStoragePathProviderFactory(),
        ).build();
        final path = await provider.getCacheDirectory();

        expect(path, isA<FilePath>());
        expect(path.value, isNotEmpty);
      });

      test('returns documents directory.', () async {
        final provider = Builder(
          ApplicationStoragePathProviderFactory(),
        ).build();
        final path = await provider.getDocumentsDirectory();

        expect(path, isA<FilePath>());
        expect(path.value, isNotEmpty);
      });

      test('respects overridden paths.', () async {
        final customAppSupportPath = FilePath(
          value: '/custom/app/support',
          os: OperatingSystem.macOS,
        );
        final customCachePath = FilePath(
          value: '/custom/cache',
          os: OperatingSystem.macOS,
        );
        final customDocsPath = FilePath(
          value: '/custom/documents',
          os: OperatingSystem.macOS,
        );

        final provider = Builder(ApplicationStoragePathProviderFactory())
            .buildWith(
              overrides: (
                applicationSupportPath: customAppSupportPath,
                cachePath: customCachePath,
                documentsPath: customDocsPath,
              ),
              seed: 1,
            );

        final appSupportPath = await provider.getApplicationSupportDirectory();
        final cachePath = await provider.getCacheDirectory();
        final docsPath = await provider.getDocumentsDirectory();

        expect(appSupportPath, equals(customAppSupportPath));
        expect(cachePath, equals(customCachePath));
        expect(docsPath, equals(customDocsPath));
      });

      test('generates platform-specific paths.', () async {
        final provider = Builder(
          ApplicationStoragePathProviderFactory(),
        ).buildWith(seed: 42);

        final appSupportPath = await provider.getApplicationSupportDirectory();
        final cachePath = await provider.getCacheDirectory();
        final docsPath = await provider.getDocumentsDirectory();

        expect(appSupportPath.os, equals(cachePath.os));
        expect(cachePath.os, equals(docsPath.os));
      });
    });
  });
}
