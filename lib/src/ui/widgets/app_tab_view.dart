import 'package:flutter/material.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_dimensions.dart';

class AppTabView extends StatefulWidget {
  final int id;
  final TextStyle titleActive;
  final TextStyle titleInActive;
  final Color bgActive;
  final Color bgInActive;
  final Color borderColorActive;
  final String title;
  final int selectedTab;
  final Function()? onClick;
  final double? width;
  final Widget? badge;

  const AppTabView(
    this.id, {
    required this.title,
    required this.selectedTab,
    this.onClick,
    this.width,
    this.bgActive = AppColors.colorF8F1DD,
    this.bgInActive = AppColors.white,
    this.borderColorActive = AppColors.colorF1D2BC,
    this.badge,
    required this.titleActive,
    required this.titleInActive,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _AppTabViewState();
}

class _AppTabViewState extends State<AppTabView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Alignment> _alignmentAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _alignmentAnimation =
        AlignmentTween(
          begin: _getAlignment(widget.selectedTab),
          end: _getAlignment(widget.selectedTab),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.linear),
        );
  }

  Alignment _getAlignment(int index) {
    return index == widget.id ? Alignment.center : Alignment.topCenter;
  }

  @override
  void didUpdateWidget(covariant AppTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != oldWidget.selectedTab) {
      _alignmentAnimation =
          AlignmentTween(
            begin: _getAlignment(oldWidget.selectedTab),
            end: _getAlignment(widget.selectedTab),
          ).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.linear),
          );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = widget.selectedTab == widget.id;
    return InkWell(
      onTap: () {
        AppAudioTap.play();
        widget.onClick?.call();
        setState(() {
          _alignmentAnimation =
              AlignmentTween(
                begin: _alignmentAnimation.value,
                end: _getAlignment(widget.id),
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.linear,
                ),
              );
          _animationController.forward(from: 0);
        });
      },
      child: AnimatedBuilder(
        animation: _alignmentAnimation,
        builder: (context, child) {
          return Align(
            alignment: _alignmentAnimation.value,
            child: Container(
              height: 52,
              width: widget.width,
              decoration: BoxDecoration(
                borderRadius: 16.borderRadiusAll,
                color: isActive ? widget.bgActive : widget.bgInActive,
                border: Border.all(
                  color: isActive
                      ? widget.borderColorActive
                      : AppColors.transparent, // borderColor
                  width: isActive ? 1 : 0, // borderWidth
                ),
              ),
              padding: AppDimensions.sideMargins,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: isActive
                          ? widget.titleActive
                          : widget.titleInActive,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.badge != null) ...[6.width, widget.badge!],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
