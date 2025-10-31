import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

enum OperatingSystem { android, iOS, macOS, windows }

class FilePath implements ValueObject {
  final String value;
  final OperatingSystem os;

  static const maxLength = 2048;

  static const macOSValuePattern =
      r'^(?:~\/|\.\/|\.\.\/|\/)?(?:[^\/\0]+\/)*[^\/\0]*$';

  static const iOSValuePattern =
      r'^(?:~\/|\.\/|\.\.\/|\/)?(?:[^\/\0]+\/)*[^\/\0]*$';

  static const androidValuePattern =
      r'^(?:~\/|\.\/|\.\.\/|\/)?(?:[^\/\0]+\/)*[^\/\0]*$';

  static const windowsValuePattern =
      r'^(?:'
      r'(?:[A-Za-z]:[\\/])'
      r'|(?:\\\\[^\\\/\0]+[\\\/][^\\\/\0]+[\\\/]?)'
      r'|(?:\.{1,2}(?:[\\\/]|$))'
      r'|)'
      r'(?:[^\\/:*?"<>|\0]+[\\\/])*'
      r'[^\\/:*?"<>|\0]*$';

  FilePath({required this.value, required this.os}) {
    switch (os) {
      case OperatingSystem.macOS:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: macOSValuePattern,
        );
        break;
      case OperatingSystem.iOS:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: iOSValuePattern,
        );
        break;
      case OperatingSystem.android:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: androidValuePattern,
        );
        break;
      case OperatingSystem.windows:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: windowsValuePattern,
        );
        break;
    }

    Invariant.length(value: value, name: 'value', min: 1, max: maxLength);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FilePath) {
      return false;
    }

    return value == other.value && os == other.os;
  }

  @override
  int get hashCode => Object.hash(value, os);

  FilePath combine(String filename) {
    final separator = _getSeparator();
    final normalizedDir = value.endsWith(separator)
        ? value
        : '$value$separator';
    return FilePath(value: '$normalizedDir$filename', os: os);
  }

  String _getSeparator() {
    switch (os) {
      case OperatingSystem.windows:
        return '\\';
      case OperatingSystem.macOS:
      case OperatingSystem.iOS:
      case OperatingSystem.android:
        return '/';
    }
  }
}

enum ChecksumAlgorithm { sha256, blake3 }

extension ChecksumAlgorithmExtension on ChecksumAlgorithm {
  int get expectedHexLength {
    switch (this) {
      case ChecksumAlgorithm.sha256:
        return 64;
      case ChecksumAlgorithm.blake3:
        return 64;
    }
  }

  String get algorithmName {
    switch (this) {
      case ChecksumAlgorithm.sha256:
        return 'sha256';
      case ChecksumAlgorithm.blake3:
        return 'blake3';
    }
  }

  static ChecksumAlgorithm fromString(String name) {
    switch (name) {
      case 'sha256':
        return ChecksumAlgorithm.sha256;
      case 'blake3':
        return ChecksumAlgorithm.blake3;
      default:
        throw InvariantViolationError(
          'Unsupported checksum algorithm: $name. '
          'Supported algorithms: sha256, blake3',
        );
    }
  }
}

class Checksum implements ValueObject {
  final ChecksumAlgorithm algorithm;
  final String value;

  static const hexPattern = r'^[0-9a-fA-F]+$';

  Checksum({required this.algorithm, required this.value}) {
    final expectedLength = algorithm.expectedHexLength;
    Invariant.length(
      value: value,
      name: 'value',
      min: expectedLength,
      max: expectedLength,
    );

    Invariant.pattern(value: value, name: 'value', pattern: hexPattern);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Checksum) {
      return false;
    }

    return algorithm == other.algorithm &&
        value.toLowerCase() == other.value.toLowerCase();
  }

  @override
  int get hashCode => Object.hash(algorithm, value.toLowerCase());
}

abstract interface class ChecksumCalculator {
  Checksum calculate(FilePath path, ChecksumAlgorithm algorithm);
}

class ChecksumMismatchError extends StateError {
  ChecksumMismatchError(super.message);
}

abstract interface class ApplicationStoragePathProvider {
  Future<FilePath> getApplicationSupportDirectory();

  Future<FilePath> getCacheDirectory();

  Future<FilePath> getDocumentsDirectory();
}
