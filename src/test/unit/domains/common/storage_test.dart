import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/storage.dart';
import '../../../supports/factories/string.dart';

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

    group('FilePath', () {
      group('instantiate', () {
        group('successfully with valid value', () {
          final valids = [
            (
              os: OperatingSystem.macOS,
              value: StringFactory.createFromPattern(
                pattern: FilePath.macOSValuePattern,
                minimumLength: 1,
              ),
            ),
            (
              os: OperatingSystem.iOS,
              value: StringFactory.createFromPattern(
                pattern: FilePath.iOSValuePattern,
                minimumLength: 1,
              ),
            ),
            (
              os: OperatingSystem.android,
              value: StringFactory.createFromPattern(
                pattern: FilePath.androidValuePattern,
                minimumLength: 1,
              ),
            ),
            (
              os: OperatingSystem.windows,
              value: StringFactory.createFromPattern(
                pattern: FilePath.windowsValuePattern,
                minimumLength: 3,
              ),
            ),
          ];

          for (final values in valids) {
            test('os: ${values.os}, value: "${values.value}".', () {
              final instance = FilePath(value: values.value, os: values.os);

              expect(instance.value, equals(values.value));
            });
          }
        });
        group('unsuccessfully with', () {
          final invalids = [
            (os: OperatingSystem.windows, value: '/invalid/path'),
            (os: OperatingSystem.windows, value: 'invalid|path'),
            (os: Builder(OperatingSystemFactory()).build(), value: ''),
            (
              os: OperatingSystem.macOS,
              value:
                  '/${StringFactory.create(min: FilePath.maxLength, max: FilePath.maxLength, candidates: StringFactory.alphanumeric)}',
            ),
          ];

          for (final invalid in invalids) {
            test('os: ${invalid.os}, value: "${invalid.value}".', () {
              expect(
                () => FilePath(value: invalid.value, os: invalid.os),
                throwsA(isA<InvariantViolationException>()),
              );
            });
          }
        });
      });

      group('equals', () {
        test('returns true with same values.', () {
          final value = StringFactory.createFromPattern(
            pattern: FilePath.macOSValuePattern,
          );

          final os = OperatingSystem.macOS;

          final instance1 = FilePath(value: value, os: os);
          final instance2 = FilePath(value: value, os: os);

          expect(instance1 == instance2, isTrue);
        });

        test('returns false with different values.', () {
          final instance1 = FilePath(
            value: '/valid/path/to/file1.txt',
            os: OperatingSystem.macOS,
          );
          final instance2 = FilePath(
            value: '/valid/path/to/file2.txt',
            os: OperatingSystem.macOS,
          );

          expect(instance1 == instance2, isFalse);
        });
      });
    });
  });
}
