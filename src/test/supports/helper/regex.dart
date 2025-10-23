import 'dart:math';

abstract class Node {
  String generate(Random random);
}

class SequenceNode extends Node {
  final List<Node> children;

  SequenceNode(this.children);

  @override
  String generate(Random random) =>
      children.map((child) => child.generate(random)).join();
}

class AltNode extends Node {
  final List<Node> options;

  AltNode(this.options);

  @override
  String generate(Random random) =>
      options[random.nextInt(options.length)].generate(random);
}

class LiteralNode extends Node {
  final String character;

  LiteralNode(this.character);

  @override
  String generate(Random random) => character;
}

class DotNode extends Node {
  static const _pool =
      r"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.";

  @override
  String generate(Random random) => _pool[random.nextInt(_pool.length)];
}

class ClassNode extends Node {
  final List<String> characters;

  ClassNode(this.characters);

  @override
  String generate(Random random) =>
      characters[random.nextInt(characters.length)];
}

class RepeatNode extends Node {
  final Node child;
  final int min;
  final int max;

  RepeatNode({required this.child, required this.min, required this.max});

  @override
  String generate(Random random) {
    final count = (max == min) ? min : min + random.nextInt(max - min + 1);

    final buffer = StringBuffer();

    for (var i = 0; i < count; i++) {
      buffer.write(child.generate(random));
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
      if (_try('*')) return RepeatNode(child: atom, min: 0, max: 10);
      if (_try('+')) return RepeatNode(child: atom, min: 1, max: 10);
      if (_try('?')) return RepeatNode(child: atom, min: 0, max: 1);
      if (_try('{')) {
        final start = _readNumber();

        int? end;

        if (_try(',')) {
          end = _try('}') ? start + 10 : _readNumber();
          _expect('}');
        } else {
          _expect('}');
          end = start;
        }

        final max = end.clamp(0, 1000);

        return RepeatNode(child: atom, min: start, max: max);
      }
    }
    return atom;
  }

  Node _parseAtom() {
    // アンカー（^ と $）を検出して無視
    if (_try('^') || _try('\$')) {
      return LiteralNode(''); // 空文字として扱う
    }

    if (_try('(')) {
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
          // エスケープされた ^ と $ はリテラル文字として扱う
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
    // 否定文字クラスの検出
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

    // 否定文字クラスの場合は補集合を返す
    if (negate) {
      return _negateCharClass(chars);
    }

    return chars;
  }

  /// 文字クラスの補集合を生成
  List<String> _negateCharClass(List<String> excluded) {
    final all = <String>[];

    // 印字可能ASCII文字の範囲を生成
    all.addAll(_range('a', 'z'));
    all.addAll(_range('A', 'Z'));
    all.addAll(_range('0', '9'));

    // よく使われる記号を追加
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

    // excluded に含まれない文字のみを返す
    return all.where((c) => !excluded.contains(c)).toList();
  }

  int _readNumber() {
    final start = index;
    while (!eof && isDigit(string[index])) index++;

    if (start == index) {
      throw FormatException('Number expected at $index');
    }

    return int.parse(string.substring(start, index));
  }

  static bool isDigit(String c) =>
      c.codeUnitAt(0) ^ 0x30 <= 9 && c.codeUnitAt(0) >= 0x30;

  bool _isMeta(String c) => '()[]{}|*+?.'.contains(c);
  List<String> _range(String a, String b) {
    final sa = a.codeUnitAt(0), sb = b.codeUnitAt(0);
    final lo = min(sa, sb), hi = max(sa, sb);
    return [for (var k = lo; k <= hi; k++) String.fromCharCode(k)];
  }
}
