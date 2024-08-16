import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DynamicAppIconHandler {
  static Widget buildIcon({
    required BuildContext context,
    IconData? icon,
    String? svg,
    double? iconHeight,
    double? iconWidth,
    EdgeInsetsGeometry margins = EdgeInsets.zero,
    Color? iconColor,
    BoxFit? fit,
  }) {
    if (svg != null) {
      return Padding(
        padding: margins,
        child: SvgPicture.asset(
          svg,
          height: iconHeight,
          width: iconWidth,
          fit: fit ?? BoxFit.contain,
          color: iconColor,
        ),
      );
    } else if (icon != null) {
      return Padding(
        padding: margins,
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.surface,
          size: iconHeight,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
