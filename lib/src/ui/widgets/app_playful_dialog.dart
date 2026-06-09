import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';

enum AppPlayfulDialogTone { info, success, warning, danger }

enum AppPlayfulDialogButtonStyle { primary, soft, danger }

class AppPlayfulDialog extends StatelessWidget {
  const AppPlayfulDialog({
    required this.title,
    this.subtitle,
    this.content,
    this.actions = const [],
    this.tone = AppPlayfulDialogTone.info,
    this.showCloseButton = true,
    this.maxWidth = 360,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final List<Widget> actions;
  final AppPlayfulDialogTone tone;
  final bool showCloseButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      elevation: 0,
      backgroundColor: AppColors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.96),
                borderRadius: 30.borderRadiusAll,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.74),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PlayfulColors.ink.withValues(alpha: 0.16),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppStyles.h4(
                        color: PlayfulColors.ink,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      6.height,
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodySmall(
                          color: PlayfulColors.muted,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ],
                    if (content != null) ...[18.height, content!],
                    if (actions.isNotEmpty) ...[
                      20.height,
                      Row(
                        children: List.generate(actions.length * 2 - 1, (
                          index,
                        ) {
                          if (index.isOdd) return 12.width;
                          return Expanded(child: actions[index ~/ 2]);
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showCloseButton)
              Positioned(
                top: 18,
                right: 18,
                child: AppPlayfulDialogCloseButton(
                  onTap: () => Get.back<void>(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppPlayfulDialogButton extends StatelessWidget {
  const AppPlayfulDialogButton({
    required this.label,
    required this.onTap,
    this.style = AppPlayfulDialogButtonStyle.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final AppPlayfulDialogButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final isPrimary = style == AppPlayfulDialogButtonStyle.primary;
    final isDanger = style == AppPlayfulDialogButtonStyle.danger;

    return GestureDetector(
      onTap: enabled ? AppAudioTap.wrap(onTap) : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isPrimary || isDanger
              ? null
              : PlayfulColors.lobbySeatInactive.withValues(alpha: 0.72),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [PlayfulColors.cyan, PlayfulColors.blue],
                )
              : isDanger
              ? const LinearGradient(
                  colors: [AppColors.colorEF4056, AppColors.colorFF5B42],
                )
              : null,
          borderRadius: 16.borderRadiusAll,
          boxShadow: enabled && (isPrimary || isDanger)
              ? [
                  BoxShadow(
                    color:
                        (isDanger ? AppColors.colorEF4056 : PlayfulColors.blue)
                            .withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.bodyMedium(
                color: isPrimary || isDanger
                    ? AppColors.white
                    : PlayfulColors.lobbyPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppPlayfulDialogCloseButton extends StatelessWidget {
  const AppPlayfulDialogCloseButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: playfulShadow,
        ),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.close_rounded, color: PlayfulColors.ink, size: 22),
        ),
      ),
    );
  }
}
