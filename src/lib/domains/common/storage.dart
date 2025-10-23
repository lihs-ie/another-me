import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

enum OperatingSystem { android, iOS, macOS, windows }

class FilePath implements ValueObject {
  final String value;
  final OperatingSystem os;

  static const maxLength = 2048;

  static const macOSValuePattern =
      r'^(?:~\/|\.\/|\.\.\/|\/)?(?:[^\/\0]+\/)*[^\/\0]*$';

  static const iOSValuePattern =
      r'^(?:~\/|\.\/|\.\.\/|\/)?(?:[^\/\0]+\/)*[^\/\0]*$';

  static const androidValuePattern =
      r'^(?:~\/|\.\/|\.\.\/|\/)?(?:[^\/\0]+\/)*[^\/\0]*$';

  static const windowsValuePattern =
      r'^(?:'
      r'(?:[A-Za-z]:[\\/])'
      r'|(?:\\\\[^\\\/\0]+[\\\/][^\\\/\0]+[\\\/]?)'
      r'|(?:\.{1,2}(?:[\\\/]|$))'
      r'|)'
      r'(?:[^\\/:*?"<>|\0]+[\\\/])*'
      r'[^\\/:*?"<>|\0]*$';

  FilePath({required this.value, required this.os}) {
    switch (os) {
      case OperatingSystem.macOS:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: macOSValuePattern,
        );
        break;
      case OperatingSystem.iOS:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: iOSValuePattern,
        );
        break;
      case OperatingSystem.android:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: androidValuePattern,
        );
        break;
      case OperatingSystem.windows:
        Invariant.pattern(
          value: value,
          name: 'value',
          pattern: windowsValuePattern,
        );
        break;
    }

    Invariant.length(value: value, name: 'value', min: 1, max: maxLength);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FilePath) {
      return false;
    }

    return value == other.value && os == other.os;
  }

  @override
  int get hashCode => Object.hash(value, os);
}
