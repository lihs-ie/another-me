import 'package:another_me/domains/common/number.dart';

import '../common.dart';

class DoubleFactory extends Factory<double, ({double? value})> {
  @override
  double create({({double? value})? overrides, required int seed}) {
    return overrides?.value ?? (seed % 10000) / 100.0;
  }

  @override
  double duplicate(double instance, ({double? value})? overrides) {
    return overrides?.value ?? instance;
  }
}

typedef RationalOverrides = ({BigInt? numerator, BigInt? denominator});

class RationalFactory extends Factory<Rational, RationalOverrides> {
  @override
  Rational create({RationalOverrides? overrides, required int seed}) {
    final numerator = overrides?.numerator ?? BigInt.from((seed % 100) + 1);
    final denominator = overrides?.denominator ?? BigInt.from((seed % 10) + 1);

    return Rational(numerator: numerator, denominator: denominator);
  }

  @override
  Rational duplicate(Rational instance, RationalOverrides? overrides) {
    final numerator = overrides?.numerator ?? instance.numerator;
    final denominator = overrides?.denominator ?? instance.denominator;

    return Rational(numerator: numerator, denominator: denominator);
  }
}
