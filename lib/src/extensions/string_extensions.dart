import 'dart:io';

extension NullableStringExtensions on String? {
  /// Returns [true] if this nullable string is either null or empty.
  bool isNullOrEmpty() {
    return this?.trim().isEmpty ?? true;
  }
}

extension StringExtensions on String {
  bool get isNetworkUri => startsWith('http');

  bool get isSvg => endsWith('.svg');

  bool get isLocalPath => File(this).existsSync();

  /// Capitalize first letter of the word
  String get inFirstLetterCaps =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';

  /// Capitalize first letter of each word
  String get capitalizeFirstOfEach => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.inFirstLetterCaps).join(' ');

  /// Format thousands number to convert to double.
  String get formatThousands => replaceAll(',', '');
}
