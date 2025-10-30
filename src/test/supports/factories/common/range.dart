import 'package:another_me/domains/common/range.dart';

import '../common.dart';

typedef RangeOverrides<T extends Comparable<T>> = ({T? start, T? end});

class RangeFactory<T extends Comparable<T>, O>
    extends Factory<Range<T>, RangeOverrides<T>> {
  final Factory<T, O> valueFactory;

  RangeFactory(this.valueFactory);

  @override
  Range<T> create({RangeOverrides<T>? overrides, required int seed}) {
    final start =
        overrides?.start ?? Builder(valueFactory).buildWith(seed: seed);
    final end =
        overrides?.end ?? Builder(valueFactory).buildWith(seed: seed + 1);

    return Range<T>(start: start, end: end);
  }

  @override
  Range<T> duplicate(Range<T> instance, RangeOverrides<T>? overrides) {
    final start =
        overrides?.start ??
        (instance.start != null
            ? Builder(
                valueFactory,
              ).duplicate(instance: instance.start as T, overrides: null)
            : null);

    final end =
        overrides?.end ??
        (instance.end != null
            ? Builder(
                valueFactory,
              ).duplicate(instance: instance.end as T, overrides: null)
            : null);

    return Range<T>(start: start, end: end);
  }
}
