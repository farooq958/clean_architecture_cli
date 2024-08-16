import 'package:flutter/material.dart';
import 'package:flutter_quick_router/quick_router.dart';

import '../../../data/app_data/app_context.dart';

class Navigate {
  Navigate._privateConstructor();

  // Singleton instance
  static final Navigate instance = Navigate._privateConstructor();

  static BuildContext context=AppContext.navigatorKey.currentContext!;

  to(Widget child, {QuickTransition? transition}) {
   context.to(child, transitions: transition);
  }

  toReplace(Widget child, {QuickTransition? transition}) {
    context.pushReplacement(child, transitions: transition);

  }

  toReplaceAll(Widget child ,{QuickTransition? transition}) {
    context.pushAndRemoveUntil(child,(dd)=>false , transitions: transition);

  }

  pop(BuildContext? context ) {
    context!.back();
  }
}
