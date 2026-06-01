import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpInput extends StatelessWidget {
  final TextEditingController? controller;
  final Color? color;
  final Color? textColor;
  final Function(String?) onChanged;

  const OtpInput({
    super.key,
    this.controller,
    required this.onChanged,
    this.color = AppColors.colorE1E1E1,
    this.textColor = AppColors.color484848,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      autoDisposeControllers: controller == null,
      controller: controller,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      appContext: context,
      errorTextSpace: 0,
      length: 6,
      textStyle: AppStyles.h3(color: textColor!),
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        fieldOuterPadding: EdgeInsets.zero,
        borderWidth: 1,
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(10),
        fieldHeight: 55,
        fieldWidth: (Get.width - 100) / 6,
        activeFillColor: AppColors.transparent,
        activeColor: AppColors.colorE1E1E1,
        selectedFillColor: AppColors.colorE3F2D9,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.colorE1E1E1,
        inactiveFillColor: AppColors.transparent,
        inactiveColor: color,
      ),
      cursorColor: textColor,
      enableActiveFill: true,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      beforeTextPaste: (_) => false,
    );
  }
}
