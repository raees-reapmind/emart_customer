import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constant/constant.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? borderRadius;
  final Color? color;

  const NetworkImageWidget({super.key, this.height, this.width, this.fit, required this.imageUrl, this.borderRadius, this.errorWidget, this.color});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit ?? BoxFit.fitWidth,
      height: height,
      width: width,
      color: color,
      progressIndicatorBuilder:
          (context, url, downloadProgress) => Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(value: downloadProgress.progress))),
      errorWidget: (context, url, error) => errorWidget ?? Image.network(Constant.placeHolderImage, fit: fit ?? BoxFit.fitWidth, height: height, width: width),
    );
  }
}
