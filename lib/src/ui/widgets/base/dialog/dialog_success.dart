import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/widgets/app_playful_dialog.dart';

class DialogSuccess extends StatelessWidget {
  final String message;
  final String? textConfirm;
  final void Function()? onConfirmPressed;

  const DialogSuccess({
    super.key,
    required this.message,
    this.textConfirm,
    this.onConfirmPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppPlayfulDialog(
      title: LocaleKey.success.tr,
      subtitle: message,
      tone: AppPlayfulDialogTone.success,
      showCloseButton: false,
      actions: [
        AppPlayfulDialogButton(
          label: textConfirm ?? LocaleKey.ok.tr,
          onTap: onConfirmPressed ?? () => Navigator.pop(context),
        ),
      ],
    );
  }
}
