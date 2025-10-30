import 'package:another_me/domains/common/identifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

void ulidBasedIdentifierTest<T extends ULIDBasedIdentifier, A>({
  required T Function(A) constructor,
  required T Function() generate,
  required T Function(String) fromString,
  required T Function(Uint8List) fromBinary,
  A Function()? propsGenerator,
}) {
  group(T.toString(), () {
    final fixedPropsGenerator = propsGenerator ?? () => Ulid() as A;

    group('instantiate', () {
      test('successfully with valid value.', () {
        final identifier = constructor(fixedPropsGenerator());
        expect(identifier, isA<T>());
      });
    });

    group('generate', () {
      test('successfully creates new identifier.', () {
        final identifier = generate();
        expect(identifier, isA<T>());
        expect(identifier.value, isA<Ulid>());
      });
    });

    group('fromString', () {
      test('successfully returns an instance from a valid string.', () {
        final value = Ulid().toString();
        final identifier = fromString(value);
        expect(identifier, isA<T>());
        expect(identifier.value.toString(), equals(value));
      });

      test('unsuccessfully throws FormatException from an invalid string.', () {
        final invalidValue = 'invalid';
        expect(() => fromString(invalidValue), throwsA(isA<ArgumentError>()));
      });
    });

    group('fromBinary', () {
      test('successfully returns an instance from valid bytes.', () {
        final ulid = Ulid();
        final bytes = ulid.toBytes();
        final identifier = fromBinary(bytes);
        expect(identifier, isA<T>());
        expect(identifier.value, equals(ulid));
      });

      test('unsuccessfully throws ArgumentError from invalid bytes.', () {
        final invalidBytes = Uint8List.fromList([0, 1, 2]);
        expect(() => fromBinary(invalidBytes), throwsA(isA<ArgumentError>()));
      });
    });

    group('toString', () {
      test('returns the ULID string representation.', () {
        final value = Ulid().toString();
        final identifier = fromString(value);
        expect(identifier.toString(), equals(value));
      });
    });

    group('toBinary', () {
      test('returns the ULID byte representation.', () {
        final ulid = Ulid();
        final bytes = ulid.toBytes();
        final identifier = constructor(ulid as A);
        expect(listEquals(identifier.toBinary(), bytes), isTrue);
      });
    });

    group('equals', () {
      test('returns true with same value.', () {
        final props = fixedPropsGenerator();
        final instance1 = constructor(props);
        final instance2 = constructor(props);
        expect(instance1 == instance2, isTrue);
      });

      test('returns false with different value.', () {
        final instance1 = generate();
        final instance2 = generate();
        expect(instance1 == instance2, isFalse);
      });
    });
  });
}
