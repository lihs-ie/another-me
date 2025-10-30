class AggregateNotFoundError implements Exception {
  final String message;
  AggregateNotFoundError(this.message);

  @override
  String toString() => 'AggregateNotFoundError: $message';
}
