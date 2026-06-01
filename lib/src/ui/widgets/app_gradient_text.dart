import 'package:flutter/material.dart';

class AppGradientText extends StatelessWidget {
  final Widget? widget;

  const AppGradientText({
    super.key,
    required this.text,
    required this.gradient,
    this.style,
    this.widget,
    this.textAlign,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Gradient gradient;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child:
          widget ??
          Text(
            text,
            style: style,
            textAlign: textAlign ?? TextAlign.start,
            overflow: overflow ?? TextOverflow.clip,
          ),
    );
  }
}
