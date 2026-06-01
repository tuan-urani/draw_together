import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_dimensions.dart';

class AppTextSection extends StatelessWidget {
  final Widget text;
  final SvgPicture icon;
  final Color color;
  final Color iconBackgroundColor;
  final TextStyle? textStyle;
  final double spacing;
  final double widthContainer;
  final double heightContainer;

  const AppTextSection({
    super.key,
    required this.text,
    required this.icon,
    this.color = AppColors.primary,
    this.iconBackgroundColor = AppColors.white,
    this.textStyle,
    this.spacing = 4.0,
    this.widthContainer = 28,
    this.heightContainer = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: widthContainer,
          height: heightContainer,
          padding: 4.paddingAll,
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            borderRadius: AppDimensions.borderRadius,
          ),
          child: icon,
        ),
        SizedBox(width: spacing),
        text,
      ],
    );
  }
}
