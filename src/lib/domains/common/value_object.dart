abstract interface class ValueObject {
  @override
  bool operator ==(Object other);
  @override
  int get hashCode;
}
