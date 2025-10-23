import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Package domains/common/variant', () {
    group('InvariantViolationException', () {
      test('creates instance with message.', () {
        final message = 'Test error message';
        final exception = InvariantViolationException(message);

        expect(exception.message, equals(message));
      });

      test('toString returns formatted message.', () {
        final message = 'Test error message';
        final exception = InvariantViolationException(message);

        expect(
          exception.toString(),
          equals('InvariantViolationException: Test error message'),
        );
      });
    });

    group('Invariant.length', () {
      group('validates successfully with', () {
        final valids = [
          (value: 'test', min: null, max: null),
          (value: 'test', min: 1, max: 10),
          (value: 'test', min: 4, max: 4),
          (value: '', min: 0, max: 0),
          (value: 'a', min: 1, max: null),
          (value: 'abc', min: null, max: 5),
        ];

        for (final valid in valids) {
          test(
            'value: "${valid.value}", min: ${valid.min}, max: ${valid.max}.',
            () {
              expect(
                () => Invariant.length(
                  value: valid.value,
                  name: 'test',
                  min: valid.min,
                  max: valid.max,
                ),
                returnsNormally,
              );
            },
          );
        }
      });

      group('throws InvariantViolationException with', () {
        final invalids = [
          (value: 'test', min: 5, max: 10),
          (value: 'test', min: 1, max: 3),
          (value: 'test', min: 10, max: null),
          (value: 'test', min: null, max: 2),
        ];

        for (final invalid in invalids) {
          test(
            'value: "${invalid.value}", min: ${invalid.min}, max: ${invalid.max}.',
            () {
              expect(
                () => Invariant.length(
                  value: invalid.value,
                  name: 'test',
                  min: invalid.min,
                  max: invalid.max,
                ),
                throwsA(isA<InvariantViolationException>()),
              );
            },
          );
        }
      });
    });

    group('Invariant.notContains', () {
      group('validates successfully with', () {
        final valids = [
          (value: 'hello', needle: 'x'),
          (value: 'test', needle: 'z'),
          (value: '', needle: 'a'),
          (value: 'abc', needle: 'def'),
        ];

        for (final valid in valids) {
          test('value: "${valid.value}", needle: "${valid.needle}".', () {
            expect(
              () => Invariant.notContains(
                value: valid.value,
                name: 'test',
                needle: valid.needle,
              ),
              returnsNormally,
            );
          });
        }
      });

      group('throws InvariantViolationException with', () {
        final invalids = [
          (value: 'hello', needle: 'e'),
          (value: 'test', needle: 't'),
          (value: 'abc', needle: 'bc'),
        ];

        for (final invalid in invalids) {
          test('value: "${invalid.value}", needle: "${invalid.needle}".', () {
            expect(
              () => Invariant.notContains(
                value: invalid.value,
                name: 'test',
                needle: invalid.needle,
              ),
              throwsA(isA<InvariantViolationException>()),
            );
          });
        }
      });
    });

    group('Invariant.pattern', () {
      group('validates successfully with', () {
        final valids = [
          (value: 'abc', pattern: r'^[a-z]+$'),
          (value: '123', pattern: r'^\d+$'),
          (value: 'test@example.com', pattern: r'^[\w\.\-]+@[\w\.\-]+$'),
          (value: '/valid/path', pattern: r'^\/[\w\/]+$'),
        ];

        for (final valid in valids) {
          test('value: "${valid.value}", pattern: "${valid.pattern}".', () {
            expect(
              () => Invariant.pattern(
                value: valid.value,
                name: 'test',
                pattern: valid.pattern,
              ),
              returnsNormally,
            );
          });
        }
      });

      group('throws InvariantViolationException with', () {
        final invalids = [
          (value: 'ABC', pattern: r'^[a-z]+$'),
          (value: 'abc', pattern: r'^\d+$'),
          (value: 'invalid', pattern: r'^[\d]+$'),
        ];

        for (final invalid in invalids) {
          test('value: "${invalid.value}", pattern: "${invalid.pattern}".', () {
            expect(
              () => Invariant.pattern(
                value: invalid.value,
                name: 'test',
                pattern: invalid.pattern,
              ),
              throwsA(isA<InvariantViolationException>()),
            );
          });
        }
      });
    });

    group('Invariant.range', () {
      group('validates successfully with', () {
        final valids = [
          (value: 5, min: null, max: null),
          (value: 5, min: 1, max: 10),
          (value: 5, min: 5, max: 5),
          (value: 0, min: 0, max: 0),
          (value: 10, min: 5, max: null),
          (value: 5, min: null, max: 10),
          (value: 5.5, min: 1.0, max: 10.0),
        ];

        for (final valid in valids) {
          test(
            'value: ${valid.value}, min: ${valid.min}, max: ${valid.max}.',
            () {
              expect(
                () => Invariant.range(
                  value: valid.value,
                  name: 'test',
                  min: valid.min,
                  max: valid.max,
                ),
                returnsNormally,
              );
            },
          );
        }
      });

      group('throws InvariantViolationException with', () {
        final invalids = [
          (value: 5, min: 10, max: 20),
          (value: 5, min: 1, max: 4),
          (value: 5, min: 10, max: null),
          (value: 5, min: null, max: 4),
          (value: 5.5, min: 6.0, max: 10.0),
        ];

        for (final invalid in invalids) {
          test(
            'value: ${invalid.value}, min: ${invalid.min}, max: ${invalid.max}.',
            () {
              expect(
                () => Invariant.range(
                  value: invalid.value,
                  name: 'test',
                  min: invalid.min,
                  max: invalid.max,
                ),
                throwsA(isA<InvariantViolationException>()),
              );
            },
          );
        }
      });
    });

    group('Invariant.greaterThanRight', () {
      group('validates successfully with', () {
        final valids = [
          (left: 10, right: 5, orEqualTo: false),
          (left: 10, right: 10, orEqualTo: true),
          (left: 100, right: 50, orEqualTo: false),
          (left: 5, right: 5, orEqualTo: true),
        ];

        for (final valid in valids) {
          test(
            'left: ${valid.left}, right: ${valid.right}, orEqualTo: ${valid.orEqualTo}.',
            () {
              expect(
                () => Invariant.greaterThanRight(
                  left: valid.left,
                  right: valid.right,
                  leftName: 'left',
                  rightName: 'right',
                  orEqualTo: valid.orEqualTo,
                ),
                returnsNormally,
              );
            },
          );
        }
      });

      group('throws InvariantViolationException with', () {
        final invalids = [
          (left: 5, right: 10, orEqualTo: false),
          (left: 5, right: 5, orEqualTo: false),
          (left: 5, right: 10, orEqualTo: true),
        ];

        for (final invalid in invalids) {
          test(
            'left: ${invalid.left}, right: ${invalid.right}, orEqualTo: ${invalid.orEqualTo}.',
            () {
              expect(
                () => Invariant.greaterThanRight(
                  left: invalid.left,
                  right: invalid.right,
                  leftName: 'left',
                  rightName: 'right',
                  orEqualTo: invalid.orEqualTo,
                ),
                throwsA(isA<InvariantViolationException>()),
              );
            },
          );
        }
      });
    });

    group('Invariant.lessThanRight', () {
      group('validates successfully with', () {
        final valids = [
          (left: 5, right: 10, orEqualTo: false),
          (left: 5, right: 5, orEqualTo: true),
          (left: 50, right: 100, orEqualTo: false),
          (left: 10, right: 10, orEqualTo: true),
        ];

        for (final valid in valids) {
          test(
            'left: ${valid.left}, right: ${valid.right}, orEqualTo: ${valid.orEqualTo}.',
            () {
              expect(
                () => Invariant.lessThanRight(
                  left: valid.left,
                  right: valid.right,
                  leftName: 'left',
                  rightName: 'right',
                  orEqualTo: valid.orEqualTo,
                ),
                returnsNormally,
              );
            },
          );
        }
      });

      group('throws InvariantViolationException with', () {
        final invalids = [
          (left: 10, right: 5, orEqualTo: false),
          (left: 10, right: 10, orEqualTo: false),
          (left: 10, right: 5, orEqualTo: true),
        ];

        for (final invalid in invalids) {
          test(
            'left: ${invalid.left}, right: ${invalid.right}, orEqualTo: ${invalid.orEqualTo}.',
            () {
              expect(
                () => Invariant.lessThanRight(
                  left: invalid.left,
                  right: invalid.right,
                  leftName: 'left',
                  rightName: 'right',
                  orEqualTo: invalid.orEqualTo,
                ),
                throwsA(isA<InvariantViolationException>()),
              );
            },
          );
        }
      });
    });
  });
}
