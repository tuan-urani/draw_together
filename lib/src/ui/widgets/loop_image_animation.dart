import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:draw_together/src/utils/app_colors.dart';

class AnimatedImage extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;

  const AnimatedImage({
    super.key,
    required this.imagePath,
    this.width = 200,
    this.height = 200,
    this.fit = BoxFit.contain,
  });

  @override
  State<AnimatedImage> createState() => _AnimatedImageState();
}

class _AnimatedImageState extends State<AnimatedImage>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Gif(
      image: AssetImage(widget.imagePath),
      autostart: Autostart.loop,
      useCache: true,
      placeholder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
