import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class WidgetFunctions {
  WidgetFunctions._private();

  static final instance = WidgetFunctions._private();

  bool _isSnackBarVisible = false;

  showErrorSnackBar({String? error, required BuildContext context}) {
    WidgetFunctions.instance.snackBar(context,
        text: error,
       // textStyle: AppTextStyles.phosphateRegular(context, color: AppColors.whiteColor)


    );
  }

  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?> snackBar(
      BuildContext context,
      {String? text,
        Color? bgColor,
        TextStyle? textStyle}) async {
    if (_isSnackBarVisible) {
      return null;
    }
    _isSnackBarVisible = true;

    //ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        text ?? "",
        style: textStyle,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: Theme.of(context).snackBarTheme.shape,
    )).closed.then((_) {
      _isSnackBarVisible = false;
    });
  }

  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> toast(
      BuildContext context, SnackBar snackBar) async {
    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
