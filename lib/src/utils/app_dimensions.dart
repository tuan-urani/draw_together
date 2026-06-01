import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDimensions {
  /// Use for padding
  static const double top = 14;
  static const double marginLeft = 14;
  static const double marginRight = 14;
  static const EdgeInsets sideMargins = EdgeInsets.symmetric(horizontal: 14);
  static const EdgeInsets allMargins = EdgeInsets.all(14);

  static const EdgeInsetsGeometry paddingTop = EdgeInsets.only(top: 280);

  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static double bottomBarHeight = 80 + Get.mediaQuery.padding.bottom;
  static double iconPlusBottomBarHeight = 40;
  static double totalBottomBarHeight =
      bottomBarHeight + iconPlusBottomBarHeight;
}
