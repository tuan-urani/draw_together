import 'package:flutter/material.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_dimensions.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class AppCheckbox extends StatelessWidget {
  final String title;
  final bool? isChecked;
  final VoidCallback onTap;
  final Color bgActive;
  final Color? borderColor;
  final double spacing;
  final double iconSize;
  final double? numberCompletedTask;
  final double? totalCompleteTask;
  final Icon? iconCheck;
  final Icon? iconUncheck;

  const AppCheckbox({
    super.key,
    required this.title,
    this.isChecked = false,
    required this.onTap,
    this.bgActive = AppColors.colorFE6F4EC,
    this.borderColor,
    this.spacing = 8,
    this.iconSize = 22,
    this.numberCompletedTask,
    this.totalCompleteTask,
    this.iconCheck,
    this.iconUncheck,
  });

  @override
  Widget build(BuildContext context) {
    final checked = isChecked ?? false;
    final resolvedBorderColor =
        borderColor ??
        (checked ? AppColors.transparent : AppColors.colorDFE4F5);

    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: Container(
        padding: AppDimensions.allMargins,
        decoration: BoxDecoration(
          color: checked ? bgActive : AppColors.white,
          borderRadius: AppDimensions.borderRadius,
          border: Border.all(color: resolvedBorderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: checked
                  ? iconCheck ??
                        Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: iconSize,
                        )
                  : iconUncheck ??
                        Icon(
                          Icons.check_box_outline_blank,
                          color: AppColors.colorDFE4F5,
                          size: iconSize,
                        ),
            ),
            spacing.toInt().width,
            Text(
              title,
              style: AppStyles.bodyMedium(color: AppColors.color667394),
            ),
            Spacer(),
            _buildTaskProgress(checked),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskProgress(bool checked) {
    if (numberCompletedTask != null && totalCompleteTask != null) {
      return Container(
        padding: 8.paddingAll,
        decoration: BoxDecoration(
          color: checked ? AppColors.primary : AppColors.colorFBFC9DE,
          borderRadius: 8.borderRadiusAll,
        ),
        child: Text(
          '${numberCompletedTask!.toInt()}/${totalCompleteTask!.toInt()}',
          style: AppStyles.bodyMedium(color: AppColors.white),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
