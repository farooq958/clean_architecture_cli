
import 'package:flutter/material.dart';

class QuickText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final int? maxLine;
  final VoidCallback? onTap;

  const QuickText(
      this.text, {
        super.key,
        this.style,
        this.overflow,
        this.maxLine = 1,
        this.onTap,
        this.textAlign = TextAlign.start,
      });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,

        maxLines: maxLine,
        textAlign: textAlign,
        textScaler: const TextScaler.linear(1),
        // overflow: overflow ?? TextOverflow.fade,
        style: style,
      ),
    );
  }
}
