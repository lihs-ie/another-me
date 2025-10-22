import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

class Randomizer {
  static List<int> uniqueNumbers({
    required int count,
    int min = 1,
    int max = 9007199254740991,
  }) {
    if (count < 0) {
      throw ArgumentError('Count must be zero or positive.');
    }

    if (max - min + 1 < count) {
      throw ArgumentError(
        'Range is too small for the requested count of unique numbers.',
      );
    }

    final random = Random();

    return List<int>.generate(count, (int index) => index + 1).fold<List<int>>(
      List.empty(),
      (List<int> carry, int current) {
        final upper = max - current;

        final base = min + random.nextInt(upper - min + 1);

        var value = base;

        for (final existence in carry) {
          if (existence <= value) {
            value++;
          }
        }

        return List<int>.from(carry)..add(value);
      },
    )..shuffle(random);
  }
}
