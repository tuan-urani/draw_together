import 'package:flutter/material.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class AppTextGradient extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign textAlign;

  const AppTextGradient({
    super.key,
    required this.text,
    this.style,
    this.gradient = const LinearGradient(
      colors: [AppColors.primary, AppColors.white],
    ),
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: style ?? AppStyles.h4(color: AppColors.black),
      ),
    );
  }
}
