import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

import 'app_circular_progress.dart';

class AppListView extends StatefulWidget {
  final EdgeInsets? padding;
  final Axis scrollDirection;
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final Function()? refresh;
  final VoidCallback? loadMore;
  final bool isLoadMore;
  final bool isLoading;
  final bool shrinkWrap;
  final String? emptyMessage;

  const AppListView({
    super.key,
    this.padding,
    this.scrollDirection = Axis.vertical,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.refresh,
    this.loadMore,
    this.isLoadMore = false,
    this.isLoading = false,
    this.shrinkWrap = true,
    this.emptyMessage,
  });

  @override
  State<StatefulWidget> createState() {
    return _AppListViewState();
  }
}

class _AppListViewState extends State<AppListView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Add listener to scroll controller
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        // Trigger loadMore when scrolled to the bottom
        if (!widget.isLoadMore) widget.loadMore?.call();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.itemCount > 0
        ? RefreshIndicator(
            onRefresh: () async {
              widget.refresh?.call();
            },
            child: Stack(
              children: [
                if (widget.isLoading) ...[
                  const Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
                ] else ...[
                  widget.itemCount == 0
                      ? _emptyView()
                      : ListView.separated(
                          controller: _scrollController,
                          shrinkWrap: widget.shrinkWrap,
                          padding: widget.padding ?? EdgeInsets.zero,
                          scrollDirection: widget.scrollDirection,
                          itemCount: widget.itemCount,
                          separatorBuilder: widget.separatorBuilder,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: widget.itemBuilder,
                        ),
                  widget.isLoadMore
                      ? Align(
                          alignment: widget.scrollDirection == Axis.vertical
                              ? Alignment.bottomCenter
                              : Alignment.centerRight,
                          child: AppCircularProgress(color: AppColors.primary),
                        )
                      : const SizedBox(),
                ],
              ],
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) => RefreshIndicator(
              onRefresh: () async {
                widget.refresh?.call();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: _emptyView(),
                ),
              ),
            ),
          );
  }

  Widget _emptyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          (((Get.height - 352) / 2) - 32).toInt().height,
          Center(
            child: Text(
              widget.emptyMessage ?? "No data",
              style: AppStyles.bodySmall(),
            ),
          ),
          24.height,
        ],
      ),
    );
  }
}
