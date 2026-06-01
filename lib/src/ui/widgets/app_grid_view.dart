import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/ui/widgets/app_circular_progress.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_dimensions.dart';

class AppGridView extends StatelessWidget {
  final Axis scrollDirection;
  final int itemCount;
  final Widget? Function(BuildContext context, int index, double heightItem)
  itemBuilder;
  final Function()? refresh;
  final VoidCallback? loadMore;
  final bool isLoadMore;
  final bool isLoading;
  final int crossAxisCount;
  final double axisSpacing;
  final double itemRatio;
  final double? height;
  final int spaceHorizontal;
  final ScrollPhysics? scrollPhysics;

  const AppGridView({
    super.key,
    this.scrollDirection = Axis.vertical,
    required this.itemCount,
    required this.itemBuilder,
    this.refresh,
    this.loadMore,
    this.isLoading = false,
    this.isLoadMore = false,
    this.crossAxisCount = 2,
    this.axisSpacing = 6,
    this.itemRatio = 1.6,
    this.height,
    this.spaceHorizontal = 10,
    this.scrollPhysics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (ScrollNotification scrollNotification) {
        if (scrollNotification.metrics.pixels >=
            scrollNotification.metrics.maxScrollExtent / 2) {
          if (!isLoadMore) loadMore?.call();
        }
        return true;
      },
      child: refresh != null
          ? RefreshIndicator(
              onRefresh: () async {
                await refresh?.call();
              },
              child: _mainGridView(),
            )
          : _mainGridView(),
    );
  }

  Widget _mainGridView() {
    final double heightItem =
        height ??
        ((Get.width - (spaceHorizontal * 2 + axisSpacing)) /
                (crossAxisCount * itemRatio)) +
            axisSpacing;
    final rows = ((isLoadMore ? itemCount + 1 : itemCount) / crossAxisCount)
        .ceil();
    final double heightWidget = heightItem * rows;

    return Stack(
      children: [
        if (isLoading) ...[
          Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.bottomBarHeight),
            child: const AppCircularProgress(color: AppColors.primary),
          ),
        ] else if (itemCount == 0 && !isLoadMore)
          Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.bottomBarHeight),
            // child: const CustomNoDataWidget(),
          ),
        SizedBox(
          height: scrollPhysics == const NeverScrollableScrollPhysics()
              ? heightWidget
              : null,
          child: GridView.builder(
            shrinkWrap: true,
            padding: spaceHorizontal.paddingHorizontal,
            itemCount: isLoadMore && itemCount != 0 ? itemCount + 1 : itemCount,
            physics: scrollPhysics,
            gridDelegate: height != null
                ? SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: axisSpacing,
                    crossAxisSpacing: axisSpacing,
                    height: height!,
                  )
                : SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: axisSpacing,
                    crossAxisSpacing: axisSpacing,
                    childAspectRatio: itemRatio,
                  ),
            itemBuilder: (context, index) {
              if (index == itemCount) {
                return const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                );
              }
              return itemBuilder(context, index, heightWidget);
            },
          ),
        ),
      ],
    );
  }
}

class SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight
    extends SliverGridDelegate {
  /// Creates a delegate that makes grid layouts with a fixed number of tiles in
  /// the cross axis.
  ///
  /// All of the arguments must not be null. The `mainAxisSpacing` and
  /// `crossAxisSpacing` arguments must not be negative. The `crossAxisCount`
  /// and `childAspectRatio` arguments must be greater than zero.
  const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.height = 56.0,
  });

  /// The number of children in the cross axis.
  final int crossAxisCount;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// The height of the crossAxis.
  final double height;

  bool _debugAssertIsValid() {
    assert(crossAxisCount > 0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(height > 0.0);
    return true;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    final double usableCrossAxisExtent =
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = height;
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(
    SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight oldDelegate,
  ) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.height != height;
  }
}
