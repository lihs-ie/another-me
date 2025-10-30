import 'package:another_me/domains/common/storage.dart';
import 'package:crypto/crypto.dart';
import 'package:thirds/blake3.dart';

import '../common.dart';
import '../enum.dart';
import '../string.dart';

class OperatingSystemFactory extends EnumFactory<OperatingSystem> {
  OperatingSystemFactory() : super(OperatingSystem.values);
}

class FilePathFactory
    extends Factory<FilePath, ({String? value, OperatingSystem? os})> {
  @override
  FilePath create({
    ({String? value, OperatingSystem? os})? overrides,
    required int seed,
  }) {
    final os =
        overrides?.os ??
        Builder(OperatingSystemFactory()).buildWith(seed: seed);

    final extension = [
      'png',
      'json',
      'aac',
      'm4a',
      'mp3',
      'wav',
      'txt',
    ].elementAt(seed % 7);

    final value = overrides?.value ?? _generateValidPath(os, extension, seed);

    return FilePath(value: value, os: os);
  }

  String _generateValidPath(OperatingSystem os, String extension, int seed) {
    final dirCount = (seed % 4);

    final parts = <String>[];

    final separator = switch (os) {
      OperatingSystem.windows => '\\',
      _ => '/',
    };

    if (os == OperatingSystem.windows) {
      if (seed % 2 == 0) {
        final driveLetter = String.fromCharCode(
          'A'.codeUnitAt(0) + (seed % 26),
        );

        parts.add('$driveLetter:');
        parts.add(separator);
      }
    } else {
      if (seed % 3 == 0) {
        parts.add(separator);
      }
    }

    for (var i = 0; i < dirCount; i++) {
      final dirName = StringFactory.create(
        seed: seed + i + 1,
        min: 1,
        max: 10,
        candidates: StringFactory.alphanumeric,
      );

      parts.add(dirName);
      parts.add(separator);
    }

    final fileName = StringFactory.create(
      seed: seed + dirCount + 1,
      min: 1,
      max: 20,
      candidates: StringFactory.alphanumeric,
    );

    parts.add(fileName);
    parts.add('.');
    parts.add(extension);

    return parts.join();
  }

  @override
  FilePath duplicate(
    FilePath instance,
    ({String? value, OperatingSystem? os})? overrides,
  ) {
    final value = overrides?.value ?? instance.value;
    final os = overrides?.os ?? instance.os;

    return FilePath(value: value, os: os);
  }
}

class ChecksumAlgorithmFactory extends EnumFactory<ChecksumAlgorithm> {
  ChecksumAlgorithmFactory() : super(ChecksumAlgorithm.values);
}

class _ChecksumCalculator implements ChecksumCalculator {
  @override
  Checksum calculate(FilePath path, ChecksumAlgorithm algorithm) {
    final value = switch (algorithm) {
      ChecksumAlgorithm.sha256 =>
        sha256.convert(path.value.codeUnits).toString(),
      ChecksumAlgorithm.blake3 => blake3(
        path.value.codeUnits,
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
    };

    return Checksum(algorithm: algorithm, value: value);
  }
}

class ChecksumCalculatorFactory extends Factory<ChecksumCalculator, void> {
  @override
  ChecksumCalculator create({void overrides, required int seed}) {
    return _ChecksumCalculator();
  }

  @override
  ChecksumCalculator duplicate(ChecksumCalculator instance, void overrides) {
    throw UnimplementedError();
  }
}

class ChecksumFactory
    extends Factory<Checksum, ({ChecksumAlgorithm? algorithm, String? value})> {
  @override
  Checksum create({
    ({ChecksumAlgorithm? algorithm, String? value})? overrides,
    required int seed,
  }) {
    final algorithm =
        overrides?.algorithm ??
        Builder(ChecksumAlgorithmFactory()).buildWith(seed: seed);

    final hexLength = algorithm.expectedHexLength;

    final hexChars = '0123456789abcdef';
    final buffer = StringBuffer();

    var currentSeed = seed;
    for (var i = 0; i < hexLength; i++) {
      currentSeed = (currentSeed * 1103515245 + 12345) & 0x7fffffff;
      buffer.write(hexChars[currentSeed % 16]);
    }

    final value = overrides?.value ?? buffer.toString();

    return Checksum(algorithm: algorithm, value: value);
  }

  @override
  Checksum duplicate(
    Checksum instance,
    ({ChecksumAlgorithm? algorithm, String? value})? overrides,
  ) {
    final algorithm = overrides?.algorithm ?? instance.algorithm;
    final value = overrides?.value ?? instance.value;

    return Checksum(algorithm: algorithm, value: value);
  }
}
