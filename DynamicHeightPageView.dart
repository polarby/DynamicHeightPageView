import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:collection/collection.dart';

typedef PageChangedCallback = void Function(double? page);
typedef PageSelectedCallback = void Function(int index);

class DynamicHeightPageView extends StatefulWidget {
  final List<double> heightList;
  final List<Widget> children;
  final double cardWidth;
  final ScrollPhysics? physics;
  final PageChangedCallback? onPageChanged;
  final PageSelectedCallback? onSelectedItem;
  final int initialPage;

  DynamicHeightPageView({
    required this.heightList,
    required this.children,
    this.physics,
    this.cardWidth = 300,
    this.onPageChanged,
    this.initialPage = 0,
    this.onSelectedItem,
  }) : assert(heightList.length == children.length);

  @override
  _DynamicHeightPageViewState createState() => _DynamicHeightPageViewState();
}

class _DynamicHeightPageViewState extends State<DynamicHeightPageView> {
  double? currentPosition;
  PageController? controller;

  @override
  void initState() {
    super.initState();
    currentPosition = widget.initialPage.toDouble();
    controller = PageController(initialPage: widget.initialPage);

    controller!.addListener(() {
      setState(() {
        currentPosition = controller!.page;

        if (widget.onPageChanged != null) {
          Future(() => widget.onPageChanged!(currentPosition));
        }

        if (widget.onSelectedItem != null && (currentPosition! % 1) == 0) {
          Future(() => widget.onSelectedItem!(currentPosition!.toInt()));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTap: () {
          print("Current Element index tab: ${currentPosition!.round()}");
        },
        child: Stack(
          children: [
            CardController(
              cardWidth: widget.cardWidth,
              heightList: widget.heightList,
              children: widget.children,
              currentPosition: currentPosition,
              cardViewPagerHeight: constraints.maxHeight,
              cardViewPagerWidth: constraints.maxWidth,
            ),
            Positioned.fill(
              child: PageView.builder(
                physics: widget.physics,
                scrollDirection: Axis.vertical,
                itemCount: widget.children.length,
                controller: controller,
                itemBuilder: (context, index) {
                  return Container();
                },
              ),
            )
          ],
        ),
      );
    });
  }
}

class CardController extends StatelessWidget {
  final double? currentPosition;
  final List<double> heightList;
  final double cardWidth;
  final double cardViewPagerHeight;
  final double? cardViewPagerWidth;
  final List<Widget>? children;

  CardController({
    this.children,
    this.cardViewPagerWidth,
    required this.cardWidth,
    required this.cardViewPagerHeight,
    required this.heightList,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> cardList = [];

    for (int i = 0; i < children!.length; i++) {
      var cardHeight = heightList[i];

      var cardTop = getTop(cardHeight, cardViewPagerHeight, i, heightList);
      var cardLeft = (cardViewPagerWidth! / 2) - (cardWidth / 2);

      Widget card = Positioned(
        top: cardTop,
        left: cardLeft,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          child: children![i],
        ),
      );

      cardList.add(card);
    }

    return Stack(
      children: cardList,
    );
  }

  double getTop(
      double cardHeight, double viewHeight, int i, List<double> heightList) {
    double diff = (currentPosition! - i);
    double diffAbs = diff.abs();

    double basePosition = (viewHeight / 2) - (cardHeight / 2);

    if (diffAbs == 0) {
      //element in focus
      return basePosition;
    }

    int intCurrentPosition = currentPosition!.toInt();
    double doubleCurrentPosition = currentPosition! - intCurrentPosition;

    //calculate distance between to-pull elements
    late double pullHeight;
    if (heightList.length > intCurrentPosition + 1) {
      //check for end of list
      pullHeight = heightList[intCurrentPosition] / 2 +
          heightList[intCurrentPosition + 1] / 2;
    } else {
      pullHeight = heightList[intCurrentPosition] / 2;
    }

    if (diff >= 0) {
      //before focus element
      double afterListSum = heightList.getRange(i, intCurrentPosition + 1).sum;

      return (viewHeight / 2) -
          afterListSum +
          heightList[intCurrentPosition] / 2 -
          pullHeight * doubleCurrentPosition;
    } else {
      //after focus element
      var beforeListSum = heightList.getRange(intCurrentPosition, i).sum;
      return (viewHeight / 2) +
          beforeListSum -
          heightList[intCurrentPosition] / 2 -
          pullHeight * doubleCurrentPosition;
    }
  }
}
