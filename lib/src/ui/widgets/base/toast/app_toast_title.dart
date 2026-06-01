import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/enums/toast_type.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:percent_indicator/percent_indicator.dart';

class AppToastTitle extends StatelessWidget {
  final ToastType toastType;

  const AppToastTitle({super.key, required this.toastType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: 8.paddingLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          toastType.title,
          LinearPercentIndicator(
            width: Get.width * .32,
            lineHeight: 4,
            percent: 1.0,
            backgroundColor: AppColors.primary,
            progressColor: AppColors.primary,
            animation: true,
            animationDuration: 3000,
            barRadius: 2.radius,
            padding: 6.paddingRight,
          ),
        ],
      ),
    );
  }
}
