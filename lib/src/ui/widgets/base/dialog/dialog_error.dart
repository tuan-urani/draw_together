import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/widgets/app_playful_dialog.dart';

class DialogError extends StatelessWidget {
  final String message;
  final String? textConfirm;
  final void Function()? onConfirmPressed;

  const DialogError({
    super.key,
    required this.message,
    this.textConfirm,
    this.onConfirmPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppPlayfulDialog(
      title: LocaleKey.error.tr,
      subtitle: message,
      tone: AppPlayfulDialogTone.danger,
      showCloseButton: false,
      actions: [
        AppPlayfulDialogButton(
          label: textConfirm ?? LocaleKey.ok.tr,
          style: AppPlayfulDialogButtonStyle.danger,
          onTap: onConfirmPressed ?? () => Navigator.pop(context),
        ),
      ],
    );
  }
}
