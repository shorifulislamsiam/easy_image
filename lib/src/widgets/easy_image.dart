import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../enums/easy_image_cache_source.dart';
import '../enums/easy_image_format.dart';
import '../enums/easy_image_loading_type.dart';
import '../errors/easy_image_exception.dart';
import '../models/easy_image_config.dart';
import '../models/easy_image_source.dart';
import '../services/image_cache_key.dart';
import '../services/image_cache_manager.dart';
import '../services/image_cache_service.dart';
import '../services/image_compression_service.dart';
import '../services/image_download_queue.dart';
import '../services/image_downloader.dart';
import '../services/image_format_detector.dart';
import '../services/image_retry_service.dart';
import '../utils/file_image_helper.dart';
import 'easy_image_error.dart';
import 'easy_image_loader.dart';
import 'easy_image_renderers.dart';

/// The unified, all-in-one image widget for Flutter apps.
///
/// Handles network loading with CDN transformation, two-tier caching with HTTP 304 revalidation,
/// BlurHash progressive loading, optional compression, retries with backoff, local files/assets/bytes/base64,
/// SVG vector rendering, shimmer animations, and error handling.
class EasyImage extends StatefulWidget {
  /// Remote network image URL (HTTP/HTTPS).
  final String? url;

  /// Optional variant URL used when the active theme is dark.
  final String? darkUrl;

  /// Bundled Flutter asset path.
  final String? asset;

  /// Local file system image (non-Web only).
  final Object? file;

  /// In-memory raw bytes.
  final Uint8List? bytes;

  /// Base64 or Data-URI image string.
  final String? base64;

  /// Render width.
  final double? width;

  /// Render height.
  final double? height;

  /// How the image should be inscribed into the space allocated.
  final BoxFit fit;

  /// Alignment of the image within its bounds.
  final Alignment alignment;

  /// Uniform corner radius shortcut.
  final double? radius;

  /// Explicit border radius. Overrides [radius] if provided.
  final BorderRadius? borderRadius;

  /// Box shape (e.g. [BoxShape.circle] for avatars).
  final BoxShape? shape;

  /// Custom placeholder widget shown while loading.
  final Widget? placeholder;

  /// Custom error widget shown on failure.
  final Widget? errorWidget;

  /// Loading animation style. Defaults to [EasyImageLoadingType.shimmer] if [shimmer] is true,
  /// otherwise [EasyImageLoadingType.none].
  final EasyImageLoadingType? loadingType;

  /// Convenience flag to enable shimmer loading animation.
  final bool shimmer;

  /// BlurHash string decoded as a smooth gradient placeholder.
  final String? blurHash;

  /// Optional low-resolution preview image URL for progressive blur-up loading.
  final String? lowResUrl;

  /// Whether to perform a smooth fade-in transition when the image finishes loading.
  final bool fadeIn;

  /// Duration of the fade-in animation.
  final Duration fadeDuration;

  /// Maximum number of automatic retries on failure.
  final int retryCount;

  /// Base retry delay before applying exponential backoff with jitter.
  final Duration retryDelay;

  /// Target decoding width for raster memory optimization.
  final int? cacheWidth;

  /// Target decoding height for raster memory optimization.
  final int? cacheHeight;

  /// Whether to compress local/file images before rendering. Defaults to false.
  final bool compress;

  /// Compression quality from 1 to 100 when [compress] is enabled. Defaults to 80.
  final int quality;

  /// Whether animated formats (GIF, WebP) should auto-play. Defaults to true.
  final bool autoPlay;

  /// Number of times to loop animated images. If null, loops continuously.
  final int? loopCount;

  /// Semantic label for accessibility and screen readers.
  final String? semanticLabel;

  /// Custom HTTP request headers for authenticated endpoints.
  final Map<String, String>? headers;

  /// Background color of the container.
  final Color? backgroundColor;

  /// Color filter applied to the image.
  final Color? color;

  /// Blend mode used when applying [color].
  final BlendMode? colorBlendMode;

  /// Opacity multiplier for the image (0.0 to 1.0).
  final double opacity;

  /// Hero animation tag for screen transitions.
  final Object? heroTag;

  /// Advanced configuration object.
  final EasyImageConfig? config;

  /// Optional custom callback invoked when the user clicks the retry button in the default error UI.
  final VoidCallback? onRetry;

  const EasyImage({
    super.key,
    this.url,
    this.darkUrl,
    this.asset,
    this.file,
    this.bytes,
    this.base64,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.radius,
    this.borderRadius,
    this.shape,
    this.placeholder,
    this.errorWidget,
    this.loadingType,
    this.shimmer = false,
    this.blurHash,
    this.lowResUrl,
    this.fadeIn = true,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.retryCount = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.cacheWidth,
    this.cacheHeight,
    this.compress = false,
    this.quality = 80,
    this.autoPlay = true,
    this.loopCount,
    this.semanticLabel,
    this.headers,
    this.backgroundColor,
    this.color,
    this.colorBlendMode,
    this.opacity = 1.0,
    this.heroTag,
    this.config,
    this.onRetry,
  });

  /// Convenience constructor for circular avatar images.
  const EasyImage.circle({
    super.key,
    this.url,
    this.darkUrl,
    this.asset,
    this.file,
    this.bytes,
    this.base64,
    double? radius,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.loadingType,
    this.shimmer = false,
    this.blurHash,
    this.lowResUrl,
    this.fadeIn = true,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.retryCount = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.cacheWidth,
    this.cacheHeight,
    this.compress = false,
    this.quality = 80,
    this.autoPlay = true,
    this.loopCount,
    this.semanticLabel,
    this.headers,
    this.backgroundColor,
    this.color,
    this.colorBlendMode,
    this.opacity = 1.0,
    this.heroTag,
    this.config,
    this.onRetry,
  })  : shape = BoxShape.circle,
        radius = null,
        borderRadius = null,
        width = radius != null ? radius * 2 : null,
        height = radius != null ? radius * 2 : null;

  /// Clears both memory and disk caches across the entire application.
  static Future<void> clearCache() =>
      EasyImageCacheService.instance.clearAll();

  /// Clears a specific image key or URL from memory and disk caches.
  static Future<void> clearImageCache(String key) =>
      EasyImageCacheService.instance.clearImage(key);

  /// Clears all stored cache on user logout to prevent cross-user data leakage.
  static Future<void> clearCacheOnLogout() =>
      EasyImageCacheService.instance.clearCacheOnLogout();

  @override
  State<EasyImage> createState() => _EasyImageState();
}

enum _LoadStatus { loading, success, error }

class _EasyImageState extends State<EasyImage> {
  _LoadStatus _status = _LoadStatus.loading;
  ResolvedImageSource? _resolvedSource;
  Uint8List? _loadedBytes;
  EasyImageFormat _detectedFormat = EasyImageFormat.unknown;
  EasyImageException? _error;
  double? _downloadProgress;

  /// Tracks active load operation generation to ignore superseded async callbacks.
  int _activeLoadId = 0;
  bool _isDisposed = false;

  EasyImageConfig get _effectiveConfig =>
      widget.config ?? EasyImageConfig.defaultConfig;

  EasyImageCacheManager get _effectiveCacheManager =>
      _effectiveConfig.cacheManager ?? EasyImageCacheService.instance;

  EasyImageLoadingType get _effectiveLoadingType {
    if (widget.loadingType != null) return widget.loadingType!;
    if (widget.blurHash != null || _effectiveConfig.blurHash != null) {
      return EasyImageLoadingType.blurUp;
    }
    if (widget.shimmer) return EasyImageLoadingType.shimmer;
    return EasyImageLoadingType.none;
  }

  BorderRadius? get _effectiveBorderRadius {
    if (widget.shape == BoxShape.circle) return null;
    if (widget.borderRadius != null) return widget.borderRadius;
    if (widget.radius != null) return BorderRadius.circular(widget.radius!);
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAndLoad();
  }

  @override
  void didUpdateWidget(covariant EasyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.darkUrl != widget.darkUrl ||
        oldWidget.asset != widget.asset ||
        oldWidget.file != widget.file ||
        oldWidget.bytes != widget.bytes ||
        oldWidget.base64 != widget.base64 ||
        oldWidget.headers != widget.headers ||
        oldWidget.blurHash != widget.blurHash ||
        oldWidget.compress != widget.compress ||
        oldWidget.quality != widget.quality) {
      _resolveAndLoad();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _activeLoadId++;
    super.dispose();
  }

  void _resolveAndLoad() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ResolvedImageSource? source;
    try {
      source = EasyImageSourceResolver.resolve(
        url: widget.url,
        darkUrl: widget.darkUrl ?? _effectiveConfig.darkUrl,
        asset: widget.asset,
        file: widget.file,
        bytes: widget.bytes,
        base64: widget.base64,
        isDarkMode: isDark,
      );
    } catch (e, st) {
      final exc = e is EasyImageException
          ? e
          : EasyImageDecodeException('Failed to resolve image source: $e',
              cause: e, stackTrace: st);
      _handleError(exc);
      return;
    }

    if (source == null) {
      _handleError(
        const EasyImageInvalidUrlException(
          'No valid image source provided.',
          url: '',
        ),
      );
      return;
    }

    _resolvedSource = source;
    _startLoading(source);
  }

  Future<void> _startLoading(ResolvedImageSource source) async {
    final loadId = ++_activeLoadId;
    setState(() {
      _status = _LoadStatus.loading;
      _error = null;
      _downloadProgress = null;
    });

    _effectiveConfig.onLoadStart?.call();
    final stopwatch = Stopwatch()..start();

    try {
      switch (source.type) {
        case EasyImageSourceType.network:
          await _loadNetworkImage(source.stringData!, loadId, stopwatch);
          break;

        case EasyImageSourceType.asset:
          await _loadAssetImage(source.stringData!, loadId, stopwatch);
          break;

        case EasyImageSourceType.file:
          await _loadFileImage(source.stringData!, loadId, stopwatch);
          break;

        case EasyImageSourceType.bytes:
          await _loadBytesImage(source.byteData!, loadId, stopwatch);
          break;
      }
    } on EasyImageException catch (e) {
      if (loadId == _activeLoadId && !_isDisposed) {
        if (_effectiveConfig.fallbackAsset != null &&
            source.type == EasyImageSourceType.network) {
          try {
            await _loadAssetImage(
                _effectiveConfig.fallbackAsset!, loadId, stopwatch);
            return;
          } catch (_) {}
        }
        _handleError(e);
      }
    } catch (e, st) {
      if (loadId == _activeLoadId && !_isDisposed) {
        _handleError(
          EasyImageNetworkException(
            'Failed to load image: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }
  }

  Future<void> _loadNetworkImage(
      String url, int loadId, Stopwatch stopwatch) async {
    // Validate URL upfront
    ImageDownloader.validateUrl(url);

    // Apply CDN URL transformation if configured
    String requestUrl = url;
    if (_effectiveConfig.cdnTransform != null) {
      requestUrl = _effectiveConfig.cdnTransform!(
        url,
        width: widget.cacheWidth ?? widget.width?.toInt(),
        height: widget.cacheHeight ?? widget.height?.toInt(),
      );
    }

    final effectiveHeaders = {
      if (_effectiveConfig.headers != null) ..._effectiveConfig.headers!,
      if (widget.headers != null) ...widget.headers!,
    };

    final cacheKey = ImageCacheKey.generate(
      url: requestUrl,
      headers: effectiveHeaders.isEmpty ? null : effectiveHeaders,
      includeHeaders: _effectiveConfig.includeHeadersInCacheKey,
    );

    // 1. Check cache manager
    final cached = await _effectiveCacheManager.get(cacheKey);

    // If cache hit and not stale, serve immediately with 0 network calls
    if (cached != null && !cached.isStale) {
      if (loadId != _activeLoadId || _isDisposed) return;

      final format = await ImageFormatDetector.detectAsync(
        contentType: cached.contentType,
        bytes: cached.bytes,
        pathOrUrl: requestUrl,
      );

      _effectiveConfig.onCacheHit?.call(cached.source);
      _handleSuccess(
        bytes: cached.bytes,
        format: format,
        cacheSource: cached.source,
        sourceStr: requestUrl,
        stopwatch: stopwatch,
      );
      return;
    }

    // 2. Queue download with throttled concurrency & retry logic
    final downloader = ImageDownloader();
    final queue = ImageDownloadQueue.shared;

    final downloaded = await queue.enqueue<DownloadedImage>(
      () => ImageRetryService.retry<DownloadedImage>(
        retryCount: widget.retryCount,
        baseDelay: widget.retryDelay,
        customBackoff: _effectiveConfig.retryBackoff,
        isCancelled: () => loadId != _activeLoadId || _isDisposed,
        operation: () => downloader.download(
          url: requestUrl,
          headers: effectiveHeaders.isEmpty ? null : effectiveHeaders,
          cachedETag: cached?.eTag,
          cachedLastModified: cached?.lastModified,
          timeout: _effectiveConfig.timeout,
          maxBytes: _effectiveConfig.maxBytes,
          isCancelled: () => loadId != _activeLoadId || _isDisposed,
          onProgress: (received, total) {
            if (loadId == _activeLoadId && !_isDisposed) {
              _effectiveConfig.onLoadProgress?.call(received, total);
              if (total > 0) {
                setState(() {
                  _downloadProgress = received / total;
                });
              }
            }
          },
        ),
      ),
      isCancelled: () => loadId != _activeLoadId || _isDisposed,
    );

    if (loadId != _activeLoadId || _isDisposed) return;

    // 3. Handle 304 Not Modified
    if (downloaded.isNotModified && cached != null) {
      final cacheDuration = downloaded.maxAgeSeconds != null
          ? Duration(seconds: downloaded.maxAgeSeconds!)
          : _effectiveConfig.defaultCacheDuration;

      await _effectiveCacheManager.put(
        key: cacheKey,
        bytes: cached.bytes,
        contentType: cached.contentType,
        duration: cacheDuration,
        eTag: downloaded.eTag ?? cached.eTag,
        lastModified: downloaded.lastModified ?? cached.lastModified,
        cacheControl: downloaded.cacheControl,
      );

      final format = await ImageFormatDetector.detectAsync(
        contentType: cached.contentType,
        bytes: cached.bytes,
        pathOrUrl: requestUrl,
      );

      _effectiveConfig.onCacheHit
          ?.call(EasyImageCacheSource.networkNotModified);
      _handleSuccess(
        bytes: cached.bytes,
        format: format,
        cacheSource: EasyImageCacheSource.networkNotModified,
        sourceStr: requestUrl,
        stopwatch: stopwatch,
      );
      return;
    }

    // 4. Handle 200 Fresh Download
    final cacheDuration = downloaded.maxAgeSeconds != null
        ? Duration(seconds: downloaded.maxAgeSeconds!)
        : _effectiveConfig.defaultCacheDuration;

    if (!downloaded.noStore) {
      await _effectiveCacheManager.put(
        key: cacheKey,
        bytes: downloaded.bytes,
        contentType: downloaded.contentType,
        duration: cacheDuration,
        eTag: downloaded.eTag,
        lastModified: downloaded.lastModified,
        cacheControl: downloaded.cacheControl,
        noStore: downloaded.noStore,
      );
    }

    final format = await ImageFormatDetector.detectAsync(
      contentType: downloaded.contentType,
      bytes: downloaded.bytes,
      pathOrUrl: requestUrl,
    );

    _effectiveConfig.onCacheHit?.call(EasyImageCacheSource.network);
    _handleSuccess(
      bytes: downloaded.bytes,
      format: format,
      cacheSource: EasyImageCacheSource.network,
      sourceStr: requestUrl,
      stopwatch: stopwatch,
    );
  }

  Future<void> _loadAssetImage(
      String assetPath, int loadId, Stopwatch stopwatch) async {
    final byteData = await rootBundle.load(assetPath).catchError((e, st) {
      throw EasyImageDecodeException(
        'Unable to load asset: $assetPath ($e)',
        cause: e,
        stackTrace: st,
      );
    });

    if (loadId != _activeLoadId || _isDisposed) return;

    final bytes = byteData.buffer.asUint8List();
    final format = await ImageFormatDetector.detectAsync(
      bytes: bytes,
      pathOrUrl: assetPath,
    );

    _handleSuccess(
      bytes: bytes,
      format: format,
      cacheSource: EasyImageCacheSource.memory,
      sourceStr: assetPath,
      stopwatch: stopwatch,
    );
  }

  Future<void> _loadFileImage(
      String filePath, int loadId, Stopwatch stopwatch) async {
    if (kIsWeb) {
      throw const EasyImageUnsupportedPlatformException(
        'dart:io File is not supported on Web.',
        platform: 'web',
      );
    }

    try {
      getFileImageProvider(filePath);
    } catch (e, st) {
      throw EasyImageDecodeException(
        'Failed to load file at $filePath: $e',
        cause: e,
        stackTrace: st,
      );
    }

    if (loadId != _activeLoadId || _isDisposed) return;

    final format = ImageFormatDetector.detect(pathOrUrl: filePath);
    _handleSuccess(
      bytes: Uint8List(0),
      format: format,
      cacheSource: EasyImageCacheSource.disk,
      sourceStr: filePath,
      stopwatch: stopwatch,
    );
  }

  Future<void> _loadBytesImage(
      Uint8List bytes, int loadId, Stopwatch stopwatch) async {
    Uint8List effectiveBytes = bytes;

    // Optional compression
    if (widget.compress) {
      effectiveBytes = await ImageCompressionService.instance.compressBytes(
        bytes,
        options: ImageCompressionOptions(quality: widget.quality),
      );
    }

    final format = await ImageFormatDetector.detectAsync(bytes: effectiveBytes);
    _handleSuccess(
      bytes: effectiveBytes,
      format: format,
      cacheSource: EasyImageCacheSource.memory,
      sourceStr: 'memory:bytes',
      stopwatch: stopwatch,
    );
  }

  void _handleSuccess({
    required Uint8List bytes,
    required EasyImageFormat format,
    required EasyImageCacheSource cacheSource,
    required String sourceStr,
    required Stopwatch stopwatch,
  }) {
    stopwatch.stop();

    if (_isDisposed) return;

    setState(() {
      _status = _LoadStatus.success;
      _loadedBytes = bytes;
      _detectedFormat = format;
      _error = null;
    });

    _effectiveConfig.onLoadComplete?.call(
      EasyImageLoadInfo(
        source: sourceStr,
        cacheSource: cacheSource,
        byteLength: bytes.isNotEmpty ? bytes.length : null,
        duration: stopwatch.elapsed,
      ),
    );
  }

  void _handleError(EasyImageException error) {
    if (_isDisposed) return;

    setState(() {
      _status = _LoadStatus.error;
      _error = error;
    });

    _effectiveConfig.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (_status) {
      case _LoadStatus.loading:
        content = EasyImageLoader(
          loadingType: _effectiveLoadingType,
          customPlaceholder: widget.placeholder,
          blurHash: widget.blurHash ?? _effectiveConfig.blurHash,
          lowResUrl: widget.lowResUrl ?? _effectiveConfig.lowResUrl,
          width: widget.width,
          height: widget.height,
          borderRadius: _effectiveBorderRadius,
          backgroundColor: widget.backgroundColor,
          progress: _downloadProgress,
        );
        break;

      case _LoadStatus.error:
        content = EasyImageError(
          error: _error,
          customErrorWidget: widget.errorWidget,
          onRetry: () {
            widget.onRetry?.call();
            _resolveAndLoad();
          },
          width: widget.width,
          height: widget.height,
          borderRadius: _effectiveBorderRadius,
          backgroundColor: widget.backgroundColor,
        );
        break;

      case _LoadStatus.success:
        content = EasyImageRenderer(
          source: _resolvedSource!,
          bytes: _loadedBytes,
          format: _detectedFormat,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
          colorBlendMode: widget.colorBlendMode,
          opacity: widget.opacity,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          fadeIn: widget.fadeIn,
          fadeDuration: widget.fadeDuration,
        );
        break;
    }

    // Apply circular shape or border radius clipping
    if (widget.shape == BoxShape.circle) {
      content = ClipOval(child: content);
    } else if (_effectiveBorderRadius != null &&
        _effectiveBorderRadius != BorderRadius.zero) {
      content = ClipRRect(
        borderRadius: _effectiveBorderRadius!,
        child: content,
      );
    }

    // Wrap in Hero if heroTag provided
    if (widget.heroTag != null) {
      content = Hero(
        tag: widget.heroTag!,
        child: content,
      );
    }

    // Wrap in Semantics for accessibility
    if (widget.semanticLabel != null) {
      content = Semantics(
        label: widget.semanticLabel,
        image: true,
        child: content,
      );
    }

    return content;
  }
}

/// Backwards compatibility alias for [EasyImage].
typedef SmartImage = EasyImage;
