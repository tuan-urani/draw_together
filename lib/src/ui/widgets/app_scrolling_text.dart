// Scrolling text widget
import 'package:flutter/material.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class AppScrollingText extends StatefulWidget {
  final String text;
  final double speed; // pixel/giây
  final TextStyle? style;

  const AppScrollingText({
    super.key,
    required this.text,
    this.speed = 50,
    this.style,
  });

  @override
  State<AppScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<AppScrollingText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late double _textWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setup();
    });
  }

  void _setup() {
    // Đo width của text
    final tp = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: widget.style ?? const TextStyle(),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _textWidth = tp.width;
    final screenWidth = MediaQuery.of(context).size.width;

    // Tổng quãng đường di chuyển = textWidth
    final durationSeconds = (_textWidth + screenWidth) / widget.speed;

    _controller = AnimationController(
      duration: Duration(seconds: durationSeconds.ceil()),
      vsync: this,
    )..repeat();

    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();

    return SizedBox(
      height: widget.style?.fontSize != null
          ? widget.style!.fontSize! * 1.4
          : 20,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, _) {
            final dx = -(_controller!.value * _textWidth);

            return OverflowBox(
              maxWidth: double.infinity, // Cho phép Row vượt màn hình
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      style:
                          widget.style ??
                          AppStyles.bodyLarge(
                            color: AppColors.white,
                            height: 1.4,
                          ),
                    ),
                    Text(
                      widget.text,
                      style:
                          widget.style ??
                          AppStyles.bodyLarge(
                            color: AppColors.white,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
