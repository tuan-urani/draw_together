import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/utils/app_assets.dart';

class AppRadioOption {
  final String value;
  final String label;
  final Widget? leading;

  const AppRadioOption({
    required this.value,
    required this.label,
    this.leading,
  });
}

class AppRadioGroup extends StatelessWidget {
  final String? value;
  final List<AppRadioOption> options;
  final ValueChanged<String> onChanged;
  final Axis direction;
  final TextStyle? textStyle;
  final Color? activeColor;
  final double iconSize;

  const AppRadioGroup({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.direction = Axis.horizontal,
    this.textStyle,
    this.activeColor,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final bool selected = option.value == value;

        return Expanded(
          child: InkWell(
            onTap: AppAudioTap.wrap(() => onChanged(option.value)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 6,
              children: [
                SvgPicture.asset(
                  width: iconSize,
                  height: iconSize,
                  selected
                      ? AppAssets.iconsRadioCheckSvg
                      : AppAssets.iconsRadioUncheckSvg,
                ),
                Text(option.label, style: textStyle),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
