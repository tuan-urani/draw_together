import 'package:flutter/material.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 44,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    final double padding = 2;
    final double thumbSize = height - padding * 2;

    final BoxDecoration decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      gradient: value
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFAFDF46), Color(0xFF76C90D)],
            )
          : null,
      color: value ? null : const Color(0xFFE5E7EB),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: AppAudioTap.wrap(() => onChanged(!value)),
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: 2.paddingAll,
          decoration: decoration,
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 10),
                    blurRadius: 15,
                    spreadRadius: -3,
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    spreadRadius: -4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
