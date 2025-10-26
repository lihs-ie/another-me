import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter/material.dart';

class Range<T extends Comparable<T>> implements ValueObject {
  final T? start;
  final T? end;

  Range({required this.start, required this.end}) {
    if (start != null && end != null) {
      Invariant.greaterThanRight(
        left: end!,
        right: start!,
        leftName: 'end',
        rightName: 'start',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Range<T>) {
      return false;
    }

    if (start != other.start) {
      return false;
    }

    if (end != other.end) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @protected
  bool validate() {
    // Noop
    return true;
  }

  bool isLessThan(T value) {
    if (end == null) {
      return false;
    }

    return end!.compareTo(value) < 0;
  }

  bool isGreaterThan(T value) {
    if (start == null) {
      return false;
    }

    return start!.compareTo(value) > 0;
  }

  bool includes(T value) {
    if (start != null && start!.compareTo(value) > 0) {
      return false;
    }

    if (end != null && end!.compareTo(value) < 0) {
      return false;
    }

    return true;
  }
}
