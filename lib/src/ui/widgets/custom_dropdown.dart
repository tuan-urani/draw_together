import 'package:flutter/material.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final bool hasValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool isExpanded;

  const CustomDropdown({
    super.key,
    this.value,
    this.hint,
    this.hasValue = false,
    this.items,
    this.onChanged,
    this.validator,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      hint: hint != null ? Text(hint!) : null,
      isExpanded: isExpanded,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: 16.paddingHorizontal.copyWith(top: 0, bottom: 0),
        border: OutlineInputBorder(
          borderRadius: 8.borderRadiusAll,
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: AppColors.black, fontSize: 14),
      dropdownColor: AppColors.white,
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.black),
    );
  }
}
