extension DoubleNullExtension on double? {
  bool get isNotNull => this != null;
}

extension DouleWithoutDecimal on double? {
  String get withoutDecimal =>
      this != null ? (this! % 1 == 0 ? '${this!.toInt()}' : '$this') : '0';
}
