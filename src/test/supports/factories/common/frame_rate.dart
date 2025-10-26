import 'package:another_me/domains/common/frame_rate.dart';

import '../common.dart';

class FramesPerSecondFactory extends Factory<FramesPerSecond, ({int value})> {
  @override
  FramesPerSecond create({({int value})? overrides, required int seed}) {
    final value =
        overrides?.value ??
        FramesPerSecond.supportedValues.elementAt(
          seed % FramesPerSecond.supportedValues.length,
        );

    return FramesPerSecond(value: value);
  }

  @override
  FramesPerSecond duplicate(
    FramesPerSecond instance,
    ({int? value})? overrides,
  ) {
    final value = overrides?.value ?? instance.value;

    return FramesPerSecond(value: value);
  }
}
