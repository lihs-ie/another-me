import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:ulid/ulid.dart';

enum TimelineLoopMode { single, pingpong, loop }

class TimelineIdentifier extends ULIDBasedIdentifier {
  TimelineIdentifier({required Ulid value}) : super(value);

  factory TimelineIdentifier.generate() => TimelineIdentifier(value: Ulid());

  factory TimelineIdentifier.fromString(String value) =>
      TimelineIdentifier(value: Ulid.parse(value));

  factory TimelineIdentifier.fromBinary(Uint8List bytes) =>
      TimelineIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! TimelineIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class TimelineDefinition {
  final TimelineIdentifier identifier;
  final String name;
  final FramesPerSecond fps;
  final int frameCount;
  final TimelineLoopMode loopMode;
  final String? defaultNext;

  TimelineDefinition({
    required this.identifier,
    required this.name,
    required this.fps,
    required this.frameCount,
    required this.loopMode,
    required this.defaultNext,
  }) {
    Invariant.range(value: frameCount, name: 'frameCount', min: 1);

    if (frameCount % fps.value != 0) {
      throw InvariantViolationError(
        'frameCount must be a multiple of fps (${fps.value})',
      );
    }

    Invariant.length(value: name, name: 'name', min: 1);

    if (loopMode == TimelineLoopMode.single && defaultNext == null) {
      throw InvariantViolationError(
        'defaultNext is required when loopMode is single',
      );
    }
  }
}

class TimelineEvent extends BaseEvent {
  TimelineEvent(super.occurredAt);
}

class TimelineDefinitionRegistered extends TimelineEvent {
  final TimelineIdentifier timeline;
  final FramesPerSecond fps;
  final int frameCount;

  TimelineDefinitionRegistered({
    required DateTime occurredAt,
    required this.timeline,
    required this.fps,
    required this.frameCount,
  }) : super(occurredAt);
}

abstract interface class TimelineDefinitionRepository {
  Future<TimelineDefinition> find(TimelineIdentifier identifier);
  Future<void> persist(TimelineDefinition definition);
}
