import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter/foundation.dart';

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
