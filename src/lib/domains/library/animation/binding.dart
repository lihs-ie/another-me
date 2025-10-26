import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/animation/atlas.dart';
import 'package:another_me/domains/library/animation/timeline.dart';
import 'package:ulid/ulid.dart';

class AnimationBindingIdentifier extends ULIDBasedIdentifier {
  AnimationBindingIdentifier({required Ulid value}) : super(value);

  factory AnimationBindingIdentifier.generate() =>
      AnimationBindingIdentifier(value: Ulid());

  factory AnimationBindingIdentifier.fromString(String value) =>
      AnimationBindingIdentifier(value: Ulid.parse(value));

  factory AnimationBindingIdentifier.fromBinary(Uint8List bytes) =>
      AnimationBindingIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AnimationBindingIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

enum AnimationBindingTag { typing, coffee, ambient, wardrobe }

class FrameRange implements ValueObject {
  final int start;
  final int end;

  FrameRange({required this.start, required this.end}) {
    Invariant.range(value: start, name: 'start', min: 0);
    Invariant.range(value: end, name: 'end', min: 0);

    Invariant.greaterThanRight(
      left: end,
      right: start,
      leftName: 'end',
      rightName: 'start',
      orEqualTo: true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FrameRange) {
      return false;
    }

    if (start != other.start) {
      return false;
    }

    if (end != other.end) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

class AnimationBindingManifest {
  final AnimationBindingIdentifier identifier;
  final TimelineIdentifier timeline;
  final SpriteAtlasIdentifier spriteAtlas;
  final FrameRange frameRange;
  final int frameCount;
  final Set<AnimationBindingTag> tags;

  AnimationBindingManifest({
    required this.identifier,
    required this.timeline,
    required this.spriteAtlas,
    required this.frameRange,
    required this.frameCount,
    required this.tags,
  }) {
    if (frameRange.end >= frameCount) {
      throw InvariantViolationError(
        'frameRange.end must be less than frameCount',
      );
    }

    if (frameRange.start > frameRange.end) {
      throw InvariantViolationError(
        'frameRange.start must be less than or equal to frameRange.end',
      );
    }

    if (tags.isEmpty) {
      throw InvariantViolationError('tags must contain at least one tag');
    }
  }

  (TimelineIdentifier, SpriteAtlasIdentifier, FrameRange) extractMetadata() {
    return (timeline, spriteAtlas, frameRange);
  }
}

class AnimationBindingEvent extends BaseEvent {
  AnimationBindingEvent(super.occurredAt);
}

class AnimationBindingManifestUpdated extends AnimationBindingEvent {
  final AnimationBindingIdentifier binding;
  final TimelineIdentifier timeline;
  final SpriteAtlasIdentifier spriteAtlas;
  final FrameRange frameRange;

  AnimationBindingManifestUpdated({
    required DateTime occurredAt,
    required this.binding,
    required this.timeline,
    required this.spriteAtlas,
    required this.frameRange,
  }) : super(occurredAt);
}

class Criteria implements ValueObject {
  final Set<AnimationBindingTag>? tags;

  Criteria({this.tags});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Criteria) {
      return false;
    }

    return tags == other.tags;
  }

  @override
  int get hashCode => tags.hashCode;
}

abstract interface class AnimationBindingManifestRepository {
  Future<AnimationBindingManifest> find(AnimationBindingIdentifier identifier);
  Future<List<AnimationBindingManifest>> search(Criteria criteria);
  Future<void> persist(AnimationBindingManifest manifest);
}
