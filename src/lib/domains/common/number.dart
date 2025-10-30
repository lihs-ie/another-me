import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

class Rational implements Comparable<Rational>, ValueObject {
  final BigInt numerator;
  final BigInt denominator;
  const Rational._(this.numerator, this.denominator);

  factory Rational({required BigInt numerator, required BigInt denominator}) {
    if (denominator == BigInt.zero) {
      throw InvariantViolationError('Denominator must not be zero.');
    }

    var a = numerator;
    var b = denominator;
    if (b.isNegative) {
      a = -a;
      b = -b;
    }

    final g = _gcd(a, b);
    return Rational._(a ~/ g, b ~/ g);
  }

  factory Rational.fromInt(int v) =>
      Rational(numerator: BigInt.from(v), denominator: BigInt.one);

  factory Rational.fromBigInt(BigInt v) =>
      Rational(numerator: v, denominator: BigInt.one);

  static Rational parse(String s) {
    final t = s.trim();
    final slash = t.indexOf('/');
    if (slash < 0) {
      return Rational(numerator: BigInt.parse(t), denominator: BigInt.one);
    }
    final a = t.substring(0, slash).trim();
    final b = t.substring(slash + 1).trim();
    return Rational(numerator: BigInt.parse(a), denominator: BigInt.parse(b));
  }

  static Rational? tryParse(String s) {
    try {
      return parse(s);
    } catch (_) {
      return null;
    }
  }

  factory Rational.fromDouble(
    double x, {
    int maxDenominator = 1000000,
    double epsilon = 1e-12,
  }) {
    if (x.isNaN || x.isInfinite) {
      throw ArgumentError('Cannot convert non-finite double to Rational.');
    }
    if (x == 0.0) {
      return Rational(numerator: BigInt.zero, denominator: BigInt.one);
    }

    final sign = x.isNegative ? -1 : 1;
    final absX = x.abs();
    var v = absX;

    BigInt p0 = BigInt.one, p1 = BigInt.zero;
    BigInt q0 = BigInt.zero, q1 = BigInt.one;

    while (true) {
      final a = v.floor();
      final A = BigInt.from(a);
      final p = A * p0 + p1;
      final q = A * q0 + q1;

      final approx = p.toDouble() / q.toDouble();
      if ((approx - absX).abs() <= epsilon || q.toInt() > maxDenominator) {
        final num = BigInt.from(sign) * p;
        return Rational(numerator: num, denominator: q);
      }

      final frac = v - a;
      if (frac == 0.0) {
        final num = BigInt.from(sign) * p;
        return Rational(numerator: num, denominator: q);
      }
      v = 1.0 / frac;

      p1 = p0;
      p0 = p;
      q1 = q0;
      q0 = q;
    }
  }

  Rational operator +(Rational other) => Rational(
    numerator: numerator * other.denominator + other.numerator * denominator,
    denominator: denominator * other.denominator,
  );

  Rational operator -(Rational other) => Rational(
    numerator: numerator * other.denominator - other.numerator * denominator,
    denominator: denominator * other.denominator,
  );

  Rational operator *(Rational other) => Rational(
    numerator: numerator * other.numerator,
    denominator: denominator * other.denominator,
  );

  Rational operator /(Rational other) {
    if (other.numerator == BigInt.zero) {
      throw ArgumentError('Division by zero.');
    }
    return Rational(
      numerator: numerator * other.denominator,
      denominator: denominator * other.numerator,
    );
  }

  Rational operator -() =>
      Rational(numerator: -numerator, denominator: denominator);

  Rational get reciprocal {
    if (numerator == BigInt.zero) {
      throw ArgumentError('Zero has no reciprocal.');
    }
    return Rational(numerator: denominator, denominator: numerator);
  }

  @override
  int compareTo(Rational other) {
    final left = numerator * other.denominator;
    final right = other.numerator * denominator;
    return left.compareTo(right);
  }

  bool operator <(Object other) {
    if (other is Rational) {
      return compareTo(other) < 0;
    } else if (other is int) {
      return compareTo(Rational.fromInt(other)) < 0;
    } else if (other is double) {
      return compareTo(Rational.fromDouble(other)) < 0;
    }
    throw ArgumentError('Cannot compare Rational with ${other.runtimeType}');
  }

  bool operator >(Object other) {
    if (other is Rational) {
      return compareTo(other) > 0;
    } else if (other is int) {
      return compareTo(Rational.fromInt(other)) > 0;
    } else if (other is double) {
      return compareTo(Rational.fromDouble(other)) > 0;
    }
    throw ArgumentError('Cannot compare Rational with ${other.runtimeType}');
  }

  bool operator <=(Object other) {
    if (other is Rational) {
      return compareTo(other) <= 0;
    } else if (other is int) {
      return compareTo(Rational.fromInt(other)) <= 0;
    } else if (other is double) {
      return compareTo(Rational.fromDouble(other)) <= 0;
    }
    throw ArgumentError('Cannot compare Rational with ${other.runtimeType}');
  }

  bool operator >=(Object other) {
    if (other is Rational) {
      return compareTo(other) >= 0;
    } else if (other is int) {
      return compareTo(Rational.fromInt(other)) >= 0;
    } else if (other is double) {
      return compareTo(Rational.fromDouble(other)) >= 0;
    }
    throw ArgumentError('Cannot compare Rational with ${other.runtimeType}');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Rational) {
      return false;
    }

    if (numerator != other.numerator) {
      return false;
    }

    if (denominator != other.denominator) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);

  double toDouble() => numerator.toDouble() / denominator.toDouble();

  BigInt floor() {
    final quotient = numerator ~/ denominator;
    final remainder = numerator % denominator;

    if (numerator.isNegative && remainder != BigInt.zero) {
      return quotient - BigInt.one;
    }

    return quotient;
  }

  @override
  String toString() => denominator == BigInt.one
      ? numerator.toString()
      : '$numerator/$denominator';

  static BigInt _gcd(BigInt a, BigInt b) {
    a = a.abs();
    b = b.abs();

    while (b != BigInt.zero) {
      final t = a % b;
      a = b;
      b = t;
    }
    return a == BigInt.zero ? BigInt.one : a;
  }
}
