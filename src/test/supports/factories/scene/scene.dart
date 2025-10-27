import 'package:another_me/domains/scene/scene.dart';
import 'package:ulid/ulid.dart';

import '../common/identifier.dart';

class SceneIdentifierFactory
    extends ULIDBasedIdentifierFactory<SceneIdentifier> {
  SceneIdentifierFactory()
    : super((Ulid value) => SceneIdentifier(value: value));
}
