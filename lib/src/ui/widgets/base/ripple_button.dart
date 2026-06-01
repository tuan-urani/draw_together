import 'package:flutter/material.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_dimensions.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class RippleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? highlightColor;
  final ShapeBorder? customBorder;
  final bool enable;
  final double? height;
  final EdgeInsets? padding;
  final String? title;
  final Color? colorTitle;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final Color disabledColor;
  final EdgeInsets? margin;
  final double thickness;
  final double fontSizeTitle;
  final FontWeight fontWeight;
  final BoxBorder? border;
  final Color? tapColor;
  final Duration? tapColorDuration;

  const RippleButton({
    super.key,
    this.child = const SizedBox(),
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderRadius,
    this.customBorder,
    this.highlightColor,
    this.enable = true,
    this.height,
    this.padding,
    this.title,
    this.colorTitle,
    this.boxShadow,
    this.width,
    this.disabledColor = Colors.white54,
    this.margin,
    this.thickness = 1,
    this.fontSizeTitle = 16,
    this.fontWeight = FontWeight.normal,
    this.border,
    this.tapColor = AppColors.primary,
    this.tapColorDuration,
  });

  @override
  State<RippleButton> createState() => _RippleButtonState();
}

class _RippleButtonState extends State<RippleButton> {
  Color? _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.backgroundColor;
  }

  Future<void> _handleTap() async {
    if (!widget.enable) return;
    if (widget.tapColor != null) {
      if (mounted) {
        setState(() => _currentColor = widget.tapColor);
      }
      await Future.delayed(
        widget.tapColorDuration ?? const Duration(milliseconds: 300),
      );
      if (mounted) {
        setState(() => _currentColor = widget.backgroundColor);
      }
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      width: widget.width,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.all(12.radius),
        boxShadow: widget.enable ? widget.boxShadow : null,
        border: widget.border,
        color: _currentColor,
        gradient: _currentColor == null ? AppColors.primaryGradient() : null,
      ),
      child: MaterialButton(
        color: AppColors.transparent,
        disabledColor: AppColors.backgroundDisabled,
        highlightColor: AppColors.transparent,
        splashColor: AppColors.transparent,
        focusColor: AppColors.transparent,
        elevation: 0,
        minWidth: double.infinity,
        height: widget.height,
        shape:
            widget.customBorder ??
            RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.all(12.radius),
              side: BorderSide.none,
            ),
        onPressed: widget.enable ? _handleTap : null,
        onLongPress: widget.enable ? widget.onLongPress : null,
        padding: widget.padding ?? AppDimensions.allMargins,
        child: widget.title != null
            ? Text(
                widget.title!,
                style: AppStyles.bodyMedium(
                  color:
                      widget.colorTitle ??
                      (widget.enable
                          ? AppColors.white
                          : AppColors.textDisabled),
                  fontWeight: widget.fontWeight,
                ),
              )
            : widget.child,
      ),
    );
  }
}
