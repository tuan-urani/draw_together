import 'dart:math';

import 'package:flutter/material.dart';
import 'package:draw_together/src/utils/app_colors.dart';

class AppProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final double width;
  final Color backgroundColor;
  final Gradient progressGradient;
  final BorderRadius? borderRadius;
  final double? padding;
  final double? widthDot;
  final double? heightDot;
  final bool showDot;

  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.backgroundColor = AppColors.colorE8EDF5,
    required this.width,
    required this.progressGradient,
    this.borderRadius,
    this.padding = 6.0,
    this.widthDot = 4.0,
    this.heightDot = 8.0,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(height / 2);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: radius),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: const Duration(milliseconds: 500),
        builder: (context, animValue, child) {
          final currentWidth = max(0.0, (width * animValue) - (padding ?? 6));
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: currentWidth + (padding ?? 6),
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: radius,
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: currentWidth,
                    height: height - (padding ?? 6),
                    decoration: BoxDecoration(
                      gradient: progressGradient,
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
              if (showDot)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: currentWidth - 10,
                  top: (height - (heightDot ?? 8)) / 2,
                  child: Container(
                    width: widthDot,
                    height: heightDot,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
