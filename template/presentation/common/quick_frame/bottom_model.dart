import 'dart:ui';

class BottomModel{
  final String? path;
  final String? title;
  final double?  iconHeight;
  final double? iconWidth;
  final String?  selectedIconPath;
  final Color? unSelectedColor;
  final Color? selectedColor;
  final Color? selectedIconColor;
  final Color? unSelectedIconColor;

  final Offset? offset;
  BottomModel({this.path,this.unSelectedIconColor, this.selectedIconColor,this.title,this.unSelectedColor,this.offset, this.selectedColor,this.iconHeight, this.iconWidth, this.selectedIconPath,  });

}