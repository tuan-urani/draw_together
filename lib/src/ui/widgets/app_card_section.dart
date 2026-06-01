import 'package:flutter/material.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_dimensions.dart';

class AppCardSection extends StatelessWidget {
  final Color color;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;
  final Widget child;

  const AppCardSection({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.borderRadius = AppDimensions.borderRadius,
    this.padding = AppDimensions.allMargins,
    this.margin,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        border: border,
      ),
      child: child,
    );
  }
}
