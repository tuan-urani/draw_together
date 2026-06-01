import 'package:flutter/material.dart';

/// Tai cac UI, Widget sau nay chi can go 6.height or 6.width thay vi phai ghi SizedBox(width: 6), SizedBox(height: 6)
extension IntExtensions on int? {
  /// Leaves given height of space
  Widget get height => SizedBox(height: this?.toDouble());

  /// Leaves given width of space
  Widget get width => SizedBox(width: this?.toDouble());

  /// Radius
  Radius get radius => Radius.circular(this?.toDouble() ?? 0);

  /// BorderRadius All
  BorderRadius get borderRadiusAll =>
      BorderRadius.circular(this?.toDouble() ?? 0);

  /// BorderRadius Top
  BorderRadius get borderRadiusTop =>
      BorderRadius.vertical(top: (this ?? 0).radius);

  /// BorderRadius Bottom
  BorderRadius get borderRadiusBottom =>
      BorderRadius.vertical(bottom: (this ?? 0).radius);

  /// BorderRadius Left
  BorderRadius get borderRadiusLeft =>
      BorderRadius.horizontal(left: (this ?? 0).radius);

  /// BorderRadius Right
  BorderRadius get borderRadiusRight =>
      BorderRadius.horizontal(right: (this ?? 0).radius);

  /// Padding all
  EdgeInsets get paddingAll => EdgeInsets.all((this ?? 0).toDouble());

  /// Padding horizontal
  EdgeInsets get paddingHorizontal =>
      EdgeInsets.symmetric(horizontal: (this ?? 0).toDouble());

  /// Padding vertical
  EdgeInsets get paddingVertical =>
      EdgeInsets.symmetric(vertical: (this ?? 0).toDouble());

  EdgeInsets get paddingLeft => EdgeInsets.only(left: (this ?? 0).toDouble());

  EdgeInsets get paddingRight => EdgeInsets.only(right: (this ?? 0).toDouble());

  EdgeInsets get paddingTop => EdgeInsets.only(top: (this ?? 0).toDouble());

  EdgeInsets get paddingBottom =>
      EdgeInsets.only(bottom: (this ?? 0).toDouble());
}
