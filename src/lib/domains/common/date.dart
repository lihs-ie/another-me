import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

enum DayPeriod { morning, noon, night }

class OfflineGracePeriod implements ValueObject {
  final int minutes;

  OfflineGracePeriod({required this.minutes}) {
    Invariant.range(value: minutes, name: 'minutes', min: 1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! OfflineGracePeriod) {
      return false;
    }

    return minutes == other.minutes;
  }

  @override
  int get hashCode => minutes.hashCode;
}

class Timeline implements ValueObject {
  final DateTime createdAt;
  final DateTime updatedAt;

  Timeline({required this.createdAt, required this.updatedAt}) {
    Invariant.lessThanRight(
      left: createdAt,
      right: updatedAt,
      leftName: 'createdAt',
      rightName: 'updatedAt',
      orEqualTo: true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Timeline) {
      return false;
    }

    if (createdAt != other.createdAt) {
      return false;
    }

    if (updatedAt != other.updatedAt) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(createdAt, updatedAt);

  DateTime age(DateTime now) {
    final duration = now.difference(createdAt);

    return DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds);
  }

  DateTime lastUpdateAge(DateTime now) {
    final duration = now.difference(updatedAt);

    return DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds);
  }

  Timeline markUpdated(DateTime now) {
    return Timeline(createdAt: createdAt, updatedAt: now);
  }
}
