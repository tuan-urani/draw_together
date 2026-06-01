import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../extensions/int_extensions.dart';
import '../locale/locale_key.dart';
import '../utils/app_colors.dart';

enum ToastType {
  success(Colors.green),
  error(AppColors.error);

  final Color color;
  const ToastType(this.color);

  Widget get icon {
    IconData icon;
    switch (this) {
      case ToastType.success:
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        icon = Icons.error_rounded;
    }

    return Padding(
      padding: 20.paddingLeft,
      child: Icon(icon, size: 40, color: color),
    );
  }

  Widget get title {
    switch (this) {
      case ToastType.success:
        return Text(LocaleKey.success.tr, style: TextStyle(color: color));
      case ToastType.error:
        return Text(LocaleKey.error.tr, style: TextStyle(color: color));
    }
  }
}
