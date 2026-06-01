import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ItemsCarousel extends StatefulWidget {
  final List<Widget> items;
  final int spacing;
  final String title;
  final String seeMoreText;
  final VoidCallback onTapSeeMore;
  final int itemsPerPage;
  final bool disableScroll;

  const ItemsCarousel({
    super.key,
    required this.items,
    this.spacing = 10,
    required this.title,
    required this.seeMoreText,
    required this.onTapSeeMore,
    this.itemsPerPage = 2, // Default to 2 items per page
    this.disableScroll = false,
  });

  @override
  State<StatefulWidget> createState() => _ItemsCarouselState();
}

class _ItemsCarouselState extends State<ItemsCarousel> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _current = 0;
  bool _disableScroll = false;

  @override
  void initState() {
    _disableScroll = widget.disableScroll;
    super.initState();
  }

  @override
  void didUpdateWidget(ItemsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.disableScroll != widget.disableScroll) {
      setState(() {
        _disableScroll = widget.disableScroll;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CarouselSlider(
            disableGesture: _disableScroll,
            key: PageStorageKey('carousel_${widget.title}'),
            carouselController: _carouselController,
            options: CarouselOptions(
              // height: 220,
              scrollPhysics: _disableScroll
                  ? const NeverScrollableScrollPhysics()
                  : null,
              enlargeCenterPage: true,
              viewportFraction: 1.0,
              enlargeFactor: 0.2,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
            items: _buildGroupedItems(),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _buildCustomIndicator(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedItems() {
    List<Widget> groupedItems = [];
    for (int i = 0; i < widget.items.length; i += widget.itemsPerPage) {
      List<Widget> rowItems = [];
      for (int j = 0; j < widget.itemsPerPage; j++) {
        if (i + j < widget.items.length) {
          rowItems.add(Expanded(child: widget.items[i + j]));
          if (j < widget.itemsPerPage - 1) {
            rowItems.add(widget.spacing.width);
          }
        } else {
          rowItems.add(Expanded(child: Container()));
          if (j < widget.itemsPerPage - 1) {
            rowItems.add(widget.spacing.width);
          }
        }
      }
      groupedItems.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowItems,
        ),
      );
    }
    return groupedItems;
  }

  Widget _buildCustomIndicator() {
    int itemCount = (widget.items.length / widget.itemsPerPage).ceil();

    return AnimatedSmoothIndicator(
      activeIndex: _current,
      count: itemCount,
      effect: const WormEffect(
        activeDotColor: AppColors.primary,
        dotColor: AppColors.white,
        dotHeight: 6,
        dotWidth: 6,
      ),
      onDotClicked: (index) {
        _carouselController.animateToPage(index);
      },
    );
  }
}
