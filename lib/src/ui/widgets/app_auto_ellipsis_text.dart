import 'package:flutter/material.dart';

class AppAutoEllipsisText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const AppAutoEllipsisText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final TextStyle effectiveStyle =
            style ?? DefaultTextStyle.of(context).style;

        // Chiều cao 1 dòng text
        final double lineHeight =
            (effectiveStyle.height ?? 1.0) * (effectiveStyle.fontSize ?? 14);

        // Số dòng tối đa dựa trên chiều cao của Container
        final int maxLines = (constraints.maxHeight / lineHeight).floor();

        return Text(
          text,
          style: effectiveStyle,
          maxLines: maxLines > 0 ? maxLines : 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
