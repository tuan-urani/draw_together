import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSingleScrollView extends StatelessWidget {
  final Widget child;
  final double? height;
  const AppSingleScrollView({super.key, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: Get.width,
          minHeight: height ?? Get.height,
        ),
        child: IntrinsicHeight(child: child),
      ),
    );
  }
}
