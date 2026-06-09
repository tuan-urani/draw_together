import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/widgets/app_playful_dialog.dart';

class DialogConfirm extends StatelessWidget {
  final String message;
  final String? textConfirm;
  final String? textCancel;
  final void Function()? onConfirmPressed;
  final void Function()? onCancelPressed;
  final bool hideCancelButton;

  const DialogConfirm({
    super.key,
    required this.message,
    this.textConfirm,
    this.textCancel,
    this.onConfirmPressed,
    this.onCancelPressed,
    this.hideCancelButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppPlayfulDialog(
      title: LocaleKey.widgetConfirm.tr,
      subtitle: message,
      tone: AppPlayfulDialogTone.warning,
      showCloseButton: !hideCancelButton,
      actions: [
        if (!hideCancelButton)
          AppPlayfulDialogButton(
            label: textCancel ?? LocaleKey.cancel.tr,
            onTap: onCancelPressed ?? () => Get.back(result: false),
          ),
        AppPlayfulDialogButton(
          label: textConfirm ?? LocaleKey.ok.tr,
          style: AppPlayfulDialogButtonStyle.danger,
          onTap: onConfirmPressed ?? () => Get.back(result: true),
        ),
      ],
    );
  }
}
