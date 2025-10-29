import 'package:another_me/domains/common/number.dart';
import 'package:flutter_test/flutter_test.dart';

import 'value_object.dart';

void main() {
  group('Package domains/common/number', () {
    valueObjectTest(
      constructor: (({BigInt numerator, BigInt denominator}) props) =>
          Rational(numerator: props.numerator, denominator: props.denominator),
      generator: () => (numerator: BigInt.from(3), denominator: BigInt.from(4)),
      variations: (({BigInt numerator, BigInt denominator}) props) => [
        (numerator: BigInt.from(1), denominator: BigInt.from(2)),
        (numerator: BigInt.from(2), denominator: BigInt.from(3)),
        (numerator: BigInt.from(-3), denominator: BigInt.from(4)),
        (numerator: BigInt.from(5), denominator: BigInt.one),
      ],
      invalids: (({BigInt numerator, BigInt denominator}) props) => [
        (numerator: BigInt.from(1), denominator: BigInt.zero),
        (numerator: BigInt.from(5), denominator: BigInt.zero),
        (numerator: BigInt.zero, denominator: BigInt.zero),
      ],
      additionalTests: () {
        group('Rational', () {
          group('constructor', () {
            test('reduces fraction to lowest terms', () {
              final rational = Rational(
                numerator: BigInt.from(6),
                denominator: BigInt.from(8),
              );
              expect(rational.numerator, equals(BigInt.from(3)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('normalizes negative denominator', () {
              final rational = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(-2),
              );
              expect(rational.numerator, equals(BigInt.from(-1)));
              expect(rational.denominator, equals(BigInt.from(2)));
            });

            test('normalizes both negative values', () {
              final rational = Rational(
                numerator: BigInt.from(-3),
                denominator: BigInt.from(-4),
              );
              expect(rational.numerator, equals(BigInt.from(3)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('handles zero numerator', () {
              final rational = Rational(
                numerator: BigInt.zero,
                denominator: BigInt.from(5),
              );
              expect(rational.numerator, equals(BigInt.zero));
              expect(rational.denominator, equals(BigInt.one));
            });
          });

          group('fromInt', () {
            test('creates rational from positive integer', () {
              final rational = Rational.fromInt(5);
              expect(rational.numerator, equals(BigInt.from(5)));
              expect(rational.denominator, equals(BigInt.one));
            });

            test('creates rational from negative integer', () {
              final rational = Rational.fromInt(-3);
              expect(rational.numerator, equals(BigInt.from(-3)));
              expect(rational.denominator, equals(BigInt.one));
            });

            test('creates rational from zero', () {
              final rational = Rational.fromInt(0);
              expect(rational.numerator, equals(BigInt.zero));
              expect(rational.denominator, equals(BigInt.one));
            });
          });

          group('fromBigInt', () {
            test('creates rational from BigInt', () {
              final rational = Rational.fromBigInt(BigInt.from(42));
              expect(rational.numerator, equals(BigInt.from(42)));
              expect(rational.denominator, equals(BigInt.one));
            });
          });

          group('parse', () {
            test('parses fraction string', () {
              final rational = Rational.parse('3/4');
              expect(rational.numerator, equals(BigInt.from(3)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('parses integer string', () {
              final rational = Rational.parse('5');
              expect(rational.numerator, equals(BigInt.from(5)));
              expect(rational.denominator, equals(BigInt.one));
            });

            test('parses negative fraction', () {
              final rational = Rational.parse('-3/4');
              expect(rational.numerator, equals(BigInt.from(-3)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('parses fraction with spaces', () {
              final rational = Rational.parse(' 1 / 2 ');
              expect(rational.numerator, equals(BigInt.from(1)));
              expect(rational.denominator, equals(BigInt.from(2)));
            });

            test('reduces parsed fraction', () {
              final rational = Rational.parse('6/8');
              expect(rational.numerator, equals(BigInt.from(3)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('throws on invalid format', () {
              expect(() => Rational.parse('invalid'), throwsFormatException);
            });

            test('throws on zero denominator', () {
              expect(() => Rational.parse('1/0'), throwsA(anything));
            });
          });

          group('tryParse', () {
            test('returns rational for valid string', () {
              final rational = Rational.tryParse('3/4');
              expect(rational, isNotNull);
              expect(rational!.numerator, equals(BigInt.from(3)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('returns null for invalid string', () {
              final rational = Rational.tryParse('invalid');
              expect(rational, isNull);
            });

            test('returns null for zero denominator', () {
              final rational = Rational.tryParse('1/0');
              expect(rational, isNull);
            });
          });

          group('fromDouble', () {
            test('converts simple fraction', () {
              final rational = Rational.fromDouble(0.5);
              expect(rational.numerator, equals(BigInt.from(1)));
              expect(rational.denominator, equals(BigInt.from(2)));
            });

            test('converts quarter', () {
              final rational = Rational.fromDouble(0.25);
              expect(rational.numerator, equals(BigInt.from(1)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('converts negative fraction', () {
              final rational = Rational.fromDouble(-0.75);
              expect(rational.numerator, equals(BigInt.from(-3)));
              expect(rational.denominator, equals(BigInt.from(4)));
            });

            test('converts zero', () {
              final rational = Rational.fromDouble(0.0);
              expect(rational.numerator, equals(BigInt.zero));
              expect(rational.denominator, equals(BigInt.one));
            });

            test('converts integer value', () {
              final rational = Rational.fromDouble(5.0);
              expect(rational.numerator, equals(BigInt.from(5)));
              expect(rational.denominator, equals(BigInt.one));
            });

            test('throws on NaN', () {
              expect(
                () => Rational.fromDouble(double.nan),
                throwsArgumentError,
              );
            });

            test('throws on positive infinity', () {
              expect(
                () => Rational.fromDouble(double.infinity),
                throwsArgumentError,
              );
            });

            test('throws on negative infinity', () {
              expect(
                () => Rational.fromDouble(double.negativeInfinity),
                throwsArgumentError,
              );
            });

            test('approximates irrational number within epsilon', () {
              final rational = Rational.fromDouble(0.333333333);
              expect((rational.toDouble() - 0.333333333).abs(), lessThan(1e-6));
            });
          });

          group('arithmetic operations', () {
            test('adds two rationals', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              ); // 1/2
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(3),
              ); // 1/3
              final result = a + b;
              expect(result.numerator, equals(BigInt.from(5)));
              expect(result.denominator, equals(BigInt.from(6)));
            });

            test('subtracts two rationals', () {
              final a = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(4),
              ); // 3/4
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(4),
              ); // 1/4
              final result = a - b;
              expect(result.numerator, equals(BigInt.from(1)));
              expect(result.denominator, equals(BigInt.from(2)));
            });

            test('multiplies two rationals', () {
              final a = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(3),
              ); // 2/3
              final b = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(4),
              ); // 3/4
              final result = a * b;
              expect(result.numerator, equals(BigInt.from(1)));
              expect(result.denominator, equals(BigInt.from(2)));
            });

            test('divides two rationals', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              ); // 1/2
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(4),
              ); // 1/4
              final result = a / b;
              expect(result.numerator, equals(BigInt.from(2)));
              expect(result.denominator, equals(BigInt.one));
            });

            test('throws on division by zero', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              final zero = Rational(
                numerator: BigInt.zero,
                denominator: BigInt.one,
              );
              expect(() => a / zero, throwsArgumentError);
            });

            test('negates rational', () {
              final rational = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(4),
              );
              final negated = -rational;
              expect(negated.numerator, equals(BigInt.from(-3)));
              expect(negated.denominator, equals(BigInt.from(4)));
            });

            test('negates negative rational', () {
              final rational = Rational(
                numerator: BigInt.from(-3),
                denominator: BigInt.from(4),
              );
              final negated = -rational;
              expect(negated.numerator, equals(BigInt.from(3)));
              expect(negated.denominator, equals(BigInt.from(4)));
            });

            test('reduces result after addition', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(4),
              );
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(4),
              );
              final result = a + b;
              expect(result.numerator, equals(BigInt.from(1)));
              expect(result.denominator, equals(BigInt.from(2)));
            });
          });

          group('reciprocal', () {
            test('calculates reciprocal of positive fraction', () {
              final rational = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(4),
              );
              final reciprocal = rational.reciprocal;
              expect(reciprocal.numerator, equals(BigInt.from(4)));
              expect(reciprocal.denominator, equals(BigInt.from(3)));
            });

            test('calculates reciprocal of negative fraction', () {
              final rational = Rational(
                numerator: BigInt.from(-3),
                denominator: BigInt.from(4),
              );
              final reciprocal = rational.reciprocal;
              expect(reciprocal.numerator, equals(BigInt.from(-4)));
              expect(reciprocal.denominator, equals(BigInt.from(3)));
            });

            test('calculates reciprocal of integer', () {
              final rational = Rational.fromInt(5);
              final reciprocal = rational.reciprocal;
              expect(reciprocal.numerator, equals(BigInt.one));
              expect(reciprocal.denominator, equals(BigInt.from(5)));
            });

            test('throws on reciprocal of zero', () {
              final zero = Rational(
                numerator: BigInt.zero,
                denominator: BigInt.one,
              );
              expect(() => zero.reciprocal, throwsArgumentError);
            });
          });

          group('compareTo', () {
            test('compares equal rationals', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              final b = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(4),
              );
              expect(a.compareTo(b), equals(0));
            });

            test('compares less than', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(3),
              );
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              expect(a.compareTo(b), lessThan(0));
            });

            test('compares greater than', () {
              final a = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(3),
              );
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              expect(a.compareTo(b), greaterThan(0));
            });

            test('< operator', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(3),
              );
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              expect(a < b, isTrue);
              expect(b < a, isFalse);
            });

            test('> operator', () {
              final a = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(3),
              );
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              expect(a > b, isTrue);
              expect(b > a, isFalse);
            });

            test('<= operator', () {
              final a = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              final b = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(4),
              );
              final c = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(3),
              );
              expect(a <= b, isTrue);
              expect(a <= c, isTrue);
              expect(c <= a, isFalse);
            });

            test('>= operator', () {
              final a = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(3),
              );
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              final c = Rational(
                numerator: BigInt.from(4),
                denominator: BigInt.from(6),
              );
              expect(a >= b, isTrue);
              expect(a >= c, isTrue);
              expect(b >= a, isFalse);
            });

            test('< operator with int', () {
              final rational = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              ); // 0.5
              expect(rational < 1, isTrue);
              expect(rational < 0, isFalse);
            });

            test('> operator with int', () {
              final rational = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(2),
              ); // 1.5
              expect(rational > 1, isTrue);
              expect(rational > 2, isFalse);
            });

            test('<= operator with int', () {
              final rational = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(1),
              ); // 2
              expect(rational <= 2, isTrue);
              expect(rational <= 3, isTrue);
              expect(rational <= 1, isFalse);
            });

            test('>= operator with int', () {
              final rational = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(1),
              ); // 3
              expect(rational >= 3, isTrue);
              expect(rational >= 2, isTrue);
              expect(rational >= 4, isFalse);
            });

            test('< operator with double', () {
              final rational = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(4),
              ); // 0.25
              expect(rational < 0.5, isTrue);
              expect(rational < 0.1, isFalse);
            });

            test('> operator with double', () {
              final rational = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(4),
              ); // 0.75
              expect(rational > 0.5, isTrue);
              expect(rational > 0.8, isFalse);
            });

            test('<= operator with double', () {
              final rational = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              ); // 0.5
              expect(rational <= 0.5, isTrue);
              expect(rational <= 0.6, isTrue);
              expect(rational <= 0.4, isFalse);
            });

            test('>= operator with double', () {
              final rational = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(4),
              ); // 0.75
              expect(rational >= 0.75, isTrue);
              expect(rational >= 0.5, isTrue);
              expect(rational >= 0.8, isFalse);
            });

            test('throws on comparison with unsupported type', () {
              final rational = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              expect(() => rational < 'string', throwsArgumentError);
              expect(() => rational > 'string', throwsArgumentError);
              expect(() => rational <= 'string', throwsArgumentError);
              expect(() => rational >= 'string', throwsArgumentError);
            });
          });

          group('toDouble', () {
            test('converts fraction to double', () {
              final rational = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              expect(rational.toDouble(), equals(0.5));
            });

            test('converts integer to double', () {
              final rational = Rational.fromInt(5);
              expect(rational.toDouble(), equals(5.0));
            });

            test('converts negative fraction to double', () {
              final rational = Rational(
                numerator: BigInt.from(-3),
                denominator: BigInt.from(4),
              );
              expect(rational.toDouble(), equals(-0.75));
            });

            test('converts zero to double', () {
              final rational = Rational(
                numerator: BigInt.zero,
                denominator: BigInt.one,
              );
              expect(rational.toDouble(), equals(0.0));
            });
          });

          group('floor', () {
            test('floors positive fraction', () {
              final rational = Rational(
                numerator: BigInt.from(7),
                denominator: BigInt.from(3),
              ); // 2.333...
              expect(rational.floor(), equals(BigInt.from(2)));
            });

            test('floors negative fraction', () {
              final rational = Rational(
                numerator: BigInt.from(-7),
                denominator: BigInt.from(3),
              ); // -2.333...
              expect(rational.floor(), equals(BigInt.from(-3)));
            });

            test('floors integer', () {
              final rational = Rational.fromInt(5);
              expect(rational.floor(), equals(BigInt.from(5)));
            });

            test('floors zero', () {
              final rational = Rational(
                numerator: BigInt.zero,
                denominator: BigInt.one,
              );
              expect(rational.floor(), equals(BigInt.zero));
            });
          });

          group('toString', () {
            test('formats fraction', () {
              final rational = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(4),
              );
              expect(rational.toString(), equals('3/4'));
            });

            test('formats integer as integer', () {
              final rational = Rational.fromInt(5);
              expect(rational.toString(), equals('5'));
            });

            test('formats negative fraction', () {
              final rational = Rational(
                numerator: BigInt.from(-3),
                denominator: BigInt.from(4),
              );
              expect(rational.toString(), equals('-3/4'));
            });

            test('formats zero', () {
              final rational = Rational(
                numerator: BigInt.zero,
                denominator: BigInt.one,
              );
              expect(rational.toString(), equals('0'));
            });

            test('formats reduced fraction', () {
              final rational = Rational(
                numerator: BigInt.from(6),
                denominator: BigInt.from(8),
              );
              expect(rational.toString(), equals('3/4'));
            });
          });

          group('invariants', () {
            test('maintains reduced form after operations', () {
              final a = Rational(
                numerator: BigInt.from(2),
                denominator: BigInt.from(4),
              ); // Reduces to 1/2
              final b = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(4),
              );
              final result = a + b; // 1/2 + 1/4 = 3/4
              expect(result.numerator, equals(BigInt.from(3)));
              expect(result.denominator, equals(BigInt.from(4)));
            });

            test('keeps denominator positive', () {
              final rationals = [
                Rational(
                  numerator: BigInt.from(1),
                  denominator: BigInt.from(-2),
                ),
                Rational(
                  numerator: BigInt.from(-1),
                  denominator: BigInt.from(-2),
                ),
                Rational(
                  numerator: BigInt.from(-1),
                  denominator: BigInt.from(2),
                ),
              ];
              for (final r in rationals) {
                expect(r.denominator.isNegative, isFalse);
              }
            });

            test('zero has denominator of 1', () {
              final rationals = [
                Rational(numerator: BigInt.zero, denominator: BigInt.from(5)),
                Rational(numerator: BigInt.zero, denominator: BigInt.from(100)),
                Rational(numerator: BigInt.zero, denominator: BigInt.from(-7)),
              ];
              for (final r in rationals) {
                expect(r.denominator, equals(BigInt.one));
              }
            });
          });

          group('use cases', () {
            test('represents parallax speed ratio as natural number ratio', () {
              final speedRatio = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(2),
              );
              expect(speedRatio.numerator, equals(BigInt.from(3)));
              expect(speedRatio.denominator, equals(BigInt.from(2)));
              expect(speedRatio.toDouble(), equals(1.5));
            });

            test('calculates reduced speed ratio', () {
              final original = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(2),
              );
              final reduction = Rational(
                numerator: BigInt.from(1),
                denominator: BigInt.from(2),
              );
              final reduced = original * reduction;
              expect(reduced.numerator, equals(BigInt.from(3)));
              expect(reduced.denominator, equals(BigInt.from(4)));
            });

            test('compares parallax layer speeds', () {
              final faster = Rational(
                numerator: BigInt.from(5),
                denominator: BigInt.from(2),
              );
              final slower = Rational(
                numerator: BigInt.from(3),
                denominator: BigInt.from(2),
              );
              expect(faster > slower, isTrue);
              expect(slower < faster, isTrue);
            });
          });
        });
      },
    );
  });
}
