import 'package:flutter/material.dart';
import 'package:draw_together/src/utils/app_colors.dart';

class AppCircularProgress extends StatelessWidget {
  final Color color;
  final double size;

  const AppCircularProgress({
    super.key,
    this.color = AppColors.white,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
