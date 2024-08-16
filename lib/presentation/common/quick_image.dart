import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

///## QuickImage
///QuickImage is a versatile Flutter widget designed to simplify the integration
/// of various image sources in your application. It supports both network and local
/// file images, including SVG images, with additional features such as caching and error
/// handling. The widget provides flexibility through customizable properties such as dimensions,
/// fit, background color, and more.

/// ## Parameters:
///    * key: An optional key to uniquely identify this widget.
///    * width: The width of the image widget.
///    * height: The height of the image widget.
///    * url: The image source URL or file.
///    * fit: The BoxFit property to control how the image should be inscribed.
///    * backgroundColor: The background color of the container.
///    * color: The color to apply to the image.
///    * loaderIconSize: The size of the loader icon if used.
///    * errorUrl: The URL of the image to be displayed in case of an error.
///    * radius: The border radius of the container.
///    * loaderWidget: Custom loader widget to display while the image is loading.
///    * padding: The padding of the container.

/// ## Example
/// ```dart
/// QuickImage(
///   width: 200,
///   height: 150,
///   url: "https://example.com/image.jpg",
///   fit: BoxFit.cover,
///   backgroundColor: Colors.grey,
///   color: Colors.blue,
///   loaderIconSize: Size(30, 30),
///   errorUrl: "assets/error_image.png",
///   radius: BorderRadius.circular(12),
///   loaderWidget: CircularProgressIndicator(),
///   padding: EdgeInsets.all(8),
/// );
/// ```

class QuickImage<T> extends StatelessWidget {
  const QuickImage({
    super.key,
    this.width,
    this.height,
    required this.url,
    this.fit,
    this.backgroundColor,
    this.color,
    this.loaderIconSize,
    this.errorUrl,
    this.radius,
    this.loaderWidget,
    this.padding,
  });

  final double? height;
  final double? width;
  final Size? loaderIconSize;
  final Color? backgroundColor;
  final Color? color;
  final Widget? loaderWidget;
  final T url;
  final BoxFit? fit;
  final BorderRadiusGeometry? radius;
  final String? errorUrl;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {



    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: Container(
        color: backgroundColor,
        height: height,
        width: width,
        padding: padding,
        child: _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (url is File) {
      return Image.file(
        url as File,
        fit: fit ?? BoxFit.cover,
        width: width,
        height: height,
      );
    } else if(url is IconData) {
      return Icon(url as IconData);
    }else{
      return url.toString().toLowerCase().endsWith("svg")
          ? _buildSvgImage(context)
          : _buildCachedNetworkImage(context);
    }
  }

  Widget _buildSvgImage(BuildContext context) {
    return url.toString().contains("http")
        ? SvgPicture.network(
            url.toString(),
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
          )
        : SvgPicture.asset(
            url.toString(),
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
          );
  }

  Widget _buildCachedNetworkImage(BuildContext context) {
    return CachedNetworkImage(
      fit: fit,
      progressIndicatorBuilder: (context, child, progress) =>
          loaderWidget ??
          const Center(
            child: CircularProgressIndicator(),
          ),
      cacheKey: "$url",
      errorWidget: (context, str, dyn) => _buildErrorWidget(context),
      imageUrl: url.toString(),
      width: width,
      height: height,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    try {
      if (errorUrl != null) {
        return errorUrl!.contains("svg")
            ? SvgPicture.asset(
                errorUrl!,
                height: height,
                width: width,
                fit: fit ?? BoxFit.cover,
                colorFilter: color != null
                    ? ColorFilter.mode(color!, BlendMode.srcIn)
                    : null,
              )
            : Image.asset(
                errorUrl!,
                fit: fit ?? BoxFit.cover,
                width: width,
                height: height,
              );
      }
      return const Placeholder(
        child: Text(" For custom error image \n use [errorUrl:'assets_url']"),
      );
    } catch (e) {
      rethrow;
    }
  }
}
