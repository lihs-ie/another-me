import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';

void valueObjectTest<T extends ValueObject, Variation, Invalid>({
  required T Function(Variation) constructor,
  required Variation Function() generator,
  required List<Variation> Function(Variation) variations,
  required List<Invalid> Function(Variation) invalids,
  void Function()? additionalTests,
}) {
  final typeName = T.toString();

  group('Package value-object: $typeName', () {
    group('instantiate', () {
      test('successfully with valid value.', () {
        final props = generator();
        final instance = constructor(props);

        expect(instance, isA<T>());
      });

      test(
        'unsuccessfully throws InvariantViolationError with invalid value.',
        () {
          final props = generator();
          final invalidVariants = invalids(props);

          for (final invalid in invalidVariants) {
            expect(
              () => constructor(invalid as Variation),
              throwsA(isA<InvariantViolationError>()),
              reason:
                  '$typeName instantiation failed for invalid variant: $invalid',
            );
          }
        },
      );
    });

    group('equals', () {
      test('returns true with same value.', () {
        final props = generator();
        final instance1 = constructor(props);
        final instance2 = constructor(props);

        expect(instance1 == instance2, isTrue);
        expect(instance2 == instance1, isTrue);
      });

      test('returns false with different value.', () {
        final baseProps = generator();
        final variants = variations(baseProps);

        for (final variant in variants) {
          final instance1 = constructor(baseProps);
          final instance2 = constructor(variant);

          expect(
            instance1 == instance2,
            isFalse,
            reason: '$typeName equality failed for variant: $variant',
          );
          expect(instance2 == instance1, isFalse);
        }
      });
    });

    group('hashCode', () {
      test('returns same integer with same instances.', () {
        final props = generator();
        final instance1 = constructor(props);
        final instance2 = constructor(props);

        expect(instance1.hashCode, equals(instance2.hashCode));
      });

      test('returns different integer with different instances.', () {
        final baseProps = generator();
        final variants = variations(baseProps);

        for (final variant in variants) {
          final instance1 = constructor(baseProps);
          final instance2 = constructor(variant);

          expect(
            instance1.hashCode,
            isNot(equals(instance2.hashCode)),
            reason: '$typeName hashCode failed for variant: $variant',
          );
        }
      });
    });

    if (additionalTests != null) {
      additionalTests();
    }
  });
}
