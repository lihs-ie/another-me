import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

enum LoopMode { single, playlist }

class FadeDuration implements Comparable<FadeDuration>, ValueObject {
  final int milliseconds;

  FadeDuration({required this.milliseconds}) {
    Invariant.range(value: milliseconds, name: 'milliseconds', min: 0);
  }

  @override
  int compareTo(FadeDuration other) {
    return milliseconds.compareTo(other.milliseconds);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FadeDuration) {
      return false;
    }

    return milliseconds == other.milliseconds;
  }

  @override
  int get hashCode => milliseconds.hashCode;
}

class VolumeLevel implements ValueObject {
  final double value;
  final bool isMuted;

  VolumeLevel({required this.value, required this.isMuted}) {
    Invariant.range(value: value, name: 'value', min: 0.0, max: 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! VolumeLevel) {
      return false;
    }

    if (isMuted != other.isMuted) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
