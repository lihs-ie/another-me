import 'package:another_me/domains/library/animation/common.dart';

import '../../common.dart';
import '../../enum.dart';

class GridSizeFactory extends Factory<GridSize, ({int? value})> {
  @override
  GridSize create({({int? value})? overrides, required int seed}) {
    final supportedValues = [8, 16, 32];
    final value =
        overrides?.value ?? supportedValues[seed % supportedValues.length];

    return GridSize(value: value);
  }

  @override
  GridSize duplicate(GridSize instance, ({int? value})? overrides) {
    final value = overrides?.value ?? instance.value;

    return GridSize(value: value);
  }
}

typedef PivotOverrides = ({int? x, int? y, GridSize? gridSize});

class PivotFactory extends Factory<Pivot, PivotOverrides> {
  @override
  Pivot create({PivotOverrides? overrides, required int seed}) {
    final gridSize =
        overrides?.gridSize ?? Builder(GridSizeFactory()).buildWith(seed: seed);

    final x = overrides?.x ?? ((seed % 100) * gridSize.value);
    final y = overrides?.y ?? ((seed % 100 + 1) * gridSize.value);

    return Pivot(x: x, y: y, gridSize: gridSize);
  }

  @override
  Pivot duplicate(Pivot instance, PivotOverrides? overrides) {
    final x = overrides?.x ?? instance.x;
    final y = overrides?.y ?? instance.y;
    final gridSize =
        overrides?.gridSize ??
        Builder(GridSizeFactory()).duplicate(instance: instance.gridSize);

    return Pivot(x: x, y: y, gridSize: gridSize);
  }
}

class HitboxPurposeFactory extends EnumFactory<HitboxPurpose> {
  HitboxPurposeFactory() : super(HitboxPurpose.values);
}

typedef HitboxOverrides = ({
  int? originX,
  int? originY,
  int? width,
  int? height,
  HitboxPurpose? purpose,
});

class HitboxFactory extends Factory<Hitbox, HitboxOverrides> {
  @override
  Hitbox create({HitboxOverrides? overrides, required int seed}) {
    final originX = overrides?.originX ?? (seed % 100);
    final originY = overrides?.originY ?? (seed % 100 + 10);
    final width = overrides?.width ?? ((seed % 50) + 1);
    final height = overrides?.height ?? ((seed % 50) + 1);
    final purpose =
        overrides?.purpose ??
        Builder(HitboxPurposeFactory()).buildWith(seed: seed);

    return Hitbox(
      originX: originX,
      originY: originY,
      width: width,
      height: height,
      purpose: purpose,
    );
  }

  @override
  Hitbox duplicate(Hitbox instance, HitboxOverrides? overrides) {
    final originX = overrides?.originX ?? instance.originX;
    final originY = overrides?.originY ?? instance.originY;
    final width = overrides?.width ?? instance.width;
    final height = overrides?.height ?? instance.height;
    final purpose =
        overrides?.purpose ??
        Builder(HitboxPurposeFactory()).duplicate(instance: instance.purpose);

    return Hitbox(
      originX: originX,
      originY: originY,
      width: width,
      height: height,
      purpose: purpose,
    );
  }
}

typedef FrameSequenceOverrides = ({int? count, int? durationMilliseconds});

class FrameSequenceFactory
    extends Factory<FrameSequence, FrameSequenceOverrides> {
  @override
  FrameSequence create({FrameSequenceOverrides? overrides, required int seed}) {
    final count = overrides?.count ?? ((seed % 100) + 1);
    final durationMilliseconds =
        overrides?.durationMilliseconds ?? ((seed % 10000) + 1);

    return FrameSequence(
      count: count,
      durationMilliseconds: durationMilliseconds,
    );
  }

  @override
  FrameSequence duplicate(
    FrameSequence instance,
    FrameSequenceOverrides? overrides,
  ) {
    final count = overrides?.count ?? instance.count;
    final durationMilliseconds =
        overrides?.durationMilliseconds ?? instance.durationMilliseconds;

    return FrameSequence(
      count: count,
      durationMilliseconds: durationMilliseconds,
    );
  }
}
