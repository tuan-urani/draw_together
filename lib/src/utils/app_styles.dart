import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppStyles {
  // Font Families
  static const String fontFamily = 'ZenMaruGothic';
  static const String fontHiraginoKakuProW6 = 'ZenMaruGothic';
  static const String fontHiraginoKakuStd = 'ZenMaruGothic';

  static TextStyle h40({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(45.0, color, fontWeight, height, fontFamily: fontFamily);

  // Text Styles
  static TextStyle h1({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(32.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h2({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
  }) => _textStyle(28.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle headlineLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(36.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle titleLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(26.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h3({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
  }) => _textStyle(24.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h4({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w500,
    double? height,
  }) => _textStyle(20.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h5({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w500,
    double? height,
  }) => _textStyle(18.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle bodyLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(16.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle bodyMedium({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(14.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle bodySmall({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(12.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle caption({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(10.0, color, fontWeight, height, fontFamily: fontFamily);

  // Button Styles
  static TextStyle buttonLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.white,
    FontWeight fontWeight = FontWeight.w600,
  }) => _textStyle(16.0, color, fontWeight, 1.5, fontFamily: fontFamily);

  static TextStyle buttonMedium({
    String fontFamily = fontFamily,
    Color color = AppColors.white,
    FontWeight fontWeight = FontWeight.w500,
  }) => _textStyle(14.0, color, fontWeight, 1.4, fontFamily: fontFamily);

  static TextStyle buttonSmall({
    String fontFamily = fontFamily,
    Color color = AppColors.white,
    FontWeight fontWeight = FontWeight.w500,
  }) => _textStyle(12.0, color, fontWeight, 1.3, fontFamily: fontFamily);

  // Helper method for text styles
  static TextStyle _textStyle(
    double fontSize,
    Color color,
    FontWeight fontWeight,
    double? height, {
    required String fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }
}
