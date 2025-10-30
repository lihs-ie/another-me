import 'package:another_me/domains/media/media.dart';

import '../common/identifier.dart';

class TrackIdentifierFactory
    extends ULIDBasedIdentifierFactory<TrackIdentifier> {
  TrackIdentifierFactory() : super((value) => TrackIdentifier(value: value));
}
