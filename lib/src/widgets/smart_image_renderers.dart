import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../enums/smart_image_format.dart';
import '../models/smart_image_source.dart';
import '../utils/file_image_helper.dart';

/// Renders decoded image data according to its format (Raster vs SVG) with optional fade-in.
class SmartImageRenderer extends StatefulWidget {
  final ResolvedImageSource source;
  final Uint8List? bytes;
  final SmartImageFormat format;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final double opacity;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool fadeIn;
  final Duration fadeDuration;

  const SmartImageRenderer({
    super.key,
    required this.source,
    this.bytes,
    required this.format,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.opacity = 1.0,
    this.cacheWidth,
    this.cacheHeight,
    this.fadeIn = true,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SmartImageRenderer> createState() => _SmartImageRendererState();
}

class _SmartImageRendererState extends State<SmartImageRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    if (widget.fadeIn) {
      _fadeController.forward();
    } else {
      _fadeController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant SmartImageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fadeDuration != widget.fadeDuration) {
      _fadeController.duration = widget.fadeDuration;
    }
    if (oldWidget.source != widget.source || oldWidget.bytes != widget.bytes) {
      if (widget.fadeIn) {
        _fadeController.reset();
        _fadeController.forward();
      } else {
        _fadeController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget content = _buildImage(context);

    if (widget.opacity < 1.0) {
      content = Opacity(opacity: widget.opacity, child: content);
    }

    if (!widget.fadeIn || disableAnimations) {
      return content;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: content,
    );
  }

  Widget _buildImage(BuildContext context) {
    // 1. Vector SVG rendering
    if (widget.format == SmartImageFormat.svg) {
      return _buildSvg(context);
    }

    // 2. Raster rendering (PNG, JPG, WebP, GIF, BMP)
    return _buildRaster(context);
  }

  Widget _buildSvg(BuildContext context) {
    final colorFilter = widget.color != null
        ? ColorFilter.mode(
            widget.color!,
            widget.colorBlendMode ?? BlendMode.srcIn,
          )
        : null;

    if (widget.bytes != null && widget.bytes!.isNotEmpty) {
      return SvgPicture.memory(
        widget.bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        colorFilter: colorFilter,
      );
    }

    if (widget.source.type == SmartImageSourceType.asset &&
        widget.source.stringData != null) {
      return SvgPicture.asset(
        widget.source.stringData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        colorFilter: colorFilter,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRaster(BuildContext context) {
    ImageProvider imageProvider;

    if (widget.bytes != null && widget.bytes!.isNotEmpty) {
      imageProvider = MemoryImage(widget.bytes!);
    } else if (widget.source.type == SmartImageSourceType.asset &&
        widget.source.stringData != null) {
      imageProvider = AssetImage(widget.source.stringData!);
    } else if (widget.source.type == SmartImageSourceType.file &&
        widget.source.stringData != null) {
      imageProvider = getFileImageProvider(widget.source.stringData!);
    } else if (widget.source.byteData != null) {
      imageProvider = MemoryImage(widget.source.byteData!);
    } else {
      return const SizedBox.shrink();
    }

    // Apply cache dimensions if specified for memory optimization
    if (widget.cacheWidth != null || widget.cacheHeight != null) {
      imageProvider = ResizeImage(
        imageProvider,
        width: widget.cacheWidth,
        height: widget.cacheHeight,
        allowUpscaling: false,
      );
    }

    return Image(
      image: imageProvider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
