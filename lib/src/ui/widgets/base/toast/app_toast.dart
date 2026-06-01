import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/enums/toast_type.dart';
import 'package:draw_together/src/extensions/color_extension.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast_title.dart';
import 'package:draw_together/src/utils/app_colors.dart';

void showSuccessToast(String? message) => showToast(message);

void showErrorToast(String? message) =>
    showToast(message, toastType: ToastType.error);

SnackbarController? showToast(
  String? message, {
  ToastType toastType = ToastType.success,
}) {
  if (message == null || message.isEmpty) return null;
  return Get.rawSnackbar(
    titleText: AppToastTitle(toastType: toastType),
    messageText: Padding(
      padding: 8.paddingLeft,
      child: Text(message, style: const TextStyle(color: AppColors.black)),
    ),
    backgroundColor: AppColors.white,
    borderRadius: 12,
    duration: const Duration(seconds: 3),
    boxShadows: [
      BoxShadow(
        color: AppColors.black.withOpacityX(0.3),
        offset: const Offset(0, 4),
        blurRadius: 20,
      ),
    ],
    snackPosition: SnackPosition.TOP,
    dismissDirection: DismissDirection.horizontal,
    icon: toastType.icon,
    margin: 16.paddingHorizontal.copyWith(top: 12),
    padding: 16.paddingAll.copyWith(left: 22),
    animationDuration: const Duration(milliseconds: 500),
  );
}

SnackbarController? showConnectWifi(
  String? message, {
  required bool isConnect,
  Color backgroundColor = Colors.green,
}) {
  if (message == null || message.isEmpty) return null;
  return Get.rawSnackbar(
    message: message,
    backgroundColor: backgroundColor,
    snackPosition: SnackPosition.TOP,
    forwardAnimationCurve: Curves.easeIn,
    reverseAnimationCurve: Curves.easeIn,
    duration: const Duration(seconds: 4),
    animationDuration: const Duration(seconds: 2),
    icon: Icon(
      Icons.wifi,
      color: isConnect ? Colors.green : AppColors.black.withOpacityX(0.87),
    ),
    isDismissible: false,
  );
}
