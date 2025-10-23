class InvariantViolationException implements Exception {
  final String message;
  InvariantViolationException(this.message);

  @override
  String toString() => 'InvariantViolationException: $message';
}

class Invariant {
  Invariant._();

  static void length({
    required String value,
    required String name,
    int? min,
    int? max,
  }) {
    final len = value.length;

    if (min != null && max != null && (len < min || max < len)) {
      throw InvariantViolationException(
        'Length of $name must be between $min and $max.',
      );
    }
    if (min != null && len < min) {
      throw InvariantViolationException(
        'Length of $name must be greater than or equal to $min.',
      );
    }
    if (max != null && max < len) {
      throw InvariantViolationException(
        'Length of $name must be less than or equal to $max.',
      );
    }
  }

  static void notContains({
    required String value,
    required String name,
    required String needle,
  }) {
    if (value.contains(needle)) {
      throw InvariantViolationException(
        '${_ucfirst(name)} must not contain $needle.',
      );
    }
  }

  static void pattern({
    required String value,
    required String name,
    required String pattern,
  }) {
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      throw InvariantViolationException(
        '${_ucfirst(name)} must be matched for `$pattern`. `$value` is given.',
      );
    }
  }

  static void range<T extends num>({
    required T value,
    required String name,
    T? min,
    T? max,
  }) {
    if (min != null && max != null && (value < min || max < value)) {
      throw InvariantViolationException(
        '${_ucfirst(name)} must be between $min and $max.',
      );
    }

    if (min != null && value < min) {
      throw InvariantViolationException(
        '${_ucfirst(name)} must be greater than or equal to $min.',
      );
    }

    if (max != null && max < value) {
      throw InvariantViolationException(
        '${_ucfirst(name)} must be less than or equal to $max.',
      );
    }
  }

  static void greaterThanRight<T extends Comparable<T>>({
    required T left,
    required T right,
    required String leftName,
    required String rightName,
    bool orEqualTo = false,
  }) {
    final cmp = left.compareTo(right);
    final ok = orEqualTo ? (cmp >= 0) : (cmp > 0);
    if (!ok) {
      throw InvariantViolationException(
        '${_ucfirst(leftName)} must be ${orEqualTo ? 'greater than or equal to' : 'greater than'} ${_ucfirst(rightName)}.',
      );
    }
  }

  static void lessThanRight<T extends Comparable<T>>({
    required T left,
    required T right,
    required String leftName,
    required String rightName,
    bool orEqualTo = false,
  }) {
    final cmp = left.compareTo(right);
    final ok = orEqualTo ? (cmp <= 0) : (cmp < 0);
    if (!ok) {
      throw InvariantViolationException(
        '${_ucfirst(leftName)} must be ${orEqualTo ? 'less than or equal to' : 'less than'} ${_ucfirst(rightName)}.',
      );
    }
  }

  static String _ucfirst(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
