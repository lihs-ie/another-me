import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Package domains/common/storage', () {
    group('OperatingSystem', () {
      test('declares all defined enumerators.', () {
        expect(ThemeMode.light, isA<ThemeMode>());
        expect(ThemeMode.dark, isA<ThemeMode>());
        expect(ThemeMode.system, isA<ThemeMode>());
      });
    });
  });
}
