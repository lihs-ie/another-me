import 'dart:typed_data';

import 'package:another_me/domains/common/identifier.dart';
import 'package:ulid/ulid.dart';

class SceneIdentifier extends ULIDBasedIdentifier {
  SceneIdentifier({required Ulid value}) : super(value);

  factory SceneIdentifier.generate() => SceneIdentifier(value: Ulid());

  factory SceneIdentifier.fromString(String value) =>
      SceneIdentifier(value: Ulid.parse(value));

  factory SceneIdentifier.fromBinary(Uint8List bytes) =>
      SceneIdentifier(value: Ulid.fromBytes(bytes));
}
