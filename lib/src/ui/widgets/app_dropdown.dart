import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:draw_together/src/utils/app_assets.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_dimensions.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class AppDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final String pathIcon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final EdgeInsets? margin;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintTextStyle;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    required this.onChanged,
    this.margin,
    this.textStyle,
    this.labelStyle,
    this.hintTextStyle,
    this.pathIcon = '',
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;

    final Color borderColor = isFocused
        ? AppColors.primary
        : AppColors.colorB8BCC6;

    final Color labelColor = isFocused
        ? AppColors.primary
        : AppColors.color667394;

    final BorderRadius borderRadius = AppDimensions.borderRadius;

    return Container(
      width: double.infinity,
      padding: widget.margin,
      child: DropdownButtonFormField<T>(
        focusNode: _focusNode,
        initialValue: widget.value,
        items: widget.items,
        onChanged: widget.onChanged,
        iconSize: 10,
        icon: SvgPicture.asset(
          widget.pathIcon.isEmpty
              ? AppAssets.iconsChevronDownSvg
              : widget.pathIcon,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle:
              widget.labelStyle ?? AppStyles.bodyMedium(color: labelColor),
          hintText: widget.hint,
          hintStyle:
              widget.hintTextStyle ?? AppStyles.bodyMedium(color: labelColor),
          filled: true,
          fillColor: AppColors.white,
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
        ),
        style:
            widget.textStyle ??
            AppStyles.bodyMedium(color: AppColors.color1D2410),
        dropdownColor: AppColors.white,
      ),
    );
  }
}
