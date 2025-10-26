import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

class FramesPerSecond implements ValueObject {
  final int value;

  static const Set<int> supportedValues = {12, 24, 30, 48, 60, 96, 120};

  FramesPerSecond({required this.value}) {
    if (!supportedValues.contains(value)) {
      throw InvariantViolationError(
        'value must be one of supported values: $supportedValues',
      );
    }
  }

  factory FramesPerSecond.fromInteger(int fps) => FramesPerSecond(value: fps);

  int get frameDurationMs => (1000 / value).round();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FramesPerSecond) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  double frameDurationMilliseconds() => 1000.0 / value;

  double totalDurationMilliseconds(int frameCount) =>
      frameCount * frameDurationMilliseconds();
}
