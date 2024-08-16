import 'package:flutter/material.dart';

class QuickRichText extends StatelessWidget {
  final List<InlineSpan> textSpans;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final VoidCallback? onTap;

  const QuickRichText({
    Key? key,
    required this.textSpans,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.fade,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          children: textSpans,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
