import 'package:another_me/domains/common/notification.dart';

import '../common.dart';

class LocalTimeFactory extends Factory<LocalTime, ({int? hour, int? minute})> {
  @override
  LocalTime create({({int? hour, int? minute})? overrides, required int seed}) {
    final hour = overrides?.hour ?? (seed % 24);
    final minute = overrides?.minute ?? (seed % 60);

    return LocalTime(hour: hour, minute: minute);
  }

  @override
  LocalTime duplicate(
    LocalTime instance,
    ({int? hour, int? minute})? overrides,
  ) {
    final hour = overrides?.hour ?? instance.hour;
    final minute = overrides?.minute ?? instance.minute;

    return LocalTime(hour: hour, minute: minute);
  }
}

class QuietHoursFactory
    extends Factory<QuietHours, ({LocalTime? start, LocalTime? end})> {
  @override
  QuietHours create({
    ({LocalTime? start, LocalTime? end})? overrides,
    required int seed,
  }) {
    final start =
        overrides?.start ?? Builder(LocalTimeFactory()).buildWith(seed: seed);
    final end =
        overrides?.end ?? Builder(LocalTimeFactory()).buildWith(seed: seed + 1);

    return QuietHours(start: start, end: end);
  }

  @override
  QuietHours duplicate(
    QuietHours instance,
    ({LocalTime? start, LocalTime? end})? overrides,
  ) {
    final start =
        overrides?.start ??
        Builder(LocalTimeFactory()).duplicate(instance.start, null);
    final end =
        overrides?.end ??
        Builder(LocalTimeFactory()).duplicate(instance.end, null);

    return QuietHours(start: start, end: end);
  }
}
