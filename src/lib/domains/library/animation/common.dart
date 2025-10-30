import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

class GridSize implements ValueObject {
  final int value;
  final Set<int> _supportedValues = const {8, 16, 32};

  GridSize({required this.value}) {
    if (!_supportedValues.contains(value)) {
      throw InvariantViolationError(
        'value must be one of supported values: {8, 16, 32}',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! GridSize) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class Pivot implements ValueObject {
  final int x;
  final int y;
  final GridSize gridSize;

  Pivot({required this.x, required this.y, required this.gridSize}) {
    Invariant.range(value: x, name: 'x', min: 0);
    Invariant.range(value: y, name: 'y', min: 0);

    if (x % gridSize.value != 0) {
      throw InvariantViolationError(
        'x must be a multiple of gridSize (${gridSize.value})',
      );
    }

    if (y % gridSize.value != 0) {
      throw InvariantViolationError(
        'y must be a multiple of gridSize (${gridSize.value})',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Pivot) {
      return false;
    }

    return x == other.x && y == other.y && gridSize == other.gridSize;
  }

  @override
  int get hashCode => Object.hash(x, y, gridSize);

  (double normalizedX, double normalizedY) normalize(
    int atlasWidth,
    int atlasHeight,
  ) {
    if (atlasWidth <= 0 || atlasHeight <= 0) {
      throw InvariantViolationError(
        'atlasWidth and atlasHeight must be positive integers',
      );
    }

    return (x / atlasWidth, y / atlasHeight);
  }
}

enum HitboxPurpose { interaction, effect, boundingBox }

class Hitbox implements ValueObject {
  final int originX;
  final int originY;
  final int width;
  final int height;
  final HitboxPurpose purpose;

  Hitbox({
    required this.originX,
    required this.originY,
    required this.width,
    required this.height,
    required this.purpose,
  }) {
    Invariant.range(value: originX, name: 'originX', min: 0);
    Invariant.range(value: originY, name: 'originY', min: 0);
    Invariant.range(value: width, name: 'width', min: 1);
    Invariant.range(value: height, name: 'height', min: 1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Hitbox) {
      return false;
    }

    if (originX != other.originX) {
      return false;
    }

    if (originY != other.originY) {
      return false;
    }

    if (width != other.width) {
      return false;
    }

    if (height != other.height) {
      return false;
    }

    if (purpose != other.purpose) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(originX, originY, width, height);

  bool contains(int x, int y) {
    if (x < originX || originX + width <= x) {
      return false;
    }

    if (y < originY || originY + height <= y) {
      return false;
    }

    return true;
  }
}

class FrameSequence implements ValueObject {
  final int count;
  final int durationMilliseconds;

  FrameSequence({required this.count, required this.durationMilliseconds}) {
    Invariant.range(value: count, name: 'count', min: 1);
    Invariant.range(
      value: durationMilliseconds,
      name: 'durationMilliseconds',
      min: 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FrameSequence) {
      return false;
    }

    if (count != other.count) {
      return false;
    }

    if (durationMilliseconds != other.durationMilliseconds) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(count, durationMilliseconds);

  double get frameDurationMilliseconds => durationMilliseconds / count;
}
