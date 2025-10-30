import 'dart:math';

final Random _random = Random();

int randomInteger({required int min, required int max}) {
  return min + _random.nextInt(max - min);
}

double randomDouble({required double min, required double max}) {
  return min + _random.nextDouble() * (max - min);
}
