import 'package:flutter/material.dart';


class BottomNotifier {
  static ValueNotifier<int> bottomNavigationNotifier = ValueNotifier(0);
  static PageController? bottomPageController = PageController(initialPage: 0);

}
