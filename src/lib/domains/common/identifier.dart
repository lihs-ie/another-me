import 'dart:typed_data';

import 'package:another_me/domains/common/value_object.dart';
import 'package:ulid/ulid.dart';

abstract class ULIDBasedIdentifier implements ValueObject {
  final Ulid value;

  const ULIDBasedIdentifier(this.value);

  static ULIDBasedIdentifier generate() {
    throw UnimplementedError();
  }

  static ULIDBasedIdentifier fromString(String value) {
    throw UnimplementedError();
  }

  static ULIDBasedIdentifier fromBinary(Uint8List bytes) {
    throw UnimplementedError();
  }

  @override
  String toString() => value.toString();

  Uint8List toBinary() => value.toBytes();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (runtimeType != other.runtimeType) {
      return false;
    }

    if (other is! ULIDBasedIdentifier) {
      return false;
    }

    if (value != other.value) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => value.hashCode;
}
