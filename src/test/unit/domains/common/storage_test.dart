import 'package:another_me/domains/common/storage.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
