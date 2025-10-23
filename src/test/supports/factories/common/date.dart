import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/playback.dart';

import '../common.dart';
import '../enum.dart';

class DayPeriodFactory extends EnumFactory<DayPeriod> {
  DayPeriodFactory() : super(DayPeriod.values);
}

class OfflineGracePeriodFactory
    extends Factory<OfflineGracePeriod, ({int? minutes})> {
  @override
  OfflineGracePeriod create({({int? minutes})? overrides, required int seed}) {
    final minutes = overrides?.minutes ?? ((seed % 120) + 1);

    return OfflineGracePeriod(minutes: minutes);
  }

  @override
  OfflineGracePeriod duplicate(
    OfflineGracePeriod instance,
    ({int? minutes})? overrides,
  ) {
    final minutes = overrides?.minutes ?? instance.minutes;

    return OfflineGracePeriod(minutes: minutes);
  }
}

class VolumeLevelFactory
    extends Factory<VolumeLevel, ({double? value, bool? isMuted})> {
  @override
  VolumeLevel create({
    ({double? value, bool? isMuted})? overrides,
    required int seed,
  }) {
    final value = overrides?.value ?? ((seed % 101) / 100.0);
    final isMuted = overrides?.isMuted ?? seed % 2 == 0;

    return VolumeLevel(value: value, isMuted: isMuted);
  }

  @override
  VolumeLevel duplicate(
    VolumeLevel instance,
    ({double? value, bool? isMuted})? overrides,
  ) {
    final value = overrides?.value ?? instance.value;
    final isMuted = overrides?.isMuted ?? instance.isMuted;

    return VolumeLevel(value: value, isMuted: isMuted);
  }
}
