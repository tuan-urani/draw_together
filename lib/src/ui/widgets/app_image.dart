import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/extensions/double_extensions.dart';
import 'package:draw_together/src/extensions/string_extensions.dart';
import 'package:draw_together/src/ui/widgets/app_circular_progress.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.image,
    this.aspectRatio,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.radius,
    this.colorImage,
    this.opacity = 1,
    this.fit,
    this.progressIndicatorWidget,
  });

  final String image;
  final double? aspectRatio;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? radius;
  final Color? colorImage;
  final double opacity; // >=0 and <= 1
  final BoxFit? fit;
  final Widget? progressIndicatorWidget;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: Container(
        padding: padding,
        margin: margin,
        color: backgroundColor,
        child: aspectRatio != null
            ? AspectRatio(aspectRatio: aspectRatio!, child: _buildImage())
            : _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        image.isEmpty
            ? const SizedBox()
            : image.isNetworkUri
            ? CachedNetworkImage(
                imageUrl: image,
                color: colorImage,
                width: widthImage(),
                height: heightImage(),
                fit: fit ?? BoxFit.cover,
                errorWidget: (_, _, _) {
                  return SizedBox(
                    width: widthImage(),
                    height: heightImage(),
                    child: const SizedBox(),
                  );
                },
                progressIndicatorBuilder: (_, _, _) =>
                    progressIndicatorWidget ??
                    SizedBox(
                      width: widthImage(),
                      height: heightImage() ?? Get.height,
                      child: AppCircularProgress(),
                    ),
              )
            : image.isSvg
            ? SvgPicture.asset(
                image,
                width: widthImage(),
                height: heightImage(),
                fit: fit ?? BoxFit.contain,
              )
            : (image.isLocalPath
                  ? Image.file(
                      File(image),
                      color: colorImage,
                      width: widthImage(),
                      height: heightImage(),
                      fit: fit ?? BoxFit.cover,
                    )
                  : Image.asset(
                      image,
                      color: colorImage,
                      width: widthImage(),
                      height: heightImage(),
                      fit: fit ?? BoxFit.cover,
                    )),
        // opacity
        Container(
          width: widthImage(),
          height: heightImage(),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(((1 - opacity) * 255).round()),
            borderRadius: BorderRadius.circular(radius ?? 0),
          ),
        ),
      ],
    );
  }

  double? widthImage() => aspectRatio.isNotNull ? double.maxFinite : width;

  double? heightImage() => aspectRatio.isNotNull ? double.maxFinite : height;
}
