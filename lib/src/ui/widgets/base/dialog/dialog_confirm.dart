import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';

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
    return CupertinoAlertDialog(
      content: Padding(
        padding: 10.paddingVertical,
        child: Text(message, style: const TextStyle(fontSize: 16)),
      ),
      actions: [
        if (!hideCancelButton)
          CupertinoDialogAction(
            onPressed: onCancelPressed ?? () => Get.back(result: false),
            child: Text(textCancel ?? LocaleKey.cancel.tr),
          ),
        CupertinoDialogAction(
          onPressed: onConfirmPressed ?? () => Get.back(result: true),
          child: Text(textConfirm ?? LocaleKey.ok.tr),
        ),
      ],
    );
  }
}
