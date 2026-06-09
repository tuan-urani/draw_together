import 'package:flutter/material.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.children,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PlayfulCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayfulIconTile(
                icon: icon,
                size: 42,
                color: iconColor,
                background: iconBackground,
              ),
              16.width,
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _SettingsTextStyle.sectionTitle,
                ),
              ),
            ],
          ),
          10.height,
          ...children,
        ],
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.onChanged,
    required this.onLabel,
    this.showDivider = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String onLabel;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _SettingsRowFrame(
      showDivider: showDivider,
      child: Row(
        children: [
          PlayfulIconTile(
            icon: icon,
            size: 46,
            color: iconColor,
            background: iconBackground,
          ),
          14.width,
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _SettingsTextStyle.itemLabel,
            ),
          ),
          12.width,
          SettingsSwitch(value: value, onChanged: onChanged, onLabel: onLabel),
        ],
      ),
    );
  }
}

class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.onTap,
    this.showDivider = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: AppAudioTap.wrap(onTap),
      child: _SettingsRowFrame(
        showDivider: showDivider,
        child: Row(
          children: [
            PlayfulIconTile(
              icon: icon,
              size: 46,
              color: iconColor,
              background: iconBackground,
            ),
            14.width,
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _SettingsTextStyle.itemLabel,
              ),
            ),
            12.width,
            const Icon(
              Icons.chevron_right_rounded,
              size: 34,
              color: PlayfulColors.ink,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsDeleteCard extends StatelessWidget {
  const SettingsDeleteCard({
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PlayfulColors.settingsDangerSoft.withValues(alpha: 0.96),
          borderRadius: 28.borderRadiusAll,
          boxShadow: playfulShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            children: [
              const PlayfulIconTile(
                icon: Icons.delete_outline_rounded,
                size: 42,
                color: AppColors.white,
                background: PlayfulColors.settingsDanger,
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _SettingsTextStyle.deleteTitle),
                    6.height,
                    Text(subtitle, style: _SettingsTextStyle.deleteSubtitle),
                  ],
                ),
              ),
              14.width,
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: PlayfulColors.settingsDanger,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTextStyle {
  const _SettingsTextStyle._();

  static const double sectionTitleSize = 16;
  static const double itemLabelSize = 14;
  static const double deleteTitleSize = 14;
  static const double deleteSubtitleSize = 12;

  static final TextStyle sectionTitle = _settingsTextStyle(
    fontSize: sectionTitleSize,
    color: PlayfulColors.ink,
    fontWeight: FontWeight.w900,
    height: 1.18,
  );

  static final TextStyle itemLabel = _settingsTextStyle(
    fontSize: itemLabelSize,
    color: PlayfulColors.ink,
    fontWeight: FontWeight.w900,
    height: 1.2,
  );

  static final TextStyle deleteTitle = _settingsTextStyle(
    fontSize: deleteTitleSize,
    color: PlayfulColors.settingsDanger,
    fontWeight: FontWeight.w900,
    height: 1.2,
  );

  static final TextStyle deleteSubtitle = _settingsTextStyle(
    fontSize: deleteSubtitleSize,
    color: PlayfulColors.muted,
    fontWeight: FontWeight.w800,
    height: 1.45,
  );

  static TextStyle _settingsTextStyle({
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
    required double height,
  }) {
    return TextStyle(
      fontFamily: AppStyles.fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    required this.value,
    required this.onChanged,
    required this.onLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String onLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: AppAudioTap.wrap(() => onChanged(!value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 66,
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
                  colors: [PlayfulColors.cyan, PlayfulColors.blue],
                )
              : null,
          color: value ? null : AppColors.colorE8EDF5,
          borderRadius: 99.borderRadiusAll,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // if (value)
            //   Align(
            //     alignment: Alignment.centerLeft,
            //     child: Padding(
            //       padding: const EdgeInsets.only(left: 9),
            //       child: Text(
            //         onLabel,
            //         style: AppStyles.bodySmall(
            //           color: AppColors.white,
            //           fontWeight: FontWeight.w900,
            //         ),
            //       ),
            //     ),
            //   ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 34, height: 34),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRowFrame extends StatelessWidget {
  const _SettingsRowFrame({required this.child, required this.showDivider});

  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: PlayfulColors.settingsDivider),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: child,
      ),
    );
  }
}
