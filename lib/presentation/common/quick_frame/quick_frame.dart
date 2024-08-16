import 'package:flutter/material.dart';

import '../../../application/utils/Extensions/extensions.dart';
import '../../../application/utils/Extensions/responsive_extention.dart';
import '../quick_image.dart';
import '../quick_text.dart';
import 'Controller/btController.dart';
import 'bottom_model.dart';

/// QuickFrame is a customizable class that can be used to create a Frame of any app.
/// It is a combination of [BottomBar] and [PageViewWidget].
/// It is a singleton class, so it can be used to create a single instance of the widget.
/// It is used to create a bottom navigation bar and a page view.
class QuickFrame {
  List<Widget>? pageScreens;
  List<BottomModel>? bottomElements;
  Function(int pageVal)? onPageChanged;
  Function? initCalled;
  Color? backgroundColor;
  Color? bottomBarColor;
  double? elevation;
  double? bottomBarHeight;
  TextStyle? textStyle;
  ScrollPhysics? physics;
  CustomPainter? bottomPaint;
  static final QuickFrame _instance = QuickFrame._internal();

  factory QuickFrame({
    Key? key,
    List<Widget>? pageScreens,
    List<BottomModel>? bottomElements,
    Function(int pageVal)? onPageChanged,
    Function? initCalled,
    Color? backgroundColor,
    Color? bottomBarColor,
    double? elevation,
    double? bottomBarHeight,
    ///[CustomPainter] for the bottom bar call our predefined [NotchedBottomAppBar] or [NotchedAbovePainter] or create your own custom painter
    CustomPainter?bottomPaint,
    ScrollPhysics? physics,
    TextStyle? textStyle = const TextStyle(),
  }) {
    _instance.pageScreens = pageScreens;
    _instance.bottomElements = bottomElements;
    _instance.onPageChanged = onPageChanged;
    _instance.initCalled = initCalled;
    _instance.backgroundColor = backgroundColor;
    _instance.bottomBarColor = bottomBarColor;
    _instance.elevation = elevation;
    _instance.bottomBarHeight = bottomBarHeight=70;
    _instance.textStyle = textStyle;
    _instance.physics = physics;
    _instance.bottomPaint=bottomPaint;
    return _instance;
  }

  QuickFrame._internal();

  BottomBar get bottomBar => BottomBar(
        bottomElements: _instance.bottomElements,
        onPageChanged: _instance.onPageChanged,
        bottomBarHeight: _instance.bottomBarHeight,
        bottomBarColor: _instance.bottomBarColor,
        textStyle: _instance.textStyle,
    bottomPaint: _instance.bottomPaint,

      );

  PageViewWidget get pageWidget => PageViewWidget(
        pageScreens: _instance.pageScreens,
        onPageChanged: _instance.onPageChanged,
        physics: _instance.physics,
      );
}

class BottomBar extends StatelessWidget {
  final List<BottomModel>? bottomElements;
  final Function(int pageVal)? onPageChanged;
  final double? bottomBarHeight;
  final Color? bottomBarColor;
  final TextStyle? textStyle;
  final CustomPainter? bottomPaint;
  //final BottomBarShape? shape;
  const BottomBar({
    Key? key,
    this.bottomElements,
    this.bottomPaint,
    this.onPageChanged,
    this.bottomBarHeight = 80.0,
    this.bottomBarColor,
  //  this.shape,

    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
print(bottomBarHeight);
    return Container(
      color: bottomBarColor ?? themeData.bottomAppBarTheme.color,
      height: 1.btB+ bottomBarHeight!,
      child: CustomPaint(
        painter:bottomPaint?? NotchedBottomAppBar(borderColor: Colors.black, backgroundColor: Colors.grey),
        child: ValueListenableBuilder(
          valueListenable: BottomNotifier.bottomNavigationNotifier,
          builder: (context, state, _) {
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bottomElements?.map((e) {
                    final int index = bottomElements!.indexOf(e);

                    // print(state == index);
                    return Transform.translate(
                      offset: e.offset ?? const Offset(0, 0),
                      child: InkWell(
                        onTap: () {
                          if (state != index) {
                            BottomNotifier.bottomPageController!
                                .jumpToPage(index);
                            BottomNotifier.bottomNavigationNotifier.value = index;
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            5.y,
                            Expanded(
                              flex: 2,
                              child: Align(
                                child:  QuickImage(
                                  url: index==state&&e.selectedIconPath!=null?e.selectedIconPath: e.path ?? "",
                                  height: e.iconHeight?? 30.h,
                                  width:e.iconWidth?? 30.w,
                                  color: state==index&&e.selectedIconPath!=null? e.selectedIconColor:e.unSelectedIconColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: QuickText(
                                e.title ?? "",
                                style: textStyle?.copyWith(
                                  color: state == index
                                      ? e.selectedColor
                                      : e.unSelectedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList() ??
                  [],
            );
          },
        ),
      ),
    );
  }
}

class PageViewWidget extends StatelessWidget {
  final List<Widget>? pageScreens;
  final ScrollPhysics? physics;
  final Function(int pageVal)? onPageChanged;

  const PageViewWidget(
      {Key? key, this.pageScreens, this.onPageChanged, this.physics})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.sw,
      height: 1.sh,
      child: PageView(
        onPageChanged: (val) {
          BottomNotifier.bottomNavigationNotifier.value = val;
          onPageChanged!(val);
        },
        controller: BottomNotifier.bottomPageController,
        physics: physics ?? const NeverScrollableScrollPhysics(),
        children: pageScreens ?? [],
      ),
    );
  }
}


class NotchedBottomAppBar extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;

  NotchedBottomAppBar({
    super.repaint,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5 - 65, 0)
      ..quadraticBezierTo(size.width * 0.5 - 55, 0, size.width * 0.5 - 50, 6)
      ..conicTo(size.width * 0.5, 70, size.width * 0.5 + 50, 6, 1.2)
      ..quadraticBezierTo(size.width * 0.5 + 55, 0, size.width * 0.5 + 65, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5 - 65, 0)
      ..quadraticBezierTo(size.width * 0.5 - 55, 0, size.width * 0.5 - 50, 6)
      ..conicTo(size.width * 0.5, 70, size.width * 0.5 + 50, 6, 1.2)
      ..quadraticBezierTo(size.width * 0.5 + 55, 0, size.width * 0.5 + 65, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paintBg);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class BottomBarClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5 - 65, 0)
      ..quadraticBezierTo(size.width * 0.5 - 55, 0, size.width * 0.5 - 50, 6)
      ..conicTo(size.width * 0.5, 70, size.width * 0.5 + 50, 6, 1.5)
      ..quadraticBezierTo(size.width * 0.5 + 55, 0, size.width * 0.5 + 65, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}


class NotchedAbovePainter extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;

  NotchedAbovePainter({
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5 - 65, 0)
      ..conicTo(size.width * 0.5, -70, size.width * 0.5 + 65, 0, 1.2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5 - 65, 0)
      ..conicTo(size.width * 0.5, -70, size.width * 0.5 + 65, 0, 1.2)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paintBg);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

