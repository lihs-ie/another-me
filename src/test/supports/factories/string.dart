import 'dart:math';

import 'random.dart';

class StringFactory {
  static const List<String> alphanumeric = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  static const List<String> alpha = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  static const List<String> numeric = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  static const List<String> symbol = [
    '!',
    '"',
    '#',
    '\$',
    '%',
    '&',
    "'",
    '(',
    ')',
    '*',
    '+',
    ',',
    '-',
    '.',
    '/',
    ':',
    ';',
    '<',
    '=',
    '>',
    '?',
    '@',
    '[',
    '\\',
    ']',
    '^',
    '_',
    '`',
    '{',
    '|',
    '}',
    '~',
  ];

  static const List<String> uid = [...alphanumeric, '-', '_'];

  static const List<String> hex = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
  ];

  static String create({
    int? seed,
    int min = 1,
    int max = 32,
    List<String> candidates = const [],
  }) {
    final fixedSeed = seed ?? _generateSeed(min: min, max: max);
    final offset = (fixedSeed & (max - min + 1)).abs();
    final length = min + offset;

    final random = Random(fixedSeed);

    final characters = candidates.isNotEmpty ? candidates : alphanumeric;

    return List<String>.generate(
      length,
      (int index) =>
          characters[random.nextInt(9007199254740991) % characters.length],
    ).join();
  }

  static List<String> createList({
    required int count,
    int? seed,
    int min = 1,
    int max = 255,
    List<String> candidates = const [],
  }) {
    return Randomizer.uniqueNumbers(count: count, min: min, max: max)
        .map(
          (int seed) =>
              create(seed: seed, min: min, max: max, candidates: candidates),
        )
        .toList();
  }

  static int _generateSeed({required int min, required int max}) {
    if (min > max) {
      throw ArgumentError('min must be <= max');
    }

    final random = Random();
    return min + random.nextInt(max - min + 1);
  }
}
