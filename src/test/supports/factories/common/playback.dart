import 'package:another_me/domains/common/playback.dart';

import '../common.dart';
import '../enum.dart';

class LoopModeFactory extends EnumFactory<LoopMode> {
  LoopModeFactory() : super(LoopMode.values);
}

class PlaybackModeFactory extends EnumFactory<PlaybackMode> {
  PlaybackModeFactory() : super(PlaybackMode.values);
}

class FadeDurationFactory extends Factory<FadeDuration, ({int? milliseconds})> {
  @override
  FadeDuration create({({int? milliseconds})? overrides, required int seed}) {
    final milliseconds = overrides?.milliseconds ?? (seed % 10000);

    return FadeDuration(milliseconds: milliseconds);
  }

  @override
  FadeDuration duplicate(
    FadeDuration instance,
    ({int? milliseconds})? overrides,
  ) {
    final milliseconds = overrides?.milliseconds ?? instance.milliseconds;

    return FadeDuration(milliseconds: milliseconds);
  }
}
