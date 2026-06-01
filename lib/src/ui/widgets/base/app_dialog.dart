import 'package:get/get.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/widgets/base/dialog/dialog_confirm.dart';
import 'package:draw_together/src/ui/widgets/base/dialog/dialog_error.dart';
import 'package:draw_together/src/ui/widgets/base/dialog/dialog_success.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_shared.dart';

Future<dynamic> showDialogErrorToken() {
  if (Get.isDialogOpen == true) return Future.value();
  return Get.dialog(
    DialogConfirm(
      message: LocaleKey.loginSessionExpires,
      onConfirmPressed: () async {
        await Get.find<AppShared>().clear();
        await Get.offNamedUntil(AppPages.splash, (route) => false);
      },
    ),
    barrierDismissible: false,
  );
}

Future<void> showErrorDialog(String message) {
  if (message.isEmpty) return Future.value();
  if (Get.isDialogOpen == true) return Future.value();
  return Get.dialog(DialogError(message: message), barrierDismissible: false);
}

Future<void> showSuccessDialog(String message) {
  if (message.isEmpty) return Future.value();
  if (Get.isDialogOpen == true) return Future.value();
  return Get.dialog(DialogSuccess(message: message), barrierDismissible: false);
}

Future<dynamic> showConfirmDialog(
  String? message, {
  String? textConfirm,
  void Function()? onConfirmPressed,
  String? textCancel,
  void Function()? onCancelPressed,
}) {
  if (message == null || message.isEmpty) return Future.value();
  if (Get.isDialogOpen == true) return Future.value();
  return Get.dialog(
    DialogConfirm(
      message: message,
      textConfirm: textConfirm,
      textCancel: textCancel,
      onConfirmPressed: onConfirmPressed,
      onCancelPressed: onCancelPressed,
    ),
    barrierDismissible: false,
  );
}
