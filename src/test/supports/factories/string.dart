import 'dart:math';

import 'random.dart';

class LengthConstraint {
  final int? minimum;
  final int? maximum;

  const LengthConstraint({this.minimum, this.maximum});

  bool satisfies(int length) {
    final minimumValue = minimum;
    final maximumValue = maximum;
    if (minimumValue != null && length < minimumValue) return false;
    if (maximumValue != null && length > maximumValue) return false;
    return true;
  }

  int clampRepeatCount(int min, int max, Random random) {
    final minimumValue = minimum;
    final maximumValue = maximum;

    if (minimumValue == null && maximumValue == null) {
      return min + random.nextInt(max - min + 1);
    }

    final effectiveMin = minimumValue ?? min;
    final effectiveMax = maximumValue ?? max;

    final clampedMin = effectiveMin.clamp(min, max);
    final clampedMax = effectiveMax.clamp(min, max);

    if (clampedMin > clampedMax) {
      return clampedMin;
    }

    return clampedMin + random.nextInt(clampedMax - clampedMin + 1);
  }
}

abstract class Node {
  String generate(Random random, [LengthConstraint? lengthConstraint]);
  (int, int) lengthRange();
}

class SequenceNode extends Node {
  final List<Node> children;

  SequenceNode(this.children);

  @override
  (int, int) lengthRange() {
    int minTotal = 0;
    int maxTotal = 0;
    for (final child in children) {
      final (min, max) = child.lengthRange();
      minTotal += min;
      maxTotal += max;
    }
    return (minTotal, maxTotal);
  }

  @override
  String generate(Random random, [LengthConstraint? lengthConstraint]) {
    if (lengthConstraint == null) {
      return children.map((child) => child.generate(random)).join();
    }

    final constraintMin = lengthConstraint.minimum ?? 0;
    final constraintMax = lengthConstraint.maximum ?? 1000;
    final results = <String>[];
    int currentLength = 0;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final (childMin, childMax) = child.lengthRange();

      int remainingChildrenMin = 0;
      for (var j = i + 1; j < children.length; j++) {
        final (minLen, _) = children[j].lengthRange();
        remainingChildrenMin += minLen;
      }

      final calculatedMin =
          constraintMin - currentLength - remainingChildrenMin;
      final availableMin = childMin > calculatedMin ? childMin : calculatedMin;
      final calculatedMax =
          constraintMax - currentLength - remainingChildrenMin;
      final availableMax = childMax < calculatedMax ? childMax : calculatedMax;

      if (availableMin > availableMax) {
        if (childMin == 0) {
          results.add('');
        } else {
          final result = child.generate(random);
          results.add(result);
          currentLength += result.length;
        }
      } else if (availableMin < 0) {
        final result = child.generate(random);
        results.add(result);
        currentLength += result.length;
      } else {
        final childConstraint = LengthConstraint(
          minimum: availableMin,
          maximum: availableMax,
        );
        final result = child.generate(random, childConstraint);
        results.add(result);
        currentLength += result.length;
      }
    }

    return results.join();
  }
}

class AltNode extends Node {
  final List<Node> options;

  AltNode(this.options);

  @override
  (int, int) lengthRange() {
    int minLen = 1000000;
    int maxLen = 0;
    for (final option in options) {
      final (min, max) = option.lengthRange();
      if (min < minLen) minLen = min;
      if (max > maxLen) maxLen = max;
    }
    return (minLen, maxLen);
  }

  @override
  String generate(Random random, [LengthConstraint? lengthConstraint]) {
    if (lengthConstraint == null) {
      return options[random.nextInt(options.length)].generate(random);
    }

    final constraintMin = lengthConstraint.minimum ?? 0;
    final constraintMax = lengthConstraint.maximum ?? 1000;

    final validOptions = <Node>[];
    for (final option in options) {
      final (min, max) = option.lengthRange();
      if (max >= constraintMin && min <= constraintMax) {
        validOptions.add(option);
      }
    }

    if (validOptions.isEmpty) {
      return options.first.generate(random, lengthConstraint);
    }

    return validOptions[random.nextInt(validOptions.length)].generate(
      random,
      lengthConstraint,
    );
  }
}

class LiteralNode extends Node {
  final String character;

  LiteralNode(this.character);

  @override
  (int, int) lengthRange() => (character.length, character.length);

  @override
  String generate(Random random, [LengthConstraint? lengthConstraint]) =>
      character;
}

class DotNode extends Node {
  static const _pool =
      r"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.";

  @override
  (int, int) lengthRange() => (1, 1);

  @override
  String generate(Random random, [LengthConstraint? lengthConstraint]) =>
      _pool[random.nextInt(_pool.length)];
}

class ClassNode extends Node {
  final List<String> characters;

  ClassNode(this.characters);

  @override
  (int, int) lengthRange() => (1, 1);

  @override
  String generate(Random random, [LengthConstraint? lengthConstraint]) =>
      characters[random.nextInt(characters.length)];
}

class RepeatNode extends Node {
  final Node child;
  final int min;
  final int max;

  RepeatNode({required this.child, required this.min, required this.max});

  @override
  (int, int) lengthRange() {
    final (childMin, childMax) = child.lengthRange();
    return (childMin * min, childMax * max);
  }

  @override
  String generate(Random random, [LengthConstraint? lengthConstraint]) {
    if (lengthConstraint == null) {
      final effectiveMax = max > 1000 ? 1000 : max;
      final count = (effectiveMax == min)
          ? min
          : min + random.nextInt(effectiveMax - min + 1);
      final buffer = StringBuffer();
      for (var i = 0; i < count; i++) {
        buffer.write(child.generate(random));
      }
      return buffer.toString();
    }

    final constraintMin = lengthConstraint.minimum ?? 0;
    final constraintMax = lengthConstraint.maximum ?? 1000;
    final (childMin, childMax) = child.lengthRange();

    int minCount = min;
    int maxCount = max;

    if (childMax > 0) {
      final calculatedMin = (constraintMin / childMax).ceil();
      minCount = calculatedMin > min ? calculatedMin : min;
    }
    if (childMin > 0) {
      final calculatedMax = (constraintMax / childMin).floor();
      if (calculatedMax < min) {
        minCount = min;
        maxCount = min;
      } else {
        maxCount = calculatedMax;
      }
    }

    const absoluteMaxRepeat = 100000;
    if (minCount > absoluteMaxRepeat) {
      minCount = absoluteMaxRepeat;
    }
    if (maxCount > absoluteMaxRepeat) {
      maxCount = absoluteMaxRepeat;
    }

    if (minCount > maxCount) {
      minCount = min;
      maxCount = min;
    }

    if (min == 0 && childMin > 1 && maxCount > 20) {
      final reasonableMax = (constraintMax / (childMin * 3)).floor();
      if (reasonableMax > 3 && reasonableMax < maxCount) {
        maxCount = reasonableMax;
      } else if (maxCount > 20) {
        maxCount = 20;
      }
    }

    final count = (minCount == maxCount)
        ? minCount
        : minCount + random.nextInt(maxCount - minCount + 1);

    final buffer = StringBuffer();
    int generated = 0;

    for (var i = 0; i < count; i++) {
      final remaining = count - i;
      final remainingMinCalc =
          constraintMin - generated - (childMin * (remaining - 1));
      final remainingMin = remainingMinCalc > 0 ? remainingMinCalc : 0;
      final remainingMax =
          constraintMax - generated - (childMin * (remaining - 1));

      var itemMin = childMin > remainingMin ? childMin : remainingMin;
      var itemMax = childMax < remainingMax ? childMax : remainingMax;

      if (count > 5 && childMin > 1 && itemMax - itemMin > 10) {
        final avgSize = (constraintMax / count).floor();
        if (avgSize > itemMin && avgSize < itemMax) {
          final variance = (avgSize * 0.5).floor();
          itemMin = (avgSize - variance) > childMin
              ? (avgSize - variance)
              : childMin;
          itemMax = avgSize + variance;
          if (itemMax > remainingMax) {
            itemMax = remainingMax;
          }
        }
      }

      if (itemMin > itemMax || itemMin < 0) {
        final item = child.generate(random);
        buffer.write(item);
        generated += item.length;
      } else {
        final itemConstraint = LengthConstraint(
          minimum: itemMin,
          maximum: itemMax,
        );
        final item = child.generate(random, itemConstraint);
        buffer.write(item);
        generated += item.length;
      }
    }

    return buffer.toString();
  }
}

class Parser {
  final String string;

  int index = 0;

  Parser(this.string);

  bool get eof => index >= string.length;

  String get cur => string[index];

  bool _try(String character) {
    if (!eof && string[index] == character) {
      index++;
      return true;
    }

    return false;
  }

  String _expect(String character) {
    if (_try(character)) {
      return character;
    }

    throw FormatException("Expected '$character' at $index");
  }

  Node parse() {
    final node = _parseExpr();

    if (!eof) {
      throw FormatException('Unexpected char "${string[index]}" at $index.');
    }

    return node;
  }

  Node _parseExpr() {
    final terms = <Node>[];
    terms.add(_parseTerm());

    while (!eof && _try('|')) {
      terms.add(_parseTerm());
    }

    if (terms.length == 1) {
      return terms.first;
    }

    return AltNode(terms);
  }

  Node _parseTerm() {
    final nodes = <Node>[];

    while (!eof && string[index] != ')' && string[index] != '|') {
      nodes.add(_parseFactor());
    }

    if (nodes.isEmpty) {
      return LiteralNode('');
    }

    if (nodes.length == 1) {
      return nodes.first;
    }

    return SequenceNode(nodes);
  }

  Node _parseFactor() {
    var atom = _parseAtom();
    if (!eof) {
      if (_try('*')) return RepeatNode(child: atom, min: 0, max: 100000);
      if (_try('+')) return RepeatNode(child: atom, min: 1, max: 100000);
      if (_try('?')) return RepeatNode(child: atom, min: 0, max: 1);
      if (_try('{')) {
        final start = _readNumber();

        int? end;

        if (_try(',')) {
          end = _try('}') ? start + 100000 : _readNumber();
          _expect('}');
        } else {
          _expect('}');
          end = start;
        }

        final max = end.clamp(0, 100000);

        return RepeatNode(child: atom, min: start, max: max);
      }
    }
    return atom;
  }

  Node _parseAtom() {
    if (_try('^') || _try('\$')) {
      return LiteralNode('');
    }

    if (_try('(')) {
      if (_try('?')) {
        if (!_try(':')) {
          throw FormatException('Unsupported group construct at $index');
        }
      }

      final inner = _parseExpr();
      _expect(')');

      return inner;
    }

    if (_try('[')) {
      final chars = _parseClass();
      _expect(']');

      return ClassNode(chars);
    }

    if (_try('.')) {
      return DotNode();
    }

    if (_try('\\')) {
      if (eof) throw FormatException('Dangling escape at $index');
      final character = string[index++];
      switch (character) {
        case 'd':
          return ClassNode(
            List.generate(
              10,
              (code) => String.fromCharCode('0'.codeUnitAt(0) + code),
            ),
          );
        case 'w':
          final pool = <String>[];

          pool.addAll(_range('a', 'z'));
          pool.addAll(_range('A', 'Z'));
          pool.addAll(_range('0', '9'));
          pool.add('_');

          return ClassNode(pool);
        case 's':
          return ClassNode([' ', '\t']);
        case '^':
        case '\$':
          return LiteralNode(character);

        default:
          return LiteralNode(character);
      }
    }
    if (!eof && !_isMeta(string[index])) {
      return LiteralNode(string[index++]);
    }

    throw FormatException(
      'Unexpected token "${eof ? 'EOF' : string[index]}" at $index',
    );
  }

  List<String> _parseClass() {
    final negate = _try('^');

    final chars = <String>[];
    while (!eof && string[index] != ']') {
      if (_try('\\')) {
        if (eof) {
          throw FormatException('Dangling escape in class at $index');
        }

        final character = string[index++];

        switch (character) {
          case 'd':
            chars.addAll(_range('0', '9'));
            break;
          case 'w':
            chars.addAll(_range('a', 'z'));
            chars.addAll(_range('A', 'Z'));
            chars.addAll(_range('0', '9'));
            chars.add('_');
            break;
          case 's':
            chars.addAll([' ', '\t']);
            break;
          default:
            chars.add(character);
        }
        continue;
      }
      if (index + 2 < string.length &&
          string[index + 1] == '-' &&
          string[index + 2] != ']') {
        final start = string[index];
        final end = string[index + 2];

        chars.addAll(_range(start, end));
        index += 3;
      } else {
        chars.add(string[index++]);
      }
    }
    if (chars.isEmpty) throw FormatException('Empty character class');

    if (negate) {
      return _negateCharClass(chars);
    }

    return chars;
  }

  List<String> _negateCharClass(List<String> excluded) {
    final all = <String>[];

    all.addAll(_range('a', 'z'));
    all.addAll(_range('A', 'Z'));
    all.addAll(_range('0', '9'));

    all.addAll([
      '_',
      '-',
      '.',
      ' ',
      '@',
      '#',
      '\$',
      '%',
      '&',
      '(',
      ')',
      '[',
      ']',
      '{',
      '}',
      '<',
      '>',
      '+',
      '=',
      '!',
      '?',
      '*',
      ',',
      ';',
      '\'',
      '"',
      '\\',
      '|',
      '~',
      '`',
      '^',
    ]);

    return all.where((character) => !excluded.contains(character)).toList();
  }

  int _readNumber() {
    final start = index;
    while (!eof && isDigit(string[index])) {
      index++;
    }

    if (start == index) {
      throw FormatException('Number expected at $index');
    }

    return int.parse(string.substring(start, index));
  }

  static bool isDigit(String c) =>
      c.codeUnitAt(0) ^ 0x30 <= 9 && c.codeUnitAt(0) >= 0x30;

  bool _isMeta(String character) => '()[]{}|*+?.'.contains(character);
  List<String> _range(String a, String b) {
    final sa = a.codeUnitAt(0), sb = b.codeUnitAt(0);
    final lo = min(sa, sb), hi = max(sa, sb);
    return [for (var k = lo; k <= hi; k++) String.fromCharCode(k)];
  }
}

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
    final offset = (fixedSeed % (max - min + 1)).abs();
    final length = min + offset;

    final random = Random(fixedSeed);

    final characters = candidates.isNotEmpty ? candidates : alphanumeric;

    return List<String>.generate(
      length,
      (int index) => characters[random.nextInt(characters.length)],
    ).join();
  }

  static List<String> createList({
    required int count,
    int? seed,
    int min = 1,
    int max = 255,
    List<String> candidates = const [],
  }) {
    return Randomizer.uniqueNumbers(count: count)
        .map(
          (int seed) =>
              create(seed: seed, min: min, max: max, candidates: candidates),
        )
        .toList();
  }

  static String createFromPattern({
    required String pattern,
    int? seed,
    int? minimumLength,
    int? maximumLength,
  }) {
    int? effectiveMinimumLength = minimumLength;
    int? effectiveMaximumLength = maximumLength;

    if (minimumLength != null && maximumLength == null) {
      if (minimumLength == 0) {
        effectiveMaximumLength = 10;
      } else {
        final reasonable = minimumLength + 20;
        effectiveMaximumLength = reasonable > 100 ? 100 : reasonable;
      }
    }

    if (effectiveMinimumLength != null &&
        effectiveMaximumLength != null &&
        effectiveMinimumLength > effectiveMaximumLength) {
      throw StateError(
        'minimumLength ($effectiveMinimumLength) cannot be greater than maximumLength ($effectiveMaximumLength)',
      );
    }

    final ast = Parser(pattern).parse();

    final random = seed == null ? Random() : Random(seed);

    final lengthConstraint =
        (effectiveMinimumLength != null || effectiveMaximumLength != null)
        ? LengthConstraint(
            minimum: effectiveMinimumLength,
            maximum: effectiveMaximumLength,
          )
        : null;

    final result = ast.generate(random, lengthConstraint);

    if (lengthConstraint != null &&
        !lengthConstraint.satisfies(result.length)) {
      throw StateError(
        'Failed to generate string satisfying length constraints (min: $effectiveMinimumLength, max: $effectiveMaximumLength). Generated length: ${result.length}',
      );
    }

    return result;
  }

  static int _generateSeed({required int min, required int max}) {
    if (min > max) {
      throw ArgumentError('min must be <= max');
    }

    final random = Random();
    return min + random.nextInt(max - min + 1);
  }
}
