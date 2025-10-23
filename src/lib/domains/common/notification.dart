import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

class QuietHours implements ValueObject {
  final LocalTime start;
  final LocalTime end;

  QuietHours({required this.start, required this.end}) {
    Invariant.greaterThanRight<LocalTime>(
      left: end,
      right: start,
      leftName: 'end',
      rightName: 'start',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! QuietHours) {
      return false;
    }

    return start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

class LocalTime implements Comparable<LocalTime>, ValueObject {
  final int hour;
  final int minute;

  LocalTime({required this.hour, required this.minute}) {
    Invariant.range(value: hour, name: 'hour', min: 0, max: 23);
    Invariant.range(value: minute, name: 'minute', min: 0, max: 59);
  }

  int toMinutes() => hour * 60 + minute;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LocalTime) {
      return false;
    }

    return hour == other.hour && minute == other.minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  int compareTo(LocalTime other) {
    final thisMinutes = toMinutes();
    final otherMinutes = other.toMinutes();

    return thisMinutes.compareTo(otherMinutes);
  }
}
