import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';

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
    return CupertinoAlertDialog(
      content: Padding(
        padding: 10.paddingVertical,

        child: Text(message, style: const TextStyle(fontSize: 16)),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onConfirmPressed ?? () => Navigator.pop(context),
          child: Text(textConfirm ?? LocaleKey.ok.tr),
        ),
      ],
    );
  }
}
