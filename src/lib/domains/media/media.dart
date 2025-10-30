import 'dart:typed_data';

import 'package:another_me/domains/common/identifier.dart';
import 'package:ulid/ulid.dart';

class TrackIdentifier extends ULIDBasedIdentifier {
  TrackIdentifier({required Ulid value}) : super(value);

  factory TrackIdentifier.generate() => TrackIdentifier(value: Ulid());

  factory TrackIdentifier.fromString(String value) =>
      TrackIdentifier(value: Ulid.parse(value));

  factory TrackIdentifier.fromBinary(Uint8List bytes) =>
      TrackIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! TrackIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
