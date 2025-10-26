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
  });
}
