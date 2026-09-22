import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../enums/smart_image_loading_type.dart';
import '../utils/blurhash_decoder.dart';
import 'smart_image_shimmer.dart';

/// Renders the appropriate placeholder/loading state for [SmartImage],
/// supporting BlurHash progressive placeholders, low-res previews, and shimmer animations.
class SmartImageLoader extends StatefulWidget {
  final SmartImageLoadingType loadingType;
  final Widget? customPlaceholder;
  final String? blurHash;
  final String? lowResUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? progress;

  const SmartImageLoader({
    super.key,
    required this.loadingType,
    this.customPlaceholder,
    this.blurHash,
    this.lowResUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.progress,
  });

  @override
  State<SmartImageLoader> createState() => _SmartImageLoaderState();
}

class _SmartImageLoaderState extends State<SmartImageLoader> {
  Uint8List? _blurHashBytes;

  @override
  void initState() {
    super.initState();
    _decodeBlurHash();
  }

  @override
  void didUpdateWidget(covariant SmartImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blurHash != widget.blurHash) {
      _decodeBlurHash();
    }
  }

  void _decodeBlurHash() {
    if (widget.blurHash != null && widget.blurHash!.isNotEmpty) {
      BlurHashDecoder.decodeAsync(blurHash: widget.blurHash!).then((bytes) {
        if (mounted && bytes != null) {
          setState(() {
            _blurHashBytes = bytes;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customPlaceholder != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.customPlaceholder!,
      );
    }

    // BlurHash placeholder rendering
    if (_blurHashBytes != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          _blurHashBytes!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        ),
      );
    }

    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(0);

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor ?? Colors.grey.shade200,
        child: _buildLoadingContent(context),
      ),
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    switch (widget.loadingType) {
      case SmartImageLoadingType.shimmer:
        return SmartImageShimmer(
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius,
        );

      case SmartImageLoadingType.progress:
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 2.5,
            ),
          ),
        );

      case SmartImageLoadingType.none:
      case SmartImageLoadingType.fade:
      case SmartImageLoadingType.blurUp:
        return const SizedBox.shrink();
    }
  }
}
