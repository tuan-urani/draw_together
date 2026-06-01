import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:draw_together/src/utils/app_colors.dart';

class CustomCircularProgress extends StatelessWidget {
  final Color color;

  const CustomCircularProgress({super.key, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Platform.isIOS
          ? CupertinoActivityIndicator(color: color)
          : CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 1.5,
            ),
    );
  }
}
