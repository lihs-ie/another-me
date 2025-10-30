import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/animation/common.dart';
import 'package:ulid/ulid.dart';
import 'package:path/path.dart' as path;

class SpriteAtlasIdentifier extends ULIDBasedIdentifier {
  SpriteAtlasIdentifier({required Ulid value}) : super(value);

  factory SpriteAtlasIdentifier.generate() =>
      SpriteAtlasIdentifier(value: Ulid());

  factory SpriteAtlasIdentifier.fromString(String value) =>
      SpriteAtlasIdentifier(value: Ulid.parse(value));

  factory SpriteAtlasIdentifier.fromBinary(Uint8List bytes) =>
      SpriteAtlasIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SpriteAtlasIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class SpriteAtlasDefinition {
  final SpriteAtlasIdentifier identifier;
  final FilePath pngPath;
  final FilePath jsonPath;
  final GridSize gridSize;
  final Pivot pivot;

  SpriteAtlasDefinition({
    required this.identifier,
    required this.pngPath,
    required this.jsonPath,
    required this.gridSize,
    required this.pivot,
  }) {
    final pngDirectory = path.dirname(pngPath.value);
    final jsonDirectory = path.dirname(jsonPath.value);

    if (pngDirectory != jsonDirectory) {
      throw InvariantViolationError(
        'pngPath and jsonPath must be in the same directory',
      );
    }
  }
}

abstract class SpriteAtlasEvent extends BaseEvent {
  SpriteAtlasEvent(super.occurredAt);
}

class SpriteAtlasRegistered extends SpriteAtlasEvent {
  final SpriteAtlasIdentifier spriteAtlas;
  final GridSize gridSize;
  final Pivot pivot;

  SpriteAtlasRegistered({
    required DateTime occurredAt,
    required this.spriteAtlas,
    required this.gridSize,
    required this.pivot,
  }) : super(occurredAt);
}

abstract interface class SpriteAtlasDefinitionRepository {
  Future<SpriteAtlasDefinition> find(SpriteAtlasIdentifier identifier);
  Future<void> persist(SpriteAtlasDefinition definition);
}
