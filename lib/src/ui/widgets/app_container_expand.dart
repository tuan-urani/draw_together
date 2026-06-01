import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/extensions/string_extensions.dart';

class AppContainerExpand extends StatefulWidget {
  final Widget? header;
  final Widget child;
  final String? iconExpandResource;
  final String? iconCollapseResource;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry? headerPadding;
  final bool toggleInHeader;

  const AppContainerExpand({
    super.key,
    this.header,
    required this.child,
    this.iconExpandResource,
    this.iconCollapseResource,
    this.iconColor,
    this.iconSize = 20,
    this.headerPadding,
    this.toggleInHeader = false,
  });

  @override
  State<AppContainerExpand> createState() => _AppContainerExpandState();
}

class _AppContainerExpandState extends State<AppContainerExpand> {
  bool _isExpanded = true;

  Widget _buildIcon(String? resource) {
    if (!resource.isNullOrEmpty()) {
      return _buildIconFromString(resource!);
    }
    return Icon(
      _isExpanded ? Icons.arrow_upward : Icons.arrow_downward,
      size: widget.iconSize,
      color: widget.iconColor,
    );
  }

  Widget _buildIconFromString(String path) {
    // 1. Network
    if (path.isNetworkUri) {
      // SVG network
      if (path.isSvg) {
        return SvgPicture.network(
          path,
          colorFilter: widget.iconColor != null
              ? ColorFilter.mode(widget.iconColor!, BlendMode.srcIn)
              : null,
          width: widget.iconSize,
          height: widget.iconSize,
        );
      }
      return Image.network(
        path,
        width: widget.iconSize,
        height: widget.iconSize,
        color: widget.iconColor,
      );
    }

    // 2. SVG local
    if (path.isSvg) {
      return SvgPicture.asset(
        path,
        width: widget.iconSize,
        height: widget.iconSize,
        colorFilter: widget.iconColor != null
            ? ColorFilter.mode(widget.iconColor!, BlendMode.srcIn)
            : null,
      );
    }

    // 3. Local file (assets)
    return Image.asset(
      path,
      width: widget.iconSize,
      height: widget.iconSize,
      color: widget.iconColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.toggleInHeader && widget.header != null) {
      return Column(
        children: [
          Padding(
            padding: widget.headerPadding ?? EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(child: widget.header!),
                  Transform.rotate(
                    angle: _isExpanded ? 0 : 3.1415926535897932,
                    child: _buildIcon(
                      _isExpanded
                          ? widget.iconCollapseResource
                          : widget.iconExpandResource,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppExpandedSection(expand: _isExpanded, child: widget.child),
        ],
      );
    }

    return Column(
      children: [
        AppExpandedSection(expand: _isExpanded, child: widget.child),
        8.height,
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: _buildIcon(
            _isExpanded
                ? widget.iconCollapseResource
                : widget.iconExpandResource,
          ),
        ),
      ],
    );
  }
}

class AppExpandedSection extends StatefulWidget {
  final Widget child;
  final bool expand;
  const AppExpandedSection({
    super.key,
    this.expand = false,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() {
    return _AppExpandedSectionState();
  }
}

class _AppExpandedSectionState extends State<AppExpandedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController expandController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _runExpandCheck();
  }

  ///Setting up the animation
  void prepareAnimations() {
    expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _runExpandCheck() {
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(AppExpandedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axisAlignment: 1.0,
      sizeFactor: animation,
      child: widget.child,
    );
  }
}
