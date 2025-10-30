import 'package:another_me/domains/common/locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Package domains/common/locale', () {
    group('Language', () {
      test('declares all defined enumerators.', () {
        expect(Language.english, isA<Language>());
        expect(Language.japanese, isA<Language>());
      });

      group('from', () {
        test('returns correct enumerator for valid value.', () {
          expect(Language.from('en'), equals(Language.english));
          expect(Language.from('ja'), equals(Language.japanese));
        });

        test('throws StateError for invalid value.', () {
          expect(() => Language.from('invalid'), throwsA(isA<StateError>()));
        });
      });
    });
  });
}
